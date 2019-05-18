
--搓牌动画: 支持左右上下4个方向的翻牌, 翻牌过程中先显示无字的正面(如果有的话), 结束后再显示有字牌面. 


local moveVertSourceToUp = 
"attribute vec2 a_position;\n"..
"attribute vec2 a_texCoord;\n"..
"uniform float ratio; \n"..
"uniform float radius; \n"..
"uniform float height;\n"..
"uniform float width;\n"..
"uniform float offx;\n"..
"uniform float offy;\n"..
"uniform float rotation;\n"..
"varying vec4 v_fragmentColor;\n"..
"varying vec2 v_texCoord;\n"..

"void main()\n"..
"{\n"..
"    vec4 tmp_pos = vec4(0.0, 0.0, 0.0, 0.0);;\n"..
"    tmp_pos = vec4(a_position.x, a_position.y, 0.0, 1.0);\n"..

"   float halfPeri = radius * 3.14159; \n"..
"   float hr = height * ratio;\n"..
"   if(hr > 0.0 && hr <= halfPeri){\n"..
"         if(tmp_pos.y < hr){\n"..
"               float rad = hr/3.14159;\n"..
"               float arc = (hr-tmp_pos.y)/rad;\n"..
"               tmp_pos.y = hr - sin(arc)*rad;\n"..
"               tmp_pos.z = rad * (1.0-cos(arc)); \n"..
"          }\n"..
"   }\n"..
"   if(hr > halfPeri){\n"..
"        float straight = (hr - halfPeri)/2.0;\n"..
"        if(tmp_pos.y < straight){\n"..
"            tmp_pos.y = hr - tmp_pos.y;\n"..
"            tmp_pos.z = radius * 2.0; \n"..
"        }\n"..
"        else if(tmp_pos.y < (straight + halfPeri)) {\n"..
"            float dy = halfPeri - (tmp_pos.y - straight);\n"..
"            float arc = dy/radius;\n"..
"            tmp_pos.y = hr - straight - sin(arc)*radius;\n"..
"            tmp_pos.z = radius * (1.0-cos(arc)); \n"..
"        }\n"..
"    }\n"..
"    float y1 = tmp_pos.y;\n"..
"    float z1 = tmp_pos.z;\n"..
"    float y2 = height;\n"..
"    float z2 = 0.0;\n"..
"    float sinRat = sin(rotation);\n"..
"    float cosRat = cos(rotation);\n"..
"    tmp_pos.y=(y1-y2)*cosRat-(z1-z2)*sinRat+y2;\n"..
"    tmp_pos.z=(z1-z2)*cosRat+(y1-y2)*sinRat+z2;\n"..
"    tmp_pos.y = tmp_pos.y - height/2.0*(1.0-cosRat);\n"..
"    tmp_pos += vec4(offx, offy, 0.0, 0.0);\n"..
"    gl_Position = CC_MVPMatrix * tmp_pos;\n"..
"    v_texCoord = a_texCoord;\n"..
"}\n";


-- 从上往下
local moveVertSourceToDown = 
"attribute vec2 a_position;\n"..
"attribute vec3 a_texCoord;\n"..
"uniform float ratio; \n"..
"uniform float radius; \n"..
"uniform float height;\n"..
"uniform float width;\n"..
"uniform float offx;\n"..
"uniform float offy;\n"..
"uniform float rotation;\n"..
"varying vec4 v_fragmentColor;\n"..
"varying vec2 v_texCoord;\n"..

"void main()\n"..
"{\n"..
"    vec4 tmp_pos = vec4(0.0, 0.0, 0.0, 0.0);;\n"..
"    tmp_pos = vec4(a_position.x, height - a_position.y, 0.0, 1.0);\n"..

