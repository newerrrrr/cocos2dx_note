--g_sdkManager
local sdkManager = {}
setmetatable(sdkManager,{__index = _G})
setfenv(1,sdkManager)

local targetPlatform = cc.Application:getInstance():getTargetPlatform()

--是否是新账号的标记
local isCreateRole = false
local appsFlyerConversionData = "null"
local getuiClientId = ""

--如果要增加新的渠道，需要在这增加
SdkLoginChannel = 
{
	dsuc = "dsuc",
	facebook = "facebook",
	googleplus = "googleplus",
	huawei = "huawei",
	aligames = "aligames",
	qiangwan = "qiangwan",
	haowan = "haowan",
}

SdkDownLoadChannel = {
	appstore = "appstore",
	appstore_tw = "appstore_tw",
	appstore_cn = "appstore_cn",
	googleplay = "googleplay",
	dsuc = "dsuc",
	anysdk = "anysdk",
	huawei = "huawei",
	aligames = "aligames",
	dsuc_cn = "dsuc_cn",
	taptap = "taptap",
	qiangwan = "qiangwan",
	haowan = "haowan",	
}



local _isTwAndroidSdkVaild = function()
	local vaild = true
	if require("localization.langConfig").getCountryCode() == "zhcn" then
		vaild = false
	end
	return vaild
end

local _checkLoginChannel = function(loginChannel)
	local isRightFormat = false
	if loginChannel and type(loginChannel) == "string" then
		for key, var in pairs(SdkLoginChannel) do
		  if loginChannel == var then
			 isRightFormat = true
			 break
		  end
		end
	end
	return isRightFormat
end

local _checkAppsFlyerSDKVaild = function()
	local isVaild = true
	local currentPackageVersion = require("src.resUpdate.UpdateMgr").getLocalPkgVersion()
	if cc.PLATFORM_OS_ANDROID == targetPlatform and _isTwAndroidSdkVaild() then
		if currentPackageVersion == "0.0.0.2" then--不包含Appsflyer sdk功能的包里的版本
			isVaild = false
		end
	elseif cc.PLATFORM_OS_IPHONE == targetPlatform or cc.PLATFORM_OS_IPAD == targetPlatform then
		if currentPackageVersion == "0.0.0.1" then--不包含Appsflyer sdk功能的包里的版本
			isVaild = false
		end
	end
	
	return isVaild
end

local _checkAppsFlyerConversionDataVaild = function()
	local isVaild = false
	local curLocalPkgVer = require("src.resUpdate.UpdateMgr").getLocalPkgVersion()
	if curLocalPkgVer then 
		local ver = string.split(curLocalPkgVer, ".")
		if tonumber(ver[1]) > 2 then
			isVaild = true 
		else
		  if tonumber(ver[1]) == 2 then
			if tonumber(ver[2]) > 0 then
			  isVaild = true 
			end
		  end
		end
	end 
	return isVaild
end

--目前只有官网简体，taptap和appstore简体需要接入热云
local _isReYunSdkVaild = function()
	local isVaild = false
	local download_channel = g_Account.getDownloadChannel()
	if download_channel == g_sdkManager.SdkDownLoadChannel.dsuc_cn
	--or download_channel == g_sdkManager.SdkDownLoadChannel.taptap --taptap不再使用热云
	or download_channel == g_sdkManager.SdkDownLoadChannel.appstore_cn
	then
		isVaild = true
	end
	
	return isVaild
end

--是否为老包，依据客户端里的版本号来确定
function isOldClientVersion()
	local isNewClient = false
  local curLocalPkgVer = require("src.resUpdate.UpdateMgr").getLocalPkgVersion()
  if curLocalPkgVer then 
	  local ver = string.split(curLocalPkgVer, ".")
	  if tonumber(ver[1]) > 2 then
		  isNewClient = true 
	  else
		if tonumber(ver[1]) == 2 then
		  if tonumber(ver[2]) > 0 then
			isNewClient = true 
		  end
		end
	  end
  end 
  print("isNewClient:",isNewClient)
  return not isNewClient
