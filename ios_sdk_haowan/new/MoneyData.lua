--g_moneyData

local MoneyDataMode = {}
setmetatable(MoneyDataMode,{__index = _G})
setfenv(1, MoneyDataMode)

local baseData = nil

local baseView = nil

local cardView = nil

local bannerView = nil

local isNew = false

local timeDlt = -1000

local isAnySdkPayEventRegisted = false

--更新显示
function NotificationUpdateShow()
	if baseView ~= nil then
		baseView:close()
	end
end

--请求数据
function RequestData(pid, aci, payway)

	if timeDlt == -1000 then
		timeDlt = g_clock.getCurServerTime()
	else
		if g_clock.getCurServerTime() - timeDlt < 2 then
			return
		end
	end
	
--	--for test
--	do
--		local msgData = {}
--		msgData.order = {}
--		msgData.order.order_id = "test"..g_clock.getCurServerTime()
--		huaweiPay(pid,msgData)
--		return
--	end

	--for test
--	do
--		aligamesPay(pid,msgData)
--		return
--	end

 --for test
-- do
-- 	anysdk(pid,"ttt")
-- 	return
-- end

	timeDlt = g_clock.getCurServerTime()
	local tbl = 
	{
		["id"] = pid,
		["aci"] = aci,
	}

	local function onRecv(result, msgData)
		g_busyTip.hide_1() 
		if(result==true)then
			sendRequest(msgData, payway,pid)
		end
	end
	g_busyTip.show_1() 
	g_sgHttp.postData("order/createOrder", tbl, onRecv,true)
end

function sendRequest(msgData, payway,pid)
	
	local priceConfig = g_data.pricing[tonumber(pid)]
	assert(priceConfig)
	 
	local orderId = tostring(msgData.order.orderId)
	local revenue = tonumber(priceConfig.rmb_value) or 0
	local contentType = priceConfig.goods_type or 1
	local contentId = priceConfig.id or 0
	local currencyType = "CNY"
	local payWay = payway
	
	g_sdkManager.trackPurchaseStartEvent(revenue,contentType,contentId,currencyType,orderId,payWay)
	
	if payway == g_channelManager.payWay.googleplay or payway == g_channelManager.payWay.googlestore then
		googlePay(msgData.order.orderId, msgData.order.productId)
	elseif payway == g_channelManager.payWay.appstore or	payway == g_channelManager.payWay.appstore_tw or payway == g_channelManager.payWay.appstore_cn then
		appPay(msgData.order.orderId, msgData.order.productId)
	elseif payway == g_channelManager.payWay.paypal then
		paypol(msgData.order.url)
	elseif payway == g_channelManager.payWay.mycard then
		myCard(msgData)
	elseif payway == g_channelManager.payWay.alipay or payway == g_channelManager.payWay.alipay_cn then
		aliPayment(msgData.order)
	elseif payway == g_channelManager.payWay.huawei then
		huaweiPay(pid,msgData)
	elseif payway == g_channelManager.payWay.aligames then
		aligamesPay(pid,msgData)
	elseif payway == g_channelManager.payWay.qiangwan then
		--print("payway is qiangwan")
		qiangwanPay(pid,msgData)

	elseif payway == g_channelManager.payWay.haowan then
		--print("payway is haowan")
		haowanPay(pid,msgData)

	elseif require("anysdk.PluginChannel").isVaildAnySdkChannel(payway) then
		anysdk(pid,msgData)
	end
end


