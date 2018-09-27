
cc.exports.extension = {}

extension.type_wxshare        = "weixin_share" --微信分享(android)
extension.type_wxmessage      = "weixin_message" --微信分享(ios)
extension.type_wxtoken        = "weixin_token" --获取微信token
extension.type_weixin_pay     = "weixin_pay" --微信支付
extension.type_appstore_pay   = "appstore_pay" --ios appstore pay
extension.type_ali_pay        = "ali_pay" --支付宝

--支付类型
extension.PAY_TYPE_ALI        = "pay_type_ali"
extension.PAY_TYPE_WEIXIN     = "pay_type_weixin"
extension.PAY_TYPE_APPLE      = "pay_type_apple"
extension.PAY_APPLE_URL       = "http://114.55.111.161:8018/pay/app"

--录音相关
extension.voice_init          = "voice_init"
extension.voice_get_url       = "voice_url"
extension.voice_finish        = "voice_finish"
extension.voice_finish_play   = "voice_finishplay"

--设备信息(电池、网络、定位)
extension.getBattery          = "getBattery"
extension.getNetType          = "getNetType"
extension.getLocation         = "location"

--apk下载
extension.downloadDown        = "apkDownload"

--分享
extension.shareUrl            = ""
if gt.isIOSPlatform then
    extension.SHARE_TYPE_SESSION  = "WXSceneSession"
    extension.SHARE_TYPE_TIMELINE = "WXSceneTimeline"
else 
    extension.SHARE_TYPE_SESSION  = "session"
    extension.SHARE_TYPE_TIMELINE = "timeline"    
end

--orderInfo
extension.orderInfo = ""

local APIClass = 'org/extension/ExtensionApi'
if gt.isIOSPlatform then
    extension.luaBridge = require("cocos/cocos2d/luaoc")
elseif gt.isAndroidPlatform then
    extension.luaBridge = require("cocos/cocos2d/luaj")
end


extension.callBackHandler = {} --保存回调函数
-- 提供java 和 oc 回调
cc.exports.extension_callback = function(jsonObj) 
    require("json")
    local respJson = json.decode(tostring(jsonObj))
    local call_back = extension.callBackHandler[respJson.type]
    if call_back then
        call_back(respJson)
    else
        print("extension no call_back for "..respJson.type)
    end
end

extension.iosUrlOpenHandle = function(obj)
    local roomid = obj.code.substring(1)
    print("roomid:"..roomid )
    if roomid ~= "" then
    end
end
    
extension.callBackHandler["urlOpen"] = extension.iosUrlOpenHandle

--获得app版本号
extension.getAppVersion = function()
    local ok
    local version = ""

    if gt.isAndroidPlatform then
        ok, version = extension.luaBridge.callStaticMethod(APIClass, 'getAppVersion', nil, '()Ljava/lang/String;' )
    elseif gt.isIOSPlatform then
        ok, version = extension.luaBridge.callStaticMethod('AppController', 'getAppVersion')            
    end
    return version
end

--从剪切板获取文字
extension.getTextFromClipBoard = function()
    local ok
    local text = ""

    if gt.isAndroidPlatform then
        ok, text = extension.luaBridge.callStaticMethod(APIClass, 'getClipBoardContent', nil, '()Ljava/lang/String;')
    elseif gt.isIOSPlatform then
        ok, text = extension.luaBridge.callStaticMethod('AppController', 'getTextFromBoard')            
    end
    return text 
end

--打开微信
extension.openWechat = function ()
    if gt.isAndroidPlatform then
        extension.luaBridge.callStaticMethod(APIClass, 'openWechat', nil, '()V')
    elseif gt.isIOSPlatform then
        cc.Application:getInstance():openURL("wechat://")
    end 
end 

--从分享进房间
extension.getURLRoomID = function()
    local ok
    local roomid = ""

    if gt.isAndroidPlatform then
        ok, roomid = extension.luaBridge.callStaticMethod(APIClass, 'getRoomId', nil, '()Ljava/lang/String;')
    elseif gt.isIOSPlatform then
        ok, roomid = extension.luaBridge.callStaticMethod('AppController', 'getRoomId')            
    end
    return roomid