"   float halfPeri = radius * 3.14159; \n"..
"   float hr = height * ratio ;\n"..
"   if(hr > 0.0 && hr <= halfPeri){\n"..
"         if(tmp_pos.y < hr){\n"..
"               float rad = hr/ 3.14159;\n"..
"               float arc = (hr-tmp_pos.y)/rad;\n"..
"               tmp_pos.y = hr - sin(arc)*rad;\n"..
"               tmp_pos.z = rad * (1.0-cos(arc)); \n"..
"          }\n"..
"   }\n"..
"   if(hr > halfPeri){\n"..
"        float straight = (hr - halfPeri)/2.0;\n"..
"        if(tmp_pos.y < straight){\n"..
"            tmp_pos.y = hr  - tmp_pos.y;\n"..
"            tmp_pos.z = radius * 2.0; \n"..
"        }\n"..
"        else if(tmp_pos.y < (straight + halfPeri)) {\n"..
"            float dy = halfPeri - (tmp_pos.y - straight);\n"..
"            float arc = dy/radius;\n"..
"            tmp_pos.y = hr - straight - sin(arc)*radius;\n"..
"            tmp_pos.z = radius * (1.0-cos(arc)); \n"..
"        }\n"..
"    }\n"..
"    tmp_pos.y = height - tmp_pos.y;\n"..
"    float y1 = tmp_pos.y;\n"..
"    float z1 = tmp_pos.z;\n"..
"    float y2 = height;\n"..
"    float z2 = 0.0;\n"..
"    float sinRat = sin(rotation);\n"..
"    float cosRat = cos(rotation);\n"..
"    tmp_pos.y=(y1-y2)*cosRat-(z1-z2)*sinRat+y2;\n"..
"    tmp_pos.z=(z1-z2)*cosRat+(y1-y2)*sinRat+z2;\n"..
"    tmp_pos.y = tmp_pos.y - height/2.0*(1.0-cosRat);\n"..
"    tmp_pos += vec4(offx, offy, 0.0, 0.0);\n"..
"    gl_Position = CC_MVPMatrix * tmp_pos;\n"..
"    v_texCoord = vec2(a_texCoord.x,a_texCoord.y);\n"..
"}\n";

local moveVertSourceToRight = 
"attribute vec2 a_position;\n"..
"attribute vec3 a_texCoord;\n"..
"uniform float ratio; \n"..
"uniform float radius; \n"..
"uniform float height;\n"..
"uniform float width;\n"..
"uniform float offx;\n"..
"uniform float offy;\n"..
"uniform float rotation;\n"..
"varying vec4 v_fragmentColor;\n"..
"varying vec2 v_texCoord;\n"..

"void main()\n"..
"{\n"..
"    vec4 tmp_pos = vec4(0.0, 0.0, 0.0, 0.0);;\n"..
"    tmp_pos = vec4(a_position.x, a_position.y, 0.0, 1.0);\n"..

"   float halfPeri = radius * 3.14159; \n"..
"   float hr = width * ratio;\n"..
"   if(hr > 0.0 && hr <= halfPeri){\n"..
"         if(tmp_pos.x < hr){\n"..
"               float rad = hr/ 3.14159;\n"..
"               float arc = (hr-tmp_pos.x)/rad;\n"..
"               tmp_pos.x = hr - sin(arc)*rad;\n"..
"               tmp_pos.z = rad * (1.0-cos(arc)); \n"..
"          }\n"..
"   }\n"..
"   if(hr > halfPeri){\n"..
"        float straight = (hr - halfPeri)/2.0;\n"..
"        if(tmp_pos.x < straight){\n"..
"            tmp_pos.x = hr  - tmp_pos.x;\n"..
"            tmp_pos.z = radius * 2.0; \n"..
"        }\n"..
"        else if(tmp_pos.x < (straight + halfPeri)) {\n"..
"            float dy = halfPeri - (tmp_pos.x - straight);\n"..
"            float arc = dy/radius;\n"..
"            tmp_pos.x = hr - straight - sin(arc)*radius;\n"..
"            tmp_pos.z = radius * (1.0-cos(arc)); \n"..
"        }\n"..
"    }\n"..
"    float y1 = tmp_pos.x;\n"..
"    float z1 = tmp_pos.z;\n"..
"    float y2 = width;\n"..
"    float z2 = 0.0;\n"..
"    float sinRat = sin(rotation);\n"..
"    float cosRat = cos(rotation);\n"..
"    tmp_pos.x=(y1-y2)*cosRat-(z1-z2)*sinRat+y2;\n"..
"    tmp_pos.z=(z1-z2)*cosRat+(y1-y2)*sinRat+z2;\n"..
"    tmp_pos.x = tmp_pos.x - width/2.0*(1.0-cosRat);\n"..
"    tmp_pos += vec4(offx, offy, 0.0, 0.0);\n"..
"    gl_Position = CC_MVPMatrix * tmp_pos;\n"..
"    v_texCoord = vec2(a_texCoord.x,a_texCoord.y);\n"..
"}\n";

local moveVertSourceToLeft = 
"attribute vec2 a_position;\n"..
"attribute vec3 a_texCoord;\n"..
"uniform float ratio; \n"..
"uniform float radius; \n"..
"uniform float height;\n"..
"uniform float width;\n"..
"uniform float offx;\n"..
"uniform float offy;\n"..
"uniform float rotation;\n"..
"varying vec4 v_fragmentColor;\n"..
"varying vec2 v_texCoord;\n"..