function qiangwanPay(pid,msgData)
	--判断是否是苹果渠道
	--if (cc.PLATFORM_OS_IPHONE ~= targetPlatform) and (cc.PLATFORM_OS_IPAD ~= targetPlatform) then
		--g_airBox.show("qiangwan pay valid only on ios")
		--return
	--end

	local priceConfig = g_data.pricing[tonumber(pid)]
	dump(msgData)
	--dump(priceConfig)

	local productId = priceConfig.product_id
	if productId == nil or productId == 0 then
		productId = priceConfig.id
	end

	local info = 
	{
		goodsName = priceConfig.desc1,
		goodsPrice = tostring( msgData.order.price * 100),
		goodsDesc = priceConfig.desc1,
		productId = tostring(productId),
		extendInfo = tostring(msgData.order.extend),
		player_server = g_Account.getCurrentAreaInfo().name,
		player_role = g_PlayerMode.GetData().nick,
		cp_trade_no = msgData.order.out_trade_no,
	}
	
	dump(info)
	
	local luaoc = require "cocos.cocos2d.luaoc"
	local className = "SdkHelp"
	local ok  = luaoc.callStaticMethod(className,"payAction",info)

 	--orderInfo.goodsName = @"金币";
    --orderInfo.goodsPrice = 1;//单位为分
    --orderInfo.goodsDesc = @"有了金币就可以买买买了";//商品描述
    --orderInfo.extendInfo = @"1234567890";//此字段会透传到游戏服务器，可拼接订单信息和其它信息等
    --orderInfo.productId = @"com.qiangwan.appju_6";//虚拟商品在APP Store中的ID
    -------注意：此处需要传入的是区服的名称，而不是区服编号-------------------------
    --orderInfo.player_server = @"素月流天";//玩家所在区服名称（跟游戏内显示的区服保持一致）
    --orderInfo.player_role = @"小明";// 玩家角色名称
    --orderInfo.cp_trade_no = @"201603101021";//CP订单号

end


function haowanPay(pid,msgData)

	local priceConfig = g_data.pricing[tonumber(pid)]
	dump(msgData)
	--dump(priceConfig)
	local productId = priceConfig.product_id
	if productId == nil or productId == 0 then
		productId = priceConfig.id
	end

	local info = 
	{
		goodsName = priceConfig.desc1,
		goodsPrice = tostring( msgData.order.price * 100),
		goodsDesc = priceConfig.desc1,
		productId = tostring(productId),
		extendInfo = tostring(msgData.order.extend),
		player_server = g_Account.getCurrentAreaInfo().name,
		player_role = g_PlayerMode.GetData().nick,
		cp_trade_no = msgData.order.out_trade_no,
	}
	
	dump(info)
	
	local luaoc = require "cocos.cocos2d.luaoc"
	local className = "SdkHelp"
	local ok  = luaoc.callStaticMethod(className,"payAction",info) 
end

function anysdk(pid,msgData)

		local extData = msgData.order.ext
		if not isAnySdkPayEventRegisted then
			g_gameCommon.addEventHandler(g_Consts.CustomEvent.AnySdkPayResult, function(_,data)
				--anysdk 支付事件
				local code = data.type
				if code == PayResultCode.kPaySuccess then
					--do
					g_airBox.show("支付成功")
				elseif code == PayResultCode.kPayFail then
					--do
					g_airBox.show("支付失败")
				elseif code == PayResultCode.kPayCancel then
					--do
					g_airBox.show("支付取消")
				elseif code == PayResultCode.kPayNetworkError then
					--do
					g_airBox.show("支付网络出现错误")
				elseif code == PayResultCode.kPayProductionInforIncomplete then
					--do
					g_airBox.show("支付信息提供不完全")
				elseif code == PayResultCode.kPayInitSuccess then
					--do
				elseif code == PayResultCode.kPayInitFail then
					--do
				elseif code == PayResultCode.kPayNowPaying then
					--do
				elseif code == PayResultCode.kPayRechargeSuccess then
					--do
				end
		end)
		isAnySdkPayEventRegisted = true
	end

	local pluginChannel = require("anysdk.PluginChannel"):getInstance()
	if pluginChannel then
		local priceConfig = g_data.pricing[tonumber(pid)]
		assert(priceConfig)
		
		local guildName = "暂无公会"
		if g_AllianceMode.getSelfHaveAlliance() then
			local data = g_AllianceMode.getBaseData()
			guildName = data.name
		end
		
		local productId = priceConfig.product_id
		if productId == nil or productId == 0 then
			productId = priceConfig.id
		end
		
		local info = {
			
			Product_Id=tostring(productId),
			Product_Name=priceConfig.desc1,
			--Product_Price=tostring(priceConfig.price),
			Product_Price = tostring(msgData.order.price),--使用服务器返回的价格
			Product_Count="1",
			Product_Desc=priceConfig.desc1,
			Coin_Name="元宝",
			Coin_Rate="10",
			Role_Id=g_PlayerMode.GetData().id.."",
			Role_Name=g_PlayerMode.GetData().nick,
			Role_Grade=g_PlayerMode.GetData().level.."",
			Role_Balance=g_gameTools.getPlayerCurrencyCount(g_Consts.AllCurrencyType.Gem).."",
			Vip_Level=g_PlayerMode.GetData().vip_level.."",
			Party_Name=guildName,
			Server_Id=g_Account.getCurrentAreaInfo().id.."",
			Server_Name=g_Account.getCurrentAreaInfo().name,
			EXT= extData,
		}
		
		pluginChannel:pay(info)
	end
