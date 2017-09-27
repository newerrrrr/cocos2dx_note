

local ChatLayer = class("ChatLayer",require("game.uilayer.base.BaseLayer"))
local MailHelper = require("game.uilayer.mail.MailHelper"):instance() 
local MailType = MailHelper:getMailTypeEnum() 
local SpyType = MailHelper:getSpyTypeEnum() 
local BattleSubType = MailHelper:getBattleSubTypeEnum() 
local ChatMode = require("game.uilayer.chat.ChatMode")
local ChatType = ChatMode.getChatTypeEnum()
local SendFlag = ChatMode.getSendFlagEnum()
local RecorderHelper = require("game.audiorecord.audioRecorderHelper")

local layerObj --当前layer对象

local subTag = {
    World = {all = 1,chat = 2,system = 3},
    Guild = {all = 1,chat = 2,system = 3}
}

local curWorldSubTag = subTag.World.all
local curGuildSubTag = subTag.Guild.all

function ChatLayer:ctor(chatType)
  ChatLayer.super.ctor(self)
  if chatType then 
    self.curType = chatType
  else 
    self.curType = g_chatData.getChatType()
  end 

  --如果战场聊天未开放, 则默认打开世界聊天
  if self.curType == ChatType.Battle and not g_activityData.GetCrossState() then 
    self.curType = ChatType.World
  end 

  self.myPlayerId = g_PlayerMode.GetData().id 

  cc.Director:getInstance():getTextureCache():removeUnusedTextures()

  self.chatItem1 = cc.CSLoader:createNode("chat_list1.csb") --对方
  self.chatItem2 = cc.CSLoader:createNode("chat_list2.csb") --自己

  self.blacktem = require("game.uilayer.chat.BlackNameListItem"):create()
  self.chatItem1:retain()
  self.chatItem2:retain()
  self.blacktem:retain()

  layerObj = self 
  self.preTime = 0
  self.preSendTime = 0 --点击发送时间
  self.newChatCount = 0 --联盟新聊天个数
  self.firstNewItemOffset = 0 --联盟第一条新聊天项对应的列表Y位移
  self.maxItemCount = 100 --最多显示100条
end 

function ChatLayer:onEnter()
  print("ChatLayer:onEnter")
  
  self.inputFlag = 0 
  self.isAtInput = false 
  g_chatData.setChatView(self)

  local layer = g_gameTools.LoadCocosUI("chat_panel.csb", 5) 
  if layer then 
    local mask = layer:getChildByName("mask")
    self:regBtnCallback(mask, handler(self, self.onCloseChat))

    local scaleNode = layer:getChildByName("scale_node")
    self:initBinding(scaleNode) 
    self:addChild(layer) 

    local x, y = scaleNode:getPosition()
    scaleNode:setPositionY(y-scaleNode:getContentSize().height)
    scaleNode:runAction(cc.EaseElasticOut:create(cc.MoveTo:create(0.8, cc.p(x, y)), 1.0))

    self:highlightMenu(self.curType)
    if self.curType == ChatType.Guild and (not g_AllianceMode.getSelfHaveAlliance()) then
      return 
    end 

    self:asyncLoadListWhenEnter(self.curType)
  end 

  g_gameCommon.addEventHandler(g_Consts.CustomEvent.PoorNetWork, ChatLayer.showPoorNetwork, self)
end 


function ChatLayer:onExit() 
  print("ChatLayer:onExit") 
  layerObj = nil 
  g_chatData.setChatView(nil)

  self.chatItem1:release()
  self.chatItem2:release()
  self.blacktem:release()
  g_gameCommon.removeAllEventHandlers(self)
  g_poorNetworkTip.hide()
end 