end

--从分享查看战绩
extension.getURLShareCode = function ()
    local ok
    local shareCode = ""

    if gt.isAndroidPlatform then
        ok, shareCode = extension.luaBridge.callStaticMethod(APIClass, 'getShareCode', nil, '()Ljava/lang/String;')
    elseif gt.isIOSPlatform then
        ok, shareCode = extension.luaBridge.callStaticMethod('AppController', 'getShareCode')     
    end
    return shareCode
end

--获取电池剩余容量
extension.get_Battery = function(call_back) 
    extension.callBackHandler[extension.getBattery] = call_back--注册回调函数
    local ok
    local ret = 100
    if gt.isAndroidPlatform then
        ok, ret = extension.luaBridge.callStaticMethod(APIClass, 'GetBattery', nil, '()V')
    elseif gt.isIOSPlatform then
        ok, ret = extension.luaBridge.callStaticMethod('nettools', 'getBatteryLeve')
        ret = ret * 100
    end
    return ret
end

--打开GPS设置
extension.GPSStart = function() 
    if gt.isAndroidPlatform then
        return extension.luaBridge.callStaticMethod(APIClass, 'gotoOpenGPS', nil, '()V')

    elseif gt.isIOSPlatform then
        return extension.luaBridge.callStaticMethod('AppController', 'GPSStart')
    end
end

--打开精准GPS设置
extension.DetailGPSStart = function() 
    if gt.isAndroidPlatform then
        return extension.luaBridge.callStaticMethod(APIClass, 'gotoOpenDetailGPS', nil, '()V')

    elseif gt.isIOSPlatform then
        return extension.luaBridge.callStaticMethod('AppController', 'DetailGPSStart')
    end
end

--判断GPS是否打开  待测试 暂不可使用
extension.isGPSStart = function() 
    if gt.isAndroidPlatform then
        return extension.luaBridge.callStaticMethod(APIClass, 'hasOpenGPS', nil, '()Z')
    elseif (gt.isIOSPlatform) then
        return extension.luaBridge.callStaticMethod('AppController', 'isGPSStart')
    end
end

-- 获取地理位置
extension.get_Location = function()
    if gt.location and string.len(gt.location) > 2 then
        print("已经获取到位置了")
        return
    end
    extension.callBackHandler[extension.getLocation] = extension._getLocationHandler--注册回调函数
    if gt.isAndroidPlatform then
        extension.luaBridge.callStaticMethod(APIClass, 'GetLocation', nil, '()V')
    elseif (gt.isIOSPlatform) then
        extension.luaBridge.callStaticMethod('locationtool', 'location')
    end
end

extension._getLocationHandler = function(data)
    local status = data.status
    if tonumber(status) == 1 then
        gt.location = data.code
        if gt.isIOSPlatform then
            local locationArr = string.split(gt.location,"#")
            local lat,lng = gt.convertGPS2GCJ(locationArr[1],locationArr[2])
            gt.location = string.format("%s#%s",lat,lng)
        end 
    else
        gt.location = ""
    end
end

--是否安装微信
extension.isInstallWeiXin = function()
    local ok
    local ret = false
    if gt.isIOSPlatform then
        ok, ret = extension.luaBridge.callStaticMethod("wxlogin", 'isWechatInstalled')
    elseif (gt.isAndroidPlatform) then
        ok, ret = extension.luaBridge.callStaticMethod(APIClass, 'checkInstallWeixin', nil, '()Z')
    end
    if ret == true or ret == 1 then
        return true
    end
    return false
end 

--分享图片
extension.shareToImage = function(shareTo, filePath)
    if not extension.isInstallWeiXin() then
        print("非微信登录无法分享")
        return 
    end

    if gt.isIOSPlatform then
        extension.luaBridge.callStaticMethod("wxlogin", "sendImageContent", {shareTo = shareTo, filePath = filePath})
    elseif (gt.isAndroidPlatform) then
        extension.luaBridge.callStaticMethod(APIClass, "weixinShareImg", {shareTo, filePath}, '(Ljava/lang/String;Ljava/lang/String;)V')
    end
