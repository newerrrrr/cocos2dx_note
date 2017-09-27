
--自动更新流程: 下载服务器配置表-->下载版本文件-->下载资源

local UpdateMgr = {}
setmetatable(UpdateMgr,{__index = _G})
setfenv(1, UpdateMgr)

local updateState = {
    None              = 1,
    DownloadServerCfg = 2, --下载服务器配置表
    DownloadVersion   = 3, --下载版本号文件
    DownloadManifest  = 4, --下载MD5列表
    DownloadMyself    = 5, --下载自身  
    Updating          = 6, --更新中
  }

local updateEvents = {
  DownloadServerCfgFail = 1,  --下载服务器配置表失败
  DownLoadVersionFail   = 2,  --下载版本号文件失败
  ParseVersionError     = 3,  --解析版本号文件失败
  ParseManifestError    = 4,  --解析MD5列表失败
  SkipUpdate            = 5,  --跳过更新
  NotFoundLocalManifest = 6,  --找不到本地MD5列表
  AlreadyUpToDate       = 7,  --当前是最新版本
  LocalVersionIsBiger   = 8,  --本地安装包版本高于服务器版本
  FoundNewVersion       = 9,  --发现新的版本
  DecompressZips        = 10, --解压缩失败
  DecompressFail        = 11, --解压缩失败    
  AssertFileRenameFail  = 12, --文件重命名失败
  FileSizeErrors        = 13, --下载到的文件大小不对
  UpdateSuccess         = 14, --更新成功  
  UpdateError           = 15, --更新失败  
}

--本模块包含的lua文件,用于清除lua栈
local update_pkg_lua = {
  "src.resUpdate.UpdateEntry",
  "src.resUpdate.UpdateLayer",
  "src.resUpdate.UpdateMgr",
  "src.resUpdate.Lang",
}

--本模块涉及的资源清单,供下载时优先更新自身
local update_pkg_keys = {
  ["src/resUpdate.zip"]             = 1,
  ["res/cocos/resource_update.csb"] = 2,
}

--自动更新模块搜索路径配置
local update_search_paths  = {
}


local lang                 = require("src.resUpdate.Lang") --多语言

local isIOS                = false --ios平台

local supportBatchDownload = true --是否支持多线程下载
local ID_BATCH             = "@batch" --多线程下载ID 

local RETRY_MAX            = 3 --最大失败重连次数
local retryCount           = 0 --当前失败重连次数

local server_cfg_name      = "server_cfg.json" --服务器配置列表
local version_name         = "version.manifest" --版本文件
local manifest_name        = "project.manifest" --md5资源列表

local server_cfg        --更新下来的服务器配置表(包含自动更新标志及其url, 游戏服url等信息)
local local_manifest    --apk包里的资源列表
local remote_manifest   --刚下载的最新资源列表
local download_list     --待下载的资源列表项
local localPkgManifest  --供外部访问本地安装包的版本号

--路径参数
local _fileUtils = cc.FileUtils:getInstance()
local localPath  = _fileUtils:getDefaultResourceRootPath() --注意IOS平台该路径为空字串!!
local storagePath         --缓存路径
local path_server_cfg     --服务器列表文件路径
local path_version        --版本文件路径
local path_manifest       --MD5资源列表文件路径
local path_manifest_tmp   --用于临时存储下载的MD5资源列表文件
local path_manifest_zip   
local path_download_list --下载列表项

--记录下载进度
local totalBytes, finishBytes, tmpFinish   

local _viewUI     --显示层UI对象
local _dloadImpl  --下载代理
local _state      --下载状态


function init(target, path)
  release_print("UpdateMgr:init")

  --路径参数
  storagePath        = path 
  path_server_cfg    = storagePath .. server_cfg_name  
  path_version       = storagePath .. version_name
  path_manifest      = storagePath .. manifest_name
  path_manifest_tmp  = storagePath .. manifest_name..".tmp"
  path_manifest_zip  = storagePath .. manifest_name..".zip"
  path_download_list = storagePath .. "download.list"

  --自动更新模块搜索路径配置
  update_search_paths = {
    storagePath.."res/cocos/",
    storagePath.."res/",
    storagePath.."src/",
  }

  --添加搜索路径
  initSearchPath() 

  --如果老版本C++未支持则单线程更新
  if nil == ResUpdateEx.batchDownloadFileAsync then 
    supportBatchDownload = false 
  end 