function ChatLayer:initBinding(scaleNode)
  self.root = scaleNode 

  self.nodeSend = scaleNode:getChildByName("Panel_send")
  self.nodeBlack = scaleNode:getChildByName("Panel_blackName") 
  self.nodeOperation = scaleNode:getChildByName("Panel_operation") 
  self.nodeJoin = scaleNode:getChildByName("panel_join") 
  self.nodeNew = scaleNode:getChildByName("Panel_1") 
  self.nodeTips = scaleNode:getChildByName("Panel_hong") 

  local btnClose = scaleNode:getChildByName("close_btn")
  self.listView = scaleNode:getChildByName("ListView_1")
  local btnSwitchVoice = self.nodeSend:getChildByName("Panel_dianji") 
  local nodeInput = self.nodeSend:getChildByName("Panel_write"):getChildByName("Panel_input")
  local btnSend = self.nodeSend:getChildByName("Button_3")
  local btnRemove = self.nodeBlack:getChildByName("Button_5") 
  local btnSpeaking = self.nodeSend:getChildByName("Panel_voice"):getChildByName("Button_anzhu1") 

  self.btnWorld = scaleNode:getChildByName("Button_1") 
  self.btnGuild = scaleNode:getChildByName("Button_2") 
  self.btnBattle = scaleNode:getChildByName("Button_3")   
  self.btnBlackName =  scaleNode:getChildByName("Button_4") 

  scaleNode:getChildByName("text"):setString(g_tr("chat_title"))
  scaleNode:getChildByName("Text_1"):setString(g_tr("chat_world"))
  scaleNode:getChildByName("Text_2"):setString(g_tr("chat_guild"))
  scaleNode:getChildByName("Text_3"):setString(g_tr("chat_battle"))
  self.nodeSend:getChildByName("Text_3"):setString(g_tr("chat_send"))  
  self.nodeBlack:getChildByName("Text_5"):setString(g_tr("chat_remove_from_black"))    
  self.nodeJoin:getChildByName("Text_6"):setString(g_tr("joinAlianceTips")) 
  self.nodeJoin:getChildByName("Text_7"):setString(g_tr("joinNow")) 
  self.nodeSend:getChildByName("Panel_voice"):getChildByName("Text"):setString(g_tr("press_to_speaking")) 

  self:initChatSubMenu()

  local editboxEventHandler = function(eventType)
      if eventType == "began" then
        self.inputFlag = 2 
        self.isAtInput = true 
      elseif eventType == "customEnd" then
        self:performWithDelay(function() self.isAtInput = false end, 0.2)
      end 
  end

  local size = nodeInput:getContentSize()
  self.editor = ccui.EditBox:create(size, ccui.Scale9Sprite:create())
  self.editor:setMaxLength(300) 
  self.editor:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
  self.editor:setFontColor(cc.c3b(255, 255, 255))
  self.editor:setPosition(cc.p(size.width/2, size.height/2))
  self.editor:registerScriptEditBoxHandler(editboxEventHandler)
  nodeInput:addChild(self.editor)

  self:registePressSpeeking()

  self:regBtnCallback(btnClose, handler(self, self.close))  
  self:regBtnCallback(self.btnWorld, handler(self, self.onChatWorld))
  self:regBtnCallback(self.btnGuild, handler(self, self.onChatGuild))
  self:regBtnCallback(self.btnBattle, handler(self, self.onChatBattle))
  self:regBtnCallback(self.btnBlackName, handler(self, self.onBlackList))

  self:regBtnCallback(btnSwitchVoice, handler(self, self.onSwitchVoice))  
  self:regBtnCallback(btnSend, handler(self, self.onSendText))  

  self:regBtnCallback(btnRemove, handler(self, self.onBlackRemove))  
  self:regBtnCallback(self.nodeNew, handler(self, self.onGotoFirstNewItem))
  
  self.nodeOperation:setVisible(false)
  self.nodeJoin:setVisible(false)
  self:regBtnCallback(self.nodeOperation:getChildByName("Button_x"), handler(self, self.onCloseOperation))
  self:regBtnCallback(self.nodeOperation:getChildByName("Button_1"), handler(self, self.onSendMail))
  self:regBtnCallback(self.nodeOperation:getChildByName("Button_3"), handler(self, self.onAddToBlack))
  self:regBtnCallback(self.nodeJoin:getChildByName("Button_6"), handler(self, self.onJoinGuild))

  self.nodeOperation:getChildByName("Text_1"):setString(g_tr("chat_operation"))
  self.nodeOperation:getChildByName("Text_2"):setString(g_tr("mainAllianceSend"))
  self.nodeOperation:getChildByName("Text_4"):setString(g_tr("chat_add_to_black"))

  --如果未开战则隐藏战场聊天界面
  self.btnBattle:setVisible(g_activityData.GetCrossState())
  scaleNode:getChildByName("Text_3"):setVisible(g_activityData.GetCrossState())


  --滑动列表到指定位置时隐藏新消息提示
  local function onScrollViewEvent(sender, eventType) 
    self.isListMoving = (eventType == ccui.ScrollviewEventType.scrolling)

    --显示更多旧聊天消息
    if eventType == ccui.ScrollviewEventType.scrolling then

      local minY = sender:getContentSize().height - sender:getInnerContainerSize().height
      local pos = sender:getInnerContainerPosition() 
      local deltaH = minY - pos.y 
      if deltaH > 20 and deltaH < 50 then 
        if nil == self.data then return end 
        local items = sender:getItems()
        local total = #self.data
        local len = #items
        if len >= total or len >= self.maxItemCount then 
          return 
        end 

        self:insertChatItem(self.data[total-len], 0)

        sender:doLayout() --更新布局(坐标,高度)
        sender:setInnerContainerPosition(pos) --回到插入前的位置，防止跳动厉害
      end 
    end 

    --如下只处理联盟聊天新消息数提示
    if self.curType ~= ChatType.Guild then return end 

    if not self.nodeNew:isVisible() then return end 

    if self.newChatCount <= 0 or self.firstNewItemOffset >= 0 then return end 

    if eventType == ccui.ScrollviewEventType.scrollToTop then 
      self:resetNewChatTips()

    elseif eventType == ccui.ScrollviewEventType.scrolling then
      local list_y = sender:getInnerContainerPosition().y 
      if list_y <= self.firstNewItemOffset then --往下拉
        self:resetNewChatTips()
      end 
    end 
  end 
  self.listView:addScrollViewEventListener(onScrollViewEvent) 
end 

--世界/联盟聊天子菜单
function ChatLayer:initChatSubMenu()
  local node = self.root:getChildByName("Panel_2")
  local btnAll = node:getChildByName("Image_dj1")
  local btnSub = node:getChildByName("Image_d3") 
  local btnChatSub = node:getChildByName("Image_d5") 
  
  self:regBtnCallback(btnAll, handler(self, self.onSelectAll))  
  self:regBtnCallback(btnChatSub, handler(self, self.onSelectChatSub))
  self:regBtnCallback(btnSub, handler(self, self.onSelectSub))  
  self:updateChatSubMenu(self.curType)
end 

function ChatLayer:updateChatSubMenu(chatType) 
  local node = self.root:getChildByName("Panel_2")
  node:getChildByName("Text_qb"):setString(g_tr("chat_all"))
  node:getChildByName("Text_liaot"):setString(g_tr("chat_msg"))
  
  node:getChildByName("Image_dj2"):setVisible(false)
  node:getChildByName("Image_d4"):setVisible(false)
  node:getChildByName("Image_d6"):setVisible(false)


  if chatType == ChatType.World then 
    node:setVisible(true)
    node:getChildByName("Text_xt"):setString(g_tr("chat_sys"))
    if curWorldSubTag == subTag.World.all then
        node:getChildByName("Image_dj2"):setVisible(true)
    elseif curWorldSubTag == subTag.World.chat then
        node:getChildByName("Image_d6"):setVisible(true)
    elseif curWorldSubTag == subTag.World.system then
        node:getChildByName("Image_d4"):setVisible(true)
    end
    
  elseif chatType == ChatType.Guild then  
    node:setVisible(true)
    node:getChildByName("Text_xt"):setString(g_tr("chat_battle_report"))
    if curGuildSubTag == subTag.Guild.all then
        node:getChildByName("Image_dj2"):setVisible(true)
    elseif curGuildSubTag == subTag.Guild.chat then
        node:getChildByName("Image_d6"):setVisible(true)
    elseif curGuildSubTag == subTag.Guild.system then
        node:getChildByName("Image_d4"):setVisible(true)
    end
  else 
    node:setVisible(false) 
  end 
end 

function ChatLayer:updateChatNewTips(chatType)
  --联盟聊天新消息个数红点
  local hasAlliance = g_AllianceMode.getSelfHaveAlliance() 
  local newNum = g_chatData.getNewCount() 

  self.nodeTips:setVisible(hasAlliance and chatType == ChatType.World and newNum > 0)
  if self.nodeTips:isVisible() then 
    self.nodeTips:getChildByName("Text_8"):setString(""..newNum)
  end 
  require("game.uilayer.mainSurface.mainSurfaceChat").updateChatNewTips(chatType)  
end 

