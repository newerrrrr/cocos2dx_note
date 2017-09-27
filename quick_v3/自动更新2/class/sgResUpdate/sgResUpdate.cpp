
 
#include "sgResUpdate.h"
#include "cocostudio/CocoStudio.h"

#define RES_UPDATE_PATH     "ResUpdate"

sgResUpdate::sgResUpdate():_totalSize(0), _failCount(0),_downloadByUrl2(false),_amListener(nullptr),_tipLabel(nullptr),_loadingBar(nullptr)
{
   this->initStrJson();
}

sgResUpdate::~sgResUpdate()
{
    _eventDispatcher->removeEventListener(_amListener);
    _am->release();
}

sgResUpdate* sgResUpdate::create()
{
    CCLOG(" sgResUpdate::create ");

    sgResUpdate *node = new sgResUpdate();

    return node;
}

void sgResUpdate::onEnter()
{
    CCLOG(" sgResUpdate::onEnter ");
    Scene::onEnter();
/*
    std::vector<std::string> searchPaths = FileUtils::getInstance()->getSearchPaths();
    searchPaths.insert(searchPaths.begin(), "res/cocos");
    FileUtils::getInstance()->setSearchPaths(searchPaths);
*/
    std::string storagePath = FileUtils::getInstance()->getWritablePath() + RES_UPDATE_PATH;
    FileUtils::getInstance()->addSearchPath(storagePath + "/res/cocos/", true);
    FileUtils::getInstance()->addSearchPath(storagePath + "/res/", true);
    FileUtils::getInstance()->addSearchPath(storagePath + "/src/", true);    
    
    _layer = dynamic_cast<Node *>(CSLoader::createNode("resource_update.csb"));
    _layer->setVisible(false);
    auto winSize = Director::getInstance()->getWinSize();
    auto visibleSize = Director::getInstance()->getVisibleSize();
    auto scale = visibleSize.width / winSize.width;
    _layer->getChildByName("scale_node")->setScale(scale);
    _layer->setAnchorPoint(Vec2(0.5, 0.5));
    _layer->setPosition(Vec2(winSize.width/2, winSize.height/2));
    this->addChild(_layer); 


    auto node1 = _layer->getChildByName("scale_node")->getChildByName("Panel_1");
   
    
    _tipLabel = dynamic_cast<Text *>(node1->getChildByName("Text_1"));
    _tipLabel->setString("");
    _loadingBar = dynamic_cast<LoadingBar *>(node1->getChildByName("LoadingBar_1"));
    _loadingBar->setPercent(0);

    checkUpdate();
}