"void main()\n"..
"{\n"..
"    vec4 tmp_pos = vec4(0.0, 0.0, 0.0, 0.0);;\n"..
"    tmp_pos = vec4(width - a_position.x, a_position.y, 0.0, 1.0);\n"..

"   float halfPeri = radius * 3.14159; \n"..
"   float hr = width * ratio;\n"..
"   if(hr > 0.0 && hr <= halfPeri){\n"..
"         if(tmp_pos.x < hr){\n"..
"               float rad = hr/ 3.14159;\n"..
"               float arc = (hr-tmp_pos.x)/rad;\n"..
"               tmp_pos.x = hr - sin(arc)*rad;\n"..
"               tmp_pos.z = rad * (1.0-cos(arc)); \n"..
"          }\n"..
"   }\n"..
"   if(hr > halfPeri){\n"..
"        float straight = (hr - halfPeri)/2.0;\n"..
"        if(tmp_pos.x < straight){\n"..
"            tmp_pos.x = hr  - tmp_pos.x;\n"..
"            tmp_pos.z = radius * 2.0; \n"..
"        }\n"..
"        else if(tmp_pos.x < (straight + halfPeri)) {\n"..
"            float dy = halfPeri - (tmp_pos.x - straight);\n"..
"            float arc = dy/radius;\n"..
"            tmp_pos.x = hr - straight - sin(arc)*radius;\n"..
"            tmp_pos.z = radius * (1.0-cos(arc)); \n"..
"        }\n"..
"    }\n"..
"   tmp_pos.x = width -tmp_pos.x;\n"..
"    float y1 = tmp_pos.x;\n"..
"    float z1 = tmp_pos.z;\n"..
"    float y2 = width;\n"..
"    float z2 = 0.0;\n"..
"    float sinRat = sin(rotation);\n"..
"    float cosRat = cos(rotation);\n"..
"    tmp_pos.x=(y1-y2)*cosRat-(z1-z2)*sinRat+y2;\n"..
"    tmp_pos.z=(z1-z2)*cosRat+(y1-y2)*sinRat+z2;\n"..
"    tmp_pos.x = tmp_pos.x - width/2.0*(1.0-cosRat);\n"..
"    tmp_pos += vec4(offx, offy, 0.0, 0.0);\n"..
"    gl_Position = CC_MVPMatrix * tmp_pos;\n"..
"    v_texCoord = vec2(a_texCoord.x,a_texCoord.y);\n"..
"}\n";

local smoothVertSource = 
"attribute vec2 a_position;\n"..
"attribute vec2 a_texCoord;\n"..
"uniform float height;\n"..
"uniform float offx;\n"..
"uniform float offy;\n"..
"uniform float rotation;\n"..
"varying vec2 v_texCoord;\n"..

"void main()\n"..
"{\n"..
"    vec4 tmp_pos = vec4(0.0, 0.0, 0.0, 0.0);;\n"..
"    tmp_pos = vec4(a_position.x, a_position.y, 0.0, 1.0);\n"..
"    float cl = height/5.0;\n"..
"    float sl = (height - cl)/2.0;\n"..
"    float radii = (cl/rotation)/2.0;\n"..
"    float sinRot = sin(rotation);\n"..
"    float cosRot = cos(rotation);\n"..
"    float distance = radii*sinRot;\n"..
"    float centerY = height/2.0;\n"..
"    float poxY1 = centerY - distance;\n"..
"    float poxY2 = centerY + distance;\n"..
"    float posZ = sl*sinRot;\n"..
"    if(tmp_pos.y <= sl){\n"..
"       float length = sl - tmp_pos.y;\n"..
"       tmp_pos.y = poxY1 - length*cosRot;\n"..
"       tmp_pos.z = posZ - length*sinRot;\n"..
"    }\n"..
"    else if(tmp_pos.y < (sl+cl)){\n"..
"       float el = tmp_pos.y - sl;\n"..
"       float rotation2 = -el/radii;\n"..
"       float x1 = poxY1;\n"..
"       float y1 = posZ;\n"..
"       float x2 = centerY;\n"..
"       float y2 = posZ - radii*cosRot;\n"..
"       float sinRot2 = sin(rotation2);\n"..
"       float cosRot2 = cos(rotation2);\n"..
"       tmp_pos.y=(x1-x2)*cosRot2-(y1-y2)*sinRot2+x2;\n"..
"       tmp_pos.z=(y1-y2)*cosRot2+(x1-x2)*sinRot2+y2;\n"..
"    }\n"..
"    else {\n"..
"        float length = tmp_pos.y - cl - sl;\n"..
"        tmp_pos.y = poxY2 + length*cosRot;\n"..
"        tmp_pos.z = posZ - length*sinRot;\n"..
"    }\n"..
"    tmp_pos += vec4(offx, offy, 0.0, 0.0);\n"..
"    gl_Position = CC_MVPMatrix * tmp_pos;\n"..
"    v_texCoord = vec2(a_texCoord.x, 1.0-a_texCoord.y);\n"..
"}\n"