end

local huaweiUserChanged = function()
	g_gameManager.reStartGame()
end


--传入channel，callback两个参数，callback只在成功时返回，callback带回3个参数uid,userToken,channel（uid有可能也是token）
function login(loginChannel,callback)
	assert(_checkLoginChannel(loginChannel),"invaild login channel"..(loginChannel or ""))
	if targetPlatform == cc.PLATFORM_OS_ANDROID then
		 if loginChannel == SdkLoginChannel.huawei then
			local luaj = require "cocos.cocos2d.luaj"
			local className="com/somethingbigtech/sanguomobile2/huawei/FastSdk"

			local javacallback = function(s)
				local loginResult = function()
					--g_airBox.show("loginResult:"..s)
					--[HuaweiGameService]<<--login api, the result:UserResult [playerId=190086000123411880, displayName=, isAuth=0, gameAuthSign=, isChange=0, ts=, rtnCode=0, description=, playerLevel=null]
					local params = string.split(s, ",")
						local status = params[1]
						local playerId = params[2]
						local token = params[3]
						print("RESSSSS:",status,playerId,token)
						if status == "success" then --无需服务器鉴权
							assert(playerId and playerId ~= "")
							g_Account.setUserPlatformUid(playerId)
							g_Account.setChannel(g_sdkManager.SdkLoginChannel.huawei)
							local gameUuid = g_sgHttp.getUUID()
							g_busyTip.show_1()
							g_Account.requestPlayerServerList(gameUuid,function(result,msgData)
							  g_busyTip.hide_1()
							  local data = {}
							  if result then
								  data.type = UserActionResultCode.kLoginSuccess
							  else
								  data.type = UserActionResultCode.kLoginFail
							  end
							  g_gameCommon.dispatchEvent(g_Consts.CustomEvent.AnySdkUserActionResult,data)
							end)
						elseif status == "login_auth" then --需要服务器鉴权
								if callback then
									 --uid,token,channel
									callback(playerId,token,loginChannel)
								end
					  else
							local data = {}
							data.type = UserActionResultCode.kLoginFail
							g_gameCommon.dispatchEvent(g_Consts.CustomEvent.AnySdkUserActionResult,data)
						end
				  end
				  g_autoCallback.addCocosList(loginResult , 0.15 )
			end
			
			local params = {
				javacallback,huaweiUserChanged
			}
			luaj.callStaticMethod(className, "login", params)
			return 
		 elseif loginChannel == SdkLoginChannel.aligames then
			 
				 local aligamesResult = function(s)
							local loginResult = function()
							  local params = string.split(s, ",")
							  local status = params[1]
							  local playerId = params[2]
							  
							  if g_logicDebug == true then
							  	g_airBox.show("aligamesResult:"..status..","..playerId)
							  end
							  
							  if status == "login_success" then
								if callback then
									--uid,token,channel
									callback(playerId,playerId,loginChannel)
								end
							  elseif status == "login_faild" then
								  local data = {}
								  data.type = UserActionResultCode.kLoginFail
								  g_gameCommon.dispatchEvent(g_Consts.CustomEvent.AnySdkUserActionResult,data)
							  elseif status == "init_success" then
							  elseif status == "init_faild" then
							  elseif status == "pay_user_exit" then
								  --g_airBox.show("支付取消")
							  elseif status == "login_out_success" then
							  elseif status == "login_out_faild" then
							  elseif status == "create_order_success" then
								 
							  end
						  end
						  g_autoCallback.addCocosList(loginResult , 0.15 )
										
						end

			local luaj = require "cocos.cocos2d.luaj"
				local className="com/somethingbigtech/sanguomobile2/aligames/UCGameSDK"
				
				local params = {aligamesResult}
				luaj.callStaticMethod(className, "setLuaFunctionId", params)
						
						local paramStr = ""
			local params = {
				paramStr
			}
			local arg="(Ljava/lang/String;)V"
			luaj.callStaticMethod(className, "login", params,arg)
			return 
		end
	end
	
	
	
	local param1,param2,param3
	local isSuccess = false
	if targetPlatform == cc.PLATFORM_OS_ANDROID and _isTwAndroidSdkVaild() then
		local luaj = require "cocos.cocos2d.luaj"
		local className="com/m543/pay/FastSdk"
		
		local params = {loginChannel}
		local arg="(Ljava/lang/String;)V"
		luaj.callStaticMethod(className, "setLoginChannel", params, arg)
		
		local loginResult = function(s)
			local params = string.split(s, ",")
			param1 = params[1]
			param2 = params[2]
			param3 = params[3]
			if callback then
				callback(param1,param2,param3)
			end
		end
		
		local params = {
			loginResult
		}
		luaj.callStaticMethod(className, "login", params)
	
	elseif (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform)--[[ or (cc.PLATFORM_OS_MAC == targetPlatform)]] then
		if loginChannel == SdkLoginChannel.facebook then
			local resultHandler = function(status,token)
				if status == "success" then
					param1 = token
					param2 = token
					param3 = loginChannel
					if callback then
						callback(param1,param2,param3)
					end
				end
			end
			local args = {scriptHandler = resultHandler}
			local luaoc = require "cocos.cocos2d.luaoc"
			local className = "SdkHelp"
			print("oc call login")
			local ok  = luaoc.callStaticMethod(className,"login",args)
			if not ok then
				print("oc callfail")
			else
				print("oc callsuccess")
			end
		elseif loginChannel == SdkLoginChannel.qiangwan then
			print("qiangwan login")
			local resultHandler = function(token,uid)
				if callback then
					callback(uid,token,loginChannel)
				end
			end

			local qwLogout = function (  )
				print("logout")
				g_gameManager.reStartGame()
			end

			local args = {scriptHandler = resultHandler,testHandler = qwLogout }
			local luaoc = require "cocos.cocos2d.luaoc"
			local className = "AppController"
			local ok  = luaoc.callStaticMethod(className,"loginQW",args)

		elseif loginChannel == SdkLoginChannel.haowan then
			print("haowan login")
			local resultHandler = function(token,uid)
				if callback then
					callback(uid,token,loginChannel)
				end
			end

			local hwLogout = function (  )
				print("logout")
				g_gameManager.reStartGame()
			end

			local args = {scriptHandler = resultHandler,testHandler = hwLogout }
			local luaoc = require "cocos.cocos2d.luaoc"
			local className = "AppController"
			local ok  = luaoc.callStaticMethod(className,"loginHW",args)			
		end
	else
		printf("%s sdk cannot work @ %s PLATFORM_OS",loginChannel,targetPlatform)
	end
   