function ChatLayer:highlightMenu(chatType) 
  self.btnWorld:setHighlighted(chatType == ChatType.World)
  self.btnGuild:setHighlighted(chatType == ChatType.Guild)
  self.btnBattle:setHighlighted(chatType == ChatType.Battle)
  self.btnBlackName:setHighlighted(chatType == ChatType.BlackName)  

  self:updateChatSubMenu(chatType)

  self.nodeSend:setVisible(chatType ~= ChatType.BlackName)  
  self.nodeBlack:setVisible(chatType == ChatType.BlackName)  

  self.nodeJoin:setVisible(false)
  local hasAlliance = g_AllianceMode.getSelfHaveAlliance() 
  if chatType == ChatType.Guild and (not hasAlliance) then --如果未加入联盟, 则联盟聊天显示加入联盟界面
    self.nodeJoin:setVisible(true)
    self.nodeSend:setVisible(false)
    self.nodeNew:setVisible(false)
    return
  end 

  if chatType ~= ChatType.Guild then 
    self.nodeNew:setVisible(false)
  end 

  if self.nodeSend:isVisible() then 
    --文本/语音开关, 默认文本输入
    self.nodeSend:getChildByName("Image_yuyin"):setVisible(true)
    self.nodeSend:getChildByName("Image_jianpan"):setVisible(false)

    --文本输入/语音输入
    self.nodeSend:getChildByName("Panel_write"):setVisible(true)
    self.nodeSend:getChildByName("Panel_voice"):setVisible(false)
    --发送按钮
    self.nodeSend:getChildByName("Button_3"):setVisible(true)
    self.nodeSend:getChildByName("Text_3"):setVisible(true) 
  end 

  self:updateChatNewTips(chatType)
end 



--index: 0:在最前面插入  -1:在最后追加
function ChatLayer:insertChatItem(itemData, index) 
  if nil == itemData then return end 
  dump(itemData, "insertChatItem")

  local item 
  local isSysInfo, desc = ChatMode.getSysInfo(itemData)

  if isSysInfo and self.curType == ChatType.Guild then --联盟聊天系统消息(不显示ICON)
    item = cc.CSLoader:createNode("chat_list3.csb") 
    local lbStr = item:getChildByName("Text_1") 
    local imgBg = item:getChildByName("Image_1") 
    lbStr:setString(desc)
    lbStr:setTextAreaSize(cc.size(imgBg:getContentSize().width, 0)) 

    local richText = g_gameTools.createRichText(lbStr, desc)
    local realSize = richText:getRealSize()
    local deltaH = realSize.height - imgBg:getContentSize().height
    if deltaH > 0 then 
      imgBg:setContentSize(cc.size(imgBg:getContentSize().width, imgBg:getContentSize().height + deltaH + 6))
      item:setContentSize(cc.size(item:getContentSize().width, item:getContentSize().height + deltaH + 6))
      richText:setPositionY(richText:getPositionY()+deltaH+3)
    end 

  else 
    item = (self.myPlayerId == itemData.player_id) and self.chatItem2:clone() or self.chatItem1:clone()
    local rootNode = item:getChildByName("Panel_1")
    local lbRank = rootNode:getChildByName("Text_rank")
    local lbName = rootNode:getChildByName("Text_name")
    local lbTime = rootNode:getChildByName("Text_time") 
    local pic1 = rootNode:getChildByName("pic1")

    local node_text = rootNode:getChildByName("Panel_text")
    local node_voice = rootNode:getChildByName("Panel_voice")
    local nodeRegion = node_text:getChildByName("Panel_region")
    local lbContent = node_text:getChildByName("Text_1")
    local imgShare = node_text:getChildByName("Image_fx")
    local imgContentBg 

    local isVoice = false 
    if itemData.paraData and itemData.paraData.filename then 
      isVoice = true 
    end 
    print("isVoice", isVoice)
    node_text:setVisible(not isVoice)
    node_voice:setVisible(isVoice)

    lbContent:setString("")
    rootNode:getChildByName("Text_2"):setVisible(false) --vip
    imgShare:setVisible(false) --分享icon

    --时间
    local tt = os.date("*t", itemData.time)
    lbTime:setString(string.format("%d-%d %02d:%02d",tt.month, tt.day, tt.hour, tt.min))

    --系统信息(击杀boss/招募武将/武将进阶/皇陵探宝)需要在这里组织
    local strRegion = nodeRegion:getContentSize()
    lbContent:setTextAreaSize(cc.size(strRegion.width, 0)) 

    
    if isSysInfo then 
      ChatMode.initSysContent(itemData, lbContent, desc, strRegion)

      lbRank:setString(g_tr("chat_sys_info")) 
      lbName:setString("")
      MailHelper:loadResIcon(pic1, 1020091)   

    else 
      local str = (self.curType == ChatType.World) and itemData.guild_short_name or itemData.guild_rank_name
      lbRank:setString(str or "")
      lbName:setString(itemData.nick)
      pic1:setTag(tonumber(itemData.player_id)) --用于点击头像时关联到相应数据
      MailHelper:loadPlayerIcon(pic1, tonumber(itemData.avatar_id))

      if self.myPlayerId ~= itemData.player_id  then --如果是其他玩家,则点击该头像显示操作菜单
        self:regBtnCallback(pic1, handler(self, self.showOperationPop))
      end 
     
      if not isVoice then --文本聊天
        
        --聊天内容自动换行 (由于text不能有效的对英文字串进行自动换行, 所以采用label来替换text)
        lbContent:removeAllChildren()
        lbContent:setString("")
        local content, isSharePos = self:getFormatedStr(tostring(itemData.content))
        local fontName = lbContent:getFontName()
        local target = cc.Application:getInstance():getTargetPlatform()
        local label
        if target ~= cc.PLATFORM_OS_ANDROID and target ~= cc.PLATFORM_OS_WINDOWS then 
          label = cc.Label:createWithSystemFont(content, "Heiti SC", lbContent:getFontSize())
        else 
          label = cc.Label:createWithTTF(content, lbContent:getFontName(), lbContent:getFontSize())
        end 
        label:setLineBreakWithoutSpace(true)
        label:setAlignment(cc.TEXT_ALIGNMENT_LEFT,cc.VERTICAL_TEXT_ALIGNMENT_TOP)
        label:setAnchorPoint(cc.p(0.0, 1.0))
        label:setPosition(0, 0)
        label:setTextColor(lbContent:getTextColor())
        lbContent:addChild(label)
        local strWidth = label:getContentSize().width
        if strWidth > strRegion.width then 
          label:setDimensions(strRegion.width, 0)
        end 
        strWidth = math.min(strWidth, strRegion.width)

        --如果超出高度则相应调整背景高度
        local strSize = label:getContentSize()
        local deltaH = strSize.height - strRegion.height
        if deltaH <= 0 then 
          lbContent:setPositionY(nodeRegion:getPositionY()-(strRegion.height-strSize.height)/2)
        else 
          local imgContentBg = node_text:getChildByName("Image_bg") 
          imgContentBg:setContentSize(cc.size(imgContentBg:getContentSize().width, imgContentBg:getContentSize().height+deltaH+2))
          item:setContentSize(cc.size(item:getContentSize().width, item:getContentSize().height+deltaH+2))
          rootNode:setPositionY(deltaH)
        end 

        --如果是联盟聊天里分享坐标,则添加下划线和交互
        if isSharePos then 
          self:addUnderLineForSharedPos(label, strWidth)
          imgShare:setVisible(true)

        elseif itemData.data and itemData.data.type == 5 then --邮件分享 
          self:addUnderLineForSharedMail(label, strWidth, itemData.data.userData)
          imgShare:setVisible(true)
        end 

      elseif isVoice then --语音聊天 
        local node_waiting = node_voice:getChildByName("Panel_sending")
        local icon_fail = node_voice:getChildByName("Image_t1")
        local lbVoiceTime = node_voice:getChildByName("Text_time")
        node_voice:getChildByName("Text_tag"):setString(itemData.paraData.filename) --标签,方便筛选指定项
        lbVoiceTime:setString(itemData.paraData.voiceTime .."\"")
        ChatMode.showSendStateAnimBySendFlag(itemData.send_flag, node_waiting, icon_fail)

        local btImgBg = node_voice:getChildByName("Image_bg") 
        btImgBg:setTouchEnabled(true)

        local function playVoice() 
          if RecorderHelper.isAudioRecordSupport() then 
            ChatMode.playVoice(itemData.paraData.filename, itemData.paraData.voiceTime, item)
          else 
            g_airBox.show(g_tr("record_not_support")) 
          end 
        end 
        self:regBtnCallback(btImgBg, playVoice) 
      end 
    end 

    --调整 lbRank, lbRank,lbTime 位置
    local nodetmp = node_text:isVisible() and node_text or node_voice 
    local pos_y = nodetmp:getPositionY() + nodetmp:getContentSize().height + 22 
    lbRank:setPositionY(pos_y)
    lbName:setPositionY(pos_y)
    lbTime:setPositionY(pos_y)
    lbRank:setPositionX(nodetmp:getPositionX())
    lbName:setPositionX(lbRank:getPositionX() + lbRank:getContentSize().width + 5) 
    lbTime:setPositionX(nodetmp:getPositionX() + nodetmp:getContentSize().width)
  end 

  if item then 
    if index >= 0 then 
      self.listView:insertCustomItem(item, index)
    else 
      self.listView:pushBackCustomItem(item) 
    end 
  end 