local endVertSource = 
"attribute vec2 a_position;\n"..
"attribute vec2 a_texCoord;\n"..
"uniform float offx;\n"..
"uniform float offy;\n"..
"varying vec2 v_texCoord;\n"..

"void main()\n"..
"{\n"..
"    vec4 tmp_pos = vec4(0.0, 0.0, 0.0, 0.0);;\n"..
"    tmp_pos = vec4(a_position.x, a_position.y, 0.0, 1.0);\n"..
"    tmp_pos += vec4(offx, offy, 0.0, 0.0);\n"..
"    gl_Position = CC_MVPMatrix * tmp_pos;\n"..
"    v_texCoord = vec2(a_texCoord.x, 1.0-a_texCoord.y);\n"..
"}\n"

local strFragSource =
"varying vec2 v_texCoord;\n"..
"void main()\n"..
"{\n"..
    "//TODO, 这里可以做些片段着色特效\n"..
    "gl_FragColor = texture2D(CC_Texture0, v_texCoord);\n"..
"}\n"


local RubCardLayer_Pai           = 3.141592
local RubCardLayer_State_Move    = 1
local RubCardLayer_State_Smooth  = 2
local RubCardLayer_RotationFrame = 10
local RubCardLayer_RotationAnger = RubCardLayer_Pai/3
local RubCardLayer_SmoothFrame   = 3 --无字牌翻牌后到显示有字牌之前的过渡帧数 
local RubCardLayer_SmoothAnger   = RubCardLayer_Pai/6

local RubCardLayer = {}

--滑动方向
local Direction = {
    ToUp    = "ToUp", 
    ToDown  = "ToDown",
    ToRight = "ToRight",
    ToLeft  = "ToLeft",
}

local function EJExtendUserData(luaCls, cObj)
    local t = tolua.getpeer(cObj)
    if not t then
        t = {}
        tolua.setpeer(cObj, t)
    end
    setmetatable(t, luaCls)
    return cObj 
end

--szBack:牌背图片路径 
--szFontBlank, szFont：牌面无字/有字牌路径, 在搓牌过程中显示无字牌, 翻牌后显示有字牌; 参数 szFontBlank可不传
--posX, posY:显示位置 
--rubCallBack:翻牌结束后回调 
--isRotaion90:是否将扑克翻转90角(竖版变成横版)
function RubCardLayer:create(szBack, szFontBlank, szFont, posX, posY, isRotaion90, rubCallBack)
    local layer = EJExtendUserData(RubCardLayer, cc.Layer:create())
    self.__index = self
    layer:__init(szBack, szFontBlank, szFont, posX, posY, rubCallBack)
    return layer
end