supportBatchDownload = false 
  release_print("is batch download :", supportBatchDownload)
end 


function start(target, viewUI)
  release_print("UpdateMgr:start")

  release_print("UpdateMgr:ptr=", ResUpdateEx.batchDownloadFileAsync)

  _viewUI = viewUI 
  _dloadImpl = ResUpdateEx:create()
  _dloadImpl:retain()
  _dloadImpl:addUpdateHandler(onError, onProgress, onSuccess)

  isIOS = isPlatformIOS() 
  release_print("is platform ios:", isIOS) 

  initManifest() 
end 

function exit()
  release_print("UpdateMgr:exit")
  _dloadImpl:removeUpdateHandler()
  _dloadImpl:release()
end 

--注意IOS平台 localPath 为空字串!!, 读取本地路径时必须排除搜索路径影响
function loadJsonFile(filepath, isLocalPath)
  local content = ""
  if isLocalPath then --要求读取本地路径的文件 
    -- content = _dloadImpl:getFileString(filepath)

    --由于ios不方便获取本地资源包路径(沙盒路径),所以这里仅排除缓存路径,读取后再恢复
    local searchPaths = _fileUtils:getSearchPaths()
    deinitSearchPath(true)
    content = _fileUtils:getStringFromFile(filepath)
    _fileUtils:setSearchPaths(searchPaths)

  elseif _fileUtils:isFileExist(filepath) then 
    content = _fileUtils:getStringFromFile(filepath)
  end 

  if content ~= "" then 
    --如果utf8包含3个bom字节,则先去掉bom,否则会导致json解码失败
    if string.byte(content, 1) == 0xef and string.byte(content, 2) == 0xbb and string.byte(content, 3) == 0xbf then
      local pos = string.find(content, "{")
      if pos then 
        content = string.sub(content, pos) 
      end 
    end 

    return cjson.decode(content)
  end 
end 

function saveJsonToFile(jsonTable, storagePath)
  if nil == jsonTable or type(jsonTable) ~= "table" then return end 

  _fileUtils:writeStringToFile(cjson.encode(jsonTable), storagePath)
end 

function initManifest()
  _fileUtils:createDirectory(storagePath)

  --读取apk包里的本地资源列表
  local_manifest = loadJsonFile(localPath..manifest_name, true) 
  if nil == local_manifest then 
    handleEvents(updateEvents.NotFoundLocalManifest) 
    return 
  end 
  localPkgManifest = local_manifest 

  --如果缓存目录的版本 < apk版本,则选择最新的一份,以用来与服务器最新版本进行比较 
  local cach_manifest = loadJsonFile(path_manifest) --缓存目录的资源列表 
  if cach_manifest then 
    local cmpBig, cmpSmall = compareVersion(cach_manifest.version, local_manifest.version)
    if cmpBig < 0 or (cmpBig == 0 and cmpSmall < 0) then --本地apk版本比缓存里的版本高
      release_print("apk version > cache version !!!, remove cache data...") 
      clearStorage()
    else 
      local_manifest = cach_manifest 
    end 
  end 

  --下载服务器配置表
  downloadServerCfg()
end 

--出错后尝试重新下载
function onError(customId)
  release_print("onError", customId)
  --多线程更新资源时在最后结束时再处理重试下载,单线程则直接重试下载
  if _state == updateState.Updating and supportBatchDownload then 
    --nothing 
  else 
    retryDownload()
  end 
end 


function onProgress(total, downloaded, customId)
  -- release_print("onProgress: ", total, downloaded, customId)
  if _state ~= updateState.Updating then return end 

  if finishBytes + downloaded > tmpFinish then 
    tmpFinish = finishBytes + downloaded 
  end 
  _viewUI:updateLoading(100*tmpFinish/totalBytes)

  if downloaded >= total then 
    finishBytes = finishBytes + downloaded 
    tmpFinish = finishBytes 
  end 
end 


