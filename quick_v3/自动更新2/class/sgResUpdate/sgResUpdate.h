

// sgResUpdate.h
 
#ifndef sgResUpdate_H
 
#define sgResUpdate_H
 
#include "cocos2d.h"
#include "ui/CocosGUI.h"
#include "extensions/cocos-ext.h"
#include "AppDelegate.h"

USING_NS_CC_EXT;
USING_NS_CC;
using namespace cocos2d::ui;

class sgResUpdate : public Scene
{
public:
 
    sgResUpdate();
    ~sgResUpdate();

    static sgResUpdate* create();
    void onEnter();
    void checkUpdate();
    void startUpdate();
    void setDelegate(AppDelegate *delegate);    
    void initStrJson();
    std::string getStringByJsonKey(std::string key);    
    void showLoading();
    void showPopup(const std::function<void()> &func_yes,  const std::function<void()> &func_no, std::string strTips );
    void exitUpdate(bool cleanup);
    
private:
    AppDelegate *_delegate;
    AssetsManagerEx *_am;
    EventListenerAssetsManagerEx* _amListener;
    LoadingBar *_loadingBar;
    Node *_layer;
    Text *_tipLabel;
    int _totalSize;
    int _failCount;
    bool _downloadByUrl2; //当前使用备份下载点来下载
    rapidjson::Document _strJson;
};

#endif // sgResUpdate_H

