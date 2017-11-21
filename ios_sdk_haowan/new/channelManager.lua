--region channelManager.lua
--Author : luqingqing
--Date   : 2016/4/20
--此文件由[BabeLua]插件自动生成

local channelManager = {}
setmetatable(channelManager,{__index = _G})
setfenv(1,channelManager)

payWay = 
{
	["googleplay"] = "googleplay",
	["googlestore"] = "googlestore",
	["appstore"] = "appstore", --已废弃
	["appstore_tw"] = "appstore_tw",
	["appstore_cn"] = "appstore_cn",
	["paypal"] = "paypal",
	["mycard"] = "mycard",
	["alipay"] = "alipay",
	["alipay_cn"] = "alipay_cn",
	["huawei"] = "huawei",
	["aligames"] = "aligames",
	["qiangwan"] = "qiangwan",
	["haowan"] = "haowan",
}

local payWayList = nil

local function _initPayWayList()
	local result = {}
	--anysdk
	if g_Account.getDownloadChannel() == g_sdkManager.SdkDownLoadChannel.anysdk then
		local pluginChannel = require("anysdk.PluginChannel"):getInstance()
		if pluginChannel then
			local payChannelName = pluginChannel:getCurrentChannelName()
			if payChannelName then
				table.insert(result,payChannelName)
			end
		end
	else
		local player = g_PlayerMode.GetData()
		local temData = nil
	
		for key, value in pairs(g_data.pay_way) do
			print(g_Account.getDownloadChannel(), value.channel)
			if g_Account.getDownloadChannel() == value.channel then
				temData = value
				break
			end
		end
	
		local array = string.split(temData.pay_way, ",")
	
		for i=1, #array do
			if player.level >= temData.pay_way_lv[i] then
				table.insert(result, array[i])
			end
		end
	end
	return result
end

--这里返回的是payway的list
function GetPayWayList()
	if payWayList == nil then
		payWayList =  _initPayWayList()
	end
	assert(#payWayList > 0)
	return payWayList
end

function GetMoneyType(type)
	if type == "RMB" then
		return "￥"
	elseif type == "USD" then
		return "$"
	elseif type == "POINT" then
		return g_tr("prictPoint")
	end

	return ""
end

return channelManager
--endregion