end

function aligamesPay(pid,msgData)
	 if cc.PLATFORM_OS_ANDROID ~= cc.Application:getInstance():getTargetPlatform() then
		g_airBox.show("aligames pay valid only on android")
		return
	 end
	 
	 
--		local SDKParamKey = {
--			CALLBACK_INFO = "callbackInfo",
--			AMOUNT = "amount",
--			NOTIFY_URL = "notifyUrl",
--			CP_ORDER_ID = "cpOrderId",
--			ACCOUNT_ID = "accountId",
--			SIGN_TYPE = "signType",
--			SIGN = "sign",
--		}
--
--	 
--	 
--	 --for test
--	 local payParams = {
--	 		[SDKParamKey.CALLBACK_INFO] = "{\"test\":true}",
--			[SDKParamKey.NOTIFY_URL] = "http://192.168.1.1/notifypage.do",
--			[SDKParamKey.AMOUNT] = "2.33",
--			[SDKParamKey.CP_ORDER_ID] = "20160000101001",
--			[SDKParamKey.ACCOUNT_ID] = "123", 
--			[SDKParamKey.SIGN_TYPE] = "MD5",
--	 }



--------------------------------------------------------------------------------------------
--游戏服返回的订单信息
-- {"accountId":"8f673a4a3a7c6654490b846148e3d2df",
-- 	"amount":"6.00",
-- 	"cpOrderId":"20170522105852813025",
-- 	"notifyUrl":"http:\/\/27.115.98.171\/payment\/aligamesSdkAsyncNotifyReceiver",
-- 	"sign":"ea796520270e4998121e31bac2c478f5",
-- 	"signType":"MD5",
-- 	"order_id":"20170522105852813025",
-- 	"description":"手机三国2-60元宝"} 
 	
	local payParams = msgData.order
	
	
	local paramStr = cjson.encode(payParams)
	local params = {
		paramStr
	}
	
	local luaj = require "cocos.cocos2d.luaj"
	local className="com/somethingbigtech/sanguomobile2/aligames/UCGameSDK"

	local arg="(Ljava/lang/String;)V"
	luaj.callStaticMethod(className, "pay", params,arg)
	return 
	 
end

function huaweiPay(pid,msgData)
	 if cc.PLATFORM_OS_ANDROID ~= cc.Application:getInstance():getTargetPlatform() then
		g_airBox.show("huawei pay valid only on android")
		return
	 end
	 
	 local huaweiPayResultCode = {
			["success"] = "支付成功",
			["pay_result_check_sign_failed"] = "支付失败",
			["200100"] = "支付成功",
			["200101"] = "支付参数检测失败",
			["200100"] = "支付客户端初始化失败",
			["200101"] = "支付参数检测失败 ",
			["200102"] = "获取华为帐号信息失败，建议游戏重新登录",
			["200103"] = "获取游戏券信息失败",
			["30000"] = "用户中途取消了支付",
			["30001"] = "参数或参数类型错误",
			["30002"] = "支付结果查询超时",
			["30004"] = "非法请求",
			["30005"] = "网络连接异常",
			["30006"] = "系统升级",
			["30007"] = "订单过期",
			["30008"] = "登陆帐号失败。",
			["30099"] = "系统错误",
		}
	 
	 local javacallback = function(s)
		local payResult = function()
			local status = s
			local payTip = "支付失败"
			if huaweiPayResultCode[status] then
				payTip = huaweiPayResultCode[status]
			end
			g_airBox.show(payTip)
		
		local data = {}
			if status == "success" then
					data.type = PayResultCode.kPaySuccess
				else
					data.type = PayResultCode.kPayFail
				end
				g_gameCommon.dispatchEvent(g_Consts.CustomEvent.AnySdkPayResult,data)
		end
		g_autoCallback.addCocosList(payResult , 0.15 )
	 end
	 
	 local priceConfig = g_data.pricing[tonumber(pid)]
	 assert(priceConfig)
	 
	 local price = tostring(msgData.order.amount)
	 local orderId = tostring(msgData.order.requestId)
	 local productDesc = msgData.order.productDesc
	 local productName = msgData.order.productName
	 
	 print("price:",price,",orderId:",orderId,",productDesc:",productDesc,",productName:",productName)
	 
	 local luaj = require "cocos.cocos2d.luaj"
	 local className="com/somethingbigtech/sanguomobile2/huawei/FastSdk"
	 local params={javacallback,price,productName, productDesc,orderId}
	 --local arg="(ILjava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
	 --pay(final int luaFunctionId,String price,String productName,String productDesc,String orderId)
	 luaj.callStaticMethod(className, "pay", params)
	 