local function updateWhenSuccessOne(fileName)
  local item 
  for k, v in pairs(download_list.assets) do 
    if v[1] == fileName then 
      item = v 
      table.remove(download_list.assets, k)
      break 
    end 
  end 

  if nil == item then return false end 

  local name = item[1]  
  local fullpath = storagePath..name 

  --校验文件大小是否一致 
  local filesize = _fileUtils:getFileSize(fullpath)
  if filesize ~= item[2].fileSize then 
    release_print("wrong file size --->", name, filesize, item[2].fileSize)
    table.insert(download_list.fileSizeError, item)

  else 
    local ext = _fileUtils:getFileExtension(name)
    if ext == ".zip" then --解压缩zip文件
      local found = false 
      for k, v in pairs(download_list.downloadedZips) do 
        if v == item then 
          found = true 
        end 
      end 
      if not found then 
        table.insert(download_list.downloadedZips, item) 
      end 
    end 
  end 

  saveJsonToFile(download_list, path_download_list) --状态同步到文件 
  
  return true 
end 

--下载单个文件成功 
function onSuccess(customId)
  release_print("onSuccess:", customId)

  if not supportBatchDownload then 
    retryCount = 0 --clear 
  end 

  if _state == updateState.DownloadServerCfg then 
    parseServerCfg()

  elseif _state == updateState.DownloadVersion then 
    parseVersion()

  elseif _state == updateState.DownloadManifest then 
    parseManifest()

  elseif _state == updateState.DownloadMyself then --更新自身
    updateWhenSuccessOne(download_list.assets[1][1])

    if hasMyKeysInDownloadList() then 
      downloadMyself() --继续下载自身
    else 
      if hasFileSizeError() then 
        handleEvents(updateEvents.FileSizeErrors)

      elseif decompressZipFiles() and not hasUnzipError() then 
        release_print("end download update myself, restart now...")
        clearAndReloadUpdate() 

      else 
        handleEvents(updateEvents.DecompressFail)
      end 
    end 

  elseif customId == ID_BATCH then --批量更新结束
    release_print("end batch download: ", finishBytes, totalBytes)
    if hasFileSizeError() then 
      handleEvents(updateEvents.FileSizeErrors)

    elseif decompressZipFiles() and not hasUnzipError()  then 
      if hasAssetToDownload() then 
        release_print("has unfinish download, now retry...")
        retryDownload() --中间有下载失败时        
      else 
        handleEvents(updateEvents.UpdateSuccess)
      end 
    else 
      handleEvents(updateEvents.DecompressFail)
    end 

  else 
    _viewUI:updateLoading(100*tmpFinish/totalBytes)
    updateWhenSuccessOne(customId)

    if not supportBatchDownload then 
      downloadAssets() --继续下载下一个文件 
    end 
  end 
end 

--下载服务器配置列表(里面存放自动更新的url)
function downloadServerCfg()
  _state = updateState.DownloadServerCfg 

  --只使用本地安装包里的地址下载, 否则多平台共用一套资源会指向同一个配置文件
  local urlInfo = localPkgManifest.serverCfgUrl -- local_manifest.serverCfgUrl 
  if urlInfo then 
    local url = getUrl(urlInfo, server_cfg_name, _state)
    _dloadImpl:downLoadFileAsync(url, path_server_cfg, server_cfg_name)
  else 
    release_print("invalid server cfg url !!!!")
    handleEvents(updateEvents.DownloadServerCfgFail)
  end 
end 

function parseServerCfg()
  server_cfg = loadJsonFile(path_server_cfg)
  if nil == server_cfg then 
    handleEvents(updateEvents.DownloadServerCfgFail)
    return 
  end 

  if string.lower(server_cfg.updateEnabled) == "true" then 
    downloadVersion()
  else 
    handleEvents(updateEvents.SkipUpdate) --跳过更新
  end 
end 

function downloadVersion()
  release_print("@@@ downloadVersion")
  _state = updateState.DownloadVersion
  local url = getUrl(server_cfg.updateUrl, version_name, _state)
  _dloadImpl:downLoadFileAsync(url, path_version, version_name)
end 