end 


--显示聊天列表
function ChatLayer:showChatList(chatType)
  print("showChatList, chatType=", chatType)

  self:stopFrameLoad()
  self.isListMoving = false 
  
  self.curType = chatType 
  g_chatData.setChatType(chatType)
  
  self.listView:removeAllChildren()
  -- self.listView:setItemsMargin(10)
  self.listView:setScrollBarEnabled(false)

  --联盟新消息提示
  self.newChatCount = 0 
  self.firstNewItemOffset = 0 
  if self.curType == ChatType.Guild then 
    local hasAlliacne = g_AllianceMode.getSelfHaveAlliance() 
    self.newChatCount = g_chatData.getNewCount()
    g_chatData.setNewCount(0) --只要进了一次联盟聊天界面,就复位新聊天项个数
    self.nodeNew:setVisible(hasAlliacne and self.newChatCount > 0)
    self.nodeNew:getChildByName("Text_1"):setString(g_tr("chat_newCount", {count = self.newChatCount})) 

    if not hasAlliacne then 
      return 
    end 
  else 
    self.nodeNew:setVisible(false)
  end 

  local chatData = g_chatData.GetData(chatType, false)

  if nil == chatData then return end 
  local blackData = g_chatData.GetData(ChatType.BlackName, false)

  self.data = {}
  local tmp 
  for i = #chatData, 1, -1 do 
    tmp = chatData[i] 
    if not ChatMode.isInBlackListEx(blackData, tmp.player_id) then 
      if chatType == ChatType.World then
        if curWorldSubTag == subTag.World.all then
          table.insert(self.data, 1, tmp)
        elseif curWorldSubTag == subTag.World.chat then
          if tmp.data == nil or tmp.data.type == nil then 
            table.insert(self.data, 1, tmp)
          end
        elseif curWorldSubTag == subTag.World.system then
          if tmp.data and tmp.data.type ~= nil then 
            table.insert(self.data, 1, tmp)
          end
        end
      elseif chatType == ChatType.Guild then
        if curGuildSubTag == subTag.Guild.all then
          table.insert(self.data, 1, tmp)
        elseif curGuildSubTag == subTag.Guild.chat then
          if tmp.data == nil or tmp.data.type == nil then 
            table.insert(self.data, 1, tmp)
          end
        elseif curGuildSubTag == subTag.Guild.system then
          if tmp.data and tmp.data.type == 5 then 
            table.insert(self.data, 1, tmp)
          end
        end
      elseif chatType == ChatType.Battle then 
        table.insert(self.data, 1, tmp)
      end
    end
  	 
    if #self.data > self.maxItemCount then
      break
    end
  end
  

  --先加载5条(或所有新消息),其他在手动下拉时插入
  local idx_s = 1 
  local idx_e = #self.data 

  local endIndex = math.max(idx_e - math.max(5, self.newChatCount), idx_s)  
  for i = idx_e, endIndex, -1 do 
    self:insertChatItem(self.data[i], 0)
  end 
  self.listView:doLayout()
  self.listView:jumpToBottom() 
  idx_e = endIndex - 1 
  self:calcNewItemOffsetY() 
end 