function RubCardLayer:__init(szBack, szFontBlank, szFont, posX, posY, isRotaion90, rubCallBack)
    self.posX        = posX
    self.posY        = posY
    self.isRotaion90 = isRotaion90 
    self.rubCallBack = rubCallBack 
    
    local scale = 1.0
    self.scale = scale

    self.glNode = gl.glNodeCreate()
    self:addChild(self.glNode)

    --从下往上
    self.moveGlProgramToUp = cc.GLProgram:createWithByteArrays(moveVertSourceToUp, strFragSource)
    self.moveGlProgramToUp:retain()
    self.moveGlProgramToUp:updateUniforms()

    --从上往下
    self.moveGlProgramToDown = cc.GLProgram:createWithByteArrays(moveVertSourceToDown, strFragSource)
    self.moveGlProgramToDown:retain()
    self.moveGlProgramToDown:updateUniforms()

    --从左往右
    self.moveGlProgramToRight = cc.GLProgram:createWithByteArrays(moveVertSourceToRight, strFragSource)
    self.moveGlProgramToRight:retain()
    self.moveGlProgramToRight:updateUniforms() 

    --从右往左
    self.moveGlProgramToLeft = cc.GLProgram:createWithByteArrays(moveVertSourceToLeft, strFragSource)
    self.moveGlProgramToLeft:retain()
    self.moveGlProgramToLeft:updateUniforms() 
    
    --平滑过渡
    local smoothGlProgram = cc.GLProgram:createWithByteArrays(smoothVertSource, strFragSource)
    self.smoothGlProgram = smoothGlProgram
    smoothGlProgram:retain()
    smoothGlProgram:updateUniforms()
    
    --翻牌结束
    local endGlProgram = cc.GLProgram:createWithByteArrays(endVertSource, strFragSource)
    self.endGlProgram = endGlProgram
    endGlProgram:retain()
    endGlProgram:updateUniforms()

    self:__registerTouchEvent()

    self.state = RubCardLayer_State_Move
    
    --1.牌背 
    self.backSprite = cc.Sprite:create(szBack) 
    self.backSprite:retain() 
    local id1, texRange1, sz1 = self:__getRange(self.backSprite)
    self.sz1 = sz1
    local msh1, nVerts1 = self:__initCardVertexUpDown(cc.size(sz1[1] * scale, sz1[2] * scale), texRange1, true) --上下滑动对应顶点 
    local msh3, nVerts3 = self:__initCardVertexLeftRight(cc.size(sz1[1] * scale, sz1[2] * scale), texRange1, true) --左右滑动对应顶点 
    local info_back_ud, info_back_lr = {id1, msh1, nVerts1}, {id1, msh3, nVerts3} 

    --2.牌面(无字) 
    local info_front_blank_ud, info_front_blank_lr 
    if szFontBlank then 
        self.frontBlankSprite = cc.Sprite:create(szFontBlank) 
        self.frontBlankSprite:retain() 

        local id2, texRange2, sz2 = self:__getRange(self.frontBlankSprite) 
        local msh2, nVerts2 = self:__initCardVertexUpDown(cc.size(sz2[1] * scale, sz2[2] * scale), texRange2, false) --上下滑动 
        local msh4, nVerts4 = self:__initCardVertexLeftRight(cc.size(sz2[1] * scale, sz2[2] * scale), texRange2, false) --左右滑动 
        info_front_blank_ud, info_front_blank_lr = {id2, msh2, nVerts2}, {id2, msh4, nVerts4} 
    end 

    --3.牌面(有字) 
    self.frontSprite = cc.Sprite:create(szFont)
    self.frontSprite:retain() 
    local id3, texRange3, sz3 = self:__getRange(self.frontSprite) 
    local msh6, nVerts6 = self:__initCardVertexUpDown(cc.size(sz3[1] * scale, sz3[2] * scale), texRange3, false) --上下滑动 
    local msh8, nVerts8 = self:__initCardVertexLeftRight(cc.size(sz3[1] * scale, sz3[2] * scale), texRange3, false) --左右滑动
    local info_front_ud, info_front_lr = {id3, msh6, nVerts6}, {id3, msh8, nVerts8} 

    --牌的渲染信息
    self.cardMesh1 = {info_back_ud, info_front_blank_ud, info_front_ud} --上下滑动
    self.cardMesh2 = {info_back_lr, info_front_blank_lr, info_front_lr} --左右滑动

    self.ratioVal    = 0 
    self.radiusVal   = sz1[2]*scale/10 
    
    self.pokerWidth  = sz1[1] * scale 
    self.pokerHeight = sz1[2] * scale 
    
    --self.offx, self.offy 对应牌的左下角
    self.offx = self.posX - self.pokerWidth/2
    self.offy = self.posY - self.pokerHeight/2
    
    -- OpenGL绘制函数
    local function draw(transform, transformUpdated)
        if self.state == RubCardLayer_State_Move then
            if self.isReverse then --回弹
                self.ratioVal = math.max(0, self.ratioVal - 0.05) 
            end 
            self:__drawByMoveProgram(0)
        
        elseif self.state == RubCardLayer_State_Smooth then --进入显示整张正面牌的过渡 
            if self.smoothFrame == nil then
                self.smoothFrame = 1
            end
            
            if self.smoothFrame <= RubCardLayer_RotationFrame then
                self:__drawByMoveProgram(-RubCardLayer_RotationAnger*self.smoothFrame/RubCardLayer_RotationFrame)
            
            elseif self.smoothFrame < (RubCardLayer_RotationFrame+RubCardLayer_SmoothFrame) then
                local scale = (self.smoothFrame - RubCardLayer_RotationFrame)/RubCardLayer_SmoothFrame
                self:__drawBySmoothProgram(math.max(0.01,RubCardLayer_SmoothAnger*(1-scale)))
            
            else
                if self.rubCallBack then
                    self.rubCallBack(true)
                    self.rubCallBack = nil
                end
                self:__drawByEndProgram() 

                --1秒后删除
                self:remove(1.0) 
            end
            self.smoothFrame = self.smoothFrame + 1
        end
    end
    self.glNode:registerScriptDrawHandler(draw)