function parseVersion()
  release_print("@@@ parseVersion")
  local newVerFile = loadJsonFile(path_version)
  if nil == newVerFile then 
    handleEvents(updateEvents.ParseVersionError)
    return 
  end 

  release_print("remote version, local version", newVerFile.version, local_manifest.version)
  local cmpBig, cmpSmall = compareVersion(newVerFile.version, local_manifest.version)
  if cmpBig == 0 and cmpSmall == 0 then --版本相等
    handleEvents(updateEvents.AlreadyUpToDate)

  elseif cmpBig < 0 or (cmpBig == 0 and cmpSmall < 0) then --本地的版本号 > 服务器端版本号
    handleEvents(updateEvents.LocalVersionIsBiger)

  else
    if cmpBig > 0 then --发现新的apk
      clearStorage() 
      _viewUI:showPopup(lang["newMajorVesion"], exitGame, nil)     
    else 

      --如果上次有未完成的下载项,则继续, 否则下载资源列表 
      if _fileUtils:isFileExist(path_manifest_tmp) then         
        if _fileUtils:isFileExist(path_download_list) then
          remote_manifest = loadJsonFile(path_manifest_tmp)
          local ret1, ret2 = compareVersion(remote_manifest.version, newVerFile.version) 
          if ret1 == 0 and ret2 == 0 then 
            release_print("resume last download ...")
            handleEvents(updateEvents.FoundNewVersion)
            return 
          else 
            remote_manifest = nil 
            _fileUtils:removeFile(path_manifest_tmp)
            _fileUtils:removeFile(path_download_list)
          end 
        else 
          _fileUtils:removeFile(path_manifest_tmp)
        end 
      end 

      downloadManifest()
    end 
  end 
end 

function downloadManifest()
  release_print("downloadManifest")
  _state = updateState.DownloadManifest

  local name = manifest_name..".zip"
  local url = getUrl(server_cfg.updateUrl, name, _state)
  _dloadImpl:downLoadFileAsync(url, path_manifest_zip, name) 
end 

function parseManifest() 
  release_print("parseManifest") 
  --解压缩从服务器下载完的最新资源列表 
  if _fileUtils:isFileExist(path_manifest_zip) then 
    if _dloadImpl:decompress(path_manifest_zip) then 
      remote_manifest = loadJsonFile(path_manifest)
      _fileUtils:removeFile(path_manifest_zip)
      _fileUtils:renameFile(path_manifest, path_manifest_tmp) --先改成临时名,等自动更新成功后再恢复名字      
    end 
  else 
    release_print("parseManifest: not exist:", path_manifest_zip) 
  end 

  if nil == remote_manifest then 
    handleEvents(updateEvents.ParseManifestError)
    return 
  end 
  release_print("remote_manifest.version, local_manifest.version", remote_manifest.version, local_manifest.version)
  local cmpBig, cmpSmall = compareVersion(remote_manifest.version, local_manifest.version)
  if cmpBig == 0 and cmpSmall == 0 then 
    handleEvents(updateEvents.AlreadyUpToDate) 

  elseif cmpBig < 0 or (cmpBig == 0 and cmpSmall < 0) then --本地的版本号比服务器端新
    handleEvents(updateEvents.LocalVersionIsBiger)

  else 
    handleEvents(updateEvents.FoundNewVersion) 
  end 
end 

function downloadMyself()
  _state = updateState.DownloadMyself

  --文件名插入时间戳信息
  local name = download_list.assets[1][1]
  local timeStamp = download_list.assets[1][2].timeStamp 
  local ext = _fileUtils:getFileExtension(name)
  local tmpName = addTimeStampForPath(name, ext, timeStamp)

  local url = getUrl(server_cfg.updateUrl, tmpName, _state)
  local dstpath = storagePath .. name
  release_print("start to download:", name) 

  _dloadImpl:downLoadFileAsync(url, dstpath, name)
end 

--下载资源文件
function downloadAssets()
  release_print("downloadAssets, is batch ", supportBatchDownload)

  local function getFileInfo(assetItem)
    if nil == assetItem then return end 

    local info = {}

    --文件名插入时间戳信息
    local name = assetItem[1]
    local timeStamp = assetItem[2].timeStamp 
    local ext = _fileUtils:getFileExtension(name)
    local tmpName = addTimeStampForPath(name, ext, timeStamp)

    info.srcUrl = getUrl(server_cfg.updateUrl, tmpName, updateState.Updating) 
    info.storagePath = storagePath .. name 
    info.fileName = name 

    return info 
  end 

  if hasAssetToDownload() then 
    _state = updateState.Updating

    _viewUI:updateLoading(100*tmpFinish/totalBytes)

    if supportBatchDownload then --多线程下载
      local infos = {}
      local tmp 
      for k, v in pairs(download_list.assets) do 
        tmp = getFileInfo(v)
        if tmp then 
          table.insert(infos, tmp)
        end 
      end 
      _dloadImpl:batchDownloadFileAsync(infos, ID_BATCH) 

    else --单线程下载
      local info = getFileInfo(download_list.assets[1])      
      _dloadImpl:downLoadFileAsync(info.srcUrl, info.storagePath, info.fileName) 
      release_print("start to down:", info.srcUrl) 
    end 

  else 
    if hasFileSizeError() then 
      handleEvents(updateEvents.FileSizeErrors) 

    elseif decompressZipFiles() and not hasUnzipError() then 
      handleEvents(updateEvents.UpdateSuccess)

    else 
      handleEvents(updateEvents.DecompressFail)
    end 
  end 
