
-- require "src.cocos.init"

-- 自动更新入口:根据大版本号确定缓存路径, 保证新客户端有一个干净的缓存目录;
--              防止强更时删除缓存失败,或者覆盖安装新客户端(缓存不会自动清除), 
--              结果使得新客户端访问旧的缓存数据,可能会导致程序崩溃。

--  流程: 启动客户端后执行本地的 UpdateEntry.lua , 如果是在程序中重登陆则优先执行
--        缓存中的 UpdateEntry.lua

local __G__TRACKBACK__ = function(msg)
  local msg = debug.traceback(msg, 3)
  release_print(msg)
  return msg
end


local _fileUtils = cc.FileUtils:getInstance()

local function stringSplit(input, delimiter)
  input = tostring(input)
  delimiter = tostring(delimiter)
  if (delimiter=='') then return false end
  local pos,arr = 0, {}
  -- for each divider found
  for st,sp in function() return string.find(input, delimiter, pos, true) end do
    table.insert(arr, string.sub(input, pos, st - 1))
    pos = sp + 1
  end
  table.insert(arr, string.sub(input, pos))
  return arr
end 

local function getStoragePath()
  local storagePath 

  --如果老版本则使用固定的缓存路径
  if nil == ResUpdateEx.batchDownloadFileAsync then 
    storagePath = _fileUtils:getWritablePath().."ResUpdate/"
    return storagePath 
  end 

  --读取本地MD5列表获取大版本号
  local bigVer = ""
  local localPath = _fileUtils:getDefaultResourceRootPath() --注意IOS平台该路径为空字串!!
  local content = _fileUtils:getStringFromFile(localPath.."project.manifest")
  if content ~= "" then 
    --如果utf8包含3个bom字节,则先去掉bom,否则会导致json解码失败
    if string.byte(content, 1) == 0xef and string.byte(content, 2) == 0xbb and string.byte(content, 3) == 0xbf then
      local pos = string.find(content, "{")
      if pos then 
        content = string.sub(content, pos) 
      end 
    end 
    local local_manifest = cjson.decode(content)
    if local_manifest then 
      local s = stringSplit(local_manifest.version, ".")
      bigVer = "_"..s[1].."_"..s[2]
    end 
  end  

  storagePath = _fileUtils:getWritablePath().."ResUpdate"..bigVer.."/"
  return storagePath 
end 

local function addSearchPath(path)
  --remove before add
  local searchPaths = _fileUtils:getSearchPaths()
  local tmp = {}
  for k, v in pairs(searchPaths) do 
    if v ~= path then 
      table.insert(tmp, v)
    end 
  end 
  table.insert(tmp, 1, path) -- add front 
  _fileUtils:setSearchPaths(tmp)
end 



local function entry()
  release_print("@@@ update entry ")

  --将缓存目录加入到搜索路径中, 因此后面调用的lua文件保证是最新的
  local storagePath = getStoragePath() 
  addSearchPath(storagePath)
  release_print("storagePath =", storagePath)

  --打开更新界面
  local scene = cc.Scene:create() 
  local layer = require("src.resUpdate.UpdateLayer"):create(storagePath)
  scene:addChild(layer)
  local director = cc.Director:getInstance()
  if director:getRunningScene() then 
    director:replaceScene(scene)
  else 
    director:runWithScene(scene)
  end 
end 


xpcall(entry, __G__TRACKBACK__)