--刚进入时如果有旧数据,则异步同步下数据,防止长连接推送有漏掉;
--当无旧数据时,则异步下载数据,下载失败则关闭界面退出
function ChatLayer:asyncLoadListWhenEnter(chatType) 
  print("asyncLoadListWhenEnter")

  if g_chatData.hasData(self.curType) then 

    self:showChatList(self.curType) 

    --因为中间推送过程中有可能收不到,所以每次进界面异步下载所有数据, 并更新首页聊天栏显示最新一条
    g_chatData.recordLastChatDataTime()
    local function onRecvAllData(result)
      print("onRecvAllData", result)

      if nil == layerObj then return end 
      if not result then return end 
      
      local preTime = g_chatData.getLastChatDataTime(self.curType)
      if preTime ~= g_chatData.getCurChatDataTime(self.curType) then --有新数据
        print("onRecvAllData: data changed !!")
        if (self.curType == ChatType.Guild and g_AllianceMode.getSelfHaveAlliance()) or self.curType == ChatType.World then 
          self:showChatList(self.curType)
        end 
      end 
      require("game.uilayer.mainSurface.mainSurfaceChat").updateChatComponent() 
    end 
    g_chatData.RequestAllData(true, onRecvAllData) 
  else 

    local function isDataReady(result) 
      print("isDataReady", result) 
      g_busyTip.hide_1() 
      if result then 
        self:showChatList(self.curType) 
        require("game.uilayer.mainSurface.mainSurfaceChat").updateChatComponent() 
      else 
        self:close() 
      end 
    end 

    if self.curType ~= ChatType.Battle then --战场只允许在线推送,不支持向服务器拉数据
      g_chatData.notifyDataReady(chatType, isDataReady)
      g_busyTip.show_1() 
    end 
  end 
end 

--显示黑名单列表
function ChatLayer:showBlackList()
  print("showBlackList")

  self.curType = ChatType.BlackName 

  self.listView:removeAllChildren()
  -- self.listView:setItemsMargin(10)
  self.listView:setScrollBarEnabled(false)
  self.data = g_chatData.GetData(ChatType.BlackName, false)
  if nil == self.data then return end 

  local item_new 
  for k, v in pairs(self.data) do 
    item_new = self.blacktem:clone() 
    item_new:setData(v) 
    self.listView:pushBackCustomItem(item_new) 
  end 
end 

function ChatLayer:addUnderLineForSharedPos(targetLabel, lineWidth) 
  local w = lineWidth 
  local str = string.match(targetLabel:getString(),"x=.+")
  if str and str ~= "" and string.len(str) > 5 then 
    w = string.len(str) * 12 + 12 
  end 

  local drawNode = cc.DrawNode:create()
  drawNode:setAnchorPoint(cc.p(0, 0.5))
  drawNode:drawLine(cc.p(0, 0), cc.p(w, 0), cc.c4f(0, 0.7, 1.0, 1))
  drawNode:setPosition(cc.p(0, 0))
  targetLabel:addChild(drawNode) 
  targetLabel:setTextColor(cc.c3b(0, 183, 255))

  local xx, yy
  local function gotoMapPos()
    require("game.maplayer.changeMapScene").gotoWorld_BigTileIndex({x = tonumber(xx), y = tonumber(yy)})
    self:close()
  end 
  local function onTouchBegan(touch, event) 
    local label = event:getCurrentTarget()
    if label then 
      local rect = cc.rect(0, 0, label:getContentSize().width, label:getContentSize().height)
      if cc.rectContainsPoint(rect, label:convertToNodeSpace(touch:getLocation())) then 
        return true 
      end 
    end 
    return false 
  end 

  local function onTouchEnded(touch, event) 
    print("self.isListMoving", self.isListMoving)
    if self.isListMoving then 
      self.isListMoving = false 
      return 
    end 

    local label = event:getCurrentTarget()
    if label then 
      local rect = cc.rect(0, 0, label:getContentSize().width, label:getContentSize().height)
      if cc.rectContainsPoint(rect, label:convertToNodeSpace(touch:getLocation())) then 
        xx = string.match(label:getString(),"x=(%d+)")
        yy = string.match(label:getString(),"y=(%d+)")
        if xx and yy then 
          self:performWithDelay(gotoMapPos, 0.2)
        end 
      end 
    end 
  end 

  local listener = cc.EventListenerTouchOneByOne:create()  
  -- listener:setSwallowTouches(true)
  listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN ) 
  listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED )
  cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, targetLabel)   
end 

function ChatLayer:addUnderLineForSharedMail(targetLabel, lineWidth, userData) 
  if nil == userData then return end 

  local drawNode = cc.DrawNode:create()
  drawNode:setAnchorPoint(cc.p(0, 0.5))
  drawNode:drawLine(cc.p(0, 0), cc.p(lineWidth, 0), cc.c4f(0, 0.7, 1.0, 1))
  drawNode:setPosition(cc.p(0, 0))
  targetLabel:addChild(drawNode) 
  targetLabel:setTextColor(cc.c3b(0, 183, 255))

  local function showMailContent() 
    if userData.histroy then --历史战报 
      g_sceneManager.addNodeForUI(require("game.uilayer.battleHall.BattleRecordInfoView").new(userData.mail_id)) 

    elseif userData.mail_type == 3 or userData.mail_type == 4  then --侦查/战报
      g_MailMode.RequestOneMailData(userData.mail_id, function(mail)
          if mail then 
            g_sceneManager.addNodeForUI(require("game.uilayer.mail.MailSpyBattleReport").new(mail))
          end 
        end)
    end 
  end 
  local function onTouchBegan(touch, event) 
    local label = event:getCurrentTarget()
    if label then 
      local rect = cc.rect(0, 0, label:getContentSize().width, label:getContentSize().height)
      if cc.rectContainsPoint(rect, label:convertToNodeSpace(touch:getLocation())) then 
        return true 
      end 
    end 
    return false 
  end 
  local function onTouchEnded(touch, event) 
    if self.isListMoving then 
      self.isListMoving = false 
      return 
    end 

    local label = event:getCurrentTarget()
    if label then 
      local rect = cc.rect(0, 0, label:getContentSize().width, label:getContentSize().height)
      if cc.rectContainsPoint(rect, label:convertToNodeSpace(touch:getLocation())) then 
        self:performWithDelay(showMailContent, 0.2)
      end 
    end     
  end 

  local listener = cc.EventListenerTouchOneByOne:create()  
  -- listener:setSwallowTouches(true)
  listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN ) 
  listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED )
  cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, targetLabel)   
end 