end 

--重新下载解压缩失败项
function redownloadUnzipFails()
  for k, v in pairs(download_list.unzipFails) do 
    table.insert(download_list.assets, v)
  end 
  download_list.unzipFails = {}
  saveJsonToFile(download_list, path_download_list) 

  downloadAssets()
end 

function redownloadFileSizeError()
  release_print("redownloadFileSizeError")

  local fullpath 
  for k, v in pairs(download_list.fileSizeError) do 
    fullpath = storagePath .. v[1]
    if _fileUtils:getFileSize(fullpath) ~= v[2].fileSize then 
      table.insert(download_list.assets, v) 
    end 
  end 
  download_list.fileSizeError = {}

  saveJsonToFile(download_list, path_download_list) 

  downloadAssets()
end 

function decompressZipFiles() 
  release_print("decompressZipFiles begin...")

  local decompressOk = true 
  if download_list and download_list.downloadedZips then 
    local item = download_list.downloadedZips[1]
    while item do 
      local path = storagePath..item[1] 
      release_print("    -->", path)
      if not _dloadImpl:decompress(path) then 
        release_print("decompress fail-->", path) 
        decompressOk = false 
        table.insert(download_list.unzipFails, item)
      end 
      table.remove(download_list.downloadedZips, 1)
      saveJsonToFile(download_list, path_download_list) 
      _fileUtils:removeFile(path) 

      item = download_list.downloadedZips[1]
    end 
  end 
  release_print("decompressZipFiles end...",decompressOk)
  return decompressOk 
end 

function hasUnzipError()
  if download_list.unzipFails and #download_list.unzipFails > 0 then 
    return true 
  end 

  return false 
end 

--下载到的文件大小不一致
function hasFileSizeError()
  if download_list.fileSizeError and #download_list.fileSizeError > 0 then
    release_print("has filesize error !!!")
    return true 
  end 
  return false 
end 

function hasAssetToDownload()
  if download_list and download_list.assets then 
    return #download_list.assets > 0 
  end 

  return false 
end 


function stringSplit(input, delimiter)
  input = tostring(input)
  delimiter = tostring(delimiter)
  if (delimiter=='') then return false end
  local pos,arr = 0, {}
  -- for each divider found
  for st,sp in function() return string.find(input, delimiter, pos, true) end do
    table.insert(arr, string.sub(input, pos, st - 1))
    pos = sp + 1
  end
  table.insert(arr, string.sub(input, pos))
  return arr
end 

--分别比较大版本号和小版本号: <0 小于  ==0 等于 >0 大于
--(版本号格式:"0.0.0.17" 或者 "0.0.1.7"  前半部分代表大版本号, 后半部分代表小版本号)
function compareVersion(strVer1, strVer2) 
  local ret1, ret2 
  local s = stringSplit(strVer1, ".")
  local t = stringSplit(strVer2, ".")
  ret1 = tonumber(s[1]) - tonumber(t[1])
  if ret1 == 0 then 
    ret1 = tonumber(s[2]) - tonumber(t[2])
  end 

  ret2 = tonumber(s[3]) - tonumber(t[3])
  if ret2 == 0 then 
    ret2 = tonumber(s[4]) - tonumber(t[4])
  end 

  return ret1, ret2
end 

