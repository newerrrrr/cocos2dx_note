

local ChatData = {}
setmetatable(ChatData,{__index = _G})
setfenv(1, ChatData)

local chatData = {}
local preChatDataTime = {} --记录上次最后一项数据的时间戳, 方便比较
local chatType 
local chatView 
local newChatCount = 0 
local RecorderHelper = require("game.audiorecord.audioRecorderHelper")
local ChatMode = require("game.uilayer.chat.ChatMode")
local ChatTypeEnum = ChatMode.getChatTypeEnum()
local SendFlag = ChatMode.getSendFlagEnum()

function NotificationUpdateShow()
end


--请求数据
function RequestChatDataByType(chatType, isAsync, usrCallback)
	local ret = false
	local function onRecv(result, msgData) 
		if result then
			ret = true
			if chatType == ChatTypeEnum.BlackName then 
				chatData[chatType] = msgData.ChatBlackList
			else 
				chatData[chatType] = msgData 
			end 
		end
		--通知用户
		if usrCallback then 
			usrCallback(result)
		end 		 
	end

	if chatType == ChatTypeEnum.World then 
		g_sgHttp.postData("Common/viewAllWorldMsg",{}, onRecv, isAsync)

	elseif chatType == ChatTypeEnum.Guild and g_AllianceMode.getSelfHaveAlliance() then 
		g_sgHttp.postData("Common/viewAllGuildMsg",{}, onRecv, isAsync)

	elseif chatType == ChatTypeEnum.BlackName then 
		g_sgHttp.postData("data/index",{name = {"ChatBlackList"}}, onRecv, isAsync) 

	elseif chatType == ChatTypeEnum.Battle then --暂时不支持向服务器拉数据
		--g_sgHttp.postData("data/index",{name = {"GuildCross"}}, onRecv, isAsync) 
	end 
	
	return ret 
end

function setComboData(msgData)
	if nil == msgData then return end 
	
	if msgData.World then 
		chatData[ChatTypeEnum.World] = msgData.World 
	end 
	if msgData.Guild then 
		chatData[ChatTypeEnum.Guild] = msgData.Guild 
	end 
	if msgData.ChatBlackList then 
		chatData[ChatTypeEnum.BlackName] = msgData.ChatBlackList 
	end 	
end 

--更新所有数据
function RequestAllData(isAsync, usrCallback)
	local ret = true 

	local function onRecv(result, msgData) 
		print("RequestAllData:", result)
		if result then 
			setComboData(msgData)		
		end 

		--通知用户
		if usrCallback then 
			usrCallback(result)
		end 
		ret = result 
	end 
	g_sgHttp.postData("common/comboChat",{}, onRecv, isAsync) 

	return ret 
end 


function GetData(chatType, needToReq, isAsync, usrCallback) 
	if nil == chatData[chatType] or needToReq then 
		RequestChatDataByType(chatType, isAsync, usrCallback)
	end 

	--值拷贝,防止被外部修改
	local tbl = {}
	if chatData[chatType] then 
		for k, v in pairs(chatData[chatType]) do 
			table.insert(tbl, v)
		end 
	end 

	if chatType ~= ChatTypeEnum.BlackName and chatData[chatType] then 
		table.sort(tbl, function(a, b) return a.time < b.time end)
	end 
	return tbl
end 



function hasData(chatType) 
	return nil ~= chatData[chatType] 
end 

function notifyDataReady(chatType, callback) 
	if hasData(chatType) then 
		if callback then 
			callback(true) 
		end 
	else 
		GetData(chatType, true, true, callback)
	end 
end 

function SetBlackList(listData)
	chatData[ChatTypeEnum.BlackName] = listData 
end 

function isDataExist(chatType, dataItem)
	if nil == chatData[chatType] then return false end 

	for k, v in pairs(chatData[chatType]) do 
		if v.time == dataItem.time then 
			return true 
		end 
	end 

	return false 
end 


function insertChatDataItem(dataItem)
	if nil == dataItem then return end 

	local chatType = dataItem.type 
	if isDataExist(chatType, dataItem) then return end 

	if nil == chatData[chatType] then 
		chatData[chatType] = {}
	end 
	table.insert(chatData[chatType], dataItem)
end 

