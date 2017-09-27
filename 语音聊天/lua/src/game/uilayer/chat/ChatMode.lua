local ChatMode = {}
setmetatable(ChatMode,{__index = _G})
setfenv(1, ChatMode)

local RecorderHelper = require("game.audiorecord.audioRecorderHelper") 

local userCallback
local voicePlayingAnim 
local voiceIcon

local ChatType = {
  World = "world_chat",
  Guild = "guild_chat",
  BlackName = "black_name",
  Battle = "battle_fight",
}

local SendFlag = {
  Waiting = 0,
  Success = 1,
  Fail    = 2
}


function getChatTypeEnum()
  return ChatType 
end 

function getSendFlagEnum()
  return SendFlag 
end 

local function onSendSuccess(target, msgid, data)
  if userCallback then 
    userCallback(target, msgid, data) 
    userCallback = nil 
  end 
end 

function regChatSendCallback()
  g_sgNet.registMsgCallback(g_Consts.NetMsg.ChatSendRsp, ChatMode, onSendSuccess) 
end 

function unRegChatSendCallback()
  g_sgNet.unregistMsgCallback(g_Consts.NetMsg.ChatSendRsp, ChatMode)
end 

function sendChatMsg(type, data, callback)
  userCallback = callback 
  g_sgNet.sendMessage(g_Consts.NetMsg.ChatSendReq, {Type=type, Data = data})
end 

--分享战斗报告/侦查报告/历史战报到联盟聊天
function shareMailToGuild(mailData, isHistroy, callback) 
  local str = ""
  local mailType 

  if nil == mailData then return end 

  if isHistroy then --历史战报 
    if mailData.detail.win then 
      str = g_tr("chat_history_battle_win", {name1 = mailData.detail.player1.nick, name2 = mailData.detail.player2.nick}) 
    else 
      str = g_tr("chat_history_battle_lost", {name1 = mailData.detail.player1.nick, name2 = mailData.detail.player2.nick}) 
    end 
    mailType = 4

  else --我的战斗报告和侦查报告
    local MailHelper = require("game.uilayer.mail.MailHelper"):instance() 
    local MailType = MailHelper:getMailTypeEnum() 
    local SpyType = MailHelper:getSpyTypeEnum() 
    local BattleSubType = MailHelper:getBattleSubTypeEnum()  
       
    if mailData.type == MailType.Detect then --侦查报告
      mailType = 3 
      local target = ""
      if mailData.data.type == SpyType.Normal then --侦查主城
        if mailData.data.target_player.guild_short_name and mailData.data.target_player.guild_short_name ~= "" then 
          target = "(".. mailData.data.target_player.guild_short_name ..")"
        end 
        target = target .. mailData.data.target_player.nick
      elseif mailData.data.type == SpyType.Castle then --侦查联盟 
        if mailData.data.guild_short_name and mailData.data.guild_short_name ~= "" then 
          target = target .. "("..mailData.data.guild_short_name..")"
        end 
        local element = g_data.map_element[mailData.data.map_element_id]
        if element then 
          target = target ..g_tr(element.name)
        end 
      elseif mailData.data.type == SpyType.Resource or mailData.data.type == SpyType.JuDian or mailData.data.type == SpyType.KingFight then --侦查资源点/据点
        local item = g_data.map_element[mailData.data.map_element_id] 
        if item then 
          target = g_tr(item.name)
        end 
      end 
      str = g_tr("chat_spy_info", {name = target})

    else --战斗报告
      mailType = 4 
      if mailData.data.type == BattleSubType.Normal then --攻打主城 
        local playerName = ""
        if mailData.data.player2.guild_short_name ~= "" then 
          playerName = "("..mailData.data.player2.guild_short_name .. ")"
        end 
        playerName = playerName .. mailData.data.player2.nick 
        if MailHelper:isKindOfAtk(mailData.type) then 
          if mailData.data.win then 
            str = g_tr("chat_battle_city_win", {name = playerName})
          else 
            str = g_tr("chat_battle_city_lost", {name = playerName})
          end 
        else 
          if mailData.data.win then 
            str = g_tr("chat_battle_city_win2", {name = playerName})
          else 
            str = g_tr("chat_battle_city_lost2", {name = playerName})
          end           
        end 

      elseif mailData.data.type == BattleSubType.Resource then --资源战
        local playerName = ""
        if mailData.data.player2.guild_short_name ~= "" then 
          playerName = "("..mailData.data.player2.guild_short_name .. ")"
        end 
        playerName = playerName .. mailData.data.player2.nick         
        if MailHelper:isKindOfAtk(mailData.type) then 
          if mailData.data.win then 
            str = g_tr("chat_battle_res_atk_win", {name = playerName})
          else 
            str = g_tr("chat_battle_res_atk_lost", {name = playerName})
          end 
        else 
          if mailData.data.win then 
            str = g_tr("chat_battle_res_def_win", {name = playerName})
          else 
            str = g_tr("chat_battle_res_def_lost", {name = playerName})
          end 
        end 

      elseif mailData.data.type == BattleSubType.Castle then --攻打联盟堡垒 
        if mailData.data.win then 
          str = g_tr("chat_battle_castle_win", {name = mailData.data.player2.nick or ""}) 
        else 
          str = g_tr("chat_battle_castle_lost", {name = mailData.data.player2.nick or ""}) 
        end         
      end 
    end 
  end 

  local function shareMailResult(msgid, data)
    print("shareMailResult")
    g_airBox.show(g_tr("chat_share_success"))
    if callback then 
      callback()
    end 
  end 

  if nil == mailType then return end 

  local myId = g_PlayerMode.GetData().id 
  local data = {player_id=myId, content=str, userData={mail_type=mailType, mail_id=mailData.id, histroy=isHistroy}}
  sendChatMsg("guild_chat", data, shareMailResult)
