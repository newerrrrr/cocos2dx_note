local audioRecorderHelper = {}
setmetatable(audioRecorderHelper,{__index = _G})
setfenv(1,audioRecorderHelper)

local isAPIValid

function isAudioRecordSupport()

    if nil == isAPIValid then 
        isAPIValid = false 
        local curLocalPkgVer = require("src.resUpdate.UpdateMgr").getLocalPkgVersion()
        if curLocalPkgVer then 
            local ver = string.split(curLocalPkgVer, ".")
            if tonumber(ver[1]) > 2 or tonumber(ver[2]) > 0 then 
                isAPIValid = true 
            end 
        end 
    end 

    return isAPIValid  
end 


--暂停背景音乐/音效
function prepareBackgroundAudio()
    g_musicManager.pauseMusic()
    g_musicManager.pauseAllEffects()
end 

--恢复背景音乐/音效
function restoreBackgroundAudio()
    g_musicManager.resumeMusic()
    g_musicManager.resumeAllEffects()
end 

-------------------------------------
--录音
-------------------------------------

--开始录音: 
function startAudioRecord(path, onErrorCallback)
    if not isAudioRecordSupport() then 
        if onErrorCallback then 
            onErrorCallback()
        end 
        return 
    end 

    prepareBackgroundAudio()

    --onResult() result:"success" , "error"
    local function onResult(result, path) 
        if result ~= "success" then 
            print("onRecordError, path=", path) 
            if onErrorCallback then 
                onErrorCallback() 
            end 
            restoreBackgroundAudio()
        end 
    end 

    local target = cc.Application:getInstance():getTargetPlatform()

    if target == cc.PLATFORM_OS_ANDROID then        

        local params = {path, onResult}
        local luaj = require "cocos.cocos2d.luaj"
        luaj.callStaticMethod("com/record/amrRecord/AmrRecordAndPlay", "startRecord", params)

    elseif target == cc.PLATFORM_OS_IPAD or target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_MAC then 
        local args = {pathname = path, scriptHandler = onResult}
        local luaoc = require "cocos.cocos2d.luaoc"        
        local result  = luaoc.callStaticMethod("ARRecorder","startRecord",args)
        print("oc call func result: ", result) 
    end
end

--结束录音:
function stopAudioRecord(onStopResult)
    if not isAudioRecordSupport() then 
        if onStopResult then 
            onStopResult(false)
        end 
        return 
    end 

    --onResult() result:"success" , "error"
    local function onResult(result, path)         
        print("onRecordResult: ", result)
        if onStopResult then 
            onStopResult(result == "success", path)
        end 
        restoreBackgroundAudio()
    end 

    local target = cc.Application:getInstance():getTargetPlatform()  

    if target == cc.PLATFORM_OS_ANDROID then
        local params = {onResult}
        local luaj = require "cocos.cocos2d.luaj"
        luaj.callStaticMethod("com/record/amrRecord/AmrRecordAndPlay", "stopRecord", params)

    elseif target == cc.PLATFORM_OS_IPAD or target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_MAC then 
        local args = {scriptHandler = onResult}
        local luaoc = require "cocos.cocos2d.luaoc"       
        luaoc.callStaticMethod("ARRecorder","stopRecord", args)
    end
end

--取消录音
function cancleAudioRecord()
    if not isAudioRecordSupport() then 
        return 
    end 

    local target = cc.Application:getInstance():getTargetPlatform()
    if target == cc.PLATFORM_OS_ANDROID then
        local luaj = require "cocos.cocos2d.luaj"
        luaj.callStaticMethod("com/record/amrRecord/AmrRecordAndPlay", "cancelRecord")

    elseif target == cc.PLATFORM_OS_IPAD or target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_MAC then 
        local luaoc = require "cocos.cocos2d.luaoc"
        luaoc.callStaticMethod("ARRecorder","cancelRecord")
    end

    restoreBackgroundAudio()
end



--------------------------------------
--播放
-------------------------------------

--播放语音
function startAudioPlay(fullpath, finishHandler, errorHandler)
    if not isAudioRecordSupport() then 
        if errorHandler then 
            errorHandler()
        end 
        return 
    end 

    prepareBackgroundAudio()

    --onPlayResult() result:"finish" , "error"
    local function onPlayResult(ret, path)
        print("onPlayResult: ret=", ret)

        if ret == "finish" then 
            if finishHandler then 
                finishHandler()
            end 
        else 
            if errorHandler then 
                errorHandler()
            end 
        end 
        restoreBackgroundAudio()
    end 


    local target = cc.Application:getInstance():getTargetPlatform()

    if target == cc.PLATFORM_OS_ANDROID then
        local params = {fullpath, onPlayResult}
        local luaj = require "cocos.cocos2d.luaj"
        luaj.callStaticMethod("com/record/amrRecord/AmrRecordAndPlay", "startPlaying", params)

    elseif target == cc.PLATFORM_OS_IPAD or target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_MAC then 
        local args = {pathname = fullpath, scriptHandler = onPlayResult}
        local luaoc = require "cocos.cocos2d.luaoc"
        local result  = luaoc.callStaticMethod("ARRecorder","startPlaySound",args)
        print("oc call func result: ", result) 
    end
end

function stopAudioPlay()
    if not isAudioRecordSupport() then 
        return 
    end 


    local result = false 

    local target = cc.Application:getInstance():getTargetPlatform()
    if target == cc.PLATFORM_OS_ANDROID then
        local luaj = require "cocos.cocos2d.luaj"
        result = luaj.callStaticMethod("com/record/amrRecord/AmrRecordAndPlay", "stopPlaying")

    elseif target == cc.PLATFORM_OS_IPAD or target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_MAC then 
        local luaoc = require "cocos.cocos2d.luaoc"
        result = luaoc.callStaticMethod("ARRecorder","stopPlayingSound")
    end 

    restoreBackgroundAudio() 

    return result 
end 



return audioRecorderHelper