end

--移除自身 
function RubCardLayer:remove(delay) 
    local function callBack() 
        self:removeFromParent() 
    end
    local callFunc = cc.CallFunc:create(callBack)
    local delay = cc.DelayTime:create(delay or 0.01)
    local sequence = cc.Sequence:create(delay, callFunc)
    self:runAction(cc.RepeatForever:create(sequence))
end

function RubCardLayer:__drawByMoveProgram(rotation)
    local glProgram = self.moveGlProgramToUp
    local cardMesh = self.cardMesh1 

    if self.moveDir == Direction.ToDown then 
        glProgram = self.moveGlProgramToDown 

    elseif self.moveDir == Direction.ToRight then 
        glProgram = self.moveGlProgramToRight 
        cardMesh = self.cardMesh2 

    elseif self.moveDir == Direction.ToLeft then 
        glProgram = self.moveGlProgramToLeft 
        cardMesh = self.cardMesh2 
    end 

    gl.enable(gl.CULL_FACE)
    glProgram:use()
    glProgram:setUniformsForBuiltins()

    --正面有字或无字只显示其中一种
    local tbl = {cardMesh[1], cardMesh[2] or cardMesh[3]} 
    for _, v in ipairs(tbl) do 
        gl._bindTexture(gl.TEXTURE_2D, v[1])
        local rotationLc = gl.getUniformLocation(glProgram:getProgram(), "rotation")
        glProgram:setUniformLocationF32(rotationLc, rotation)
        local ratio = gl.getUniformLocation(glProgram:getProgram(), "ratio")
        glProgram:setUniformLocationF32(ratio, self.ratioVal)
        local radius = gl.getUniformLocation(glProgram:getProgram(), "radius")
        glProgram:setUniformLocationF32(radius, self.radiusVal)
        local offx = gl.getUniformLocation(glProgram:getProgram(), "offx")
        glProgram:setUniformLocationF32(offx, self.offx)
        local offy = gl.getUniformLocation(glProgram:getProgram(), "offy")
        glProgram:setUniformLocationF32(offy, self.offy)
        local height = gl.getUniformLocation(glProgram:getProgram(), "height")
        glProgram:setUniformLocationF32(height, self.sz1[2]*self.scale)
        local width = gl.getUniformLocation(glProgram:getProgram(), "width")
        glProgram:setUniformLocationF32(width, self.sz1[1]*self.scale) 

        self:__drawArrays(v)
    end
    gl.disable(gl.CULL_FACE)
end

--正面过渡
function RubCardLayer:__drawBySmoothProgram(rotation)
    local glProgram = self.smoothGlProgram
    glProgram:use()
    glProgram:setUniformsForBuiltins()

    local cardMesh = self.cardMesh1 --(self.moveDir == Direction.ToRight or self.moveDir == Direction.ToLeft) and self.cardMesh1 or self.cardMesh2 

    local v = cardMesh[2] or cardMesh[3] --只显示无字正面或有字正面 
    gl._bindTexture(gl.TEXTURE_2D, v[1])
    local rotationLc = gl.getUniformLocation(glProgram:getProgram(), "rotation")
    glProgram:setUniformLocationF32(rotationLc, rotation)
    local offx = gl.getUniformLocation(glProgram:getProgram(), "offx")
    glProgram:setUniformLocationF32(offx, self.offx)
    local offy = gl.getUniformLocation(glProgram:getProgram(), "offy")
    glProgram:setUniformLocationF32(offy, self.offy)
    local height = gl.getUniformLocation(glProgram:getProgram(), "height")
    glProgram:setUniformLocationF32(height, self.sz1[2]*self.scale)
    self:__drawArrays(v)
end

--翻牌结束后显示正面
function RubCardLayer:__drawByEndProgram()
    local glProgram = self.endGlProgram
    glProgram:use()
    glProgram:setUniformsForBuiltins()

    local cardMesh = self.cardMesh1 --(self.moveDir == Direction.ToRight or self.moveDir == Direction.ToLeft) and self.cardMesh1 or self.cardMesh2 
    local v = cardMesh[3] --只显示有字正面
    gl._bindTexture(gl.TEXTURE_2D, v[1])
    local offx = gl.getUniformLocation(glProgram:getProgram(), "offx")
    glProgram:setUniformLocationF32(offx, self.offx)
    local offy = gl.getUniformLocation(glProgram:getProgram(), "offy")
    glProgram:setUniformLocationF32(offy, self.offy)
    self:__drawArrays(v)