function ChatLayer:registePressSpeeking() 
  print("registePressSpeeking")

  local nodeVoice = self.nodeSend:getChildByName("Panel_voice")
  local imgBg = nodeVoice:getChildByName("Image_3")

  local StateRec = {
                      None = 0,
                      Recording = 1,
                      Cancel = 2,
                      Error = 3
                    }
  local timer_press --长按检测
  local anim_recording --动画节点
  local beginTime = 0 --录音开始时间
  local recording_status = StateRec.None
  local filename = ""



    --移除动画
  local function removeAnim()
    if anim_recording then   
      anim_recording:removeFromParent()
      anim_recording = nil 
    end 
  end 

  local function stopRecordVoice()
    local elapseTime = g_clock.getCurServerTime()-beginTime 
    print("stopRecordVoice, status=", recording_status)

    if recording_status == StateRec.Recording then --正常录音时停止

      if elapseTime < 1 then --提示时间太短 
        if anim_recording then 
          anim_recording:setRecordingText(g_tr("record_time_too_short"))
          self:performWithDelay(removeAnim, 1.0)           
        end 

        RecorderHelper.cancleAudioRecord() 

      else 
        removeAnim()

        local function onStopResult(result, path)
          if result then 

            --发送语音
            print(" send voice...") 

            local function onSendResult(filename, sendFlag) 
              print("onSendResult, filename, sendFlag=", filename, sendFlag)
              
              local items = self.listView:getItems()
              for k, v in pairs(items) do 
                local node_voice = v:getChildByName("Panel_1"):getChildByName("Panel_voice") 
                local lbTag = node_voice:getChildByName("Text_tag") 
                if lbTag:getString() == filename then 
                  local node_waiting = node_voice:getChildByName("Panel_sending") 
                  local icon_fail = node_voice:getChildByName("Image_t1") 
                  ChatMode.showSendStateAnimBySendFlag(sendFlag, node_waiting, icon_fail) 
                  --更新数据 
                  g_chatData.updateVoiceDataSendFlag(filename, sendFlag)
                  
                  if icon_fail:isVisible() then --支持点击重发
                    self:regBtnCallback(icon_fail, function()
                        print("start resend...") 
                        ChatMode.sendVoiceMsg(g_chatData.getVoiceDataItem(filename), onSendResult) 
                        g_chatData.updateVoiceDataSendFlag(filename, SendFlag.Waiting)
                        ChatMode.showSendStateAnimBySendFlag(SendFlag.Waiting, node_waiting, icon_fail) 
                        end) 
                  end 

                  break 
                end 
              end 
            end 

            local dataItem = ChatMode.createOneVoiceData(filename, elapseTime)
            if ChatMode.sendVoiceMsg(dataItem, onSendResult) then 
              --插入临时数据
              g_chatData.insertChatDataItem(dataItem)
              --UI列表插入语音项, 显示等待动画
              self:insertChatItem(dataItem, -1)
            end 

          else 
            print(" stop record error !!!")
          end 
        end 

        RecorderHelper.stopAudioRecord(onStopResult)
      end 

    elseif recording_status == StateRec.Cancel then --正常录音时取消
      removeAnim()
      RecorderHelper.cancleAudioRecord() 

    elseif recording_status == StateRec.Error then --正常录音时出错
      if anim_recording then 
        anim_recording:setRecordingText(g_tr("record_error_hanppen"))
        self:performWithDelay(removeAnim, 1.0)           
      end  
      RecorderHelper.cancleAudioRecord()      
    end 

    recording_status = StateRec.None 
  end 

  local function startRecordVoice()
    print("start record...")
    timer_press = nil 
    recording_status = StateRec.Recording      

    --显示动画
    removeAnim()
    anim_recording = require("game.uilayer.chat.VoiceRecordAnim").new(20, stopRecordVoice)
    nodeVoice:getChildByName("Panel_anim"):addChild(anim_recording)
    anim_recording:showRecordingStatus() 

    --开始录音
    local function onError()
      print("recording error !!!") 
      recording_status = StateRec.Error 
      stopRecordVoice() 
    end 

    beginTime = g_clock.getCurServerTime()

    filename = "AR_" .. self.myPlayerId .. beginTime ..".amr"
    RecorderHelper.startAudioRecord(ChatMode.getRecordFilepath(filename, onError))   
  end 

  local function onTouchBegan(touch, event) 
    print("touch begin=====") 
    if nodeVoice:isVisible() then 
      local target = event:getCurrentTarget()
      if target then 
        local touch_pos = target:convertToNodeSpace(touch:getLocation())
        local rect = cc.rect(0, 0, target:getContentSize().width, target:getContentSize().height)
        if cc.rectContainsPoint(rect, touch_pos) then

          recording_status = StateRec.None 
          
          if timer_press then 
            self:stopAction(timer_press)
          end 
          timer_press = self:performWithDelay(startRecordVoice, 0.6) 
          
          return true 
        end 
      end 
    end 

    return false 
  end 

  local function onTouchMoved(touch, event) 
    local target = event:getCurrentTarget()
    if target and anim_recording then 
      local touch_pos = target:convertToNodeSpace(touch:getLocation()) 
      if touch_pos.y > 140 then 
        if recording_status == StateRec.Recording then 
          recording_status = StateRec.Cancel  
          anim_recording:showCancelStatus() 
        end 
      else 
        if recording_status == StateRec.Cancel then 
          recording_status = StateRec.Recording
          anim_recording:showRecordingStatus() 
        end 
      end 
    end 
  end 

  local function onTouchEnded(touch, event) 
    print("touch end=====") 
    if timer_press then 
      self:stopAction(timer_press)
      timer_press = nil 
    end 
    stopRecordVoice()
  end 

  local function onTouchCancelled(touch, event) 
    print("onTouchCancelled")
    if timer_press then 
      self:stopAction(timer_press)
      timer_press = nil 
    end 
    stopRecordVoice()
  end 

  imgBg:setTouchEnabled(false) --触摸优先级比imgBg交互优先级低,所以必须禁止其交互，否则触摸imgBg区域无响应！！！！
  local listener = cc.EventListenerTouchOneByOne:create()  
  listener:setSwallowTouches(true)
  listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN ) 
  listener:registerScriptHandler(onTouchMoved, cc.Handler.EVENT_TOUCH_MOVED )
  listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED )
  listener:registerScriptHandler(onTouchCancelled, cc.Handler.EVENT_TOUCH_CANCELLED )
  cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, imgBg)
end 


function ChatLayer:onChatWorld()
  RecorderHelper.stopAudioPlay()

  g_musicManager.playEffect(g_SOUNDS_SURE_PATH)

  self:highlightMenu(ChatType.World)

  if self.curType == ChatType.World then return end 
  self.curType = ChatType.World
  self:stopFrameLoad()
  self:showChatList(ChatType.World)
end 

function ChatLayer:onChatGuild()
  RecorderHelper.stopAudioPlay()

  g_musicManager.playEffect(g_SOUNDS_SURE_PATH)

  self:highlightMenu(ChatType.Guild)

  if self.curType == ChatType.Guild then return end 
  self.curType = ChatType.Guild

  self:stopFrameLoad()
  self.listView:removeAllChildren()
  if not g_AllianceMode.getSelfHaveAlliance() then
    g_airBox.show(g_tr("battleHallNoAlliance"))
    return
  end 

  self:showChatList(ChatType.Guild)
