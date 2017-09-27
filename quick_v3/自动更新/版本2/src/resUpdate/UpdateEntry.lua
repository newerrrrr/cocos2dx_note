
-- require "src.cocos.init"


local __G__TRACKBACK__ = function(msg)
  local msg = debug.traceback(msg, 3)
  print(msg)
  return msg
end


local _fileUtils = cc.FileUtils:getInstance()


local function addSearchPath(path)
  local searchPaths = _fileUtils:getSearchPaths() 
  for k, v in pairs(searchPaths) do 
    if v == path then 
      return  
    end 
  end 
  _fileUtils:addSearchPath(path, true)
end 



local function entry()
  print("@@@ update entry ")

  --搜索路径(自动更新的缓存路径已在AppDelegate.cpp里设置过,所以能保证这里调用的是最新的lua文件)
  require("src.resUpdate.UpdateMgr"):initSearchPath()

  local scene = cc.Scene:create() 
  local layer = require("src.resUpdate.UpdateLayer"):create()
  scene:addChild(layer)
  local director = cc.Director:getInstance()
  if director:getRunningScene() then 
    director:replaceScene(scene)
  else 
    director:runWithScene(scene)
  end 
end 


xpcall(entry, __G__TRACKBACK__)