end

--重置sdk的状态
function logout()
	if targetPlatform == cc.PLATFORM_OS_ANDROID and _isTwAndroidSdkVaild() then
		local luaj = require "cocos.cocos2d.luaj"
		local className="com/m543/pay/FastSdk"
		local params = {false}
		luaj.callStaticMethod(className, "setLogin", params)
	end
end

--判断登录渠道在当前系统平台是否生效
function isChannelVaild(loginChannel)
	local isVaild = false

	if loginChannel == SdkLoginChannel.facebook then
		--if cc.PLATFORM_OS_ANDROID == targetPlatform and _isTwAndroidSdkVaild() --不再使用facebook账户
		--or cc.PLATFORM_OS_IPHONE == targetPlatform 
		--or cc.PLATFORM_OS_IPAD == targetPlatform
		--then
		--	isVaild = true
		--end
	elseif loginChannel == SdkLoginChannel.googleplus then
		if  cc.PLATFORM_OS_ANDROID == targetPlatform and _isTwAndroidSdkVaild() then
			isVaild = true
		end
	elseif loginChannel == SdkLoginChannel.dsuc then
		isVaild = true
	end

	return isVaild
end

--分享到facebook
function shareToFacebook(shareInfo,retHandler)
	 
	local data = shareInfo or {}
	local title = data.title or g_tr("shareFbTitle")
	local description = data.description or g_tr("shareFbContent")
	local url = data.url or "http://www.sanguomobile2.com"
	local imageUrl = "http://www.sanguomobile2.com/view/images/fb_share.jpg"
		
	local facebookCallback = function(status)
		 --status: success,error,cancled
		 print("facebook share result:",status)
		 g_airBox.show(g_tr("share_to_facebook_"..status))
		 if retHandler then
			 retHandler(status)
		 end
	end
	

	if targetPlatform == cc.PLATFORM_OS_ANDROID and _isTwAndroidSdkVaild() then
		local status = ""
		local callback = function()
			facebookCallback(status)
		end
		local resultHandler = function(mstatus)
			status = mstatus
			g_autoCallback.addCocosList(callback , 0.15 )
		end
		
		local luaj = require "cocos.cocos2d.luaj"
		local className="com/m543/pay/FastSdk"
		local params = {resultHandler,title,description,url,imageUrl}
		luaj.callStaticMethod(className, "shareToFacebook", params)
	elseif (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform) then
		local resultHandler = function(status)
			facebookCallback(status)
		end
		local args = {scriptHandler = resultHandler,title = title,description = description,url = url,image_url = imageUrl}
		local luaoc = require "cocos.cocos2d.luaoc"
		local className = "SdkHelp"
		print("oc call shareToFacebook")
		local ok  = luaoc.callStaticMethod(className,"shareToFacebook",args)
		if not ok then
			print("oc callfail")
		else
			print("oc callsuccess")
		end
	else
		print("cannot share to facebook on current platform")
	end
