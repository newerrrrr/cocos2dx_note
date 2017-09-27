

// testClass.h
 
#ifndef __CUSTOM__CLASS
 
#define __CUSTOM__CLASS
 
#include "cocos2d.h"
 
namespace cocos2d {
class testClass : public cocos2d::Ref
{
public:
 
    testClass();

    ~testClass();
 
    static testClass* create();
    void ignorFunction();
};

} //namespace cocos2d
 
#endif // __CUSTOM__CLASS

