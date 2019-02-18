
require("socket")
local bit = require("app/libs/bit")

local NetTcp = class("NetTcp")


local NetEvent = {
    SocketError = "Evt_SocketError",
    ConnectFail = "Evt_ConnectFail",
}

local gt = cc.exports.gt
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
    -- self.recvQueue      = {} --接收队列
    self.msgCallback       = {} --消息回调容器

    self:resetRecvBuff() 
    self:resetHearBeat() 
    self:registerMsgListener(gt.HEARTBEAT, self, self.onRcvHeartbeat)
    cc.Director:getInstance():getScheduler():scheduleScriptFunc(handler(self, self.update), 0, false) 
end 

function NetTcp:connect(host, port, callback)
    if not host or not port then 
        if callback then callback(false) end 
        return false
    end
    self.host = host
    self.port = port

    print("======= connect: ip, port", self.host, self.port)

    -- tcp 协议 socket
    local tcp, errorInfo = self:getTcp(host)
    if not tcp then
        print(string.format("Connect failed when creating socket | %s", errorInfo))
        if callback then callback(false) end 
        self:onSocketError(NetEvent.SocketError) 
        return false
    end

    self:stopConnectTimer()
    self.targetTime = os.time() + self.connectTimeout 

    --创建socket
    self.socket = tcp
    tcp:setoption("tcp-nodelay", true) 
    tcp:settimeout(0) --非堵塞 

    --开始连接检测
    local code, status = tcp:connect(self.host, self.port)
    if code == 1 or status == "already connected" then
        print("Socket connect success!")
        self.isConnected = true 
        if callback then callback(true) end 
    else
        --轮询连接状态
        self.timerConnect = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function()
            local code, status = tcp:connect(self.host, self.port)
            if code == 1 or status == "already connected" then 
                print("Socket async connect success!")
                self.isConnected = true
                self:stopConnectTimer()
                if callback then callback(true) end 

            elseif os.time() >= self.targetTime then 
                print("Socket connect timeout ...") 
                self:stopConnectTimer() 
                self:onSocketError(NetEvent.ConnectFail) 
                if callback then callback(false) end 
            end 
        end, 0.1, false) 
    end 

    return true
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

function NetTcp:close()
    self:stopConnectTimer() 

    if self.socket then
        self.socket:close()
    end
    self.socket = nil
    self.isConnected = false 
    self:resetRecvBuff() 
    self:resetHearBeat() 
end 

function NetTcp:sendMessage(cmd, msgTbl) 
    if cmd ~= gt.HEARTBEAT then 
        print("=== sendMessage...", cmd)
        gt.dump(msgTbl) 
    end 

    -- 打包成messagepack格式
    local msgPackData = self.msgPackLib.pack(msgTbl)
    local msgLength   = string.len(msgPackData)
    local len         = self:luaToCByShort(msgLength)
    local time        = self:luaToCByInt(os.time())
    local cmd         = self:luaToCByInt(cmd)
    -- local checksum    = self:getCheckSum(time .. msgTbl.cmd, msgLength, msgPackData)
    -- local msgToSend   = len .. checksum .. time .. msgPackData
    local msgToSend   = len .. time ..cmd .. msgPackData
    -- 放入到消息缓冲
    table.insert(self.sendQueue, msgToSend) 
end 

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

-------------------------------------------private--------------------------------------
function NetTcp:update(dt) 
    if not self.isConnected then return end

    self:send() 
    self:receive() 
    self:checkHeartBeat(dt) 
end 

function NetTcp:send() 
    --send from queue
    if #self.sendQueue > 0 then 
        local size, errorInfo = self.socket:send(self.sendQueue[1])
        if size then
            table.remove(self.sendQueue, 1)
            self.preSendTime = socket.gettime()
        else
            self.retrySendCount = self.retrySendCount + 1 
            if self.retrySendCount > 3 then 
                -- print("@@@ socket send failed:", errorInfo) 
                self:onSocketError(NetEvent.SocketError)
            end 
        end 
    end 
end 

