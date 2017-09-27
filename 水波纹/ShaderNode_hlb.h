
#ifndef SHADERNODE_HLB_H
#define SHADERNODE_HLB_H
#include "cocos2d.h"

USING_NS_CC;
class ShaderNode_hlb : public Node
{
public:
    static ShaderNode_hlb* createWithVertexFile(const std::string &name_vert, const std::string& name_frag);
    virtual void update(float dt);
    void setColor(const Color4F& color);
    virtual void setContentSize(const Size &newSize);
    virtual void draw(Renderer *renderer, const Mat4 &transform, uint32_t flags) override;

protected:
    ShaderNode_hlb();
    ~ShaderNode_hlb();
    bool initWithVertex(const std::string &vert, const std::string &frag);

    Vec2 m_resolution;
    float  m_time;
    GLfloat m_color[4];
    
    float m_rippleDistance;
    float m_rippleRange;
    
    Texture2D *m_Texture; 
    
    //attribute 标识
    GLuint m_attributePosition, m_attributeColor, m_attributeTexCoord;
    //uniform 标识
    GLuint m_uniformTex0, m_uniformDist, m_uniformRange;


    
};

#endif /*SHADERNODE_HLB_H*/

