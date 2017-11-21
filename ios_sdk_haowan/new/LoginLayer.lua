local LoginLayer = class("LoginLayer",function()
	return cc.Layer:create()
end)

local lastClickEnterGameTime = 0

local disableRequestClosedServer = true --禁止请求处于维护状态的服务器

local isHealthGameAdviceDone = false
function LoginLayer:requestServerList(successHandler)
	local function onRecv(result, msgData)
		g_busyTip.hide_1()
		if result then
			print(msgData)
			local gameServerList = cjson.decode(msgData)
			g_gameServerList = gameServerList.server_list
			g_Account.isTestUser = gameServerList.whitelist_flag
			self:updateView()
			if successHandler and type(successHandler) == "function" then
				successHandler()
			end
		else
			g_msgBox.show(g_tr("getServerListFail"), title, ctp, handler(self,self.requestServerList), utp, {["0"] = g_tr("retryGetServerList")})
		end
	end
	g_busyTip.show_1()
	local data = ""
	httpNet:getInstance():Post(g_configHost.."/login_server/getServerList",data,string.len(data),onRecv,10,10,true,false)
end


function LoginLayer:ctor()
	--for test
	--g_Account.logout()
	local uiLayer =g_gameTools.LoadCocosUI("login_index.csb",5)
	self:addChild(uiLayer)
	local baseNode = uiLayer:getChildByName("scale_node")
	self._baseNode = baseNode
	self._baseNode:getChildByName("no_login"):setVisible(false)
	
	local area_select = self._baseNode:getChildByName("area_select")
	area_select:getChildByName("Text_area_num"):setString("")
	area_select:getChildByName("Text_server_name"):setString("")
	
	local isZhcnGame = require("localization.langConfig").getCountryCode() == "zhcn"
	baseNode:getChildByName("zhonggao"):setVisible(isZhcnGame)
	
	self._btnAccountManager = uiLayer:getChildByName("Button_manage")
	
	self._btnAccountManager:setScale(g_display.scale)
	self._btnAccountManager:setPosition(cc.p(g_display.right_top.x - 5,g_display.right_top.y - 5))
	
	g_Account.sdkLogout()
	
	self:registerScriptHandler(function(eventType)
	if eventType == "enter" then
		g_Account.setLoginLayer(self)
		g_gameCommon.addEventHandler(g_Consts.CustomEvent.AnySdkUserActionResult,function(_,data)
			local code = data.type
			if code == UserActionResultCode.kLoginSuccess then
				self.lua_playTitleAnimation()
				local isLogin = true
				self:changeBtnStatus(isLogin)
				self:useDefaultAreaId()
				self:showMaintainNoticeAfterLogin()
				g_airBox.show("登录成功")
			end
		end,self)
		
		local doAutoLogin = function()
			self:requestServerList(function()
				--anysdk登录
				local download_channel = g_Account.getDownloadChannel()
                print("download_channel",download_channel)
				if download_channel == g_sdkManager.SdkDownLoadChannel.anysdk then
						local pluginChannel = require("anysdk.PluginChannel"):getInstance()
						if pluginChannel then
						 pluginChannel:login()
						end
				elseif download_channel == g_sdkManager.SdkDownLoadChannel.huawei then
						self:doVerfityUid(g_sdkManager.SdkLoginChannel.huawei)
				elseif download_channel == g_sdkManager.SdkDownLoadChannel.aligames then
						self:doVerfityUid(g_sdkManager.SdkLoginChannel.aligames)
				elseif download_channel == g_sdkManager.SdkDownLoadChannel.qiangwan then
						self:doVerfityUid(g_sdkManager.SdkLoginChannel.qiangwan)
				elseif download_channel == g_sdkManager.SdkDownLoadChannel.haowan then
						self:doVerfityUid(g_sdkManager.SdkLoginChannel.haowan)						
				end
							
			end)
		end
		
		if isZhcnGame and not isHealthGameAdviceDone then
			local healthGameAdviceLayer = require("game.uilayer.regist.HealthGameAdviceLayer"):create()
			g_sceneManager.addNodeForSceneEffect(healthGameAdviceLayer)
			healthGameAdviceLayer:setPosition(g_display.center)
			local bgAction = cc.Sequence:create(cc.DelayTime:create(3.8),cc.FadeOut:create(0.35),cc.CallFunc:create(doAutoLogin),cc.RemoveSelf:create())
			healthGameAdviceLayer:runAction(bgAction)
			isHealthGameAdviceDone = true
		else
			doAutoLogin()
		end
	elseif eventType == "exit" then
		g_gameCommon.removeEventHandler(g_Consts.CustomEvent.AnySdkUserActionResult,self)
		g_Account.setLoginLayer(nil)
	end 
	end )
	
	
	self._currentSelectedAreaId = g_Account.getUserConfig().lastServerId or 1
	
	local changeAreaHandler = function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			g_musicManager.playEffect(g_SOUNDS_SURE_PATH)
			local selectedAreaHandler = function(areaId)
				print(areaId)
				self._currentSelectedAreaId = areaId
				self:updateView()
			end
			
			local selectLayer = require("game.uilayer.regist.AreaSelectLayer"):create(selectedAreaHandler)
			g_sceneManager.addNodeForUI(selectLayer)
		end
	end
	
	do --人物动画
		local armature , animation = g_gameTools.LoadCocosAni(
					"anime/Effect_RenWuLoading/Effect_RenWuLoading.ExportJson"
					, "Effect_RenWuLoading"
					, nil
					, nil
					)
		armature:setPosition(g_display.center)
		uiLayer:getChildByName("mask"):addChild(armature, 1)
		animation:play("Animation1")
	end
	
	
	do --标题动画
		local first_flag = true
		local armature , animation = g_gameTools.LoadCocosAni(
					"anime/Effect_RenWuLoading/Effect_RenWuLoading.ExportJson"
					, "Effect_RenWuLoading"
					, nil
					, nil
					)
		armature:setPosition(g_display.center)
		uiLayer:getChildByName("mask"):addChild(armature, 2)
		armature:setVisible(false)
		self.lua_playTitleAnimation = function()
			if first_flag == true then
				first_flag = false
				armature:setVisible(true)
				animation:play("Animation2")
				cc.Director:getInstance():setNextDeltaTimeZero(true)
				--self._baseNode:getChildByName("btn_login"):setVisible(false)
				g_autoCallback.addCocosList( function()
					--self._baseNode:getChildByName("btn_login"):setVisible(true)
					g_sceneManager.addNodeForWebView(require("game.webview.notice.NoticeLayer").new())
				end , 0.618 )
				
			end
		end
	end
	
	local changeArea = baseNode:getChildByName("area_select"):getChildByName("Text_change")
	changeArea:setTouchEnabled(false)
	--changeArea:addTouchEventListener(changeAreaHandler)
	changeArea:setString(g_tr("changeAreaTip"))
	baseNode:getChildByName("area_select"):getChildByName("Text_new"):setString(g_tr("serverNew"))
	
	baseNode:getChildByName("btn_login"):getChildByName("Text"):setString(g_tr("loginEnterGame"))

	local changeAreaBg = baseNode:getChildByName("area_select"):getChildByName("bg_select_server")
	--changeAreaBg:setTouchEnabled(true)
	--changeAreaBg:addTouchEventListener(changeAreaHandler)
	changeArea:setVisible(false)
	
	baseNode:getChildByName("no_login"):getChildByName("Panel_1"):setVisible(false)
	
	local targetPlatform = cc.Application:getInstance():getTargetPlatform()
