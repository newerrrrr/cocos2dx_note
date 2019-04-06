
--使用举例:
--1)在开头的地方打开log写文件
-- hlb_print = require("src.resUpdate.LogToFile").print
-- hlb_print("test log to file...")
  
--2)在适当的地方调用如下来关闭log文件,否则log缓存有可能未flush到文件
-- require("src.resUpdate.LogToFile").closeFile()



-- IOS release版本是无法看到log的,所以可以将log写文件, 步骤如下:
-- a) 准备一台7.x版本(或者越狱过的更高版本)的 iphone或pad;
-- b) 电脑上安装有pp助手, ios设备连接到电脑后可以在pp助手应用列表中看该应用的缓存
-- c) 拿一份本地MD5列表文件,修改自动更新模块md5信息,确保与服务器一致,使得自动更新模块不会更新覆盖自己;
-- d) 修改本地自动更新模块代码,开启log写文件
-- e) 将修改后的自动更新代码和md5列表导入到ios设备的对应缓存中
-- f) 执行程序开始更新,结束后导出手机缓存中对应的log文件即可.

--Android设备可以直接用 release_print 代替 print 函数来输出log, 在eclipse直接查看



local M = {}
setmetatable(M,{__index = _G})
setfenv(1, M)

local logFile 
local total     = 0 
local totalMax  = 100000 
local fileIndex = 0 

function print(...)
    release_print(...)

    if nil == logFile then 
        fileIndex = fileIndex + 1 
        if fileIndex > 2 then fileIndex = 1 end 
        logFile = io.open(cc.FileUtils:getInstance():getWritablePath().."log.bin" .. fileIndex, "w+")
        total = 0 
    end 

    if logFile then 
        local s = os.date("[%H:%M:%S]", os.time())
        for i, a in ipairs({...}) do
            s = s.. "\t" .. tostring(a)
        end
        logFile:write(s .. "\n")
        logFile:flush() 

        total = total + 1 
        if total > totalMax then 
            io.close(logFile) 
            logFile = nil 
        end   
    end 
end 

function dump(value, description, nesting)
    if type(nesting) ~= "number" then nesting = 3 end

    local lookupTable = {}
    local result = {}

    local traceback = string.split(debug.traceback("", 2), "\n")
    print("dump from: " .. string.trim(traceback[3]))

    local function dump_(value, description, indent, nest, keylen)
        description = description or "<var>"
        local spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(dump_value_(description)))
        end
        if type(value) ~= "table" then
            result[#result +1 ] = string.format("%s%s%s = %s", indent, dump_value_(description), spc, dump_value_(value))
        elseif lookupTable[tostring(value)] then
            result[#result +1 ] = string.format("%s%s%s = *REF*", indent, dump_value_(description), spc)
        else
            lookupTable[tostring(value)] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, dump_value_(description))
            else
                result[#result +1 ] = string.format("%s%s = {", indent, dump_value_(description))
                local indent2 = indent.."    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = dump_value_(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    dump_(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result +1] = string.format("%s}", indent)
            end
        end
    end
    dump_(value, description, "- ", 1)

    for i, line in ipairs(result) do
        print(line)
    end
end



function closeFile()
    if logFile then 
        io.close(logFile)
        logFile = nil 
    end 
end 

return M 