end

function shareSdkShare()
	
	local title,titleUrl,text,imagePath,url,comment,siteName,siteUrl
	title = g_tr("share_title")
	titleUrl = "sanguomobile2.cn"
	text = g_tr("share_text")
	
	--sd卡根目录开始
	imagePath = "/somethingbig_sg2_share.png"
	url = "sanguomobile2.cn"
	comment = "评论内容xxxxxx"
	siteName = "手机三国2"
	siteUrl = "sanguomobile2.cn"

	if targetPlatform == cc.PLATFORM_OS_ANDROID then
		local shareCallBack = function(status)
			
			
			
			g_autoCallback.addCocosList(function()
				if status == "success" then
				
				elseif status == "error" then
					
				elseif status == "cancel" then
					
				end
				print("status:",status)
				g_airBox.show(status)
			end , 0.15 )
			
			
		
		end
	
		local luaj = require "cocos.cocos2d.luaj"
		local className="cn/sharesdk/onekeyshare/ShareHelper"
		local params = {shareCallBack,title,titleUrl,text,imagePath,url,comment,siteName,siteUrl}
		luaj.callStaticMethod(className, "showShare", params)
	end

end

--创建角色事件追踪
function trackCreateRoleEvent()
	
	isCreateRole = true
	
	if _isReYunSdkVaild() then
		if targetPlatform == cc.PLATFORM_OS_ANDROID then
			local luaj = require "cocos.cocos2d.luaj"
			local className="com/reyun/ReYunHelper"
			local gameUuid = g_sgHttp.getUUID()
			local params = {gameUuid}
			luaj.callStaticMethod(className, "trackCreateRoleEvent", params)
		elseif (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform)  then
			local gameUuid = g_sgHttp.getUUID()
			local args = {account_id = gameUuid}
			local luaoc = require "cocos.cocos2d.luaoc"
			local className = "SdkHelp"
			print("oc call trackCreateRoleEventReyun")
			local ok  = luaoc.callStaticMethod(className,"trackCreateRoleEventReyun",args)
			if not ok then
				print("oc callfail")
			else
				print("oc callsuccess")
			end
		end
	end
	

	if not _checkAppsFlyerSDKVaild() then
		return
	end
	
	if targetPlatform == cc.PLATFORM_OS_ANDROID and _isTwAndroidSdkVaild() then
		local luaj = require "cocos.cocos2d.luaj"
		local className="com/m543/pay/FastSdk"
		local params = {}
		luaj.callStaticMethod(className, "trackCreateRoleEvent", params)
	elseif (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform) then
		local args = {}
		local luaoc = require "cocos.cocos2d.luaoc"
		local className = "SdkHelp"
		print("oc call trackCreateRoleEvent")
		local ok  = luaoc.callStaticMethod(className,"trackCreateRoleEvent",args)
		if not ok then
			print("oc callfail")
		else
			print("oc callsuccess")
		end
	end
