
--使用举例:
--1)在开头的地方打开log写文件
-- hlb_print = require("src.resUpdate.LogToFile").print
-- hlb_print("test log to file...")
  
--2)在适当的地方调用如下来关闭log文件,否则log缓存有可能未flush到文件
-- require("src.resUpdate.LogToFile").closeFile()




local LogToFile = {}
setmetatable(LogToFile,{__index = _G})
setfenv(1, LogToFile)

local logFile
local logBuf = ""
local count = 0 

function print(...)
  local arr = {}
  for i, a in ipairs({...}) do
    arr[#arr + 1] = tostring(a)
  end


  if nil == logFile then 
    logFile = io.open(cc.FileUtils:getInstance():getWritablePath().."ResUpdate/hlb_log.tt", "w+")
  end 

  logBuf = logBuf .. table.concat(arr, "\t").."\n"
  count = count + 1 
  if logFile and count > 0 then 
      logFile:write(logBuf)
      logFile:flush()
      -- logFile:close()
      logBuf = ""
      count = 0 
  end 
end 

function closeFile()
  if logFile then 
    io.close(logFile)
    logFile = nil 
  end 
end 

return LogToFile 
