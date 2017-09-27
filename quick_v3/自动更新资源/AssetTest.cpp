
 
#include "AssetTest.h"



AssetTest::AssetTest()
{
}

AssetTest::~AssetTest()
{
}

AssetTest* AssetTest::create()
{
    CCLOG(" AssetTest::create ");

    AssetTest *node = new AssetTest();

    return node;
}

void AssetTest::onEnter()
{
    Scene::onEnter();
    
    CCLOG(" AssetTest::onEnter ");

    auto layer = Layer::create();
    auto label = Label::create("kkkk",  "Arial", 24.0f);
    label->setPosition(Vec2(300, 300));
    layer->addChild(label);
    this->addChild(layer);    
    
    
    std::string storagePath = FileUtils::getInstance()->getWritablePath() + "hlb_asset";
    _am = AssetsManagerEx::create("res/HLB_ASSET/project.manifest",  storagePath);
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
                case EventAssetsManagerEx::EventCode::ERROR_NO_LOCAL_MANIFEST:
                {
                    CCLOG("No local manifest file found, skip assets update.");
                }
                    break;

                case EventAssetsManagerEx::EventCode::NEW_VERSION_FOUND:
                {
                    CCLOG(" has  new version found !!!");
                    _am->update();
                }
                    break;

                    
                case EventAssetsManagerEx::EventCode::UPDATE_PROGRESSION:
                {
                    std::string assetId = event->getAssetId();
                    float percent = event->getPercent();
                    std::string str;
                    if (assetId == AssetsManagerEx::VERSION_ID)
                    {
                        str = StringUtils::format("Version file: %.2f", percent) + "%";
                    }
                    else if (assetId == AssetsManagerEx::MANIFEST_ID)
                    {
                        str = StringUtils::format("Manifest file: %.2f", percent) + "%";
                    }
                    else
                    {
                        str = StringUtils::format("%.2f", percent) + "%";
                        CCLOG("%.2f Percent", percent);
                    }
                }
                    break;
                case EventAssetsManagerEx::EventCode::ERROR_DOWNLOAD_MANIFEST:
                case EventAssetsManagerEx::EventCode::ERROR_PARSE_MANIFEST:
                {
                    CCLOG("Fail to download manifest file, update skipped.");
                }
                    break;
                case EventAssetsManagerEx::EventCode::ALREADY_UP_TO_DATE:
                case EventAssetsManagerEx::EventCode::UPDATE_FINISHED:
                {
                    CCLOG("Update finished--. %s", event->getMessage().c_str());
                }
                    break;
                case EventAssetsManagerEx::EventCode::UPDATE_FAILED:
                {
                    CCLOG("Update failed. %s", event->getMessage().c_str());
                    /*
                        failCount ++;
                        if (failCount < 5)
                        {
                            _am->downloadFailedAssets();
                        }
                        else
                        {
                            CCLOG("Reach maximum fail count, exit update process");
                            failCount = 0;
                            scene = new AssetsManagerExTestScene(backgroundPaths[currentId]);
                            Director::getInstance()->replaceScene(scene);
                            scene->release();
                        }
                    */
                }
                    break;
                case EventAssetsManagerEx::EventCode::ERROR_UPDATING:
                {
                    CCLOG("Asset %s : %s", event->getAssetId().c_str(), event->getMessage().c_str());
                }
                    break;
                case EventAssetsManagerEx::EventCode::ERROR_DECOMPRESS:
                {
                    CCLOG("%s", event->getMessage().c_str());
                }
                    break;
                default:
                    break;
            }
        });
            
        Director::getInstance()->getEventDispatcher()->addEventListenerWithFixedPriority(_amListener, 1);        
        //_am->update();
        _am->checkUpdate(); /*先检查版本号, 有更新则会在返回的EventCode::NEW_VERSION_FOUND 消息后调用_am->update() 下载更新包*/
        
    }
    
}