end

--登录事件追踪
function trackLoginEvent() 

	if _isReYunSdkVaild() then
		if targetPlatform == cc.PLATFORM_OS_ANDROID then
			local luaj = require "cocos.cocos2d.luaj"
			local className="com/reyun/ReYunHelper"
			local gameUuid = g_sgHttp.getUUID()
			local params = {gameUuid}
			luaj.callStaticMethod(className, "trackLoginEvent", params)
		elseif (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform)  then
			local gameUuid = g_sgHttp.getUUID()
			local args = {account_id = gameUuid}
			local luaoc = require "cocos.cocos2d.luaoc"
			local className = "SdkHelp"
			print("oc call trackLoginEventReyun")
			local ok  = luaoc.callStaticMethod(className,"trackLoginEventReyun",args)
			if not ok then
				print("oc callfail")
			else
				print("oc callsuccess")
			end
		end
	end


	if not _checkAppsFlyerSDKVaild() then
		return
	end
	
	if targetPlatform == cc.PLATFORM_OS_ANDROID and _isTwAndroidSdkVaild() then
		local luaj = require "cocos.cocos2d.luaj"
		local className="com/m543/pay/FastSdk"
		local params = {}
		luaj.callStaticMethod(className, "trackLoginEvent", params)
	elseif (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform) then
		local args = {}
		local luaoc = require "cocos.cocos2d.luaoc"
		local className = "SdkHelp"
		print("oc call appsflyer trackLoginEvent")
		local ok  = luaoc.callStaticMethod(className,"trackLoginEvent",args)
		if not ok then
			print("oc callfail")
		else
			print("oc callsuccess")
		end
	end
end

--支付开始事件追踪
function trackPurchaseStartEvent(revenue,contentType,contentId,currencyType,orderId,payWay)
	if _isReYunSdkVaild() then
		if targetPlatform == cc.PLATFORM_OS_ANDROID then
			local luaj = require "cocos.cocos2d.luaj"
			local className="com/reyun/ReYunHelper"
			local params = {tostring(orderId),tostring(payWay),tostring(currencyType),tonumber(revenue)}
			luaj.callStaticMethod(className, "trackPurchaseStartEvent", params)
		elseif (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform)  then
			local args = {transaction_id = tostring(orderId),payway = tostring(payWay),currency_type = tostring(currencyType),revenue = tonumber(revenue)}
			local luaoc = require "cocos.cocos2d.luaoc"
			local className = "SdkHelp"
			print("oc call trackPurchaseStartEventReyun")
			local ok  = luaoc.callStaticMethod(className,"trackPurchaseStartEventReyun",args)
			if not ok then
				print("oc callfail")
			else
				print("oc callsuccess")
			end
		end
	end
end

