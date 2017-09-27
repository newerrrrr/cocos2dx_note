
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