end

function googlePay(orderId, productId)
	if cc.PLATFORM_OS_ANDROID ~= cc.Application:getInstance():getTargetPlatform() then
		g_airBox.show("googlePay valid only on android")
		return
	end
	if g_sdkManager.isOldClientVersion() then
		local luaj = require "cocos.cocos2d.luaj"
		local className="com/somethingbigtech/sanguomobile2/payment/PayCode"
		local params={orderId, productId}
		local arg="(Ljava/lang/String;Ljava/lang/String;)V"
		luaj.callStaticMethod(className, "googlePay", params, arg)
	else
	
		--新包用lua控制是否为测试模式
		local notifyUrl = g_googlePayNotifyUrl
		
		local luaj = require "cocos.cocos2d.luaj"
		local className="com/somethingbigtech/sanguomobile2/payment/PayCode"
		local params={orderId, productId,notifyUrl}
		local arg="(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
		luaj.callStaticMethod(className, "googlePay", params, arg)
	end
end

function appPay(orderId, productId)
	local language = require("localization.langConfig").getLanguage()
	paymentForLua_IOS_purchase(orderId, productId,language)
end

function myCard(msgData)
	if cc.PLATFORM_OS_ANDROID ~= cc.Application:getInstance():getTargetPlatform() then
		g_airBox.show("mycard valid only on android")
		return
	end

	local authCode = msgData.order.authcode
	local paySuccess = function()
		local	url = g_paymentNotifiyHost.."/payment/mycardGlobalSyncNotifyReceiver"
		local mode = "sdk"
		local time = tostring(g_clock.getCurServerTime())
		local orderid = tostring(msgData.order.order_id)
		local from = "mobile"
		local key = "DSSanGuoMobile6399two2288"
		local tosign = mode..time..orderid..key
		local sign = string.lower(cTools_md5_encode(tosign))
		local para = string.format('mode=%s&time=%s&orderid=%s&from=%s&sign=%s',mode,time,orderid,from,sign)
		if g_logicDebug then
			print("发送：",url,para)
		end
		
		local function onResult(result, data, performCode, responseCode)
			if result then
				if g_logicDebug then
					g_airBox.show(data)
					g_msgBox.show(g_tr("moneyBuySuccess").."\n"..g_tr("moneyBuyOrderId")..orderid)
				end
			else
				--g_airBox.show("验证失败")
			end
		end
		httpNet:getInstance():Post(url,para,string.len(para),onResult,10,10,true,false)
	
	end
	
	local successHandler = function()
		g_autoCallback.addCocosList( paySuccess , 0.15 )
	end
	
	local luaj = require "cocos.cocos2d.luaj"
	local className="com/somethingbigtech/sanguomobile2/payment/PayCode"
	local params = {successHandler}
	luaj.callStaticMethod(className, "registScriptHandler", params)
	
	if g_sdkManager.isOldClientVersion() then
			local luaj = require "cocos.cocos2d.luaj"
			local className="com/somethingbigtech/sanguomobile2/payment/PayCode"
			local params = {authCode}
			local arg="(Ljava/lang/String;)V"
			luaj.callStaticMethod(className, "myCardPay", params,arg)
	else
			--新包将mycard的沙盒模式开关拿到了lua里面
			local isDebug = "NO" --是否为沙盒模式
			if g_isMayCardPayDebug == true then
				isDebug = "YES"
			end
			local luaj = require "cocos.cocos2d.luaj"
			local className="com/somethingbigtech/sanguomobile2/payment/PayCode"
			local params = {authCode,isDebug}
			local arg="(Ljava/lang/String;Ljava/lang/String;)V"
			luaj.callStaticMethod(className, "myCardPay", params,arg)
	end