void sgResUpdate::checkUpdate()
{
    std::string storagePath = FileUtils::getInstance()->getWritablePath() + RES_UPDATE_PATH;
    _am = AssetsManagerEx::create("project.manifest",  storagePath);
    _am->retain();
    

    if (!_am->getLocalManifest()->isLoaded())
    {
        CCLOG("Fail to update assets, step skipped.");
    }
    else
    {
            _amListener = cocos2d::extension::EventListenerAssetsManagerEx::create(_am, [=](EventAssetsManagerEx* event){
            
            switch (event->getEventCode())
            {
                case EventAssetsManagerEx::EventCode::ALREADY_UP_TO_DATE:
                {
                    CCLOG("aready up to date..");
                    _delegate->startGame();
                }
                    break;

            
                case EventAssetsManagerEx::EventCode::NEW_VERSION_FOUND:
                {              
                    _totalSize = _am->getTotalSizeToDownload() / 1024;
                    CCLOG(" === has  new version found !!!");
                    CCLOG("     big version is equal: %d", _am->isBigVersionEqual());
                    CCLOG("     need to download size:%d KB", _totalSize);
                    
                                       
                    if (!_am->isBigVersionEqual())
                    {
                         this->showPopup([&](){this->exitUpdate(false);}, nullptr, this->getStringByJsonKey("newMajorVesion"));
                    }
                    else
                    {                    
                        if (_totalSize > 100)
                        {
                            std::string strTips = this->getStringByJsonKey("newVesion");                                                        
                            this->showPopup([&](){ this->startUpdate();}, [&](){this->exitUpdate(false);},  StringUtils::format(strTips.c_str(), _totalSize));
                        }
                        else 
                        {                            
                            this->startUpdate();
                        }
                    }
                }
                    break;
                    
                case EventAssetsManagerEx::EventCode::UPDATE_PROGRESSION:
                {
                    std::string assetId = event->getAssetId();
                    
                    if (assetId == AssetsManagerEx::VERSION_ID)
                    {
                        CCLOG("download version file percent:  %.2f ", event->getPercent());
                    }
                    else if (assetId == AssetsManagerEx::MANIFEST_ID)
                    {
                        CCLOG("download manifest file percent:  %.2f ", event->getPercent());
                    }
                    else
                    {
                        float percentByFiles = event->getPercentByFile();
                        CCLOG("update percent:  %.2f ", percentByFiles);
                        
                        _loadingBar->setPercent(percentByFiles);
                       // _tipLabel->setString(StringUtils::format("%d/%d KB", (int)(_totalSize*percentByFiles)/100, _totalSize));
                    }
                }
                    break;

                case  EventAssetsManagerEx::EventCode::DECOMPRESING:
                {
                    CCLOG(" begin decompressing zip files...");                    
                   _tipLabel->setString(this->getStringByJsonKey("decompresing"));
                }
                    break; 

                case  EventAssetsManagerEx::EventCode::DECOMPRES_OK:
                {
                    CCLOG(" decompressing ok");
                }
                    break; 
                                       
                case EventAssetsManagerEx::EventCode::UPDATE_FINISHED:
                {
                    CCLOG("Update finished, now start game...");
                     _tipLabel->setString(this->getStringByJsonKey("runningGame"));
                    //_delegate->startGame();
                    this->runAction(Sequence::create(DelayTime::create(1.0),  CallFunc::create([&](){_delegate->startGame(); }),  nullptr) );
                }
                    break;

                case EventAssetsManagerEx::EventCode::UPDATE_FAILED:
                {
                    CCLOG("updated fail:  _failCount=%d", _failCount);
                    
                    std::string strTips = this->getStringByJsonKey("updateFail");                                                        
                    this->showPopup([&](){this->showLoading(); _am->downloadFailedAssets();}, [&](){this->exitUpdate(false);},  strTips);
                }
                    break;
                    
                case EventAssetsManagerEx::EventCode::ERROR_NO_LOCAL_MANIFEST:
                {
                    CCLOG("No local manifest file found, skip assets update.");
                }
                    break;
                    
                case EventAssetsManagerEx::EventCode::ERROR_DOWNLOAD_MANIFEST:
                {
                    CCLOG("Fail to download manifest file. _downloadByUrl2 = %d", _downloadByUrl2);
                    if (_downloadByUrl2)
                    {
                       CCLOG("update fail by using url2,  exit update.");
                    }
                    else
                    {
                        _downloadByUrl2 = true;
                        
                        //try to use url2 to update
                        if ( !_am->downloadManifestByUrl2())
                        {
                            CCLOG("no url2,  exit update.");
                        }
                    }
                }
                    break;
                    
                case EventAssetsManagerEx::EventCode::ERROR_PARSE_MANIFEST:
                {
                    CCLOG("parse manifest error !");
                }
                    break;


                    
                case EventAssetsManagerEx::EventCode::ERROR_UPDATING:
                {
                    CCLOG("updating file fail: %s : %s", event->getAssetId().c_str(), event->getMessage().c_str());
                }
                    break;
                    
                case EventAssetsManagerEx::EventCode::ERROR_DECOMPRESS:
                {
                    CCLOG("decompress error ! %s", event->getMessage().c_str());
                }
                    break;
                    
                default:
                    
                    break;
            }
        });
            
        Director::getInstance()->getEventDispatcher()->addEventListenerWithFixedPriority(_amListener, -10);        
        //_am->update();
        _am->checkUpdate(); /*先检查版本号, 有更新则会在返回的EventCode::NEW_VERSION_FOUND 消息后调用_am->update() 下载更新包*/
        
    }
        
}

void sgResUpdate::startUpdate()
{
    CCLOG(" sgResUpdate::startUpdate ");
    this->showLoading();
    assert(_am);
    //_am->update();  
    this->runAction(Sequence::create(DelayTime::create(0.3),  CallFunc::create([&](){_am->update(); }),  nullptr) );
}

