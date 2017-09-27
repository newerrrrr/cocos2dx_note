
--自动更新流程管理

local UpdateMgr = {}
setmetatable(UpdateMgr,{__index = _G})
setfenv(1, UpdateMgr)

local updateState = {
            None             = 1,
            DownloadVersion  = 2,
            DownloadManifest = 3,
            Updating         = 4,
          }

local updateEvents = {
  DownLoadVersionFail   = 1,
  ParseVersionError     = 2,
  ParseManifestError    = 3,
  
  NotFoundLocalManifest = 4,
  AlreadyUpToDate       = 5,
  LocalVersionIsBiger   = 6, 
  FoundNewVersion       = 7,
  UpdateSuccess         = 8,
  DecompressFail        = 9,
}

local lang = require("src.resUpdate.Lang")
local _fileUtils = cc.FileUtils:getInstance()

--路径参数
local localPath          = _fileUtils:getDefaultResourceRootPath() --注意IOS平台该路径为空字串!!
local storagePath        = _fileUtils:getWritablePath() .. "ResUpdate/"
local path_version       = storagePath .. "version.manifest"
local path_manifest      = storagePath .. "project.manifest"
local path_manifest_tmp  = storagePath .. "project.manifest.tmp"
local path_manifest_zip  = storagePath .. "project.manifest.zip"
local path_download_list = storagePath .. "download.list"

local local_manifest  --apk包里的资源列表
local remote_manifest --刚下载的最新资源列表
local downLoad_list   --待下载的资源列表项

local _viewUI     --显示层UI对象
local _dloadImpl  --下载代理
local _state      --下载状态

local RETRY_MAX       = 3                   --最大失败重连次数
local retryCount      = 0                   --当前失败重连次数
local useBackupUrl    = false               --是否使用备份下载点


--本模块包含的lua文件,供清lua栈时
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
local update_search_paths = {
  storagePath.."res/cocos/",
  storagePath.."res/",
  storagePath.."src/",
}


local totalBytes, finishBytes               --记录下载进度



function start(target, viewUI)
  print("UpdateMgr:start")
  _viewUI = viewUI 

  _dloadImpl = ResUpdateEx:create()
  _dloadImpl:retain()
  _dloadImpl:addUpdateHandler(onError, onProgress, onSuccess)

  initManifest()
end 

function exit()
  print("UpdateMgr:exit")
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
    return cjson.decode(content)
  end 
end 


function initManifest()
  _fileUtils:createDirectory(storagePath)

  local_manifest = loadJsonFile(localPath .. "project.manifest", true) --apk包里的资源列表
  if nil == local_manifest then 
    handleEvents(updateEvents.NotFoundLocalManifest) 
    return 
  end 

  --如果更新目录的版本低于apk版本,则选择最新的一份,以用来与服务器最新版本进行比较 
  local cach_manifest = loadJsonFile(path_manifest) --下载目录的资源列表 
  if cach_manifest then 
    if cach_manifest.version < local_manifest.version then 
      print("apk version > cache version !!!, remove cache data...") 
      clearStorage()
    else 
      local_manifest = cach_manifest 
    end 
  end 

  --下载版本文件
  downloadVersion()
end 

--出错后尝试重新下载
function onError()
  print("onError")
  retryDownload()
end 


function onProgress(total, downloaded, customId)
  -- print("onProgress: ", total, downloaded, customId)
  if customId == "@assets" then 
    _viewUI:updateLoading(100*(finishBytes + downloaded)/totalBytes)
    if downloaded >= total then 
      finishBytes = finishBytes + downloaded 
    end 
  end 
end 


--下载单个文件成功 
function onSuccess(customId)
  print("onSuccess:", customId)

  retryCount = 0 --clear 

  if customId == "@version" then 
    parseVersion()

  elseif customId == "@manifest" then 
    parseManifest()

  elseif customId == "@assets" then 
    local item = downLoad_list.assets[1]
    local timeStamp = item[2].timeStamp
    local pathname = storagePath .. item[1]  
    local ext = _fileUtils:getFileExtension(pathname)
    local tmpname = addTimeStampForPath(pathname, ext, timeStamp)
    if ext == ".zip" then --解压缩zip文件
      if _dloadImpl:decompress(tmpname) then 
        _fileUtils:removeFile(tmpname) 
      else 
        handleEvents(updateEvents.DecompressFail)
        _fileUtils:removeFile(tmpname)  
        return 
      end 
    else 
      --非压缩文件去掉时间戳
      _fileUtils:renameFile(tmpname, pathname)
    end 

    table.remove(downLoad_list.assets, 1) 
    saveDloadListToFile() --状态同步到文件

    --如果下载的是自动更新自身,如果仍有未下载的则继续下载,否则重新加载
    if update_pkg_keys[item[1]] then 
      if not hasMyKeysInDownloadList() then 
        print("end download update myself, restart now...")
        clearAndReloadUpdate()
        return 
      end 
    end 

    --继续下载下一个文件
    downloadAssets() 
  end 