end

function RubCardLayer:__drawArrays(v)
    gl.glEnableVertexAttribs(bit._or(cc.VERTEX_ATTRIB_FLAG_TEX_COORDS, cc.VERTEX_ATTRIB_FLAG_POSITION))
    gl.bindBuffer(gl.ARRAY_BUFFER, v[2][1])
    gl.vertexAttribPointer(cc.VERTEX_ATTRIB_POSITION,2,gl.FLOAT,false,0,0)
    gl.bindBuffer(gl.ARRAY_BUFFER, v[2][2])
    gl.vertexAttribPointer(cc.VERTEX_ATTRIB_TEX_COORD,2,gl.FLOAT,false,0,0)
    gl.drawArrays(gl.TRIANGLES, 0, v[3])
    gl.bindBuffer(gl.ARRAY_BUFFER, 0)
end

function RubCardLayer:__registerTouchEvent()
    local function onNodeEvent(event)
        if "exit" == event then
            gl._deleteBuffer(self.cardMesh1[1][2][1].buffer_id) 
            gl._deleteBuffer(self.cardMesh1[1][2][2].buffer_id) 
            if self.cardMesh1[2] then --无字正面
                gl._deleteBuffer(self.cardMesh1[2][2][1].buffer_id) 
                gl._deleteBuffer(self.cardMesh1[2][2][2].buffer_id) 
            end 
            gl._deleteBuffer(self.cardMesh1[3][2][1].buffer_id) 
            gl._deleteBuffer(self.cardMesh1[3][2][2].buffer_id)             
            self.moveGlProgramToUp:release() 
            self.moveGlProgramToDown:release() 
            self.moveGlProgramToRight:release() 
            self.moveGlProgramToLeft:release() 

            self.smoothGlProgram:release() 
            self.endGlProgram:release() 

            self.backSprite:release() 
            if self.frontBlankSprite then 
                self.frontBlankSprite:release() 
            end 
            self.frontSprite:release() 
            --外部回调 
            if self.rubCallBack then 
                self.rubCallBack(false) 
                self.rubCallBack = nil  
            end             
        end
    end
    self:registerScriptHandler(onNodeEvent)

   local function checkDirection(beginPos, movePos) 
        if self.moveDir then return end 

        --xy的偏移度
        local offx = math.abs(beginPos.x - movePos.x)
        local offy = math.abs(beginPos.y - movePos.y)

        if offx - offy > 5 then
            if beginPos.x > movePos.x then 
                self.moveDir = Direction.ToLeft
            else 
                self.moveDir = Direction.ToRight
            end 

        elseif offx - offy < -5 then 
            if beginPos.y > movePos.y then
                self.moveDir = Direction.ToDown
            else 
                self.moveDir = Direction.ToUp 
            end
        end 
    end

    local function onTouchBegan(touch, event) 
        self.startPos  = touch:getLocation() 
        self.moveDir   = nil 
        self.isReverse = false 
        self.ratioVal  = 0.0 
        return true
    end

    local function onTouchMoved(touch, event) 
        local movePos = touch:getLocation()

        checkDirection(self.startPos, movePos) 
        if nil == self.moveDir then return end 

        --对应牌的左小角滑动, self.ratioVal 范围在(0~1)
        if self.moveDir == Direction.ToUp then 
            self.ratioVal = (movePos.y - self.offy)/self.pokerHeight 

        elseif self.moveDir == Direction.ToDown then 
            self.ratioVal = 1.0 - (movePos.y - self.offy)/self.pokerHeight

        elseif self.moveDir == Direction.ToLeft then
            self.ratioVal = 1.0 - (movePos.x - self.offx)/self.pokerWidth 

        elseif self.moveDir == Direction.ToRight then
            self.ratioVal = (movePos.x - self.offx)/self.pokerWidth 
        end 
        self.ratioVal = math.max(0, self.ratioVal) 
        self.ratioVal = math.min(1.0, self.ratioVal) 

        --到达预定位置自动翻牌 
        if self.ratioVal >= 0.98 then 
            self.state = RubCardLayer_State_Smooth 
        end 
        return true
    end

    local function onTouchEnded(touch, event)
        if self.ratioVal >= 0.85 then --到达预定位置翻牌 
            self.state = RubCardLayer_State_Smooth 
        else 
            self.isReverse = true 
        end
        return true
    end

    local layer = cc.Layer:create() 
    self:addChild(layer)
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(onTouchMoved, cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)  
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, layer)
end