void sgResUpdate::setDelegate(AppDelegate *delegate) 
{
    _delegate = delegate;
}

void sgResUpdate::initStrJson()
{
    std::string filepath = "src/localization/strings";
    if(FileUtils::getInstance()->isFileExist(filepath))
    {
        // Load file content
        std::string content = FileUtils::getInstance()->getStringFromFile(filepath);        
        // Parse file with rapid json
        _strJson.Parse<0>(content.c_str());
        
        if (_strJson.HasParseError()) 
        {
            size_t offset = _strJson.GetErrorOffset();
            if (offset > 0)
                offset--;
            std::string errorSnippet = content.substr(offset, 10);
            CCLOG("File parse error %d at <%s>\n", _strJson.GetParseError(), errorSnippet.c_str());
        }        
    }

    if(_strJson.IsObject())
    {
        if ( _strJson.HasMember("newVesion") && _strJson["newVesion"].IsString() )
        {
            std::string st = _strJson["newVesion"].GetString();
            int k=0;
        }
    }
}

 std::string sgResUpdate::getStringByJsonKey(std::string key)
{
    std::string str = key;
    if ( _strJson.HasMember(key.c_str()) && _strJson[key.c_str()].IsString() )
    {
        str = _strJson[key.c_str()].GetString();
    }  
    return str;
}

void sgResUpdate::showLoading()
{
    _layer->setVisible(true);
    _layer->getChildByName("scale_node")->getChildByName("Panel_1")->setVisible(true);
    _layer->getChildByName("scale_node")->getChildByName("Panel_2")->setVisible(false);
    _tipLabel->setString(this->getStringByJsonKey("updating"));
}

void sgResUpdate::showPopup(const std::function<void()> &func_yes,  const std::function<void()> &func_no, std::string tips )
{
    CCLOG(" sgResUpdate::showDownloadSizePop ");

    _layer->setVisible(true);
    _layer->getChildByName("scale_node")->getChildByName("Panel_1")->setVisible(false);
    
    auto node2 = _layer->getChildByName("scale_node")->getChildByName("Panel_2");
    auto lbTititle = dynamic_cast<Text *>(node2->getChildByName("Text_1"));
    auto lbTips = dynamic_cast<Text *>(node2->getChildByName("Text_2"));
    auto lbConfirm = dynamic_cast<Text *>(node2->getChildByName("Text_3"));
    auto lbCancle = dynamic_cast<Text *>(node2->getChildByName("Text_5"));
    std::string strTitle = this->getStringByJsonKey("resUpdateTitle");
    std::string strTips = this->getStringByJsonKey("newVesion");
    std::string strConfirm = this->getStringByJsonKey("conform");
    std::string strCancle = this->getStringByJsonKey("cancle");    
    node2->setVisible(true);    
    lbTititle->setString(strTitle);
    lbTips->setString(tips);
    lbConfirm->setString(strConfirm);
    lbCancle->setString(strCancle);

    auto btn_yes = dynamic_cast<Button *>(node2->getChildByName("btn_1"));
    auto btn_no = dynamic_cast<Button *>(node2->getChildByName("btn_2"));
    btn_yes->addClickEventListener([btn_yes, this, func_yes](Ref* sender)
                                                    {
                                                        if (func_yes)
                                                            func_yes();
                                                    });
    
    btn_no->addClickEventListener([btn_no, this, func_no](Ref* sender)
                                                    {
                                                        CCLOG(" sgResUpdate::cancelUpdate ");  
                                                        if (func_no)
                                                            func_no();
                                                    });

    if (nullptr == func_no)
    {
        auto pos = Vec2( (btn_yes->getPositionX()+btn_no->getPositionX())/2, btn_yes->getPositionY());
        btn_yes->setPosition(pos);
        lbConfirm->setPosition(pos);
        btn_no->setVisible(false);
        lbCancle->setVisible(false);
    }
}

void sgResUpdate::exitUpdate(bool cleanup)
{
    if (_am && cleanup)
    {
        _am->destroyDownloadedTmp();
    }
    _delegate->exitGame();
}

