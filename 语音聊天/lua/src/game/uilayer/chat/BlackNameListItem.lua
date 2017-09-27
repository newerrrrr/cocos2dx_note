

local BlackNameListItem = class("BlackNameListItem", function() return ccui.Widget:create() end)

function BlackNameListItem:ctor()

end 

function BlackNameListItem:create()
  self._uiWidget = cc.CSLoader:createNode("chat_Black_list.csb")
  local item = BlackNameListItem.new()
  item:initBinding(self._uiWidget)
  return item 
end 

function BlackNameListItem:clone()
  local widget_new = self._uiWidget:clone()
  local item = BlackNameListItem.new()
  item:initBinding(widget_new)
  return item 
end 

function BlackNameListItem:initBinding(uiWidget)
  -- self._uiWidget = uiWidget 

  if uiWidget then 
    self:setContentSize(uiWidget:getContentSize())
    self:addChild(uiWidget) 

    local root = uiWidget:getChildByName("Panel_5")
    self.pic = root:getChildByName("pic")
    self.pic_frame = root:getChildByName("pic_0") 
    self.lbLevel = root:getChildByName("Text_1")
    self.lbName = root:getChildByName("Text_2")
    self.btnSelect = root:getChildByName("Image_4")
    self.imgSelect = root:getChildByName("Image_4_0")

    self:setSelected(false) --default

    local function onTouchSelected() 
      local state = not self:getIsSelected()
      self:setSelected(state) 
    end 
    self.btnSelect:addClickEventListener(onTouchSelected)
  end 
end 

function BlackNameListItem:setSelected(isSelected)
  self._isSelected = isSelected 
  if self.btnSelect:isVisible() then 
    self.imgSelect:setVisible(isSelected) 
  end 
end 

function BlackNameListItem:getIsSelected()
  return self._isSelected 
end 

function BlackNameListItem:setData(data)
  if nil == data then return end 

  self.data = data 
  self.pic:loadTexture(g_resManager.getResPath(g_data.res_head[tonumber(data.black_avatar_id)].head_icon))
  self.pic_frame:loadTexture(g_resManager.getResPath(1010007))
  self.lbLevel:setString("Lv."..data.black_level)
  self.lbName:setString(data.black_nick)
  self.lbName:setPositionX(self.lbLevel:getPositionX() + self.lbLevel:getContentSize().width + 5)
end 

function BlackNameListItem:getData()
  return self.data
end 

return  BlackNameListItem 