function NetTcp:receive() 
    if self.remainRecvSize <= 0 then return end 

    local recvContent, errorInfo, otherContent = self.socket:receive(self.remainRecvSize)
    
    --1.处理出错信息
    if nil ~= errorInfo then
        if errorInfo == "timeout" then --由于timeout为0并且为异步socket，不能认为socket出错
            if nil ~= otherContent and #otherContent > 0 then
                self.recvingBuffer = self.recvingBuffer .. otherContent
                self.remainRecvSize = self.remainRecvSize - #otherContent
                print("@@@ recv timeout, but had other content. size:", #otherContent)
            end            
        else
            if errorInfo ~= "closed" then
                -- print("@@@ Recv failed errorInfo:" .. errorInfo) 
                self:onSocketError(NetEvent.SocketError)
            end 
        end 
        return 
    end 
    
    --2.正常接收到数据
    local contentSize = #recvContent
    self.recvingBuffer = self.recvingBuffer .. recvContent
    self.remainRecvSize = self.remainRecvSize - #recvContent

    --如果未接收完指定长度数据, 则下帧继续接收
    if self.remainRecvSize > 0 then 
        return
    end 
    
    --3.接收完指定数据
    if self.recvState == "Head" then
        self.remainRecvSize = string.byte(self.recvingBuffer, 1)*256 + string.byte(self.recvingBuffer, 2)
        self.msgId = self:toLuaInt(self.recvingBuffer, 7) 
        self.recvingBuffer = ""
        self.recvState = "Body"

        return self:receive() --继续接收包体

    elseif self.recvState == "Body" then --接收完整包之后, 立即派发
        local messageData = self.msgPackLib.unpack(self.recvingBuffer)  
        -- table.insert(self.recvQueue, messageData) 
        self:dispatchMessage(self.msgId, messageData) 
        self:resetRecvBuff() 
        self.pingTime = socket.gettime() - self.preSendTime 
    end

    --继续接数据包
    --如果有大量网络包发送给客户端可能会有掉帧现象, 但目前不需要考虑, 解决方案可以1.设定总接收时间; 2.收完body包就不在继续接收了
    -- return self:receive() 
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

function NetTcp:resetRecvBuff()
    self.remainRecvSize = 10 --头信息数据结构为: len[2B] .. time[4B] ..cmd[4B]
    self.recvingBuffer  = ""
    self.recvState      = "Head" 
end 

function NetTcp:getTcp(host)
    local isipv6_only = false
    local addrinfo, err = socket.dns.getaddrinfo(host);
    if addrinfo then
        for i, v in ipairs(addrinfo) do
            if v.family == "inet6" then
                isipv6_only = true;
                break
            end
        end
    end
    print("isipv6_only", isipv6_only)
    if isipv6_only then
        return socket.tcp6()
    else
        return socket.tcp()
    end
end

function NetTcp:stopConnectTimer() 
    if self.timerConnect then 
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.timerConnect) 
        self.timerConnect = nil 
    end 
end 

function NetTcp:onSocketError(event)
    -- print("@@@ onSocketError: event =", event)
    if event == NetEvent.SocketError then 
        -- require("app.views.msgbox.NoticeTips"):create("网络错误，请检查网络！", function()
        --     self:reconnect()
        -- end, nil, true)

    elseif event == NetEvent.ConnectFail then 
        require("app.views.msgbox.NoticeTips"):create("连接超时,尝试重新连接服务器！", function()
            self:reconnect()
        end, nil, true)
    end 
end 

-------------------------------------------heart beat--------------------------------------
function NetTcp:enableHeartBeat(isEnabled)
    self.isHeartBeatEnabled = isEnabled 
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
    -- if not self.isHeartBeatEnabled then return end 

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

-------------------------------------------tools----------------------------------------
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

-------------------------------------------export----------------------------------------
function NetTcp:setIsLogined(isLogined)
    self.isLogined = isLogined 
end 

function NetTcp:getPingTime()
    return self.pingTime or 5 
end 

return NetTcp 
