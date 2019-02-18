local NetTcp = class("NetTcp")
require("socket")

local bit = require("app/libs/bit")

local gt = cc.exports.gt

local HEADER_LEN    = 15      --数据包头结构为: "HLBMJ"[5B] .. cmd[4B] .. time[4B] .. bodyLen[2B] 
local HEADER_PREFIX = "HLBMJ" --数据包头标识

function NetTcp:ctor()
    --加载消息打包库
    local msgPackLib = require("app/libs/MessagePack")
    msgPackLib.set_number("integer")
    msgPackLib.set_string("string")
    msgPackLib.set_array("without_hole")
    self.msgPackLib = msgPackLib 
    
    self.connectTimeout    = 8.0
    self.heartBeatTimeout  = 8.0
    self.heartBeatInterval = 5.0
    self.retryConnectCount = 0  
    self.retrySendCount    = 0 --重发消息次数
    self.sendQueue         = {} --发送队列
    self.msgCallback       = {} --消息回调容器

    self:registerMsgListener(gt.HEARTBEAT, self, self.onRcvHeartbeat)

    -- self:resetHearBeat() 
    -- self:openHeartBeat(true) 
end 

function NetTcp:connect(host, port, callback) 
    print("======= connect: ip, port", host, port) 

    if not host or not port then 
        print("[NetTcp:connect]: null host or port !!") 
        return 
    end 

    local function onSocketOpen() 
        self.isConnected = true 
        if callback then callback(true) end 
    end 

    --接收到的数据, data 为 table 格式
    local function onSocketReceive(data) 
        local unpackData = string.char(unpack(data)) 
        local pkgSize = #unpackData 
        local bodyFrom = 1 

        --1. 提取包头; 数据包头结构为: "HLBMJ"[5B] .. cmd[4B] .. time[4B] .. bodyLen[2B] 
        if pkgSize >= HEADER_LEN then 
            if nil ~= string.find(unpackData, HEADER_PREFIX) then --新的数据包
                self.msgId = self:toLuaInt(unpackData, 6) 
                self.remainRcvLen = string.byte(unpackData, 14)*256 + string.byte(unpackData, 15) 
                self.recvingBuffer = ""
                bodyFrom = HEADER_LEN + 1 
            end 
        end 

        --2.提取包体
        if bodyFrom <= pkgSize then 
            local content      = string.sub(unpackData, bodyFrom) 
            self.recvingBuffer = self.recvingBuffer .. content
            self.remainRcvLen  = self.remainRcvLen - #content 
            
            if self.remainRcvLen <= 0 then 
                local messageData = self.msgPackLib.unpack(self.recvingBuffer)  
                --reset 
                self.remainRcvLen  = 0 
                self.recvingBuffer = "" 
                self.pingTime      = socket.gettime() - self.preSendTime 
                --dispatch
                self:dispatchMessage(self.msgId, messageData) 
            end 
        end 
    end 

    local function onSocketClose() 
        print("====onSocketClose") 
        self.socket = nil 
        self:close() 
    end 

    local function onSocketError(data)  
        if not self.isConnected then --连接失败
            require("app.views.msgbox.NoticeTips"):create("连接超时,尝试重新连接服务器！", function()
                self:reconnect()
            end, nil, true)       
        end 
    end 

    self.host = host
    self.port = port
    self.remainRcvLen  = 0 
    self.recvingBuffer = "" 

    self.socket = cc.WebSocket:create("ws://echo.websocket.org") 
    if nil ~= self.socket then 
        self.socket:registerScriptHandler(onSocketOpen, cc.WEBSOCKET_OPEN)
        self.socket:registerScriptHandler(onSocketReceive, cc.WEBSOCKET_MESSAGE)
        self.socket:registerScriptHandler(onSocketClose, cc.WEBSOCKET_CLOSE)
        self.socket:registerScriptHandler(onSocketError, cc.WEBSOCKET_ERROR)
    end 
end 

--发送数据; msgTbl: 待发送的内容, 可以是table数组也可以是字符串
function NetTcp:sendMessage(cmd, msgTbl) 
    if not self.isConnected then return end
    if nil == self.socket then return end 
    if self.socket:getReadyState() ~= cc.WEBSOCKET_STATE_OPEN then 
        print("=== websocket wasn't ready !!!")
        return 
    end 
    
    if cmd ~= gt.HEARTBEAT then 
        print("=== sendMessage..., msgid =", cmd) 
        gt.dump(msgTbl) 
    end 

    -- 打包成messagepack格式
    local msgPackData = self.msgPackLib.pack(msgTbl)
    local msgLength   = string.len(msgPackData)
    local prefix      = "HLBMJ" --5B
    local cmd         = self:luaToCByInt(cmd) --4B
    local time        = self:luaToCByInt(os.time()) --4B
    local len         = self:luaToCByShort(msgLength) --2B
    local msgToSend   = prefix .. cmd .. time .. len .. msgPackData 

    self.socket:sendString(msgToSend) --发送二进制数据 
    self.preSendTime = socket.gettime() --用于计算网络延迟, 推算出WIFI信号强度
end 