end

--分享链接
extension.shareToURL = function(shareTo, title, message, url, call_back)
    if(not extension.isInstallWeiXin())then
        print("非微信登录无法邀请")
        return 
    end

    if gt.isIOSPlatform then
        extension.callBackHandler[extension.type_wxmessage] = call_back --注册回调函数
        extension.luaBridge.callStaticMethod("wxlogin", "sendLinkContent", {shareTo = shareTo, title = title, text = message, url = url})
    elseif (gt.isAndroidPlatform) then
        extension.callBackHandler[extension.type_wxshare] = call_back --注册回调函数
        extension.luaBridge.callStaticMethod(APIClass, "weixinShareApp", {shareTo, title, message, url},
            '(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V')
    end
end

--获取微信登陆token
extension.getWeixinToken = function(call_back) 
    if not call_back then
        print("error getWeixinToken need a call_back")
        return
    end
    extension.callBackHandler[extension.type_wxtoken] = call_back --注册回调函数
    print("-------->extension.getWeixinToken:"..gt.wxId)
    if gt.isAndroidPlatform then
        extension.luaBridge.callStaticMethod(APIClass, 'getWeixinToken', {gt.wxId}, '(Ljava/lang/String;)V')

    elseif (gt.isIOSPlatform) then
        extension.luaBridge.callStaticMethod('wxlogin','sendAuthReqForLoginWX',{wxid = gt.wxId})
    end
end


--获取手机号码
extension.getPhoneNumber = function() 
    if gt.isAndroidPlatform then
        local ok, tel = extension.luaBridge.callStaticMethod(APIClass, 'getPhoneNumber', nil, '()Ljava/lang/String;')
        return tel
    end 
    return ""
end

--录音初始化
extension.voiceInit = function(appid, istest) 
    if gt.isAndroidPlatform then
        extension.luaBridge.callStaticMethod(APIClass, 'voiceInit', {appid}, '(Ljava/lang/String;)V')

    elseif gt.isIOSPlatform then
        extension.luaBridge.callStaticMethod('yayavoice', 'voiceInit', {appid = appid, ifDebug = istest})
    end
end

--录音登录
extension.yayaLogin = function(uid, unick) 
    if(gt.isAndroidPlatform) then
        extension.luaBridge.callStaticMethod(APIClass, 'voiceLogin', {uid, unick}, '(Ljava/lang/String;Ljava/lang/String;)V')
    elseif (gt.isIOSPlatform) then
        extension.luaBridge.callStaticMethod('yayavoice', 'voiceLogin', {uid = uid, unick = unick})
    end
end

--开始录音
extension.voiceStart = function() 
    if gt.isAndroidPlatform then
        -- return extension.luaBridge.callStaticMethod(APIClass, 'voiceStart', nil, '()Z')
        --旧版本APK使用第三方封装的接口, 但是在android新的版本中会不兼容,导致崩溃,比如华为荣耀V10, 
        --新版本APK一律使用我们自己封装的接口
        local result 
        -- local appVer = cc.Application:getInstance():getVersion() 
        -- print("====appVer", appVer, appVer == "1.0.1")
        -- if appVer <= "1.0.1" then 
        --     result = extension.luaBridge.callStaticMethod(APIClass, 'voiceStart', nil, '()Z') 
        -- else 
            local fileName = cc.FileUtils:getInstance():getWritablePath() .. "amr_"..os.time() ..".amr"
            result = extension.luaBridge.callStaticMethod(APIClass, 'voiceStartEx', {fileName}, '(Ljava/lang/String;)Z')
        -- end 

        return result 

    elseif gt.isIOSPlatform then
        return extension.luaBridge.callStaticMethod('yayavoice', 'voiceStart')
    end
end