end 


function downloadVersion()
  print("@@@ downloadVersion")
  _state = updateState.DownloadVersion
  local url = getUrl(local_manifest, local_manifest.remoteVersionUrl)
  _dloadImpl:downLoadFileAsync(url, path_version, "@version")
end 

function parseVersion()
  print("@@@ parseVersion")
  local newVerFile = loadJsonFile(path_version)
  if nil == newVerFile then 
    handleEvents(updateEvents.ParseVersionError)
    return 
  end 

  print("remote version, local version", newVerFile.version, local_manifest.version)
  if newVerFile.version == local_manifest.version then 
    handleEvents(updateEvents.AlreadyUpToDate)

  elseif newVerFile.version < local_manifest.version then 
    handleEvents(updateEvents.LocalVersionIsBiger)

  else 

    if string.sub(newVerFile.version, 1, 3) > string.sub(local_manifest.version, 1, 3) then  
      clearStorage() 
      _viewUI:showPopup(lang["newMajorVesion"], exitGame, nil)     
    else 

      --如果上次有未完成的下载项,则继续, 否则下载资源列表 
      if _fileUtils:isFileExist(path_manifest_tmp) then 
        if _fileUtils:isFileExist(path_download_list) then
          remote_manifest = loadJsonFile(path_manifest_tmp)
          if remote_manifest.version == newVerFile.version then 
            print("resume last download ...")
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
  print("downloadManifest")
  _state = updateState.DownloadManifest
  local url = getUrl(local_manifest, local_manifest.remoteManifestUrl)
  _dloadImpl:downLoadFileAsync(url, path_manifest_zip, "@manifest") 
end 

function parseManifest() 
  print("parseManifest") 
  --解压缩从服务器下载完的最新资源列表 
  if _fileUtils:isFileExist(path_manifest_zip) then 
    if _dloadImpl:decompress(path_manifest_zip) then 
      remote_manifest = loadJsonFile(path_manifest)
      _fileUtils:removeFile(path_manifest_zip)
      _fileUtils:renameFile(path_manifest, path_manifest_tmp) --先改成临时名,等自动更新成功后再恢复名字      
    end 
  end 

  if nil == remote_manifest then 
    handleEvents(updateEvents.ParseManifestError)
    return 
  end 
  print("remote_manifest.version, local_manifest.version", remote_manifest.version, local_manifest.version)
  if remote_manifest.version == local_manifest.version then 
    handleEvents(updateEvents.AlreadyUpToDate) 

  elseif remote_manifest.version < local_manifest.version then --本地的版本号比服务器端新
    handleEvents(updateEvents.LocalVersionIsBiger)

  else 
    handleEvents(updateEvents.FoundNewVersion) 
  end 
end 

--每次下载一个资源文件
function downloadAssets()
  print("downloadAssets")

  if #downLoad_list.assets > 0 then 
    _state = updateState.Updating

    --文件名插入时间戳信息
    local pathname = downLoad_list.assets[1][1]
    local timeStamp = downLoad_list.assets[1][2].timeStamp 
    local ext = _fileUtils:getFileExtension(pathname)
    pathname = addTimeStampForPath(pathname, ext, timeStamp)

    local url = getUrl(remote_manifest, pathname)
    local filepath = storagePath .. pathname
    print("start to down:", pathname) 

    _dloadImpl:downLoadFileAsync(url, filepath, "@assets")

    _viewUI:updateLoading(100*finishBytes/totalBytes)
    
  else 
    handleEvents(updateEvents.UpdateSuccess) 
  end 
end 


--获取资源的差异项供下载
function genDiff()

  local function addToDLoadList(key, val)
    if update_pkg_keys[key] then --如果是自动更新资源则全部放到数组前面优先更新
      table.insert(downLoad_list.assets, 1, {key, val})
    else 
      table.insert(downLoad_list.assets, {key, val})
    end 
  end 


  downLoad_list = loadJsonFile(path_download_list)

  if downLoad_list and downLoad_list.version == remote_manifest.version then --上一次下载被中断, 继续上次下载
    --nothing
  else 
    
    if nil == downLoad_list then 
      downLoad_list = {}
      downLoad_list.version = remote_manifest.version 
      downLoad_list.assets = {}
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
            print("delete file:", fullpath)
            _fileUtils:removeFile(fullpath)

          elseif _fileUtils:isDirectoryExist(fullpath) then 
            print("delete dir:", fullpath)
            _fileUtils:removeDirectory(fullpath.."/")
          end 
        else 
          print("delete file:", key)
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
  end 
end 