function RubCardLayer:__getRange(sprite)
    local size = sprite:getContentSize()
    local tex = sprite:getTexture()
    local id = tex:getName() --纹理ID
    if self.isRotaion90 then 
        size = cc.size(size.height, size.width) 
        sprite:setContentSize(size) 
    end 
    return id, {0, 1, 1, 0}, {size.width, size.height}
end

--初始化顶点坐标和纹理坐标, 返回缓冲区和四边形个数
function RubCardLayer:__initCardVertexUpDown(size, texRange, isBack) 
    local nDiv = 30 --将高分成30份
    
    local verts = {} --位置坐标
    local texs  = {} --纹理坐标
    local dh    = size.height/nDiv
    local dw    = size.width

    --计算顶点位置
    for c = 1, nDiv do 
        local x, y = 0, (c-1)*dh
        local quad = {} --1个四边形包含2个三角形
        if isBack then
            quad = {x, y, x+dw, y, x, y+dh,  x+dw, y, x+dw, y+dh, x, y+dh} --2个三角形, 逆时针
        else
            quad = {x, y, x, y+dh, x+dw, y,  x+dw, y, x, y+dh, x+dw, y+dh} --2个三角形, 顺时针
        end
        for _, v in ipairs(quad) do 
            table.insert(verts, v) 
        end
    end

    --纹理坐标
    if self.isRotaion90 then 
        for i = 1, #verts/2 do 
            local x, y = verts[2*i-1], verts[2*i] 
            if isBack then 
                table.insert(texs, y/size.height)
                table.insert(texs, x/size.width) 
            else 
                table.insert(texs, 1 - y/size.height)
                table.insert(texs, x/size.width) 
            end 
        end        
    else 
        for i = 1, #verts/2 do 
            local x, y = verts[2*i-1], verts[2*i] 
            if isBack then 
                table.insert(texs, x/size.width)
                table.insert(texs, 1 - y/size.height) 
            else 
                table.insert(texs, 1 - x/size.width)
                table.insert(texs, 1 - y/size.height) 
            end 
        end 
    end 

    local res = {}
    local tmp = {verts, texs}
    for _, v in ipairs(tmp) do 
        local buffid = gl.createBuffer()
        gl.bindBuffer(gl.ARRAY_BUFFER, buffid)
        gl.bufferData(gl.ARRAY_BUFFER, table.getn(v), v, gl.STATIC_DRAW)
        gl.bindBuffer(gl.ARRAY_BUFFER, 0)
        table.insert(res, buffid)
    end
    return res, #verts
end

function RubCardLayer:__initCardVertexLeftRight(size, texRange, isBack) 
    local nDiv = 30 --将宽分成30份
    
    local verts = {} --位置坐标 
    local texs  = {} --纹理坐标 
    local dh    = size.height 
    local dw    = size.width/nDiv 

    --计算顶点位置
    for c = 1, nDiv do 
        local x, y = (c-1)*dw, 0 
        local quad = {} --1个四边形包含2个三角形 
        if isBack then 
            quad = {x, y, x+dw, y, x, y+dh, x+dw, y, x+dw, y+dh, x, y+dh} --2个三角形, 逆时针
        else
            quad = {x, y, x, y+dh, x+dw, y, x+dw, y, x, y+dh, x+dw, y+dh} --2个三角形, 顺时针
        end 
        for _, v in ipairs(quad) do 
            table.insert(verts, v) 
        end 
    end 

    --纹理坐标
    if self.isRotaion90 then 
        for i = 1, #verts/2 do 
            local x, y = verts[2*i-1], verts[2*i] 
            if isBack then 
                table.insert(texs, y/size.height)
                table.insert(texs, x/size.width) 
            else 
                table.insert(texs, 1 - y/size.height)
                table.insert(texs, x/size.width) 
            end 
        end       
    else 
        for i = 1, #verts/2 do 
            local x, y = verts[2*i-1], verts[2*i] 
            if isBack then 
                table.insert(texs, x/size.width)
                table.insert(texs, 1 - y/size.height) 
            else 
                table.insert(texs, 1 - x/size.width)
                table.insert(texs, 1 - y/size.height) 
            end 
        end 
    end 

    local res = {}
    local tmp = {verts, texs}
    for _, v in ipairs(tmp) do 
        local buffid = gl.createBuffer()
        gl.bindBuffer(gl.ARRAY_BUFFER, buffid)
        gl.bufferData(gl.ARRAY_BUFFER, table.getn(v), v, gl.STATIC_DRAW)
        gl.bindBuffer(gl.ARRAY_BUFFER, 0)
        table.insert(res, buffid)
    end
    return res, #verts
end

return RubCardLayer