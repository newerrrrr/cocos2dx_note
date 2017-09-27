

// AssetTest.h
 
#ifndef __CUSTOM__CLASS
 
#define __CUSTOM__CLASS
 
#include "cocos2d.h"
#include "extensions/cocos-ext.h"

USING_NS_CC_EXT;
USING_NS_CC;

class AssetTest : public Scene
{
public:
 
    AssetTest();

    ~AssetTest();
 
    static AssetTest* create();
    void onEnter();

private:
    AssetsManagerEx *_am;
    EventListenerAssetsManagerEx* _amListener;
 
};

#endif // __CUSTOM__CLASS