--支付事件追踪
function trackPurchaseEvent(revenue,contentType,contentId,currencyType,orderId,payWay)

	if _isReYunSdkVaild() then
		if targetPlatform == cc.PLATFORM_OS_ANDROID then
			local luaj = require "cocos.cocos2d.luaj"
			local className="com/reyun/ReYunHelper"
			local params = {tostring(orderId),tostring(payWay),tostring(currencyType),tonumber(revenue)}
			luaj.callStaticMethod(className, "trackPurchaseEvent", params)
		elseif (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform)  then
			local args = {transaction_id = tostring(orderId),payway = tostring(payWay),currency_type = tostring(currencyType),revenue = tonumber(revenue)}
			local luaoc = require "cocos.cocos2d.luaoc"
			local className = "SdkHelp"
			print("oc call trackPurchaseEventReyun")
			local ok  = luaoc.callStaticMethod(className,"trackPurchaseEventReyun",args)
			if not ok then
				print("oc callfail")
			else
				print("oc callsuccess")
			end
		end
	end
	

	if not _checkAppsFlyerSDKVaild() then
		return
	end
	
	if targetPlatform == cc.PLATFORM_OS_ANDROID and _isTwAndroidSdkVaild() then
		local luaj = require "cocos.cocos2d.luaj"
		local className="com/m543/pay/FastSdk"
		local params = {revenue,contentType,contentId,currencyType}
		local arg="(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
		luaj.callStaticMethod(className, "trackPurchaseEvent", params,arg)
	elseif (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform) then
		local args = {content_id = contentId,content_type = contentType,revenue = revenue,currency_type = currencyType}
		local luaoc = require "cocos.cocos2d.luaoc"
		local className = "SdkHelp"
		print("oc call trackPurchaseEvent")
		local ok  = luaoc.callStaticMethod(className,"trackPurchaseEvent",args)
		if not ok then
			print("oc callfail")
		else
			print("oc callsuccess")
		end
	end
end

--新手引导事件追踪（强制引导结束）
function trackTutorialCompletionEvent()
	
	if _isReYunSdkVaild() then
		if targetPlatform == cc.PLATFORM_OS_ANDROID then
			local luaj = require "cocos.cocos2d.luaj"
			local className="com/reyun/ReYunHelper"
			local params = {}
			luaj.callStaticMethod(className, "trackTutorialCompletionEvent", params)
			elseif (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform)  then
				local args = {}
				local luaoc = require "cocos.cocos2d.luaoc"
				local className = "SdkHelp"
				print("oc call trackTutorialCompletionEventReyun")
				local ok  = luaoc.callStaticMethod(className,"trackTutorialCompletionEventReyun",args)
				if not ok then
					print("oc callfail")
				else
					print("oc callsuccess")
				end
		end
	end
	
	if not _checkAppsFlyerSDKVaild() then
		return
	end

	if targetPlatform == cc.PLATFORM_OS_ANDROID and _isTwAndroidSdkVaild() then
		local luaj = require "cocos.cocos2d.luaj"
		local className="com/m543/pay/FastSdk"
		local params = {}
		luaj.callStaticMethod(className, "trackTutorialCompletionEvent", params)
	elseif (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform) then
		local args = {}
		local luaoc = require "cocos.cocos2d.luaoc"
		local className = "SdkHelp"
		print("oc call trackTutorialCompletionEvent")
		local ok  = luaoc.callStaticMethod(className,"trackTutorialCompletionEvent",args)
		if not ok then
			print("oc callfail")
		else
			print("oc callsuccess")
		end
	end
end

--获取用户 uid
function getAppsFlyerUID()
  local retStr = "null"

  if not _checkAppsFlyerSDKVaild() then
	return retStr
  end
  
  if not _checkAppsFlyerConversionDataVaild() then
	return retStr
  end
   
  if targetPlatform == cc.PLATFORM_OS_ANDROID and _isTwAndroidSdkVaild() then
	local luaj = require "cocos.cocos2d.luaj"
	local className="com/m543/pay/FastSdk"
	local sig = "()Ljava/lang/String;"
	local params = {}
	local ok,ret = luaj.callStaticMethod(className, "getAppsFlyerUID", params,sig)
	if not ok then
		print("java callfail")
	else
		print("java callsuccess")
		retStr = ret
	end
  elseif (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform) then
		local args = {}
		local luaoc = require "cocos.cocos2d.luaoc"
		local className = "SdkHelp"
		print("oc call getAppsFlyerUID")
		local ok,ret  = luaoc.callStaticMethod(className,"getAppsFlyerUID",args)
		if not ok then
			print("oc callfail")
		else
			print("oc callsuccess")
			retStr = ret
		end
  end
  
  return retStr