end

function paypol(url)
	if cc.PLATFORM_OS_ANDROID ~= cc.Application:getInstance():getTargetPlatform() then
		g_airBox.show("paypol valid only on android")
		return
	end

	local luaj = require "cocos.cocos2d.luaj"
	local className = "com.somethingbigtech.sanguomobile2.payment.PayCode"
	local params={url}
	local arg = "(Ljava/lang/String;)V"
	luaj.callStaticMethod(className, "openPaymentDialog", params, arg)
end

function aliPayment(msgData)
	if cc.PLATFORM_OS_ANDROID ~= cc.Application:getInstance():getTargetPlatform() then
		g_airBox.show("aliPayment valid only on android")
		return
	end
	
	local luaj = require "cocos.cocos2d.luaj"
	local className = "com.somethingbigtech.sanguomobile2.payment.PayCode"
	local params={msgData.orderInfo}
	local arg = "(Ljava/lang/String;)V"
	luaj.callStaticMethod(className, "pay", params, arg)
end

function setView(value)
	baseView = value
end

function setBannerView(value)
	bannerView = value
end

function updateView()
	if baseView ~= nil then
		baseView:update()
	end

	if bannerView ~= nil then
		bannerView:close()
		bannerView = nil
	end
end

--支付入口
--goodsType:1表示充值 2表示月卡 3表示至尊卡
function payProduct(goodsType, aci)
	if goodsType == 1 then
		g_sceneManager.addNodeForUI(require("game.uilayer.money.MoneyView").new())
	else
		if aci == nil then
			aci = 0
		end

		if goodsType == 2 then
			local playerInfo = g_playerInfoData.GetData()
			if playerInfo.long_card == 1 then
				g_airBox.show(g_tr("rePurchase"))
				return
			end
		end
		
		local payWay =	g_channelManager.GetPayWayList()[1]
		local data = findPriceByGoodsType(goodsType,payWay)
		if data == nil then
			print("not find pricing data:"..goodsType..",platform:"..g_Account.getDownloadChannel())
			return
		end

		if #(g_channelManager.GetPayWayList()) == 1 then
			RequestData(data.id, aci, payWay)
		else
			g_sceneManager.addNodeForUI(require("game.uilayer.money.MoneyTypeView").new(data.id))
		end

	end
end

function findPriceByGoodsType(goodsType, payway)
	local data = nil
	for key, value in pairs(g_data.pricing) do
		if value.channel == payway and value.goods_type == goodsType and value.isshow == 1 then
			data = value
			break
		end
	end

	return data
end

function cardShow()
	local playerInfo = g_playerInfoData.GetData()
	
	if playerInfo.long_card == 0 then
		return true
	else
		if g_clock.isSameDay(g_clock.getCurServerTime(), playerInfo.long_card_date) then

		else
			return true
		end
	end

	--月卡
	if playerInfo.month_card_deadline == 0 then
		return true
	else
		if playerInfo.month_card_deadline > g_clock.getCurServerTime() then
			if g_clock.isSameDay(g_clock.getCurServerTime(), playerInfo.month_card_date) then

			else
				return true
			end
		end
	end

	return false
end

function giftNew()
	if isNew == false then
		isNew = true
		return true
	else
		return false
	end
end

function resetTag()
	if cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_ANDROID then
		local luaj = require "cocos.cocos2d.luaj"
		local className = "com.somethingbigtech.sanguomobile2.payment.PayCode"
		local params={"reset"}
		local arg = "(Ljava/lang/String;)V"
		luaj.callStaticMethod(className, "setIsOpen", params, arg)
	end
end

return MoneyDataMode

--endregion