--与本地比较生成差异项供下载 
function genDiff()
  release_print("genDiff") 

  local function addToDLoadList(key, val)
    if update_pkg_keys[key] then --如果是自动更新资源则全部放到数组前面优先更新
      table.insert(download_list.assets, 1, {key, val})
    else 
      table.insert(download_list.assets, {key, val})
    end 
  end 

  download_list = loadJsonFile(path_download_list)

  if download_list and download_list.version == remote_manifest.version then --上一次下载被中断, 继续上次下载
    if nil == download_list.assets then 
      download_list.assets = {}
    end 
    if nil == download_list.downloadedZips then 
      download_list.downloadedZips = {} --保存已下载完的zip项,等全部下载完再统一解压缩
      download_list.unzipFails = {} --解压缩失败项
    end 
    if nil == download_list.fileSizeError then --下载到的文件大小不对
      download_list.fileSizeError = {}
    end 
  else 
    
    if nil == download_list then 
      download_list = {}
      download_list.version = remote_manifest.version 
      download_list.assets = {}
      download_list.downloadedZips = {} --保存已下载完的zip项,等全部下载完再统一解压缩
      download_list.unzipFails = {} --解压缩失败项
      download_list.fileSizeError = {} --下载的文件大小不对
    end 

    --比较本地和服务器端资源列表差异
    local assets_1 = local_manifest.assets 
    local assets_2 = remote_manifest.assets 
    for key, val in pairs(assets_1) do 
      if assets_2[key] then 
        if assets_1[key].md5 ~= assets_2[key].md5 then --MD5不同

          -- 如果是zip包,其包含子列表, 以子列表是否有差异为准 
          if assets_1[key].childList and assets_2[key].childList then 
            local childList_1 = assets_1[key].childList
            local childList_2 = assets_2[key].childList
            local sameFlag = true 
            for i, v in pairs(childList_1) do 
              if nil == childList_2[i] or childList_2[i].md5 ~= childList_1[i].md5 then 
                sameFlag = false 
                break 
              end 
            end

            if sameFlag then 
              for i, v in pairs(childList_2) do 
                if nil == childList_1[i] or childList_1[i].md5 ~= childList_2[i].md5 then 
                  sameFlag = false 
                  break 
                end 
              end 
            end 

            if not sameFlag then --子列表有差异才下载该zip包 
              addToDLoadList(key, assets_2[key])
            end 

          else 
            addToDLoadList(key, assets_2[key])
          end 
        end 
      else 
        --删除项 
        local ext = _fileUtils:getFileExtension(key)
        if ext == ".zip" then --如果是压缩文件, 则将相应的目录/文件删除
          local fullpath = storagePath .. string.sub(key, 1, string.len(key)-string.len(ext))
          if _fileUtils:isFileExist(fullpath) then 
            release_print("delete file:", fullpath)
            _fileUtils:removeFile(fullpath)

          elseif _fileUtils:isDirectoryExist(fullpath) then 
            release_print("delete dir:", fullpath)
            _fileUtils:removeDirectory(fullpath.."/")
          end 
        else 
          release_print("delete file:", key)
          _fileUtils:removeFile(storagePath .. key)
        end 
      end 
    end 

    for key, val in pairs(assets_2) do 
      --新增项
      if nil == assets_1[key] then 
        addToDLoadList(key, assets_2[key]) 
      end 
    end 

    saveJsonToFile(download_list, path_download_list) 
  end 
end 


function getUrl(urlInfo, filePath, state)

  --下载version文件和 md5 列表文件共用同一个域名, 下载资源使用另一域名(或备份域名)
  local host 
  if state == updateState.DownloadServerCfg then 
    host =  isIOS and urlInfo.url_ios or urlInfo.url_android
  else
    local packageUrl = isIOS and urlInfo.url_ios or urlInfo.url_android 
    if state == updateState.DownloadVersion or state == updateState.DownloadManifest then 
      host = packageUrl.checkUrl 

    else --资源url(可使用备份url)
      if retryCount > RETRY_MAX and packageUrl.cdnUrl2 ~= "" then 
        host = packageUrl.cdnUrl2 
      else 
        host = packageUrl.cdnUrl 
      end
    end 
  end 

  assert(nil ~= host)

  if string.sub(host, -1, -1) ~= "/" then 
    host = host .. "/"
  end 
  if string.sub(filePath, 1, 1) == "/" then 
    filePath = string.sub(filePath, 2) 
  end 

  return host .. filePath 
end 


function retryDownload()
  release_print("retryDownload: ", retryCount)

  retryCount = retryCount + 1 

  local function resumeDownload()
    _viewUI:hideUI()

    if _state == updateState.DownloadServerCfg then 
      downloadServerCfg()

    elseif _state == updateState.DownloadVersion then 
      downloadVersion()

    elseif _state == updateState.DownloadManifest then 
      downloadManifest()

    elseif _state == updateState.DownloadMyself then 
      downloadMyself()

    elseif _state == updateState.Updating then 
      downloadAssets()
    end 
  end 

  if retryCount > RETRY_MAX then --超过一定次数,使用备份url下载
    _viewUI:showPopup(lang["networkError"], resumeDownload, exitGame)
  else 
    resumeDownload()
  end 
