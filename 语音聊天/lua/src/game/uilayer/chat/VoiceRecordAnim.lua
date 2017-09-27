
local VoiceRecordAnim = class("VoiceRecordAnim",require("game.uilayer.base.BaseLayer"))


function VoiceRecordAnim:ctor(seconds, timeoutCallback)
  VoiceRecordAnim.super.ctor(self)

  self.timeCount = seconds 
  self.timeoutCallback = timeoutCallback 

  self:init()
end 

function VoiceRecordAnim:onEnter()
end 

function VoiceRecordAnim:onExit()
  if self.timer then  
    self:unschedule(self.timer)
    self.timer = nil 
  end 
end 

function VoiceRecordAnim:init()
  self.recordingTips = cc.CSLoader:createNode("chat_voice1.csb")
  self.cancelTips = cc.CSLoader:createNode("chat_voice2.csb") 
  self:addChild(self.recordingTips)
  self:addChild(self.cancelTips)

  self.recordingTips:getChildByName("Text_1"):setString(g_tr("recording_tips1"))
  self.cancelTips:getChildByName("Text_1"):setString(g_tr("recording_tips1"))

  --录音动画
  local target = self.recordingTips:getChildByName("Image_2")
  local size = target:getContentSize()
  local armature, animation = g_gameTools.LoadCocosAni(
    "anime/Effect_YuYinTuBiaoLoop/Effect_YuYinTuBiaoLoop.ExportJson"
    , "Effect_YuYinTuBiaoLoop"
    -- , onMovementEventCallFunc
    --, onFrameEventCallFunc
    )
  armature:setPosition(cc.p(size.width/2, size.height/2))
  target:addChild(armature)
  animation:play("Animation1")   

  --倒计时定时器
  local function updateElapseTime()
    self.timeCount = self.timeCount - 1

    if self.timeCount <= 0 then 

      if self.timer then  
        self:unschedule(self.timer)
        self.timer = nil 
      end 

      if self.timeoutCallback then 
        self.timeoutCallback()
      end 

    elseif self.timeCount <= 10 then 
      self.recordingTips:getChildByName("Text_1"):setString(g_tr("recording_tips3",{num=self.timeCount}))
    end 
  end 

  if self.timer then  
    self:unschedule(self.timer)
  end 
  self.timer = self:schedule(updateElapseTime, 1.0) 
end 


function VoiceRecordAnim:showRecordingStatus()
  self.recordingTips:setVisible(true)
  self.cancelTips:setVisible(false)
end 

function VoiceRecordAnim:showCancelStatus()
  self.recordingTips:setVisible(false)
  self.cancelTips:setVisible(true) 
end 

function VoiceRecordAnim:setRecordingText(str)
  self.recordingTips:getChildByName("Text_1"):setString(str)
end 


return VoiceRecordAnim 

