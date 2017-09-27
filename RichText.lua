
--使用说明
--[[
    RichText:ctor(str, w, h, fontName, fontSize, defaultColor, autoAlignWidth)
    str：格式为 "默认显示字串{变色字串,0xff0000}默认显示字串？"
    w,h：显示区域, 其中h可以为 0 ,则自适应高度
         最终返回的内容锚点在字串的 (0, 0)点

    autoAlignWidth :为一行显示不完时,在换行后自动缩进的宽度

    举例：
    local RichText = RichText.new(str, w, h, "Courier-Bold", 24)
    self:addChild(RichText)
--]]


RichText = class("RichText",function()
    return display.newNode()
end)


function RichText:ctor(str, w, h, fontName, fontSize, defaultColor, autoAlignWidth)
    local strTbl = self:parseString(str, defaultColor)

    --针对不同平台计算行间距, 最小字符宽度(因为有些平台是 >= fontSize/2)
    local tmplabel = CCLabelTTF:create("0\n9", fontName, fontSize)
    self.lineGap = math.max(0, tmplabel:getContentSize().height - fontSize*2) --行间距在 0--4 pixes
    self.lineGap = math.min(self.lineGap, 4)
    self.charWidthMin = math.max(fontSize/2, tmplabel:getContentSize().width)
    print("RichText: fontSize, minSize, lineGap=", fontSize, self.charWidthMin, self.lineGap)

    --如果h==0,则预排版获取高度值以用来创建渲染纹理
    if w > 0 and h == 0 then 
        local tmpStr = ""
        for k, v in pairs(strTbl) do 
            tmpStr = tmpStr..v[1]
        end 
        local size1, size2, strHeight 
        local tmp = CCLabelTTF:create(tmpStr,fontName,fontSize)
        size1 = tmp:getContentSize() 
        tmp:setDimensions(CCSizeMake(w, 0))
        size2 = tmp:getContentSize() 
        print("===size1, size2:", size1.width, size1.height, size2.width, size2.height)

        if size1.width > w and size1.height == size2.height then -- 针对全是小写字母时 CCLabelTTF 无法自动换行bug
            strHeight = math.ceil(size1.width/w)*(fontSize+self.lineGap)
        else 
            strHeight = 1.5 * size2.height 
        end 
        
        h = math.max(fontSize, strHeight) --为了防止手动排版越界,无法渲染上去
    end 
  
    --开始渲染
    self.alignWidth = autoAlignWidth or 0 
    self.fontSize = fontSize
    self.mSize = CCSize( w, h )
    self.mPoint = ccp(0,h)
    self.rt = CCRenderTexture:create( w, h)
    self:setContentSize( CCSize( w, h ) )
    self.rt:setPosition(ccp(w/2, h/2))
    self:addChild(self.rt)
    local R,G,B 
    for k, v in pairs(strTbl) do 
        R = bit.band(bit.rshift(v[2], 16), 255)
        G = bit.band(bit.rshift(v[2], 8), 255)
        B = bit.band(v[2], 255)
        if self:addString(v[1], fontName, ccc3(R,G,B)) == false then 
            break 
        end 
    end 

    --锚点设为字串的(0,0)
    local realSize = self:getTextSize()
    self.rt:setPosition(ccp(w/2,-h/2+realSize.height))
    self:setContentSize(realSize) 
end

function RichText:addString(str, fontName, fontColor)

    local function renderTexture(str, point)
        local label = CCLabelTTF:create(str, fontName, self.fontSize)
        label:setColor(fontColor)
        label:setAnchorPoint( ccp(0,1) )
        self.rt:begin()
        label:setPosition( point )
        label:visit()
        self.rt:endToLua()
    end 

    if str == nil or str:len() == 0 then 
        print("== empty rich text str...")
        return 
    end 

    local pos = 1
    local startIndex = pos 
    local fontSize = self.fontSize
    local point = self.mPoint

    local strW = 0
    local bytes = 0 
    local ch, charW, len 
    while pos <= str:len() do
        len = 1
        charW = self.charWidthMin --fontSize / 2        
        ch = string.byte(str, pos) 
        if ch > 0x80 then
            len = 3
            charW = fontSize
        end

        if ch == 10 then --换行符
            if bytes > 0 then 
                renderTexture(str:sub(startIndex, startIndex+bytes), point)
            end 
            --当前字符信息需要保存
            startIndex = pos+1
            strW = 0 
            bytes = 0 
            point.x = 0
            point.y = point.y - fontSize - self.lineGap 

        elseif point.x + strW + charW > self.mSize.width then --越界换行
            if bytes > 0 then 
                renderTexture(str:sub(startIndex, startIndex+bytes-1), point)
            end 

            --开始新的一行，但当前字符信息需要保存
            startIndex = pos
            strW = charW 
            bytes = len 
            point.x = self.alignWidth --换行后自动缩进
            point.y = point.y - fontSize - self.lineGap 

        else --中间相同属性字串
            strW = strW + charW 
            bytes = bytes + len 
        end 

        pos = pos + len 
        if pos > str:len() then --最后一段字串           
            renderTexture(str:sub(startIndex, startIndex+bytes-1), point)
            point.x = point.x + strW 
            bytes = 0 
        end 

        self.mPoint = point  

        if self.mPoint.y < 0 then 
            echo("=== out of height...")
            return false 
        end 
    end

    return true 
end

-- 字串格式："默认显示字串{变色字串,0xff0000}默认显示字串？"  
function RichText:parseString(str, defaultColor)  
    local colorDefault = defaultColor or 0xffffff --WHITE
    local tbl = {}
    while (str and string.len(str) > 0) do 
        local idx_s, idx_e, c, colorStr =string.find(str, "([{])(.-)([}])")
        if idx_s and idx_e and colorStr then 
            --变色字串前面的默认字串
            if idx_s > 1 then 
                local item = string.sub(str, 1, idx_s-1)
                table.insert(tbl, {item, colorDefault})
            end 
            --变色字串部分
            local payChannels = string.split(colorStr,",")
            if #payChannels >= 2 then 
                table.insert(tbl, {payChannels[1], toint(payChannels[2])})
            end 

            str = string.sub(str, idx_e+1)
        else 
          table.insert(tbl, {str, colorDefault})
          break 
        end 
    end 

    return tbl 
end 

function RichText:getTextSize()
    return CCSizeMake(self.mSize.width, self.mSize.height-self.mPoint.y+self.fontSize+self.lineGap)
end 

return RichText