end 


function handleEvents(event)

  --已经是最新版本
  if event == updateEvents.SkipUpdate then 
    release_print("skip update ...")
    enterGame()

  elseif event == updateEvents.AlreadyUpToDate then 
    release_print("AlreadyUpToDate")
    enterGame()

  elseif event == updateEvents.LocalVersionIsBiger then 
    release_print("local apk versiton > remote version, remove cache...")
    clearStorage() 
    enterGame()

  --发现新版本
  elseif event == updateEvents.FoundNewVersion then 
    release_print("FoundNewVersion")
    local cmpBig, cmpSmall = compareVersion(remote_manifest.version, local_manifest.version)
    if cmpBig > 0 then --发现新的apk
      clearStorage() 
      _viewUI:showPopup(lang["newMajorVesion"], exitGame, nil)           
    else 

      genDiff() 

      totalBytes = 0 
      finishBytes = 0 
      tmpFinish = 0 

      --如果上次有下载到的文件大小错误,则一并下载
      for k, v in pairs(download_list.fileSizeError) do 
        local fullpath = storagePath .. v[1]
        if _fileUtils:getFileSize(fullpath) ~= v[2].fileSize then 
          table.insert(download_list.assets, v) 
        end 
      end 
      download_list.fileSizeError = {}

      --统计总的下载字节
      for k, v in pairs(download_list.assets) do 
        totalBytes = totalBytes + v[2].fileSize
      end 
      _viewUI:setTipStrVisible(false)
      release_print("==download total size:", totalBytes)

      if hasMyKeysInDownloadList() then --更新自身
        downloadMyself()

      else --更新其他资源
        if totalBytes > 300*1024 then --下载量大于300KB时提示用户,否则直接静默下载
          local str 
          if totalBytes > 1024*1024 then 
            str = string.format("%.1fMB", totalBytes/(1024*1024))
          else 
            str = string.format("%dKB", totalBytes/1024)
          end 
          _viewUI:showPopup(string.format(lang["newVesion"], str), downloadAssets, exitGame)
          _viewUI:setTipStrVisible(true)
        else 
          downloadAssets() 
        end 
      end 
    end 

  --更新成功
  elseif event == updateEvents.UpdateSuccess then  
    release_print("UpdateSuccess")
    _fileUtils:removeFile(path_download_list)
    _fileUtils:renameFile(path_manifest_tmp, path_manifest)

    enterGame() 

  --安装包找不到资源列表
  elseif event == updateEvents.NotFoundLocalManifest then 
    release_print("no local manifest") 
    _viewUI:showPopup(lang["noLocalManifest"], exitGame, nil)

  --下载服务器配置列表失败
  elseif event == updateEvents.DownloadServerCfgFail then 
    release_print("download server cfg file fail") 
    retryDownload()

  --解析文件失败
  elseif event == updateEvents.ParseVersionError or event == updateEvents.ParseManifestError then
    retryDownload()

  --解压缩失败
  elseif event == updateEvents.DecompressFail then  
    _viewUI:showPopup(lang["decompressFail"], redownloadUnzipFails, exitGame)

  --重命名失败
  elseif event == updateEvents.AssertFileRenameFail then 
    _viewUI:showPopup(lang["fileRenameFail"], downloadAssets, exitGame)

  --下载到的文件大小不对
  elseif event == updateEvents.FileSizeErrors then 
    _viewUI:showPopup(lang["fileSizeWrong"], redownloadFileSizeError, exitGame)

  elseif event == updateEvents.UpdateError then 

  else 
    release_print("invalid event !!", event)
    _viewUI:showPopup(lang["updateFail"], exitGame, nil)
  end 
end 

--检查是否需要更新本模块, 如有,则优先更新
function checkAndUpdateMyself()
  release_print("checkAndUpdateMyself")

  if download_list and hasAssetToDownload() then 
    for k, v in pairs(download_list.assets) do 
      if update_pkg_keys[v[1]] then 
        release_print("start download update myself ...")
        --开始更新
        downloadAssets()
        return true 
      end 
    end 
  end 

  return false 
end 

--清缓存(不一定保证能清除成功)
function clearStorage()
  release_print("clearStorage")
  _fileUtils:removeFile(path_manifest_tmp)
  _fileUtils:removeFile(path_download_list)
  _fileUtils:removeDirectory(storagePath) 
  _fileUtils:createDirectory(storagePath)   
