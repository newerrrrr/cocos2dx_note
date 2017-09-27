
#include "ShaderNode_hlb.h"


ShaderNode_hlb::ShaderNode_hlb()
:m_rippleDistance(0.0f),
m_rippleRange(0.02f)
{
}

ShaderNode_hlb::~ShaderNode_hlb()
{
}


ShaderNode_hlb* ShaderNode_hlb::createWithVertexFile(const std::string &name_vert, const std::string& name_frag)
{
    auto node = new (std::nothrow) ShaderNode_hlb();
    node->initWithVertex(name_vert, name_frag);
    node->autorelease();

    return node;
}


bool ShaderNode_hlb::initWithVertex(const std::string &vert, const std::string &frag)
{
    //auto glprogram = GLProgram::createWithByteArrays(vert.c_str(), frag.c_str());   
    auto glprogram = new GLProgram();
    glprogram->initWithFilenames(vert.c_str(), frag.c_str());
        
    //绑定attribute  变量
    glprogram->bindAttribLocation("a_position", 0);  
    glprogram->bindAttribLocation("a_texCoord", 1);  
    
    glprogram->link(); //因为绑定了属性，所以需要link 一下，否则无法识别属性
    
    //获取attribute  变量标识
    m_attributePosition = glGetAttribLocation(glprogram->getProgram(), "a_position");  
    m_attributeColor = glGetAttribLocation(glprogram->getProgram(), "a_color");  
    m_attributeTexCoord = glGetAttribLocation(glprogram->getProgram(), "a_texCoord");  


    //获取uniform  变量标识
    m_uniformTex0 = glGetUniformLocation(glprogram->getProgram(), "tex0");  
    m_uniformDist = glGetUniformLocation(glprogram->getProgram(), "u_rippleDistance");  
    m_uniformRange = glGetUniformLocation(glprogram->getProgram(), "u_rippleRange");  

     /*传递uniform 变量()*/
    glprogram->updateUniforms(); //上传系统内部默认的uniform 变量
    
        
    //使用着色器程序
    this->setGLProgram(glprogram);
    glprogram->release();
    CHECK_GL_ERROR_DEBUG();

   //图片信息
    m_Texture = Director::getInstance()->getTextureCache()->addImage("hlb_image.png");


    m_time = 0;
    setContentSize(Size(m_Texture->getPixelsWide(), m_Texture->getPixelsHigh()));
    setColor(Color4F(1.0, 1.0, 1.0, 0.5));
    scheduleUpdate();

    
    return true;
}


void ShaderNode_hlb::update(float dt)
{
    //m_time += dt;
    
    float rippleSpeed = 0.25f;
    float maxRippleDistance = 1;
    m_rippleDistance += rippleSpeed * dt;
    m_rippleRange = (1 - m_rippleDistance / maxRippleDistance) * 0.02f;
 
    if (m_rippleDistance > maxRippleDistance) 
    {
        //unscheduleUpdate();
        m_rippleDistance = 0;        
    }    
}

void ShaderNode_hlb::setColor(const Color4F& color)
{
    m_color[0] = color.r;
    m_color[1] = color.g;
    m_color[2] = color.b;
    m_color[3] = color.a;
}

void ShaderNode_hlb::setContentSize(const Size &newSize)
{
    Node::setContentSize(newSize);
    m_resolution = Vec2(newSize.width, newSize.height);
}

void ShaderNode_hlb::draw(Renderer *renderer, const Mat4 &transform, uint32_t flags)
{
    auto w = m_resolution.x;
    auto h = m_resolution.y;


    getGLProgram()->use();
    getGLProgram()->setUniformsForBuiltins(transform);


     /*绑定纹理到槽位*/
    GL::bindTexture2D( m_Texture->getName()); 

    

    /*截取屏幕数据到纹理*/
    //glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,   0, 0, w,  h,  0);


    /*传递attribute 变量值*/
    glEnableVertexAttribArray(m_attributePosition);  //开启顶点属性数组
    glDisableVertexAttribArray(m_attributeColor);  //颜色数据不多，不需要开启数组传递
    GLfloat vertices[12] = {  
        0, 0,
        w, 0, 
        w, h, 
        0, 0, 
        0, h, 
        w, h,
    };  
    glVertexAttribPointer(m_attributePosition, 2, GL_FLOAT, GL_FALSE, 0, vertices);  
    glVertexAttrib4fv(m_attributeColor, m_color);  


    //纹理坐标
    auto _maxS = m_Texture->getMaxS();
    auto _maxT = m_Texture->getMaxT();
    GLfloat coordinates[] = {
        0,          _maxT,
        _maxS,  _maxT,
        _maxS,  0,
        0,          _maxT,
        0,          0,
         _maxS, 0
    };
    glEnableVertexAttribArray(m_attributeTexCoord);
    glVertexAttribPointer(m_attributeTexCoord, 2, GL_FLOAT, GL_FALSE, 0, coordinates);


    getGLProgram()->setUniformLocationWith1i(m_uniformTex0, 0); 
    getGLProgram()->setUniformLocationWith1f(m_uniformDist,  m_rippleDistance);
    getGLProgram()->setUniformLocationWith1f(m_uniformRange,  m_rippleRange);



    /*开始绘制*/
    glDrawArrays(GL_TRIANGLES, 0, 6);  

    CHECK_GL_ERROR_DEBUG();
}