--停止录音
extension.voiceStop = function(call_back) 
    extension.callBackHandler[extension.voice_finish] = call_back --注册回调函数
    if gt.isAndroidPlatform then
        -- local appVer = cc.Application:getInstance():getVersion() 
        -- if appVer <= "1.0.1" then 
        --     extension.luaBridge.callStaticMethod(APIClass, 'voiceStop', nil, '()V') 
        -- else
            extension.luaBridge.callStaticMethod(APIClass, 'voiceStopEx', nil, '()V') 
        -- end 

    elseif gt.isIOSPlatform then
        extension.luaBridge.callStaticMethod('yayavoice', 'voiceStop')
    end
end

--上传录音
extension.voiceupload = function(call_back, path, time)
    print("--------voiceupload path", path)
    extension.callBackHandler[extension.voice_get_url] = call_back --注册回调函数
    if gt.isAndroidPlatform then
        extension.luaBridge.callStaticMethod(APIClass,'voiceupload',{path, time},'(Ljava/lang/String;Ljava/lang/String;)V') 

    elseif gt.isIOSPlatform then
        extension.luaBridge.callStaticMethod('yayavoice', 'voiceupload', {path = path, time = time})
    end
end

--播放录音: 新版本必须使用自己封装的接口播放,如果用第三方接口播放也会导致死机
extension.voicePlay = function(call_back, url)
    extension.callBackHandler[extension.voice_finish_play] = call_back --注册回调函数
    if gt.isAndroidPlatform then
        -- local appVer = cc.Application:getInstance():getVersion() 
        -- if appVer <= "1.0.1" then 
        --     extension.luaBridge.callStaticMethod(APIClass,'voicePlay',{url},'(Ljava/lang/String;)V')
        -- else 
            extension.luaBridge.callStaticMethod(APIClass,'voicePlayEx',{url},'(Ljava/lang/String;)V')
        -- end 

    elseif gt.isIOSPlatform then
        extension.luaBridge.callStaticMethod('yayavoice', 'voicePlay', {url = url})
    end 
end 

--录音退出
extension.yayaLoginOut = function()
    if gt.isAndroidPlatform then
        extension.luaBridge.callStaticMethod(APIClass, 'yayaLoginOut', nil, '()V')

    elseif gt.isIOSPlatform then
        extension.luaBridge.callStaticMethod('yayavoice', 'yayaLoginOut')
    end
end

-- 网络是否可用
extension.isNetworkAvailable = function()
    local ok
    local ret = true
    if gt.isAndroidPlatform then
        ok, ret = extension.luaBridge.callStaticMethod(APIClass, 'isNetworkAvailable', nil, '()Z') 

    elseif (gt.isIOSPlatform) then
        ok, ret = extension.luaBridge.callStaticMethod('nettools', 'checkNetState') 
    end
    game.networkAvailable = ret
    return ret
end

--下载Apk
extension.downLoadApk = function(call_back, url, writablePath)
    print("--------down load apk url：" .. url)
    extension.callBackHandler[extension.downloadDown] = call_back --注册回调函数
    if gt.isAndroidPlatform then
        extension.luaBridge.callStaticMethod(APIClass, 'downloadApk', {url, writablePath}, '(Ljava/lang/String;Ljava/lang/String;)V')
    elseif gt.isIOSPlatform then               
    end
end

-- 支付
extension.pay = function(_type, orderInfo)
    extension.orderInfo = orderInfo
    if _type == extension.PAY_TYPE_ALI then
        if gt.isAndroidPlatform then
            extension.AndroidAlipay(orderInfo)
        end

    elseif _type == extension.PAY_TYPE_WEIXIN then
        if extension.isInstallWeiXin() then
            if gt.isAndroidPlatform then
                extension.AndroidWXPay(orderInfo)
            end
        else
            print("未安装微信")
        end
    elseif _type == extension.PAY_TYPE_APPLE then
        extension.IosPay(orderInfo)
    end
end

-- 安卓微信支付
extension.AndroidWXPay = function(orderInfo)
    local function payHandler(jsonData)
        local status = jsonData.status
        if status == 1 then
            print("微信支付成功")
        else
            print("微信支付取消 errorCode", jsonData.code)
        end
    end
    extension.callBackHandler[extension.type_weixin_pay] = payHandler
    print("call AndroidWXPay", orderInfo)
    extension.luaBridge.callStaticMethod('org/extension/ExtensionApi', 'weixinPay', {tostring(orderInfo)}, '(Ljava/lang/String;)V')