end 

function isInBlackList(palyerId)
  local blackData = g_chatData.GetData(ChatType.BlackName, false)
  if nil == blackData then 
    return false 
  end 

  for k, v in pairs(blackData) do 
    if v.black_player_id == palyerId then 
      return true 
    end 
  end 
 
  return false 
end 

function isInBlackListEx(blackList, palyerId)
  for k, v in pairs(blackList) do 
    if v.black_player_id == palyerId then 
      return true 
    end 
  end 
  return false 
end 

--在label后面显示武将/装备图标
function addIconForLabel(node, nodeSize, sizeMax, genId, equiId, itemId) 
  local x, y = node:getPosition()
  local ap = node:getAnchorPoint()
  local itemIcon
  if genId then 
    itemIcon = require("game.uilayer.common.DropItemView"):create(g_Consts.DropType.General, genId, 1)
  elseif equiId then 
    itemIcon = require("game.uilayer.common.DropItemView"):create(g_Consts.DropType.Equipment, equiId, 1)
  elseif itemId then 
    itemIcon = require("game.uilayer.common.DropItemView"):create(g_Consts.DropType.Props, itemId, 1)
  end 

  if itemIcon then 
    itemIcon:enableTip()
    itemIcon:setCountEnabled(false)
    itemIcon:setScale(sizeMax.height/itemIcon:getContentSize().height)
    itemIcon:setAnchorPoint(cc.p(0, 0.5)) 
    itemIcon:setPosition(cc.p(x + nodeSize.width+15, y - ap.y*nodeSize.height + nodeSize.height/2))
    node:getParent():addChild(itemIcon)
  end 
end 