end

local afHandler = function(ret)
	appsFlyerConversionData = ret
	print("appsFlyerConversionData~~~:",appsFlyerConversionData)
end

if (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform) then
	if _checkAppsFlyerSDKVaild() and _checkAppsFlyerConversionDataVaild() then
		local args = {scriptHandler = afHandler}
		local luaoc = require "cocos.cocos2d.luaoc"
		local className = "SdkHelp"
		print("oc call registerAfScriptHandler")
		local ok,ret  = luaoc.callStaticMethod(className,"registerAfScriptHandler",args)
		if not ok then
		  print("oc callfail")
		else
		  print("oc callsuccess")
		end
	end
end

--获取用户来源信息 String类型，json格式
function getAppsFlyerConversionData()
  
  local retStr = "null"

  if not _checkAppsFlyerSDKVaild() then
	return retStr
  end
  
  if not _checkAppsFlyerConversionDataVaild() then
	return retStr
  end
   
  if targetPlatform == cc.PLATFORM_OS_ANDROID and _isTwAndroidSdkVaild() then
		local luaj = require "cocos.cocos2d.luaj"
		local className="com/m543/pay/FastSdk"
		local sig = "()Ljava/lang/String;"
		local params = {}
		local ok,ret = luaj.callStaticMethod(className, "getAfConversionData", params,sig)
		if not ok then
			print("java callfail")
		else
			print("java callsuccess")
			retStr = ret
		end
	elseif (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform) then
		local args = {}
		local luaoc = require "cocos.cocos2d.luaoc"
		local className = "SdkHelp"
		print("oc call getAppsFlyerData")
		local ok,ret  = luaoc.callStaticMethod(className,"getAppsFlyerData",args)
		if not ok then
		  print("oc callfail")
		else
		  print("oc callsuccess")
		end
		retStr = appsFlyerConversionData
	end
	
	return retStr
  
end

function addPlayerInfo(type)

	if isCreateRole == true then
		type = 2
		isCreateRole = false
	end
	
	if targetPlatform == cc.PLATFORM_OS_ANDROID then
		
		local guildName = "暂无公会"
		if g_AllianceMode.getSelfHaveAlliance() then
			local data = g_AllianceMode.getBaseData()
			guildName = data.name
		end
		
		local userInfo = {
			dataType=type.."",
			roleId=tostring(g_PlayerMode.GetData().id),
			roleName=g_PlayerMode.GetData().nick,
			roleLevel=g_PlayerMode.GetData().level.."",
			zoneId=g_Account.getCurrentAreaInfo().id.."",
			zoneName=g_Account.getCurrentAreaInfo().name,
			balance=g_gameTools.getPlayerCurrencyCount(g_Consts.AllCurrencyType.Gem).."",
			partyName=guildName,
			vipLevel=g_PlayerMode.GetData().vip_level.."",
			roleCTime=g_PlayerMode.GetData().create_time.."",
			roleLevelMTime=g_PlayerMode.GetData().levelup_time.."",
		}
		
		local download_channel = g_Account.getDownloadChannel()
		if download_channel == g_sdkManager.SdkDownLoadChannel.anysdk then
			local pluginChannel = require("anysdk.PluginChannel"):getInstance()
			if pluginChannel then
			 pluginChannel:submitLoginGameRole(userInfo)
			end
		elseif download_channel == g_sdkManager.SdkDownLoadChannel.aligames then