end

-- 安卓支付宝支付
extension.AndroidAlipay = function(orderInfo)
    local function payHandler(jsonData)
        local status = jsonData.status
        if status == 1 then
            print("支付宝支付成功")
        else
            print("支付宝支付取消")
        end
    end
    extension.callBackHandler[extension.type_ali_pay] = payHandler
    extension.luaBridge.callStaticMethod('org/extension/ExtensionApi', 'alipay', {tostring(orderInfo)}, '(Ljava/lang/String;)V')
end

-- IOS支付
extension.IOSPay = function(orderInfo)
    local function payHandler(jsonData) 
        local status = jsonData.status
        if status == 1 then
            print("IOS 支付成功")
        else
            print("IOS 支付取消")
        end
    end
    extension.callBackHandler[extension.type_appstore_pay] = payHandler
    extension.luaBridge.callStaticMethod('iospay', 'makePurchase', {identifier = 'com.you9.klqp.dn'..orderInfo})
end

--复制到粘贴板
extension.CopyTextToClipboard = function(str)
    if gt.isAndroidPlatform then
        print("extension.CopyTextToClipboard android:"..str)
        extension.luaBridge.callStaticMethod(APIClass, 'copyTextToClipboard', {str}, '(Ljava/lang/String;)V')
    elseif gt.isIOSPlatform then
        extension.luaBridge.callStaticMethod('AppController', 'copyTextToClipboard', {text = str})          
    end
end

--设置横屏竖屏
extension.SetOrientation = function(orientation) 
    if orientation == 1 and CC_DESIGN_RESOLUTION.width >= CC_DESIGN_RESOLUTION.height then --已经是横屏时
        print("============== current scene orientation is already landscape")
        return 
    end 
    if orientation == 2 and CC_DESIGN_RESOLUTION.width <= CC_DESIGN_RESOLUTION.height then --已经是竖屏时
        print("============== current scene orientation is already portrait")
        return 
    end 

    local ok, ret 
    if gt.isAndroidPlatform then 
        ok, ret = extension.luaBridge.callStaticMethod(APIClass, 'setOrientation', {orientation}, '(I)I') 
    else
        local str = orientation == 1 and "landscape" or "portrait"
        ok, ret = extension.luaBridge.callStaticMethod('AppController', 'setOrientation', {strOrien = str})
    end 
    print("--------ok, ret", ok, ret)
    if ok and ret == 0 then 
        local view = cc.Director:getInstance():getOpenGLView() 
        local frameSize = view:getFrameSize() 
        local frame_w, frame_h 
        local preDesignSize = cc.size(CC_DESIGN_RESOLUTION.width, CC_DESIGN_RESOLUTION.height) 
        if orientation == 1 then --横屏
            frame_w  = math.max(frameSize.width, frameSize.height) 
            frame_h  = math.min(frameSize.width, frameSize.height) 
            CC_DESIGN_RESOLUTION.width = math.max(preDesignSize.width, preDesignSize.height) 
            CC_DESIGN_RESOLUTION.height = math.min(preDesignSize.width, preDesignSize.height) 
        else --竖屏
            frame_w  = math.min(frameSize.width, frameSize.height) 
            frame_h  = math.max(frameSize.width, frameSize.height) 
            CC_DESIGN_RESOLUTION.width = math.min(preDesignSize.width, preDesignSize.height) 
            CC_DESIGN_RESOLUTION.height = math.max(preDesignSize.width, preDesignSize.height) 
        end 
        -- print("=========old, new frame size", frameSize.width, frameSize.height, frame_w, frame_h)
        view:setFrameSize(frame_w, frame_h)
        view:setDesignResolutionSize(CC_DESIGN_RESOLUTION.width, CC_DESIGN_RESOLUTION.height, cc.ResolutionPolicy.NO_BORDER)

        -- --重加载 display.lua 
        package.loaded["cocos.framework.display"] = nil
        display = require("cocos.framework.display")
    end 
    
    return ok, ret 
end 
