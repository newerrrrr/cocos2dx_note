
--自动更新逻辑管理器
local M = {}

require("json")
require("cocos.cocos2d.functions") --会用到部分接口如 string.split
local Lang = require("src.app.update.Lang") 

local name_version       = "version.manifest" --版本文件
local name_manifest      = "project.manifest" --md5资源列表
local fileUtils          = cc.FileUtils:getInstance()
local storagePath        = fileUtils:getWritablePath() .. "ResUpdate/"

local path_vertion       = storagePath .. name_version
local path_vertion_tmp   = storagePath .. name_version .. ".tmp"
local path_manifest      = storagePath .. name_manifest
local path_manifest_tmp  = path_manifest .. ".tmp"   --用于临时存储下载的资源列表文件
local path_download_list = storagePath .. "download.list"

local local_version         --本地的版本号文件
local local_manifest        --本地的资源列表
local remote_manifest       --服务端的最新资源列表
local download_list         --待下载的资源列表项

local retryCount         = 0 --当前重连次数
local downloadingCount   = 0 --当前正在下载的文件个数
local batchCountMax      = 5 --并发下载的个数上线

local totalFileCount     = 0 --本次需要更新的文件总数

--缓存搜索路径
local searchPathCache = {
    storagePath,
    storagePath.."res",
    storagePath.."src",
}

--本模块包含的lua文件,用于更新自身后清除lua栈 
local myselfLuaFiles = {
    -- ["src/app/update/UpdateScene.luac"] = true,
    -- ["src/app/update/Lang.luac"] = true,
    ["src/app/update/UpdateMgr.luac"] = true,
    ["src/app/update/DownloadUtil.luac"] = true,
} 

