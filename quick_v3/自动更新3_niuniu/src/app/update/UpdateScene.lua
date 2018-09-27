

local UpdateScene = class("UpdateScene", function() return cc.Scene:create() end)
local Lang = require("src.app.update.Lang") 


function UpdateScene:ctor()
    release_print("[UpdateScene]:ctor")
    local csbNode = cc.CSLoader:createNode("csd/UpdateSceneLayer.csb")
    csbNode:setAnchorPoint(0.5, 0.5)
    csbNode:setPosition(gt.winCenter)
    csbNode:setScale(display.scale) 
    self:addChild(csbNode)
    
    local imgBg = csbNode:getChildByName("Img_Bg")
    self.slider = imgBg:getChildByName("Img_SliderBg"):getChildByName("Slider_Update")
    self.slider:setPercent(0)

    self.lbPercent = imgBg:getChildByName("Label_Progress")
    self.lbPercent:setString(Lang["checkingUpdate"]) 

    local listener = cc.EventListenerCustom:create("EventHotUpdateRestart", handler(self, self.restart))
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listener, 1) 

    --安卓返回键退出程序
    require("app.KeyBackExit"):regist()

    self:initSearchPath()
    require("app/update/UpdateMgr"):startUpdate(self) 
end 

--更新进度
function UpdateScene:updatePercent(percent)
    if tolua.isnull(self.lbPercent) then return end 

    self.lbPercent:setString(tostring(percent).."%")
end 

--弹框提示
function UpdateScene:showMsgBox(str, okFunc, cancelFunc)
    require("app/views/NoticeTips"):create("", str, okFunc, cancelFunc)
end 

function UpdateScene:restart()
    self.slider:setPercent(0) 
    self.lbPercent:setString("") 
    require("app/update/UpdateMgr"):startUpdate(self) 
end 

--加入缓存搜索路径在最前面
function UpdateScene:initSearchPath()
    local storagePath = cc.FileUtils:getInstance():getWritablePath() .. "ResUpdate/"
    local paths = cc.FileUtils:getInstance():getSearchPaths() 
    local found = false 
    for k, v in pairs(paths) do 
        if v == storagePath then 
            found = true 
            break 
        end 
    end 
    if not found then 
        table.insert(paths, 1, storagePath .. "res/")
        table.insert(paths, 1, storagePath .. "src/")
        table.insert(paths, 1, storagePath)
        cc.FileUtils:getInstance():setSearchPaths(paths)
    end 
end 

return UpdateScene 