function saveDloadListToFile()
  if nil == downLoad_list or type(downLoad_list) ~= "table" then return end 

  _fileUtils:writeStringToFile(cjson.encode(downLoad_list), path_download_list)
end 


function getUrl(manifest, filePath)
  if retryCount > RETRY_MAX and manifest.packageUrl2 ~= "" then 
    useBackupUrl = true 
  end 

  local host = useBackupUrl and manifest.packageUrl2 or manifest.packageUrl 
  local url 
  if string.sub(host, -1) ~= "/" and string.sub(filePath, 1) ~= "/" then 
    url = host .. "/" .. filePath 
  else 
    url = host .. filePath 
  end 

  return url 
end 


function retryDownload()
  print("retryDownload: ", retryCount)

  retryCount = retryCount + 1 

  local function resumeDownload()
    _viewUI:hideUI()

    if _state == updateState.DownloadVersion then 
      downloadVersion()

    elseif _state == updateState.DownloadManifest then 
      downloadManifest()

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
  if event == updateEvents.AlreadyUpToDate then 
    print("AlreadyUpToDate")
    enterGame()

  elseif event == updateEvents.LocalVersionIsBiger then 
    print("local apk versiton > remote version, remove cache...")
    clearStorage() 
    enterGame()

  --发现新版本
  elseif event == updateEvents.FoundNewVersion then 
    print("FoundNewVersion")
    if string.sub(remote_manifest.version, 1, 3) > string.sub(local_manifest.version, 1, 3) then   
      clearStorage() 
      _viewUI:showPopup(lang["newMajorVesion"], exitGame, nil)           
    else 

      genDiff()

      totalBytes = 0 
      finishBytes = 0 
      for k, v in pairs(downLoad_list.assets) do 
        totalBytes = totalBytes + v[2].fileSize
      end 
      print("==download total size:", totalBytes)
      _viewUI:setTipStrVisible(false)
      
      if not checkAndUpdateMyself() then --如果不更新自身,则开始更新其他资源
        if totalBytes > 300*1024 then 
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
    print("UpdateSuccess")
    _fileUtils:removeFile(path_download_list)
    _fileUtils:renameFile(path_manifest_tmp, path_manifest)

    enterGame()

  --安装包找不到资源列表
  elseif event == updateEvents.NotFoundLocalManifest then 
    print("no local manifest") 
    _viewUI:showPopup(lang["noLocalManifest"], exitGame, nil)

  --解析文件失败
  elseif event == updateEvents.ParseVersionError or event == updateEvents.ParseManifestError then
    retryDownload()

  --解压缩失败
  elseif event == updateEvents.DecompressFail then  
    print("DecompressFail") 
    _viewUI:showPopup(lang["decompressFail"], exitGame, nil)

  else 
    print("invalid event !!", event)
    _viewUI:showPopup(lang["updateFail"], exitGame, nil)
  end 
end 

--检查是否需要更新本模块, 如有,则优先更新
function checkAndUpdateMyself()
  print("checkAndUpdateMyself")

  if downLoad_list and #downLoad_list.assets > 0 then 
    for k, v in pairs(downLoad_list.assets) do 
      if update_pkg_keys[v[1]] then 
        print("start download update myself ...")
        --开始更新
        downloadAssets()
        return true 
      end 
    end 
  end 

  return false 
end 

--清缓存
function clearStorage()
  print("clearStorage")
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
  if #downLoad_list.assets > 0 and update_pkg_keys[downLoad_list.assets[1][1]] then 
    return true 
  end 
  
  return false 
end 

--进入自动更新模块前, 设置相关的搜索路径
function initSearchPath()
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
      -- if v == path then 
      --   table.remove(searchPaths, k)  
      --   break 
      -- end 
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

  print("===bForce, isNotExist", bForce, isNotExist)
  if isNotExist then --如果 res/ 和  src/目录均不存在, 则将缓存根目录也一并移除
    removeSearchPath(storagePath)
  end 

  for k, v in pairs(searchPaths) do 
    print("===searchpath:", v)
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

function enterGame()
  deinitSearchPath()

  _dloadImpl:startGame()
end 


function exitGame()
  -- _dloadImpl:exitUpdate()
  cc.Director:getInstance():endToLua()

  -- cc.PLATFORM_OS_WINDOWS = 0
  -- cc.PLATFORM_OS_LINUX   = 1
  -- cc.PLATFORM_OS_MAC     = 2
  -- cc.PLATFORM_OS_ANDROID = 3
  -- cc.PLATFORM_OS_IPHONE  = 4
  -- cc.PLATFORM_OS_IPAD    = 5
  local target = cc.Application:getInstance():getTargetPlatform()
  --if target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_IPAD then
  if target == 4 or target == 5 then 
    os.exit(0)
  end
end 



return UpdateMgr 