function initSysContent(itemData, lbContent, desc, strRegion)
  local x, y = lbContent:getPosition() 
  local defaultColor = lbContent:getTextColor() 

  if itemData.data.type == 1 then --击杀boss 
    lbContent:setString(desc) 
    local richText = g_gameTools.createRichText(lbContent, desc) 
    local realSize = richText:getRealSize()
    richText:setPositionY(y - (strRegion.height - realSize.height)/2) 

  elseif itemData.data.type == 2 then --招募武将
    lbContent:setTextAreaSize(cc.size(strRegion.width - 120, 0)) 
    lbContent:setString(desc)
    local richText = g_gameTools.createRichText(lbContent, desc)
    local realSize = richText:getRealSize()
    richText:setPositionY(y - (strRegion.height - realSize.height)/2) 
    addIconForLabel(richText, realSize, strRegion, itemData.data.general_id*100+1, nil)

  elseif itemData.data.type == 3 then --装备进阶 
    local equId = tonumber(itemData.data.equipment_id)
    local equipment = g_data.equipment[equId]
    if equipment then 
      lbContent:setTextAreaSize(cc.size(strRegion.width - 120, 0)) 
      lbContent:setString(desc) 
      local richText = g_gameTools.createRichText(lbContent, desc)
      local realSize = richText:getRealSize()
      richText:setPositionY(y - (strRegion.height - realSize.height)/2) 
      addIconForLabel(richText, realSize, strRegion, nil, equId)      
    end 

  elseif itemData.data.type == 4 then --皇陵探宝 
    lbContent:setString(desc) 
    local richText = g_gameTools.createRichText(lbContent, desc)
    local realSize = richText:getRealSize()
    richText:setPositionY(y - (strRegion.height - realSize.height)/2) 

  elseif itemData.data.type == 11 then --聚宝盆 
    if itemData.data.item_id and g_data.item[itemData.data.item_id] then 
      lbContent:setTextAreaSize(cc.size(strRegion.width - 120, 0)) 
      lbContent:setString(desc) 
      local richText = g_gameTools.createRichText(lbContent, desc)
      local realSize = richText:getRealSize()
      richText:setPositionY(y - (strRegion.height - realSize.height)/2) 
      addIconForLabel(richText, realSize, strRegion, nil, nil, itemData.data.item_id)      
    end 
  elseif itemData.data.type == 12 then --化神
    if itemData.data.general_id then 
      lbContent:setTextAreaSize(cc.size(strRegion.width - 120, 0)) 
      lbContent:setString(desc)   
      local richText = g_gameTools.createRichText(lbContent, desc)
      local realSize = richText:getRealSize()
      richText:setPositionY(y - (strRegion.height - realSize.height)/2)           
      addIconForLabel(richText, realSize, strRegion, itemData.data.general_id*100+1, nil, nil) 
    end     
  end 
end 

