
--安卓按返回键退出游戏
--使用方法:直接调用 regist() 方法即可,默认加到当前场景中,也可以指定场景

local M = {}

local msgBox 

function M:regist(scene)
    local function onrelease(code, event) 
        print("==###########==code", code) 
        if code == cc.KeyCode.KEY_BACK or code == cc.KeyCode.KEY_BACKSPACE then 
            
            if msgBox and not tolua.isnull(msgBox) then return end 

            msgBox = require("app/views/NoticeTips"):create("提示", "是否退出游戏",
                        function() 
                            cc.Director:getInstance():endToLua()            
                        end, 
                        function()
                        end,
                        false) 
            if msgBox then 
                msgBox:registerScriptHandler(function(eventName)
                    if eventName == "exit" then 
                        msgBox = nil 
                    end 
                end)
            end 
        end 
    end

    if cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_ANDROID then 
        local runningScene = scene or cc.Director:getInstance():getRunningScene() 
        print("===[regist]:runningScene:", runningScene)
        if runningScene then
            local Tag_Exit = 7788 
            if nil == runningScene:getChildByTag(Tag_Exit) then 
                local layer = cc.Layer:create()
                layer:setTag(Tag_Exit)
                runningScene:addChild(layer, 1000)

                layer:setKeypadEnabled(true) 
                local listener = cc.EventListenerKeyboard:create()
                listener:registerScriptHandler(onrelease, cc.Handler.EVENT_KEYBOARD_RELEASED) 
                layer:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, layer)
            end 
        end 
    end 
end 

return M 
