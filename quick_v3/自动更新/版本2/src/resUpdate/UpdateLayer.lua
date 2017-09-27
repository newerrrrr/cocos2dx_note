

local UpdateLayer = {}
setmetatable(UpdateLayer,{__index = _G})
setfenv(1, UpdateLayer)



local lang = require("src.resUpdate.Lang")
local UpdateMgr = require("src.resUpdate.UpdateMgr")
local rootLayer, uiLayer 

function create()
  rootLayer = cc.Layer:create()

  local function rootLayerEventHandler(eventType) 
    if eventType == "enter" then 
      onEnter() 
    elseif eventType == "exit" then 
      onExit() 
    end 
  end 
  rootLayer:registerScriptHandler(rootLayerEventHandler)


  --设计大小
  local director = cc.Director:getInstance()
  local view = director:getOpenGLView()
  if not view then
    view = cc.GLViewImpl:createWithRect("sanguo_mobile2", cc.rect(0, 0, 1280, 720))
    director:setOpenGLView(view)
  end
  view:setDesignResolutionSize(1280, 720, 1) --cc.ResolutionPolicy.NO_BORDER

  --显示logo背景图, 防止进入时有几秒钟的黑屏
  local _fileUtils = cc.FileUtils:getInstance()
  local filename = "res/cocos/cocostudio_res/login/bj.jpg"
  if _fileUtils:isFileExist(filename) then 
    local pic = ccui.ImageView:create(filename) 
    if pic then       
      pic:setAnchorPoint({ x = 0.5, y = 0.5 }) --(cc.p(0.5, 0.5))
      -- pic:setScale(director:getVisibleSize().width/1280)
      pic:setPosition({ x = director:getWinSize().width/2, y = director:getWinSize().height/2 })--cc.p(director:getWinSize().width/2, director:getWinSize().height/2))
      rootLayer:addChild(pic)
    end 
  end 

  return rootLayer 
end 


function onEnter()
  print("@@@ UpdateLayer:onEnter")
  initUI()

  UpdateMgr:start(UpdateLayer) 
end 

function onExit()
  print("@@@ UpdateLayer:onExit")
  UpdateMgr:exit()
end 

--初始化UI
function initUI()
  if nil == uiLayer then 
    local director = cc.Director:getInstance()
    
    --需要访问本地资源, 所以这里备份下搜索路径, 加载完后立刻恢复
    local searchPaths = cc.FileUtils:getInstance():getSearchPaths() 
    cc.FileUtils:getInstance():addSearchPath("res/cocos/")

    uiLayer =  cc.CSLoader:createNode("resource_update.csb")
    if uiLayer then 
      uiLayer:setAnchorPoint({ x = 0.5, y = 0.5 }) --(cc.p(0.5, 0.5))
      uiLayer:getChildByName("scale_node"):setScale(director:getVisibleSize().width/1280)
      uiLayer:setPosition({ x = director:getWinSize().width/2, y = director:getWinSize().height/2 })--cc.p(director:getWinSize().width/2, director:getWinSize().height/2))
      rootLayer:addChild(uiLayer)
      --default 
      uiLayer:setVisible(false) 
    end 

    cc.FileUtils:getInstance():setSearchPaths(searchPaths) 
  end 
end 

function updateLoading(target, percent)
  initUI()

  if nil == uiLayer then return end 

  uiLayer:setVisible(true)

  local node1 = uiLayer:getChildByName("scale_node"):getChildByName("Panel_1")
  local node2 = uiLayer:getChildByName("scale_node"):getChildByName("Panel_2")
  node2:setVisible(false)
  node1:setVisible(true)
  node1:getChildByName("Text_1"):setString(lang["updating"])
  node1:getChildByName("LoadingBar_1"):setPercent(percent or 0)
end 

function showPopup(target, str, func_yes, func_no)
  initUI()

  if nil == uiLayer then return end 

  uiLayer:setVisible(true)

  local root = uiLayer:getChildByName("scale_node")  
  root:getChildByName("Panel_1"):setVisible(false)
  local node2 = root:getChildByName("Panel_2")
  node2:setVisible(true)
  node2:getChildByName("Text_1"):setString(lang["resUpdateTitle"])
  node2:getChildByName("Text_2"):setString(str)
  
  local btn_yes = node2:getChildByName("btn_1")
  local btn_no = node2:getChildByName("btn_2")
  local lb_yes = node2:getChildByName("Text_3")
  local lb_no = node2:getChildByName("Text_5")
  if func_yes then btn_yes:addClickEventListener(func_yes) end 
  if func_no then btn_no:addClickEventListener(func_no) end 
  lb_yes:setString(lang["msgBox_ok"])
  lb_no:setString(lang["msgBox_cancle"])

  if nil == func_no then --只有确定按钮
    local x = (btn_yes:getPositionX() + btn_no:getPositionX())/2 
    btn_yes:setPositionX(x) 
    lb_yes:setPositionX(x) 
    btn_no:setVisible(false)
    lb_no:setVisible(false)
  end 
end 

function hideUI()
  initUI()
  if nil == uiLayer then return end 

  uiLayer:setVisible(false)
end 

function setTipStrVisible(target, isVisible)
  if nil == uiLayer then return end 

  local node1 = uiLayer:getChildByName("scale_node"):getChildByName("Panel_1")
  node1:getChildByName("Text_1"):setVisible(isVisible)
end 

return UpdateLayer 