function getSysInfo(itemData)
  local isSysInfo = false 
  local desc = ""
  if itemData.data and itemData.data.type and itemData.data.type ~= 5 then --历史战报不属于系统信息
    isSysInfo = true 

    if itemData.data.type == 1 then --击杀boss 
      local npc = g_data.npc[tonumber(itemData.data.boss_npc_id)]
      if npc then 
        local bossName = g_tr(npc.monster_name)
       desc = g_tr(g_data.title_notice[8].desc, {playername=itemData.nick, bossname = bossName}) 
      end 

    elseif itemData.data.type == 2 then --招募武将
      local general = g_data.general[itemData.data.general_id*100+1] 
      local genName = "" 
      local descId = 7 --金色
      if general then 
        genName = g_tr(general.general_name)
        descId = general.general_quality == 5 and 7 or 11 
      end 
      desc = g_tr(g_data.title_notice[descId].desc, {playername = itemData.nick, generalname = genName})

    elseif itemData.data.type == 3 then --装备进阶 
      local equId = tonumber(itemData.data.equipment_id)
      local equipment = g_data.equipment[equId] 
      if equipment then 
        local equipName = g_tr(equipment.equip_name)
        local descId = equipment.quality_id == 5 and 10 or 9 
        desc = g_tr(g_data.title_notice[descId].desc, {playername=itemData.nick, equipmentname=equipName, startstar=equipment.star_level-1,endstar=equipment.star_level})  
      end 

    elseif itemData.data.type == 4 then --皇陵探宝 
      local drop = g_data.drop[tonumber(itemData.data.drop)]
      if drop then 
        local dropItem = drop.drop_data[1]
        local item = require("game.uilayer.common.DropItemView"):create(dropItem[1], dropItem[2], dropItem[3])
        if item then 
          desc = g_tr("chat_draw_treasure", {player = itemData.nick, num = itemData.data.times, item = item:getName()})
          desc = desc .. "x"..dropItem[3]
        end     
      end 

    elseif itemData.data.type == 6 then --联盟聊天: 新加入联盟玩家
      desc = g_tr("chat_new_member", {name = itemData.data.nick})

    elseif itemData.data.type == 7 then --联盟聊天: 官职升降 
      local rankName = itemData.data.to_rank_name
      if rankName == "" then 
        rankName = g_tr("allianceRankName"..itemData.data.to_rank) 
      end 
      if itemData.data.step == "up" then 
        desc = g_tr("chat_be_promoted", {name = itemData.data.member_nick, leader = itemData.data.admin_nick, rank = rankName})
      else 
        desc = g_tr("chat_be_degrated", {name = itemData.data.member_nick, leader = itemData.data.admin_nick, rank = rankName})
      end 

    elseif itemData.data.type == 8 then --联盟聊天: 被剔除联盟
      desc = g_tr("chat_be_removed", {name = itemData.data.member_nick, leader = itemData.data.admin_nick}) 

    elseif itemData.data.type == 9 then --联盟聊天: 自动退出联盟
      desc = g_tr("chat_quite", {name = itemData.data.member_nick}) 

    elseif itemData.data.type == 10 then --联盟商店买东西 
      local itemName = ""
      if itemData.data.itemId and g_data.item[itemData.data.itemId] then 
        itemName = g_tr(g_data.item[itemData.data.itemId].item_name)
      end 
      desc = g_tr("chat_buy_from_guild_shop", {player = itemData.data.nick, num = itemData.data.itemNum, item = itemName})

    elseif itemData.data.type == 11 then --聚宝盆
      local itemName = ""
      if itemData.data.item_id and g_data.item[itemData.data.item_id] then 
        itemName = g_tr(g_data.item[itemData.data.item_id].item_name)
      end 
      desc = g_tr(g_data.title_notice[15].desc, {playername = itemData.nick, itemname = itemName})

    elseif itemData.data.type == 12 then --化神
      local itemName = ""
      if itemData.data.general_id then 
        local general = g_data.general[itemData.data.general_id*100+1] 
        if general then 
          desc = g_tr(g_data.title_notice[16].desc, {playername = itemData.nick, generalname = g_tr(general.general_name)})  
        end 
      end 
      
    elseif itemData.data.type == 13 then --弹劾
      desc = g_tr("impeachTips", {name1 = itemData.data.from_nick, name2 = itemData.data.to_nick}) 

    elseif itemData.data.type == 14 then --放置 联盟建筑 
      local buildingName = ""
      if itemData.data.map_element_id then 
        local element = g_data.map_element[itemData.data.map_element_id] 
        if element then 
          buildingName = g_tr(element.name)
        end   
      end 
      local strPos = ""
      if itemData.data.x then 
        strPos = "X:"..itemData.data.x .. " Y:"..itemData.data.y
      end     
      desc = g_tr("place_building_tips", {player = itemData.data.nick or "", building = buildingName, pos = strPos})

    elseif itemData.data.type == 15 then --拆除 联盟建筑
      local buildingName = ""
      if itemData.data.map_element_id then 
        local element = g_data.map_element[itemData.data.map_element_id] 
        if element then 
          buildingName = g_tr(element.name)
        end   
      end  
      local strPos = ""
      if itemData.data.x then 
        strPos = "X:"..itemData.data.x .. " Y:"..itemData.data.y
      end       
      desc = g_tr("remove_building_tips", {player = itemData.data.nick or "", building = buildingName, pos = strPos})

    elseif itemData.data.type == 16 then --完成 联盟建筑
      local buildingName = ""
      if itemData.data.map_element_id then 
        local element = g_data.map_element[itemData.data.map_element_id] 
        if element then 
          buildingName = g_tr(element.name)
        end   
      end 
      local strPos = ""
      if itemData.data.x then 
        strPos = "X:"..itemData.data.x .. " Y:"..itemData.data.y
      end        
      desc = g_tr("complete_building_tips", {building = buildingName, pos = strPos})
    
    end 
  end 

  return isSysInfo, desc 