local updateState = {
    None              = 1,
    DownloadVersion   = 2, --下载版本号文件
    DownloadManifest  = 3, --下载MD5列表
    DownloadMyself    = 4, --下载自身  
    DownloadAssets    = 5, --下载清单里的文件
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

local _viewUI 
local _state

function M:startUpdate(view)
	release_print("[UpdateMgr]:startUpdate")

	_viewUI = view 
    M:initManifest()
	M:downloadVersion()
end 

function M:initManifest()
    release_print("[initManifest]") 
    retryCount = 0 
    downloadingCount = 0 
    fileUtils:createDirectory(storagePath)

    --读取apk包里的本地资源列表
    local_version = M:loadJsonFile(name_version, true) 
    local_manifest = M:loadJsonFile(name_manifest, true) 
    if nil == local_manifest then 
        M:handleEvents(updateEvents.NotFoundLocalManifest) 
        return 
    end 

    --如果缓存目录的版本 > apk版本, 则以缓存的版本为准, 用来与服务器最新版本进行比较 
    local cache_version = M:loadJsonFile(storagePath..name_version) 
    local cache_manifest = M:loadJsonFile(storagePath..name_manifest)
    
    if cache_version and cache_manifest then 
        local bigVerKey = M:isPlatformIOS() and "appVerIos" or "appVerAnd"
        local cmpBigRet = M:compareVersion(cache_version[bigVerKey], local_version[bigVerKey]) --大版本号比较
        local cmpSmallRet = M:compareVersion(cache_version["version"], local_version["version"]) --小版本号比较 
        if cmpBigRet or cmpSmallRet then --本地apk版本比缓存里的版本高 
            release_print("apk version > cache version !!!, remove cache data...") 
            M:clearStorage()
        else 
            local_version = cache_version 
            local_manifest = cache_manifest
        end 
    end 
    assert(local_manifest and local_manifest ~= "") 
end 

function M:downloadVersion()
    release_print("[downloadVersion]")
    _state = updateState.DownloadVersion
    M:requestOneFile(local_version.packageUrl, name_version, M.onResponse)
end 

function M:parseVersion()
    release_print("[parseVersion]")
    local remote_version = M:loadJsonFile(storagePath..name_version..".tmp")
    if nil == remote_version then 
        M:handleEvents(updateEvents.ParseVersionError)
        return 
    end 

    --先判断是否需要强更
    local bigVerKey = M:isPlatformIOS() and "appVerIos" or "appVerAnd" 
    release_print(" big  version: remote, local =", remote_version[bigVerKey], local_version[bigVerKey])
    release_print("small version: remote, local =", remote_version.version, local_version.version)
    if M:compareVersion(remote_version[bigVerKey], local_version[bigVerKey]) then --大版本号较新,需要强更 
        _viewUI:showMsgBox(Lang["foundNewPkg"], 
        function()
            local appDownloadUrl = M:isPlatformIOS() and remote_version.appUrlIos or remote_version.appUrlAnd 
            cc.Application:getInstance():openURL(appDownloadUrl) 
            M:clearStorage() 
            M:exitGame() 
        end, 
        M.exitGame) 
        return 
    end 

    --比较小版本号, 判断是否需要更新资源 
    if M:compareVersion(remote_version.version, local_version.version) then 
        release_print("need to update ...")

        --如果上次有未完成的下载项, 则继续之前的下载, 反之更新资源列表 
        if fileUtils:isFileExist(path_manifest_tmp) and fileUtils:isFileExist(path_download_list) then 
            remote_manifest = M:loadJsonFile(path_manifest_tmp) 
            if remote_manifest.version == remote_version.version then 
                release_print("resume last download ...")
                M:genDownloadList() 
                if M:needToUpdateMyself() then 
                    M:downloadMyself() 
                else 
                    M:downloadAssets() 
                end 
                return 
            else 
                fileUtils:removeFile(path_manifest_tmp) 
                fileUtils:removeFile(path_download_list)
            end 
        end 

        --下载资源列表
        M:downloadManifest()
    else 
        M:handleEvents(updateEvents.AlreadyUpToDate)
    end 
end 

function M:downloadManifest() 
    release_print("[downloadManifest]") 
    _state = updateState.DownloadManifest
    if fileUtils:isFileExist(path_manifest_tmp) then 
        fileUtils:removeFile(path_manifest_tmp)
    end 
    if fileUtils:isFileExist(path_download_list) then 
        fileUtils:removeFile(path_download_list)
    end 
    M:requestOneFile(local_version.packageUrl, name_manifest, M.onResponse)
end 

function M:parseManifest()
    release_print("[parseManifest]")
    remote_manifest = M:loadJsonFile(path_manifest_tmp)
    if nil == remote_manifest then 
        M:handleEvents(updateEvents.ParseManifestError)
        return 
    end 
    M:genDownloadList()

    if M:needToUpdateMyself() then 
        M:downloadMyself() 
    else 
        M:downloadAssets() 
    end 
end 

function M:genDownloadList()
    release_print("[genDownloadList]:") 
    local function addToDownloadList(key, val)
        if myselfLuaFiles[key] then --如果是自动更新资源则全部放到数组前面优先更新
            table.insert(download_list.myself, {key, val})
        else 
            table.insert(download_list.assets, {key, val})
        end 
    end 

    assert(remote_manifest and local_manifest)
    download_list = M:loadJsonFile(path_download_list)
    
    if download_list and download_list.version == remote_manifest.version then --如果上一次下载被中断, 继续上次下载
        if nil == download_list.assets then download_list.assets = {} end 
        if nil == download_list.myself then download_list.myself = {} end 

    else --全新下载 
        if nil == download_list then 
            download_list = {} 
            download_list.version = remote_manifest.version 
            download_list.assets = {} 
            download_list.myself = {} 
        end 

        --比较本地和服务器端资源列表差异
        local assets_1 = local_manifest.assets 
        local assets_2 = remote_manifest.assets 
        for key, v in pairs(assets_1) do 
            if assets_2[key] then --修改项
                if assets_1[key].md5 ~= assets_2[key].md5 then --MD5不同
                    addToDownloadList(key, assets_2[key])
                end 
            else --删除项 
                release_print("delete file:", key) 
                if fileUtils:isFileExist(storagePath .. key) then 
                    fileUtils:removeFile(storagePath .. key) 
                end 
            end 
        end 

        for key, v in pairs(assets_2) do             
            if nil == assets_1[key] then --新增项
                addToDownloadList(key, v) 
            end 
        end 
        M:saveAsJsonFile(download_list, path_download_list) 
        dump(download_list, "===download_list")
    end 

    --文件总数
    totalFileCount = #download_list.myself + #download_list.assets
end 

function M:downloadMyself() 
    release_print("[downloadMyself]:", #download_list.myself) 
    _state = updateState.DownloadMyself 
    for i = 1, batchCountMax do 
        local item = download_list.myself[i] 
        local key = item and item[1] or nil 
        if key then 
            if myselfLuaFiles[key] then 
                M:requestOneFile(remote_manifest.packageUrl, key, M.onResponse) 
            end 
        end 
    end 
end 

function M:downloadAssets() 
    release_print("[downloadAssets]: left count = ", #download_list.assets)
    if #download_list.assets == 0 and downloadingCount == 0 then 
        M:handleEvents(updateEvents.UpdateSuccess) 
    else 
        _state = updateState.DownloadAssets
        for i = 1, batchCountMax do 
            local item = download_list.assets[i]
            local key = item and item[1] or nil 
            if key then 
                M:requestOneFile(remote_manifest.packageUrl, key, M.onResponse) 
            end 
        end 
    end 
end 

function M:findListItem(list, filepath)
    for k, v in pairs(list) do 
        if v[1] == filepath then 
            return k, v 
        end 
    end 
end 

--下载文件服务器响应
function M:onResponse(code, filepath) 
    downloadingCount = math.max(0, downloadingCount - 1) 
    release_print("[onResponse]:", code, filepath, downloadingCount)

    if code == "success" then 
        if _state == updateState.DownloadVersion then 
            M:parseVersion() 

        elseif _state == updateState.DownloadManifest then 
            M:parseManifest() 

        elseif _state == updateState.DownloadMyself then --更新自身
            local k1, v1 = M:findListItem(download_list.myself, filepath)
            if k1 then --从列表中清除 
                table.remove(download_list.myself, k1)
                fileUtils:renameFile(storagePath..filepath..".tmp", storagePath..filepath)
                M:saveAsJsonFile(download_list, path_download_list) 
            end 
            if #download_list.myself > 0 then 
                if downloadingCount == 0 then --开始第二批下载
                    M:downloadMyself()
                end  
            else
                assert(downloadingCount == 0) 
                M:clearAndReloadUpdate() 
            end 

        elseif _state == updateState.DownloadAssets then --更新资源
            local k1, v1 = M:findListItem(download_list.assets, filepath)
            if k1 then --从列表中清除
                table.remove(download_list.assets, k1) 
                fileUtils:renameFile(storagePath..filepath..".tmp", storagePath..filepath)
                M:saveAsJsonFile(download_list, path_download_list) 
            end 

            if #download_list.assets > 0 then 
                if downloadingCount == 0 then --开始第二批下载 
                    M:downloadAssets()
                end 
            else --更新成功
                assert(downloadingCount == 0)
                M:handleEvents(updateEvents.UpdateSuccess)
            end 

            --UI显示进度
            if not tolua.isnull(_viewUI) then 
                local percent = 100*(totalFileCount - #download_list.assets)/totalFileCount
                if percent > 100 then percent = 100 end 
                if percent < 0 then percent = 0 end 
                _viewUI:updatePercent(math.floor(percent)) 
            end 
        end 
        
    else 
        if downloadingCount == 0 then --等上一轮都结束后开始重试下载
            M:retryDownload() 
        end 
    end 
end 

function M:checkFile(filepath) 
    local tmpPath = storagePath .. filepath .. ".tmp"
    if fileUtils:getFileSize(tmpPath) > 0 then 
        return true 
    end 
    release_print("[checkFile]: file size error: ", filepath) 
    return result 
end 

function M:saveDataFile(filePath, data)
    --先检查目录,如果不存在则递归创建
    filePath = string.gsub(string.trim(filePath), "\\", "/" )
    local info = io.pathinfo(filePath) 
    if not fileUtils:isFileExist(info.dirname) then 
        fileUtils:createDirectory(info.dirname)
    end 
    io.writefile(filePath, data) 
end

function M:loadJsonFile(filepath, isInApk) 
    local content 
    if isInApk then --要求读取在安装包里的文件(排除缓存路径,读取后再恢复) 
        local searchPaths = fileUtils:getSearchPaths() 
        local searchPaths_tmp = {} 
        for i, path in pairs(searchPaths) do 
            local found = false 
            for k, v in pairs(searchPathCache) do 
                if path == v then 
                    found = true 
                    break 
                end 
            end 
            if not found then 
                table.insert(searchPaths_tmp, path)
            end 
        end 
        fileUtils:setSearchPaths(searchPaths_tmp) 
        content = fileUtils:getStringFromFile(filepath)
        fileUtils:setSearchPaths(searchPaths)

    elseif fileUtils:isFileExist(filepath) then 
        content = fileUtils:getStringFromFile(filepath)
    end 

    if content and content ~= "" then 
        --如果utf8包含3个bom字节,则先去掉bom,否则会导致json解码失败
        if string.byte(content, 1) == 0xef and string.byte(content, 2) == 0xbb and string.byte(content, 3) == 0xbf then
            local pos = string.find(content, "{")
            if pos then 
                content = string.sub(content, pos) 
            end 
        end 
        if cjson and cjson.decode then 
            content = cjson.decode(content) 
        else 
            content = json.decode(content) --效率太低了!!! 300K 文件耗时35s !!
        end 
    end 
    
    return content 
end 

function M:saveAsJsonFile(data, savePath) 
    if nil == data or type(data) ~= "table" then return end 
    fileUtils:writeStringToFile(json.encode(data), savePath)
end 

--下载单个文件API
function M:requestOneFile(host, filePath, callback) 
    downloadingCount = downloadingCount + 1 

    local xhr = cc.XMLHttpRequest:new() 
    -- xhr.timeout = 8000 -- 8秒超时
    xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    xhr:open("GET", host..filePath) 

    -- readyState: UNSENT=0; OPENED=1; HEADERS_RECEIVED=2; LOADING=3; DONE=4;
    local function onReadyStateChanged()         
        if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then --lua_xml_http_request.cpp有个bug:只处理了状态码200的情况
            local response = xhr.response 
            M:saveDataFile(storagePath..filePath..".tmp", response) 
            M:performWithDelay(function() 
                local code = M:checkFile(filePath) and "success" or "error"
                if callback then callback(self, code, filePath) end 
            end, 0) 

        elseif xhr.readyState == 1 and xhr.status == 0 then -- 网络问题,异常断开 
            M:performWithDelay(function() 
                if callback then callback(self, "error", filePath) end 
            end, 0) 
        else 
            release_print("onReadyStateChanged: readyState, status=", xhr.readyState, xhr.status)
        end 
        xhr:unregisterScriptHandler() 
    end 
    xhr:registerScriptHandler(onReadyStateChanged) 
    xhr:send() 
end 

--处理事件
function M:handleEvents(event)
    if event == updateEvents.SkipUpdate then --跳过更新(比如苹果审核期间)
        release_print("skip update ...")
        M:enterGame()

    elseif event == updateEvents.AlreadyUpToDate then --已经是最新版本
        release_print("already up-to-date") 
        M:enterGame()

    elseif event == updateEvents.LocalVersionIsBiger then 
        release_print("local apk versiton > remote version, remove cache...")
        M:clearStorage() 
        M:enterGame()
    
    elseif event == updateEvents.NotFoundLocalManifest then --安装包找不到资源列表
        release_print("no local manifest") 
        if tolua.isnull(_viewUI) then return end 
        _viewUI:showPopBox(Lang["noLocalManifest"], M.exitGame, nil) 

    elseif event == updateEvents.ParseVersionError then 
        release_print("parse vertion fail !!") 
        M:retryDownload()

    elseif event == updateEvents.ParseManifestError then
        release_print("parse manifest fail !!") 
        M:retryDownload()

    elseif event == updateEvents.UpdateSuccess then 
        release_print("update success...") 
        fileUtils:removeFile(path_download_list) 
        fileUtils:renameFile(path_vertion_tmp, path_vertion)
        fileUtils:renameFile(path_manifest_tmp, path_manifest)
        M:performWithDelay(function() 
            M:enterGame()
        end, 0)
    end 
end 

--比较版本号, ver1 > ver2 则返回true
function M:compareVersion(strVer1, strVer2) 
    local s = string.split(strVer1, ".")
    local t = string.split(strVer2, ".")
    for i = 1, #s do 
        if tonumber(s[i]) > tonumber(t[i]) then 
            return true 
        end 
    end 
    return false 
end 

--清缓存(不一定保证能清除成功) 
function M:clearStorage() 
    release_print("[clearStorage]") 
    fileUtils:removeFile(path_vertion_tmp) 
    fileUtils:removeFile(path_manifest_tmp) 
    fileUtils:removeFile(path_download_list) 
    fileUtils:removeDirectory(storagePath) 
    -- fileUtils:createDirectory(storagePath) 
end 

--重新加载本模块
function M:clearAndReloadUpdate() 
    release_print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
    release_print("[clearAndReloadUpdate]")
    for k, v in pairs(myselfLuaFiles) do 
        local info = io.pathinfo(k)
        local key = info.dirname .. info.basename
        package.preload[key] = nil 
        package.loaded[key] = nil 
    end 

    fileUtils:purgeCachedEntries() 
    cc.Director:getInstance():getEventDispatcher():dispatchCustomEvent("EventHotUpdateRestart") 
end 

function M:enterGame()
    release_print("[enterGame]")
    local loginScene = require("app/views/LoginScene"):create()
    cc.Director:getInstance():replaceScene(loginScene)    
end 

function M:exitGame()
    release_print("[exitGame]")
    cc.Director:getInstance():endToLua() 
    if M:isPlatformIOS() then 
        os.exit(0)
    end 
end 

function M:isPlatformIOS() 
    --如下变量的初始化有可能晚于自动更新
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


function M:retryDownload() 
    release_print("[retryDownload]: retryCount, state=", retryCount, _state) 
    local function resumeDownload()
        retryCount = retryCount + 1 
        M:performWithDelay(function() 
            if _state == updateState.DownloadVersion then 
                M:downloadVersion()

            elseif _state == updateState.DownloadManifest then 
                M:downloadManifest()

            elseif _state == updateState.DownloadMyself then 
                M:downloadMyself() 

            elseif _state == updateState.DownloadAssets then 
                M:downloadAssets()               
            end 
        end, 0) 
    end 

    if retryCount >= 3 then --超过一定次数弹框提示
        _viewUI:showMsgBox(Lang["networkError"], resumeDownload, M.exitGame) 
    else 
        resumeDownload() 
    end 
end 

--下载列表中是否包含自动更新自身
function M:needToUpdateMyself()
    if download_list and download_list.myself and #download_list.myself > 0 then 
        return true 
    end 
    return false 
end 

--延迟一帧执行(防止线程堵塞导致UI无法及时刷新)
function M:performWithDelay(callback, delay)
    local delayTimer  
    local function doCallback()
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(delayTimer) 
        if tolua.isnull(_viewUI) then return end 
        if callback then callback() end 
    end 
    delayTimer = cc.Director:getInstance():getScheduler():scheduleScriptFunc(doCallback, delay or 0, false)
end 

return M 