function updateVoiceDataSendFlag(name, sendFlag)
	if not hasData(ChatTypeEnum.Battle) then return end 

	for k, v in pairs(chatData[ChatTypeEnum.Battle]) do 
		if v.paraData and v.paraData.filename == name then 
			chatData[ChatTypeEnum.Battle][k].send_flag = sendFlag 
			break 
		end 
	end 
end 

function getVoiceDataItem(name)
	local item 
	if hasData(ChatTypeEnum.Battle) then 
		for k, v in pairs(chatData[ChatTypeEnum.Battle]) do 
			if v.paraData and v.paraData.filename == name then 
				item = v 
				break 
			end 
		end 
	end 
	return item 	
end 

function saveVoiceDataToFile(para)
	if nil == para or nil == para.filename or nil == para.fileData then return end 

	local path = ChatMode.getRecordFilepath(para.filename)
	local file = io.open(path, "wb") 
	if file then 
		file:write(cTools_base64_decode(para.fileData))
		io.close(file)
	end 
end 


function setChatType(_type)
	chatType = _type
end 

function getChatType()
	if chatType then 
		return chatType 
	end 

	--第一次的打开聊天如果战场开的时候默认进战场
	if g_activityData.GetCrossState() then 
		return ChatTypeEnum.Battle
	end 

	return ChatTypeEnum.World
end 

function onWillEnterForeground(dt) 
	print("chat:onWillEnterForeground", dt) 
	if nil == dt or dt > 5.0 then 
		GetData(getChatType(), true, true) 
	end 
	-- require("game.uilayer.mainSurface.mainSurfaceChat").updateChatComponent()
end 

function setChatView(viewObj)
	chatView = viewObj 
end 

function getChatView()
	return chatView 
end 

function setNewCount(count)
	newChatCount = count 
end 

function getNewCount()
	return newChatCount or 0 
end 


--获取最新数据的时间戳
function getCurChatDataTime(chatType) 
	local data = chatData[chatType]
	if data and data[#data] and data[#data].time then 
		return data[#data].time 
	end 
end 

--备份最新数据的时间戳
function recordLastChatDataTime()
	preChatDataTime[ChatTypeEnum.World] = getCurChatDataTime(ChatTypeEnum.World) 
	preChatDataTime[ChatTypeEnum.Guild] = getCurChatDataTime(ChatTypeEnum.Guild) 
end 

--获取上次记录的最新数据时间戳
function getLastChatDataTime(chatType)
	return preChatDataTime[chatType] 
end 

--更新语音发送成功标志
function setVoiceDataSentFlag(filename, isSentSucess)
	for k, v in pairs(chatData[ChatTypeEnum.Battle]) do 
		if v.para and v.para.filename == filename then 
			chatData[ChatTypeEnum.Battle][k].para.isSentSucess = isSentSucess 
		end 
	end 
end 

local function onRecvChatItem(obj, dataItem)
	if nil == dataItem then return end 
	dump(dataItem, "onRecvChatItem")

	--如果是战场语音,则将语音保存到本地, 并自动播放
	if dataItem.type == ChatTypeEnum.Battle and dataItem.paraData then 
		saveVoiceDataToFile(dataItem.paraData)
		dataItem.paraData.fileData = nil 
		--如果设置自动播放语音,并且处于开战状态,则自动播放其他玩家的语音
		if g_saveCache.voice_auto_play > 0 and g_PlayerMode.GetData().id ~= dataItem.player_id then 
			if RecorderHelper.isAudioRecordSupport() and g_activityData.GetCrossState() then --底层支持并且处于开战状态
				ChatMode.playVoice(dataItem.paraData.filename, dataItem.paraData.voiceTime, nil) 
			end 
		end 
	end 
	g_chatData.insertChatDataItem(dataItem) 
	
	if chatView then 
		if not chatView:isGuildChatType() and dataItem.type == ChatTypeEnum.Guild then 
			setNewCount(getNewCount() + 1)
		end 
		chatView:updateChatData(dataItem)
		
	elseif dataItem.type == ChatTypeEnum.Guild then 
		setNewCount(getNewCount() + 1)
	end 
end 

g_gameCommon.addEventHandler(g_Consts.CustomEvent.Chat, onRecvChatItem, ChatData) 


return ChatData 