end 

function getRecordFilepath(filename)
  local _fileUtils = cc.FileUtils:getInstance()
  local storagePath = _fileUtils:getWritablePath().."VoiceRecord/"
  if not _fileUtils:isDirectoryExist(storagePath) then 
    _fileUtils:createDirectory(storagePath) 
  end 

  return storagePath .. filename 
end 

function stopVoicePlayingAnim()
  if voicePlayingAnim then 
    voicePlayingAnim:removeFromParent()
    voicePlayingAnim = nil 
    if voiceIcon then 
      voiceIcon:setVisible(true)
    end 
  end 
end 

function showVoicePlayingAnim(target, isFlipX)
  if nil == target then return end 

  stopVoicePlayingAnim()

  target:setVisible(false)

  local armature, animation = g_gameTools.LoadCocosAni(
    "anime/Effect_YuYinBoFang/Effect_YuYinBoFang.ExportJson"
    , "Effect_YuYinBoFang"
    -- , onMovementEventCallFunc
    --, onFrameEventCallFunc
    )

  armature:setPosition(cc.p(target:getPosition()))
  target:getParent():addChild(armature)
  if isFlipX then 
    animation:play("Animation2") 
  else 
    animation:play("Animation1") 
  end 

  voicePlayingAnim = armature 
  voiceIcon = target 

  local function rootLayerEventHandler(eventType)
    if eventType == "exit" then 
      voicePlayingAnim = nil 
    end
  end 
  armature:registerScriptHandler(rootLayerEventHandler)  
end 

function playVoice(filename, voiceTime, listItem)

  local pathname = getRecordFilepath(filename)
  print("playVoice: ", pathname) 

  if cc.FileUtils:getInstance():isFileExist(pathname) then 
    local function stopPlayingAnim()
      print("stopPlayingAnim")
      stopVoicePlayingAnim()
    end     

    RecorderHelper.startAudioPlay(pathname, stopPlayingAnim, stopPlayingAnim) 

    if listItem then 
      local node_voice = listItem:getChildByName("Panel_1"):getChildByName("Panel_voice")
      local icon1 = node_voice:getChildByName("Image_4") 
      local icon2 = node_voice:getChildByName("Image_5")
      local target = icon1 or icon2 
      local isFlipx = icon1 and true or false 
      showVoicePlayingAnim(target, isFlipx)
    end 
  else 
    print(" file not exist !!!")
  end 
end 

function showSendStateAnimBySendFlag(sendFlag, node_waiting, icon_fail)
  print("showSendStateAnimBySendFlag: sendFlag=", sendFlag)
  node_waiting:removeAllChildren()
  icon_fail:setVisible(false)

  if sendFlag == SendFlag.Waiting then
    local armature, animation = g_gameTools.LoadCocosAni(
      "anime/Effect_YuYinLoading/Effect_YuYinLoading.ExportJson"
      , "Effect_YuYinLoading"
      -- , onMovementEventCallFunc
      --, onFrameEventCallFunc
      )

    armature:setPosition(cc.p(0, 0))
    node_waiting:addChild(armature)
    animation:play("Animation1") 

  elseif sendFlag == SendFlag.Success then 
  elseif sendFlag == SendFlag.Fail then 
    icon_fail:setVisible(true)
  end  