end 

--重新加载本模块
function clearAndReloadUpdate()
  for k, v in pairs(update_pkg_lua) do 
    package.preload[v] = nil 
    package.loaded[v] = nil 
  end
  _fileUtils:purgeCachedEntries()
  require("src.resUpdate.UpdateEntry")
end 

--下载列表中是否包含自动更新自身
function hasMyKeysInDownloadList()
  if hasAssetToDownload() and update_pkg_keys[download_list.assets[1][1]] then 
    return true 
  end 
  
  return false 
end 

--清除制定的搜索路径
function clearSeachPaths(removedPaths)
  release_print("clearSeachPaths")
  
  local tmp = {}
  local found 
  local searchPaths = _fileUtils:getSearchPaths() 
  for k, v in pairs(searchPaths) do 
    found = false 
    for i, p in pairs(removedPaths) do 
      if v == p then 
        found = true 
        break
      end 
    end 
    if not found then 
      table.insert(tmp, v)
    end 
  end 

  _fileUtils:setSearchPaths(tmp)
end 

--进入自动更新模块前, 设置相关的搜索路径
function initSearchPath()
  clearSeachPaths(update_search_paths)

  local searchPaths = _fileUtils:getSearchPaths() 
  for k, v in pairs(update_search_paths) do 
    table.insert(searchPaths, 1, v)
  end 
  _fileUtils:setSearchPaths(searchPaths)
end 

--进入游戏前, 如果自动更新目录下无内容,则将相应的搜索路径移除
--bForce:强制移除所有缓存路径(包括缓存根路径), 所以之后执行自动更新,
--       必须确保重新执行C++自动更新入口, 因为缓存根路径在C++处设置!!!
function deinitSearchPath(bForce)
  local searchPaths = _fileUtils:getSearchPaths()
  local isNotExist = true 

  local function removeSearchPath(path)
    local tmp = {}
    for k, v in pairs(searchPaths) do 
      if v ~= path then 
        table.insert(tmp, v)
      end 
    end 

    searchPaths = tmp 
  end 

  for k, v in pairs(update_search_paths) do 
    if bForce or (not _fileUtils:isDirectoryExist(v)) then 
      removeSearchPath(v)
    else 
      isNotExist = false 
    end 
  end 

  release_print("===bForce, isNotExist", bForce, isNotExist)
  if isNotExist then --如果 res/ 和  src/目录均不存在, 则将缓存根目录也一并移除
    removeSearchPath(storagePath)
  end 

  for k, v in pairs(searchPaths) do 
    release_print("===searchpath:", v)
  end 

  _fileUtils:setSearchPaths(searchPaths)
end 

--在后缀名之前添加时间戳,拼出新的路径名
function addTimeStampForPath(pathname, ext, timeStamp)
  -- local ext = _fileUtils:getFileExtension(pathname)  
  --注意:string.gsub替换有问题,如果路径中目录名与扩展名相同会出问题,会将"."与"/"混淆,
  --如 res/fnt/test.fnt 
  --替换的结果是 res@201604291745fnt/test@201604291745.fnt
  -- local tmpname = string.gsub(pathname, ext, timeStamp..ext) 
  local tmpname = string.sub(pathname, 1, string.len(pathname)-string.len(ext)) .. timeStamp..ext
  return tmpname 
end 

function isPlatformIOS()
  -- cc.PLATFORM_OS_WINDOWS = 0
  -- cc.PLATFORM_OS_LINUX   = 1
  -- cc.PLATFORM_OS_MAC     = 2
  -- cc.PLATFORM_OS_ANDROID = 3
  -- cc.PLATFORM_OS_IPHONE  = 4
  -- cc.PLATFORM_OS_IPAD    = 5

  local target = cc.Application:getInstance():getTargetPlatform()
  if target == 4 or target == 5 then 
    return true 
  end 

  return false 
end 

function enterGame()
  deinitSearchPath()

  _dloadImpl:startGame()
end 


function exitGame()
  cc.Director:getInstance():endToLua()

  if isIOS then 
    os.exit(0)
  end 
end 

function getLocalPkgVersion()
  if localPkgManifest then 
    return localPkgManifest.version 
  end 
end 

function getServerCfg()
  return server_cfg 
end 

return UpdateMgr 