--	if cc.PLATFORM_OS_ANDROID == targetPlatform
--	or cc.PLATFORM_OS_IPHONE == targetPlatform 
--	or cc.PLATFORM_OS_IPAD == targetPlatform
--	then
--		baseNode:getChildByName("no_login"):getChildByName("Panel_1"):setVisible(true)
--	end
	
	baseNode:getChildByName("no_login"):getChildByName("btn_1"):getChildByName("Text"):setString(g_tr("accountFastRigist"))
	baseNode:getChildByName("no_login"):getChildByName("btn_2"):getChildByName("Text"):setString(g_tr("accountLoginLabel"))
	baseNode:getChildByName("no_login"):getChildByName("btn_3"):getChildByName("Text"):setString(g_tr("accountRegistLabel"))
	
	baseNode:getChildByName("no_login"):getChildByName("Panel_1"):getChildByName("Text_21"):setString(g_tr("accountOtherAccount"))
	
	--使用g+登录
	local googleLoginBtn = baseNode:getChildByName("no_login"):getChildByName("Panel_1"):getChildByName("Button_1")
	googleLoginBtn:setVisible(g_sdkManager.isChannelVaild(g_sdkManager.SdkLoginChannel.googleplus))
	googleLoginBtn:addClickEventListener(function(sender)
		g_musicManager.playEffect(g_SOUNDS_SURE_PATH)
		self:doVerfityUid(g_sdkManager.SdkLoginChannel.googleplus)
	end)
	
	--使用facebook登录
	local facebookLoginBtn = baseNode:getChildByName("no_login"):getChildByName("Panel_1"):getChildByName("Button_1_0")
	facebookLoginBtn:setVisible(g_sdkManager.isChannelVaild(g_sdkManager.SdkLoginChannel.facebook))
	facebookLoginBtn:addClickEventListener(function(sender)
		g_musicManager.playEffect(g_SOUNDS_SURE_PATH)
		self:doVerfityUid(g_sdkManager.SdkLoginChannel.facebook)
	end)
	
	if not googleLoginBtn:isVisible() then
		facebookLoginBtn:setPosition(googleLoginBtn:getPosition())
	end
	
	if googleLoginBtn:isVisible() or facebookLoginBtn:isVisible() then
	 baseNode:getChildByName("no_login"):getChildByName("Panel_1"):setVisible(true)
	end
	
	--简体中文版不提供其他方式登入
	if require("localization.langConfig").getCountryCode() == "zhcn" then
		 baseNode:getChildByName("no_login"):getChildByName("Panel_1"):setVisible(false)
	end
	
	baseNode:getChildByName("no_login"):getChildByName("btn_1"):addTouchEventListener(function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			g_musicManager.playEffect(g_SOUNDS_SURE_PATH)
			--fast login
			g_msgBox.show(g_tr("accountCreateTmpAccountTip"),nil,nil,function(event)
				if event == 0 then
				 local resultHandler = function(result,data)
					if result then
						if data.status == "success" then
							 g_msgBox.show(g_tr("accountCreateTmpAccountSuccess"))
							 self:updateView()
						else
							 g_airBox.show(g_tr("userPlatform_"..data.message))
						end
					end
				 end
				 g_Account.userPlatformRegisterQuick(resultHandler)
				end
			end,1)
		end
	end)
	
	 baseNode:getChildByName("no_login"):getChildByName("btn_2"):addTouchEventListener(function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			g_musicManager.playEffect(g_SOUNDS_SURE_PATH)
			--login
			local inputLayer = require("game.uilayer.regist.LoginInputLayer"):create(handler(self,self.updateView))
			g_sceneManager.addNodeForUI(inputLayer)
		end
	end)
	
	 baseNode:getChildByName("no_login"):getChildByName("btn_3"):addTouchEventListener(function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			g_musicManager.playEffect(g_SOUNDS_SURE_PATH)
			--regist
			local inputLayer = require("game.uilayer.regist.RegistInfoInputLayer"):create(handler(self,self.updateView))
			g_sceneManager.addNodeForUI(inputLayer)
		end
	end)
	
	self._baseNode:getChildByName("btn_login"):addClickEventListener(function(sender)
        self:doEnterGameHandler()
	end)
	
	self._btnAccountManager:getChildByName("Text"):setString(g_tr("accountManager"))
	self._btnAccountManager:addClickEventListener(function(sender,eventType)
			g_musicManager.playEffect(g_SOUNDS_SURE_PATH)
			self:onClickAccountManagerHandler()
	end)
	
	self._baseNode:getChildByName("Button_notice"):getChildByName("Text"):setString(g_tr("accountNotice"))
	self._baseNode:getChildByName("Button_notice"):addTouchEventListener(function(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			g_musicManager.playEffect(g_SOUNDS_SURE_PATH)
			g_sceneManager.addNodeForWebView(require("game.webview.notice.NoticeLayer").new())
		end
	end)
	
	--获取选区列表
	--[[local function requestServerList()
		g_busyTip.show_1()
		local xhr = cc.XMLHttpRequest:new() -- http请求
		xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING -- 响应类型
		xhr:open("GET", g_configHost.."/server.json") -- 打开链接
		
		-- 状态改变时调用
		local function onReadyStateChange()
			g_busyTip.hide_1()
			if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
				print(xhr.response)
				g_gameServerList = cjson.decode(xhr.response)
				self:updateView()
			else
				print("xhr.readyState is:", xhr.readyState, "xhr.status is: ",xhr.status)
				g_msgBox.show(g_tr("getServerListFail"), title, ctp, requestServerList, utp, {["0"] = g_tr("retryGetServerList")})
			end
		end

		xhr:registerScriptHandler(onReadyStateChange)
		xhr:send() -- 发送请求
		
	end]]
end

function LoginLayer:doEnterGameHandler()
	g_musicManager.playEffect(g_SOUNDS_SURE_PATH)
	
	do --防止频繁点击
		if g_clock.getCurServerTime() - lastClickEnterGameTime < 5 then
			return
		end
		lastClickEnterGameTime = g_clock.getCurServerTime()
	end
	
	--for test 
--	do
--		g_sdkManager.shareSdkShare()
--		return
--	end
	
	 --ansdk登录状态检查
	local download_channel = g_Account.getDownloadChannel()
	if download_channel == "anysdk" then
		local isLogined = false
		local pluginChannel = require("anysdk.PluginChannel"):getInstance()
		if pluginChannel then
			isLogined = pluginChannel:isLogined()
		end
		
		if not isLogined then
			if pluginChannel then
				pluginChannel:login()
			else
				g_airBox.show("pluginChannel invaild")
			end
			return
		end
	elseif download_channel == "huawei" then
		if g_Account.getUserPlatformUid() == "" then
			self:doVerfityUid(g_sdkManager.SdkLoginChannel.huawei)
			return
		end
	elseif download_channel == "aligames" then
		if g_Account.getUserPlatformUid() == "" then
			self:doVerfityUid(g_sdkManager.SdkLoginChannel.aligames)
			return
		end
	elseif download_channel == "qiangwan" then
		if g_Account.getUserPlatformUid() == "" then
			self:doVerfityUid(g_sdkManager.SdkLoginChannel.qiangwan)
			return
		end

	elseif download_channel == "haowan" then
		if g_Account.getUserPlatformUid() == "" then
			self:doVerfityUid(g_sdkManager.SdkLoginChannel.haowan)
			return
		end
	end
	
	local userCode = g_Account.getLoginUserCode()
	--为防止首次登录还没成功时误操作
	if g_Account.getUserPlatformUid() == "" and userCode == "" then
		return
	end
	
	if g_logicDebug == true then
		if userCode ~= "" then
			g_airBox.show("userCode:"..userCode)
		else
			g_airBox.show("gameUuid:"..g_sgHttp.getUUID())
		end
	end
	
	local currentSelectedServerId = tonumber(self._currentAreaInfo.id)
	 --fb賬號限制
	if g_Account.getChannel() == g_sdkManager.SdkLoginChannel.facebook and currentSelectedServerId > g_facebookAcountEnableMax then
		g_msgBox.show(g_tr("accountFbDisableTip",{area_name = self._currentAreaInfo.name}),nil,nil,function(event)
		if event == 0 then
			
		end
		end)
		return
	end
	
	local function onCheckPlayerRecv(result1, msgData1)
		--关掉菊花
		g_busyTip.hide_1()
		if result1 == true then
			
			g_Account.setLoginHashCode(msgData1.login_hashcode)
			
			local targetAreaTag = g_Account.getTargetAreaTag()
			if g_saveCache[targetAreaTag] and g_saveCache[targetAreaTag] ~= 0 then
				g_saveCache[targetAreaTag] = 0
			end
			
			local gameUuid = g_sgHttp.getUUID()
			g_Account.requestPlayerServerList(gameUuid)
			
			if msgData1.checkPlayer == 1 then --账号已经存在
				g_sceneManager.setScene(g_sceneManager.sceneMode.loading)
			elseif msgData1.checkPlayer == 0 then --新账号
			
				--这里注掉了。服务器checkPlay后，如果没有账号会自动生成一个账号 不需要再次发送消息
				--[[local function onNewPlayerRecv(result2, msgData2)
					if result2 == true then
						g_sceneManager.setScene(g_sceneManager.sceneMode.cg)
					else
						--关掉菊花
						g_busyTip.hide_1()
					end
				end
				g_sgHttp.postData("player/newPlayer",{},onNewPlayerRecv,true)
				]]
				--appsflyer追踪角色创建事件
				g_sdkManager.trackCreateRoleEvent()
				g_sceneManager.setScene(g_sceneManager.sceneMode.cg)
				
			end
			
			--appsflyer追踪登录事件
			g_sdkManager.trackLoginEvent()
		end
	end
	
	g_Account.setServerHost(self._currentAreaInfo.gameServerHost)
	g_Account.setNetHost(self._currentAreaInfo.netServerHost)
	g_Account.setCurrentAreaInfo(self._currentAreaInfo)
	
	print("current game server:",g_Account.getServerHost())
	print("current net server:",g_Account.getNetHost())
	
	if self._currentAreaInfo.server_id then
		g_Account.getUserConfig().lastServerId = self._currentAreaInfo.server_id
		g_Account.saveToFile()
	end
	
	--getValidCode
	local function reqValidCode()
	
		
					
		local function onGetValidCodeResult(result,validCodeMsgData)
			if result then
				local deviceInfoResult = function(deviceName,systemVersion,platformName)
					local login_channel = g_Account.getChannel()
					local download_channel = g_Account.getDownloadChannel()
					local pay_channel = download_channel
					local platform = platformName
					local device_mode = deviceName
					local system_version = systemVersion
					local valid_code = validCodeMsgData.valid_code
					local language = require("localization.langConfig").getLanguage()
					
					
					local afConversionData = g_sdkManager.getAppsFlyerConversionData()
					local afUid = g_sdkManager.getAppsFlyerUID()
					

					--登录游戏
					g_sgHttp.postData("common/checkPlayer",
					{
						valid_code = valid_code,
						login_channel = login_channel,
						download_channel = download_channel,
						pay_channel = pay_channel,
						platform = platform,
						device_mode = device_mode,
						system_version = system_version,
						lang = language,
						af_uid = afUid,
						af_media_sourc = afConversionData
					},onCheckPlayerRecv,true)
										
				end
				g_gameTools.reqDeviceNameAndSystemVersion(deviceInfoResult)
			else
				g_busyTip.hide_1()
				self:checkNeedShowMaintainNotice()
			end
		end
		g_sgHttp.postData("common/getValidCode",{},onGetValidCodeResult,true)
	end
	
	--是否开启加密
	local function onResult(result, data, responseCode)
		if result then
			g_useMsgPack = (tonumber(data) == 1)
			reqValidCode()
		else
			--关掉菊花
			g_busyTip.hide_1()
			self:checkNeedShowMaintainNotice()
		end
	end
	
	local function reqEncryptInfo()
		--打开菊花
		g_busyTip.show_1()
		httpNet:getInstance():Post(g_Account.getServerHost().."/detect_encrypt.php","",string.len(""),onResult,10,10,true,false)
	end
	
	g_sdkManager.updateGeTuiClientId(reqEncryptInfo)
	
end

function LoginLayer:checkNeedShowMaintainNotice()
	local serverListLoadSuccess = function()
	if disableRequestClosedServer and self._currentAreaInfo then
		 dump(self._currentAreaInfo)
		 if self._currentAreaInfo and tonumber(self._currentAreaInfo.status) > 0 then --维护状态
			local str = self._currentAreaInfo.maintain_notice or ""
			if str == "" then
				str = g_tr("serverMaintainDefaultTip")
			end
			--g_msgBox.show(str)
			g_sceneManager.addNodeForUI(require("game.uilayer.regist.MaintainAlertLayer"):create(str))
		 else --正常状态
			g_airBox.show(g_tr("accountGetMessageTypeFail"))
		 end
	else
		 g_airBox.show(g_tr("accountGetMessageTypeFail"))
	end
	end
	self:requestServerList(serverListLoadSuccess)
end

function LoginLayer:showMaintainNoticeAfterLogin()
	local serverListLoadSuccess = function()
		if disableRequestClosedServer and self._currentAreaInfo then
			 dump(self._currentAreaInfo)
			 if self._currentAreaInfo.status and tonumber(self._currentAreaInfo.status) > 0 then
				local str = self._currentAreaInfo.maintain_notice or ""
				if str == "" then
					str = g_tr("serverMaintainDefaultTip")
				end
				--g_msgBox.show(str)
				g_sceneManager.addNodeForUI(require("game.uilayer.regist.MaintainAlertLayer"):create(str))
			 end
		end
	end
	self:requestServerList(serverListLoadSuccess)
end

function LoginLayer:doVerfityUid(channel)
	assert(channel)
	local resultHandler = function(result,dataTable)
		dump(dataTable)
		--{"status":"success","uid":1234,”message”:”获得用户信息成功”,"channel":"dsuc"}
		if result then
			if dataTable.status == "success" then
				--g_airBox.show("login "..dataTable.channel.." success")
				--g_airBox.show(g_tr("loginSuccess"))
				local isLogin = true
				self:changeBtnStatus(isLogin)
				if g_Account.getAccountManagerLayer() ~= nil then
					g_Account.getAccountManagerLayer():removeFromParent()
				end
			else
				g_msgBox.show("verfity fail"..dataTable.message)
			end
		end
	end
	g_Account.doVerfityUid(channel,resultHandler)
end

function LoginLayer:changeBtnStatus(isLogin)
	self._baseNode:getChildByName("no_login"):setVisible(not isLogin)
	self._baseNode:getChildByName("btn_login"):setVisible(isLogin)
	self._baseNode:getChildByName("area_select"):setVisible(isLogin and (cc.PLATFORM_OS_WINDOWS == cc.Application:getInstance():getTargetPlatform()))
	self._btnAccountManager:setVisible(isLogin)
	
	local targetPlatform = cc.Application:getInstance():getTargetPlatform()
	if cc.PLATFORM_OS_WINDOWS ~= targetPlatform then
		local download_channel = g_Account.getDownloadChannel()
		if download_channel == g_sdkManager.SdkDownLoadChannel.anysdk 
		or download_channel == g_sdkManager.SdkDownLoadChannel.huawei
		or download_channel == g_sdkManager.SdkDownLoadChannel.aligames 
		or download_channel == g_sdkManager.SdkDownLoadChannel.qiangwan 
		or download_channel == g_sdkManager.SdkDownLoadChannel.haowan 
		then
			self._baseNode:getChildByName("no_login"):setVisible(false)
			self._baseNode:getChildByName("btn_login"):setVisible(true)
			self._btnAccountManager:setVisible(false)
		end
	 end
	 
end

function LoginLayer:onClickAccountManagerHandler()

	local targetPlatform = cc.Application:getInstance():getTargetPlatform()
	if cc.PLATFORM_OS_WINDOWS ~= targetPlatform then
		local download_channel = g_Account.getDownloadChannel()
		if download_channel == g_sdkManager.SdkDownLoadChannel.anysdk 
		or download_channel == g_sdkManager.SdkDownLoadChannel.huawei 
		or download_channel == g_sdkManager.SdkDownLoadChannel.aligames 
		or download_channel == g_sdkManager.SdkDownLoadChannel.qiangwan 
		or download_channel == g_sdkManager.SdkDownLoadChannel.haowan 
		then
			return
		end
	end

	local userConfig = g_Account.getUserConfig()
	if userConfig.lastLoginAccount 
	and userConfig.lastLoginAccount.user_account 
	and userConfig.lastLoginAccount.user_account ~= "" then
		local managerLayer = require("game.uilayer.regist.AccountManagerLayer"):create()
		g_sceneManager.addNodeForUI(managerLayer)
		self:changeBtnStatus(true)
	else
		g_Account.sdkLogout()
		local isLogin = false
		self:changeBtnStatus(isLogin)
	end
end

function LoginLayer:useDefaultAreaId(serverId)
	local historyServerInfo = g_Account.getHistoryServerList()
	if historyServerInfo and historyServerInfo.last.last_server_id then
		local areaId = tonumber(historyServerInfo.last.last_server_id)
		self._currentSelectedAreaId = areaId
	else
		for key, var in pairs(g_gameServerList) do
		 if var.default_enter == 1 then
			 self._currentSelectedAreaId = var.id
			 break
		 end
		end
	end
	self:updateView()
end

function LoginLayer:forceUseAreaId(serverId)
	self._currentSelectedAreaId = serverId
	self:updateView()
end

function LoginLayer:getCurrentSelectedAreaInfo() 
	return self._currentAreaInfo
end

function LoginLayer:setCurrentSelectedAreaInfo(areaInfo) 
	self._currentAreaInfo = areaInfo
end

function LoginLayer:updateView()	

	local list = g_gameServerList
	local currentAreaInfo = nil 
	for key, var in pairs(list) do
	 if var.id == self._currentSelectedAreaId then
		 currentAreaInfo = var
		 break
	 end
	end
	
	if currentAreaInfo == nil then
		for key, var in pairs(list) do
		 if var.default_enter == 1 then
			 currentAreaInfo = var
			 break
		 end
		end
	end
	
	if currentAreaInfo == nil then
		currentAreaInfo = g_gameServerList[1]
	end
	
	--用户自行选区
	local targetAreaTag = g_Account.getTargetAreaTag()
	if g_saveCache[targetAreaTag] and g_saveCache[targetAreaTag] > 0 then
		for key, var in pairs(list) do
		 if var.id == g_saveCache[targetAreaTag] then
			 currentAreaInfo = var
			 break
		 end
		end
	end
	
	local area_select = self._baseNode:getChildByName("area_select")
	area_select:getChildByName("Text_new"):setVisible(tonumber(currentAreaInfo.isNew) > 0)
	area_select:getChildByName("Text_area_num"):setString(currentAreaInfo.areaName)
	area_select:getChildByName("Text_server_name"):setString(currentAreaInfo.name)
	
	self._currentAreaInfo = currentAreaInfo
	
	
	--ansdk,huawei,aligames登录界面
	local targetPlatform = cc.Application:getInstance():getTargetPlatform()
	if cc.PLATFORM_OS_WINDOWS ~= targetPlatform then
		local download_channel = g_Account.getDownloadChannel()
		if download_channel == g_sdkManager.SdkDownLoadChannel.anysdk 
		or download_channel == g_sdkManager.SdkDownLoadChannel.huawei 
		or download_channel == g_sdkManager.SdkDownLoadChannel.aligames 
		or download_channel == g_sdkManager.SdkDownLoadChannel.qiangwan
		or download_channel == g_sdkManager.SdkDownLoadChannel.haowan
		then
			self:changeBtnStatus(true)
		end
	end
	
end

return LoginLayer