end 

--生成一条临时语音dataItem
function createOneVoiceData(path, elapseTime)
  local player = g_PlayerMode.GetData() 
  local dataItem = {
                    type = ChatType.Battle,
                    player_id = player.id,
                    nick = player.nick or "",
                    avatar_id = player.avatar_id or 1 ,
                    guild_short_name = "",
                    content = "",
                    time = g_clock.getCurServerTime(),
                    paraData = {filename = path, voiceTime = elapseTime}, 
                    send_flag = SendFlag.Waiting, 
                  }
  return dataItem 
end 


local sendVoiceQueue = {} 
local sendCheckTimer 

function sendVoiceMsg(dataItem, onResult) 
  print("sendVoiceMsg")

  if nil == dataItem or nil == dataItem.paraData then 
    print("invalid voice data to send !!!")
    return false 
  end 

  local _filename = dataItem.paraData.filename
  local _voiceTime = dataItem.paraData.voiceTime 
  local scheduler = cc.Director:getInstance():getScheduler()

  local function sendSuccess() 
    print("sendVoiceSuccess")

    for k, v in pairs(sendVoiceQueue) do 
      if v.name == _filename then 
        if v.userCallback then 
          v.userCallback(v.name, SendFlag.Success) 
        end         
        table.remove(sendVoiceQueue, k)
        break 
      end 
    end 
  end 

  local function updateSendQueue()
    -- dump(sendVoiceQueue, "sendVoiceQueue")
    if #sendVoiceQueue > 0 then 
      local curSec = g_clock.getCurServerTime() 
      for k, v in pairs(sendVoiceQueue) do 
        if curSec - v.sendTime > 10 then 
          if v.userCallback then 
            v.userCallback(v.name, SendFlag.Fail) 
          end 
          table.remove(sendVoiceQueue, k) 
          break 
        end 
      end 
    else 
      if sendCheckTimer then 
        scheduler:unscheduleScriptEntry(sendCheckTimer) 
        sendCheckTimer = nil 
      end 
    end 
  end 

  local path = getRecordFilepath(_filename) 
  if cc.FileUtils:getInstance():getFileSize(path) == 0 then 
    print("voice file is empty !!!")
    return false 
  end 

  local buffer = cTools_read_file_data(path)
  if buffer then 
    local para = {
                  filename = _filename,
                  voiceTime = _voiceTime,
                  fileData = cTools_base64_encode(buffer)
                }
    --发送语音
    local id = g_PlayerMode.GetData().id
    sendChatMsg("battle_fight", {player_id = id, content = "", paraData = para}, sendSuccess)

    --备份发送请求
    table.insert(sendVoiceQueue, {name = _filename, sendTime = g_clock.getCurServerTime(), userCallback = onResult})
    if nil == sendCheckTimer then 
      sendCheckTimer = scheduler:scheduleScriptFunc(updateSendQueue, 1.0, false)
    end 
  else 
    print("invalid voice file path: ", path)
    return false 
  end 

  return true  
end 

--获取战场聊天最后一条非语音内容
function getNewestBattleChatContent()
  local str = ""
  if g_chatData.hasData(ChatType.Battle) then 
    local item 
    local data = g_chatData.GetData(ChatType.Battle, false)
    for i = #data, 1, -1 do 
      if nil == data[i].paraData or data[i].paraData.filename then 
        item = data[i] 
        break 
      end 
    end 

    if item then 
      local isSysInfo, desc = getSysInfo(item) 
      if not isSysInfo then 
          desc = item.content 
          str = str .. "|<#255, 250, 145#>"..item.nick.."：|"
      end 
      str = str .. desc
    end 
  end 

  return str
end 


regChatSendCallback()

return ChatMode