end 

function ChatLayer:onChatBattle()
  RecorderHelper.stopAudioPlay()

  g_musicManager.playEffect(g_SOUNDS_SURE_PATH)

  self:highlightMenu(ChatType.Battle)

  if self.curType == ChatType.Battle then return end 
  self.curType = ChatType.Battle

  self:stopFrameLoad()
  self.listView:removeAllChildren()

  self:showChatList(ChatType.Battle)
end 

function ChatLayer:onBlackList()
  g_musicManager.playEffect(g_SOUNDS_SURE_PATH)

  self:highlightMenu(ChatType.BlackName) 

  if self.curType == ChatType.BlackName then return end 
  self.curType = ChatType.BlackName
  self:stopFrameLoad()
  self:showBlackList()
end 

function ChatLayer:onSwitchVoice()
  print("onSwitchVoice")

  if self.curType ~= ChatType.Battle then return end 

  if not RecorderHelper.isAudioRecordSupport() then 
    g_airBox.show(g_tr("record_not_support")) 
    return 
  end  

  --开关
  local iconVoice = self.nodeSend:getChildByName("Image_yuyin") 
  local iconText = self.nodeSend:getChildByName("Image_jianpan")  
  iconVoice:setVisible(not iconVoice:isVisible())
  iconText:setVisible(not iconText:isVisible())

  --文本 / 语音 输入
  self.nodeSend:getChildByName("Panel_write"):setVisible(iconVoice:isVisible())
  self.nodeSend:getChildByName("Panel_voice"):setVisible(iconText:isVisible())  

  --发送按钮
  self.nodeSend:getChildByName("Button_3"):setVisible(iconVoice:isVisible())
  self.nodeSend:getChildByName("Text_3"):setVisible(iconVoice:isVisible()) 
end 

--聊天文本发送
function ChatLayer:onSendText()
  print("onSendText")
  g_musicManager.playEffect(g_SOUNDS_SURE_PATH)

  --防止频繁点击发送按钮
  if os.time() - self.preSendTime < 5 then 
    return 
  end 

  local contentStr = MailHelper:getTrimedSpace(self.editor:getText()) 
  if contentStr == "" then 
    g_airBox.show(g_tr("noContent"))
    return 
  end  

  if os.time() - self.preTime < 5 then 
    g_airBox.show(g_tr("chat_too_frequent"))
    return     
  end 

  self.preSendTime = os.time()


  local function onSendSuccess(target, msgid, data)
    print("onSendSuccess", msgid, data)
    if nil == layerObj then return end 

    self.editor:setText("")
    self.preTime = os.time()
    self.preSendTime = 0 

    if data and data.flag then 
      if data.flag == "banned" then 
        g_airBox.show(g_tr("beBanned")) 

      elseif data.flag == "low_level" then 
        if g_PlayerMode.GetData().level < data.level then 
          g_airBox.show(g_tr("chat_low_level", {lv = data.level})) 
        end 
      end 
    end 
  end 

  ChatMode.sendChatMsg(self.curType, {player_id = self.myPlayerId, content = contentStr}, onSendSuccess)

  if self.listView then --发送时置底
    self.listView:doLayout() 
    self.listView:jumpToBottom() 
  end 
end 


--接收后台推送的聊天数据
function ChatLayer:updateChatData(dataItem)
  print("updateChatData")
  if nil == dataItem then return end 

  local _type = dataItem.type

  -- g_chatData.insertChatDataItem(dataItem) --更新到数据缓存里

  self:updateChatNewTips(self.curType)

  local tmp = dataItem
  if self.curType == _type then --更新UI 
    if not ChatMode.isInBlackList(dataItem.player_id) then 
      local needShow = false
      if self.curType == ChatType.World then
        if curWorldSubTag == subTag.World.all then
           needShow = true
        elseif curWorldSubTag == subTag.World.chat then
           if tmp.data == nil or tmp.data.type == nil then 
             needShow = true
           end
        elseif curWorldSubTag == subTag.World.system then
           if tmp.data and tmp.data.type ~= nil then 
             needShow = true
           end
        end
      elseif self.curType == ChatType.Guild then
        if curGuildSubTag == subTag.Guild.all then
            needShow = true
        elseif curGuildSubTag == subTag.Guild.chat then
           if tmp.data == nil or tmp.data.type == nil then 
              needShow = true
           end
        elseif curGuildSubTag == subTag.Guild.system then
           if tmp.data and tmp.data.type == 5 then 
              needShow = true
           end
        end
      elseif self.curType == ChatType.Battle then
        needShow = true 
      end
      
      if needShow then
        --如果超出上限则移除最旧的一项
        local items = self.listView:getItems()
        if #items >= self.maxItemCount then 
          print("remove exceed item...")
          self.listView:removeItem(0)
        end 
        self:insertChatItem(dataItem, -1)
        local pos = self.listView:getInnerContainerPosition()
        if pos.y > -10 then 
          self.listView:doLayout()
          self.listView:jumpToBottom()  
        end 
      end
    end  
  end 
end 

function ChatLayer:onAddToBlack()
  print("onAddToBlack")
  g_musicManager.playEffect(g_SOUNDS_SURE_PATH)

  if not self.nodeOperation:isVisible() then return end 

  if nil == self.curData then return end 

  local function addResult(result, data)
    print("addResult:", result)
    if result then 
      g_airBox.show(g_tr("chat_add_to_black_success"))
      self:onCloseOperation()
      if data and data.ChatBlackList then 
        g_chatData.SetBlackList(data.ChatBlackList)
      end 
      self:showChatList(self.curType)
    end 
  end 
  g_sgHttp.postData("Common/addChatBlack", {black_player_id = self.curData.player_id}, addResult) 
end 

--从黑名单移除
function ChatLayer:onBlackRemove()
  print("onBlackRemove")
  g_musicManager.playEffect(g_SOUNDS_SURE_PATH)

  if self.curType ~= ChatType.BlackName then return end 
  local itemsTbl = {}
  local idsTbl = {}
  for k, v in pairs(self.listView:getItems()) do 
    if v:getIsSelected() then 
      table.insert(idsTbl, tonumber(v:getData().black_player_id))
      table.insert(itemsTbl, v)
    end 
  end 

  if #idsTbl == 0 then return end 

  local function removeResult(result, data)
    print("removeResult result:", result)
    if result then 
      for k, v in pairs(itemsTbl) do 
        self.listView:removeChild(v, true)
      end 

      if data and data.ChatBlackList then 
        g_chatData.SetBlackList(data.ChatBlackList)
      end       
    end 
  end 
  g_sgHttp.postData("Common/removeChatBlack", {black_player_ids = idsTbl}, removeResult) 