function NetTcp:close() 
    if nil ~= self.socket then 
        self.socket:close() 
        self.socket = nil
    end 
    
    self.isConnected = false 
    self:resetHearBeat() 
end 

function NetTcp:reconnect(callback) 
    self:close() 
    self:connect(self.host, self.port, function(result)
        if result then 
            gt.dispatchEvent( gt.EventType.RELOGIN ) 
        end 
        if callback then callback(result) end  
    end) 
end 

------------------------------------ heart beat---------------------------------
function NetTcp:openHeartBeat(isEnabled) 
    if nil ~= self.timer then 
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.timer) 
        self.timer = nil 
    end 
    if isEnabled then 
        self.timer = cc.Director:getInstance():getScheduler():scheduleScriptFunc(handler(self, self.checkHeartBeat), 1.0, false) 
    end 
end 

function NetTcp:sendHeartbeat() 
    -- print("================= send heart beat...") 
    self:sendMessage(gt.HEARTBEAT, {}) 
end 

function NetTcp:onRcvHeartbeat(msgTbl) 
    -- print(">>>>>>>>>>>>>>>>> rcv heart beat...") 
    self:resetHearBeat() 
end 

function NetTcp:checkHeartBeat(dt) 
    if not self.isConnected then return end 
    if not self.isLogined then return end 

    --5秒周期发送心跳包
    self.heartBeatCD = self.heartBeatCD - dt 
    if self.heartBeatCD <= 0 then 
        self:sendHeartbeat() 
        self.heartBeatCD = self.heartBeatInterval 
    end 

    self.heartBeatLeftTime = self.heartBeatLeftTime - dt 
    if self.heartBeatLeftTime < 0 then --超时重连 
        print("@@@ Heartbeat timeout")
        self:reconnect()
    end 
end 

function NetTcp:resetHearBeat() 
    self.heartBeatCD       = self.heartBeatInterval 
    self.heartBeatLeftTime = self.heartBeatInterval + self.heartBeatTimeout 
end 


--------------------------------- 消息注册管理 ----------------------------------
--绑定消息回调
function NetTcp:registerMsgListener(msgId, msgTarget, msgFunc) 
    if nil == self.msgCallback[msgId] then self.msgCallback[msgId] = {} end 

    --如果已注册则返回
    for k, v in pairs(self.msgCallback[msgId]) do 
        if v.target == msgTarget and v.func == msgFunc then 
            return 
        end 
    end 
    table.insert(self.msgCallback[msgId], {target = msgTarget, func = msgFunc})
end 

--注销指定对象target的msgId消息回调
function NetTcp:unregisterMsgListener(msgId, target)
    local cbs = self.msgCallback[msgId]
    if cbs then 
        for k, v in pairs(cbs) do 
            if v.target == target then 
                cbs[k] = nil 
            end
        end 

        --如果该消息无任何回调则清空
        if table.nums(cbs) == 0 then 
            self.msgCallback[msgId] = nil 
        end  
    end  
end 

--注销指定对象target的所有消息回调
function NetTcp:unregisterAllMsgListener(target)
    if nil == target then return end 

    for id, cbs in pairs(self.msgCallback) do 
        local found = false 
        for k, v in pairs(cbs) do 
            if v.target == target then 
                cbs[k] = nil 
                found = true 
            end 
        end 

        --如果该消息无任何回调则清空
        if found and table.nums(cbs) == 0 then 
            self.msgCallback[id] = nil 
        end 
    end 
end 

function NetTcp:dispatchMessage(msgId, msgTbl) 
    local t = self.msgCallback[msgId] 
    if t then 
        if msgId ~= gt.HEARTBEAT then 
            print("@@@ dispatch msg:", msgId) 
        end 
        for k, v in pairs(t) do 
            v.func(v.target, msgTbl) 
        end 
    else 
        print("@@@ could not handle message: " .. msgId)
    end 
end 

----------------------------------- tools ------------------------------------
function NetTcp:luaToCByShort(value)
    return string.char(math.floor(value / 256)) .. string.char(value % 256) 
end

--大端
function NetTcp:luaToCByInt(value)
    local lowByte1 = string.char(math.floor(value / (256 * 256 * 256)))
    local lowByte2 = string.char(math.floor(value / (256 * 256)) % 256)
    local lowByte3 = string.char(math.floor(value / 256) % 256)
    local lowByte4 = string.char(value % 256)
    return lowByte4 .. lowByte3 .. lowByte2 .. lowByte1
end

function NetTcp:toLuaInt(buff, from) 
    local len = string.byte(buff, from) + string.byte(buff, from+1)*256 
              + string.byte(buff, from+2)*256*256 + string.byte(buff, from+3)*256*256*256 
    return len 
end 

function NetTcp:getCheckSum(time, msgLength, msgPackData)
    local crc = ""
    local len = string.len(time) + msgLength
    if len < 16 then
        crc = bit:DataCRC(time .. msgPackData, len)
    else
        crc = bit:DataCRC(time .. msgPackData, 16)
    end
    return self:luaToCByShort(crc)
end

---------------------------------- export -----------------------------------
function NetTcp:setIsLogined(isLogined)
    self.isLogined = isLogined 
end 

function NetTcp:getPingTime()
    return self.pingTime or 5 
end 

return NetTcp 