--			STRING_ROLE_ID	roleId	String	是	角色ID,长度不超过50
--			STRING_ROLE_NAME	roleName	String	是	角色名称,长度不超过50
--			LONG_ROLE_LEVEL	roleLevel	long	是	角色等级,长度不超过10
--			LONG_ROLE_CTIME	roleCTime	long	是	角色创建时间(单位：秒)，长度10，获取服务器存储的时间，不可用手机本地时间
--			STRING_ZONE_ID	zoneId	String	是	区服ID,长度不超过50
--			STRING_ZONE_NAME	zoneName	String	是	区服名称,长度不超过50

			for key, var in pairs(userInfo) do
				if key == "roleLevel" or key == "roleCTime" then
					userInfo[key] = tonumber(var)
				end
			end
			
			local paramStr = cjson.encode(userInfo)
			local params = {
				paramStr
			}
			
			local luaj = require "cocos.cocos2d.luaj"
			local className="com/somethingbigtech/sanguomobile2/aligames/UCGameSDK"
		
			local arg="(Ljava/lang/String;)V"
			luaj.callStaticMethod(className, "submitRoleData", params,arg)
		elseif download_channel == g_sdkManager.SdkDownLoadChannel.huawei then
			 --addPlayerInfo(final String levelInfo,final String roleInfo,final String areaInfo,final String guildInfo)
			local luaj = require "cocos.cocos2d.luaj"
			local className="com/somethingbigtech/sanguomobile2/huawei/FastSdk"
			local params = {userInfo.roleLevel,userInfo.roleName,userInfo.zoneId,userInfo.partyName}
			local arg="(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
			luaj.callStaticMethod(className, "addPlayerInfo", params,arg)
		end
	end
end

function alertExitGame()
	if targetPlatform == cc.PLATFORM_OS_ANDROID then
		local download_channel = g_Account.getDownloadChannel()
		if download_channel == g_sdkManager.SdkDownLoadChannel.anysdk then
			local luaj = require "cocos.cocos2d.luaj"
			local className="com/somethingbigtech/sanguomobile2/MainActivity"
			local params = {}
			local ok,ret = luaj.callStaticMethod(className, "exitGame", params)
			if not ok then
				print("java callfail")
			else
				print("java callsuccess")
			end
		end
	end
end

function updateGeTuiClientId(callback)
	local clientId = ""
	if targetPlatform == cc.PLATFORM_OS_ANDROID then
		if isOldClientVersion() then
			clientId = cTools_getNotificationClientid()
			getuiClientId = clientId
			print("getui:"..clientId)
			if callback then
				callback(clientId)
			end
		else
			local resultHandler = function(ret)
				clientId = ret
				getuiClientId = clientId
				print("getui:"..clientId)
				if callback then
					callback(clientId)
				end
			end
			
			local luaj = require "cocos.cocos2d.luaj"
			local className="org/cocos2dx/lib/Cocos2dxHelper"
			local params = {resultHandler}
			print("getui:call java")
			luaj.callStaticMethod(className, "reqNotificationClientid", params)
		end

	elseif cc.PLATFORM_OS_IPHONE == targetPlatform or cc.PLATFORM_OS_IPAD == targetPlatform then
        local args = {}
        local luaoc = require "cocos.cocos2d.luaoc"
        local className = "SdkHelp"
        print("oc call getGetuiClientId")
        local ok,ret  = luaoc.callStaticMethod(className,"getGetuiClientId",args)
        if not ok then
            print("oc callfail")
        else
            print("oc callsuccess")
            clientId = ret
        end

		getuiClientId = clientId
        print("clientId:",clientId)
		if callback then
			callback(clientId)
		end
	else
		getuiClientId = clientId
		if callback then
			callback(clientId)
		end
	end
end

function getGeTuiClientId()
	return getuiClientId
end

		
return sdkManager