end 

--点击玩家头像弹出操作界面
function ChatLayer:showOperationPop(rootNode)
  g_musicManager.playEffect(g_SOUNDS_SURE_PATH)

  self.nodeOperation:setVisible(true)

  local playerId = rootNode:getTag()
  self.curData = nil 
  for k, v in pairs(self.data) do 
    if v.player_id == playerId then 
      self.curData = v 
      break 
    end 
  end 
end 

function ChatLayer:onCloseOperation()
  self.nodeOperation:setVisible(false)
end 

function ChatLayer:onSendMail()
  print("onSendMail")
  g_musicManager.playEffect(g_SOUNDS_SURE_PATH)

  if not self.nodeOperation:isVisible() then return end 
  if nil == self.curData then return end 

  self:onCloseOperation()

  local pop = require("game.uilayer.mail.MailContentWritePop").new(false, self.curData.nick)
  g_sceneManager.addNodeForUI(pop)  
end 

function ChatLayer:onJoinGuild()
  print("onJoinGuild")
  g_musicManager.playEffect(g_SOUNDS_SURE_PATH)
  
  g_sceneManager.addNodeForUI(require("game.uilayer.alliance.AllianceMainLayer"):create())
  self:close()

end 

--分享坐标到联盟聊天
function ChatLayer:shareToGuild(name, x, y)
  print("shareToGuild", name, x, y)
  if nil == name then return end 

  local str = name..":x="..x..",y="..y 
  local myId = g_PlayerMode.GetData().id 

  ChatMode.sendChatMsg("guild_chat", {player_id = myId, content = str}, nil)
end 

function ChatLayer:onCloseChat()
  --如果在输入状态下,则不关闭
  print("onCloseChat: inputFlag", self.inputFlag, self.isAtInput) 
  if self.inputFlag then 
    self.inputFlag = self.inputFlag - 1 
  else 
    self.inputFlag = 0 
  end 

  if not self.isAtInput or self.inputFlag <= 0 then 
    self:close()
  end 
end 

--如果是分享坐标,则将坐标单独作为一行放最后
function ChatLayer:getFormatedStr(strContent)
  local str = strContent 
  local isSharePos = false 

  if self.curType == ChatType.Guild then 
    local x = string.match(strContent,"x=(%d+)")
    local y = string.match(strContent,"y=(%d+)")
    if x and y then 
      str = string.gsub(strContent, "x=", "\nx=") 
      isSharePos = true 
    end 
  end 

  return str, isSharePos 
end 

function ChatLayer:resetNewChatTips()
  self.newChatCount = 0 
  self.firstNewItemOffset = 0 
  self.nodeNew:setVisible(false)
  g_chatData.setNewCount(0) 
end 

--计算联盟聊天列表里第一条新消息对应的y偏移位置
function ChatLayer:calcNewItemOffsetY()
  self.firstNewItemOffset = 0 

  if self.newChatCount > 0 then 
    local items = self.listView:getItems() 
    local totalLen = #items 
    if totalLen >= self.newChatCount then 
      for i = 1, self.newChatCount do 
        local it = items[totalLen-i+1]
        if it then 
          self.firstNewItemOffset = self.firstNewItemOffset - it:getContentSize().height 
        end 
      end 
      self.firstNewItemOffset = self.firstNewItemOffset + self.listView:getContentSize().height 
      if self.firstNewItemOffset >= 0 then 
        self:resetNewChatTips()
      end 
    end 
  end 
  print("self.firstNewItemOffset", self.firstNewItemOffset) 
end 

function ChatLayer:onGotoFirstNewItem()

  if nil == self.newChatCount then return end 

  if self.curType == ChatType.Guild and self.newChatCount > 0 then 
    local pos = self.listView:getInnerContainerPosition()
    pos.y = self.firstNewItemOffset 
    self.listView:setInnerContainerPosition(pos)
  end 
  self:resetNewChatTips() 
end 

function ChatLayer:isGuildChatType()
  return self.curType == ChatType.Guild 
end 

function ChatLayer:onSelectAll()
  if self.curType ~= ChatType.World and self.curType ~= ChatType.Guild then
    return 
  end 

  if self.curType == ChatType.World then
    if curWorldSubTag == subTag.World.all then
      return
    end
    curWorldSubTag = subTag.World.all
  elseif self.curType == ChatType.Guild then
    if curGuildSubTag == subTag.Guild.all then
      return
    end
    curGuildSubTag = subTag.Guild.all
  end
  
  self:stopFrameLoad()
  self:updateChatSubMenu(self.curType)
  self:showChatList(self.curType)  
end 

function ChatLayer:onSelectChatSub()
  if self.curType ~= ChatType.World and self.curType ~= ChatType.Guild then
    return 
  end 

  if self.curType == ChatType.World then
    if curWorldSubTag == subTag.World.chat then
      return
    end
    curWorldSubTag = subTag.World.chat
  elseif self.curType == ChatType.Guild then
    if curGuildSubTag == subTag.Guild.chat then
      return
    end
    curGuildSubTag = subTag.Guild.chat
  end
  
  self:stopFrameLoad()
  self:updateChatSubMenu(self.curType)
  self:showChatList(self.curType)   
end 

function ChatLayer:onSelectSub()
  if self.curType ~= ChatType.World and self.curType ~= ChatType.Guild then
    return 
  end 

  if self.curType == ChatType.World then
    if curWorldSubTag == subTag.World.system then
      return
    end
    curWorldSubTag = subTag.World.system
  elseif self.curType == ChatType.Guild then
    if curGuildSubTag == subTag.Guild.system then
      return
    end
    curGuildSubTag = subTag.Guild.system
  end

  self:stopFrameLoad()
  self:updateChatSubMenu(self.curType)
  self:showChatList(self.curType)   
end 

function ChatLayer:stopFrameLoad()
  self:stopAllActions()

  if self.frameLoadTimer then 
    self:unschedule(self.frameLoadTimer) 
    self.frameLoadTimer = nil  
  end 
end 

function ChatLayer:showPoorNetwork(data)
  if nil == data then return end 

  print("===is poor", data.is_poor)
  if data.is_poor then 
    g_poorNetworkTip.show()
  else 
    g_poorNetworkTip.hide()
  end 
end 


return ChatLayer 
