#include "AppDelegate.h"
#include "CCLuaEngine.h"
#include "SimpleAudioEngine.h"
#include "cocos2d.h"
#include "lua_module_register.h"
#include "reStartScene/reStartScene.h"
#include "httpNet/httpNet.h"

#if (CC_TARGET_PLATFORM != CC_PLATFORM_LINUX)
#include "ide-support/CodeIDESupport.h"
#endif

#if (COCOS2D_DEBUG > 0) && (CC_CODE_IDE_DEBUG_SUPPORT > 0)
#include "runtime/Runtime.h"
#include "ide-support/RuntimeLuaImpl.h"
#endif

#include "sgResUpdate/sgResUpdate.h"
#include "sgNet/NetLua.h"
#include "sgHttp/sgHttpLua.h"
#include "common/PSDeviceInfoLua.h"


#include "gameDelegate/gameDelegate.h"
#include "forLua/forLua.h"
#include "forLua/luaBindFunction.h"
#include "forLua/cToolsForLua.h"
#include "payment/paymentForLua.h"
#include "cTools_Control/lua_cTools_Control_auto.hpp"
#include "cjson/lua_cjson.h"

#include "sgResUpdate/sgResUpdate.h"
#include "sgResUpdate/ResUpdateEx.h"
#include "sgResUpdate/ResUpdateExLua.h"

using namespace CocosDenshion;

USING_NS_CC;
using namespace std;

AppDelegate::AppDelegate()
{

}

AppDelegate::~AppDelegate()
{
    SimpleAudioEngine::end();

	luaBindFunction::destroyInstance();
	gameDelegate::destroyInstance();

#if (COCOS2D_DEBUG > 0) && (CC_CODE_IDE_DEBUG_SUPPORT > 0)
    // NOTE:Please don't remove this call if you want to debug with Cocos Code IDE
    RuntimeEngine::getInstance()->end();
#endif

}

//if you want a different context,just modify the value of glContextAttrs
//it will takes effect on all platforms
void AppDelegate::initGLContextAttrs()
{
    //set OpenGL context attributions,now can only set six attributions:
    //red,green,blue,alpha,depth,stencil
    GLContextAttrs glContextAttrs = {8, 8, 8, 8, 24, 8};

    GLView::setGLContextAttrs(glContextAttrs);
}

// If you want to use packages manager to install more packages,
// don't modify or remove this function
static int register_all_packages()
{
    return 0; //flag for packages manager
}

bool AppDelegate::applicationDidFinishLaunching()
{
    // set default FPS
    Director::getInstance()->setAnimationInterval(1.0 / 60.0f);
    Director::getInstance()->setDisplayStats(false);
	Director::getInstance()->setpulsDirectorDelegate(gameDelegate::getInstance());
	cToolsForLua::init(this);


    // register lua module
    auto engine = LuaEngine::getInstance();
    ScriptEngineManager::getInstance()->setScriptEngine(engine);
    LuaStack* stack = engine->getLuaStack();
    lua_State* L = stack->getLuaState();

    lua_module_register(L);

    register_all_packages();

    register_sgNet_luabinding(L);   //net 
    register_sgHttp_luabinding(L);  //http
    register_PSDeviceInfo_luabinding(L); //device info
    register_all_cTools_Control(L);

    luaopen_cjson(L); //cjson

    tolua_forLua_open(L);
    cToolsForLua::cTools_manual(L); //lua ctools manual
	paymentForLua::paymentForLua_manual(L);
    register_ResUpdateEx_luabinding(L);

	runGame();
    
    return true;
}

// This function will be called when the app is inactive. When comes a phone call,it's be invoked too
void AppDelegate::applicationDidEnterBackground()
{
	gameDelegate::getInstance()->applicationDidEnterBackground();
}

// this function will be called when the app is active again
void AppDelegate::applicationWillEnterForeground()
{
	gameDelegate::getInstance()->applicationWillEnterForeground();
}

void AppDelegate::runGame()
{
#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
	startGame();
#else
	resUpdate();
#endif
}

void AppDelegate::resUpdate()
{
	auto storagePath = FileUtils::getInstance()->getWritablePath() + "ResUpdate";
	std::vector<std::string> remvoeList;
	remvoeList.push_back(storagePath);
	cToolsForLua::removeSearchPaths(remvoeList);
	FileUtils::getInstance()->addSearchPath(storagePath, true);
    LuaEngine::getInstance()->executeScriptFile("src/resUpdate/UpdateEntry.lua");
}

void AppDelegate::startGame()
{
#if (COCOS2D_DEBUG > 0) && (CC_CODE_IDE_DEBUG_SUPPORT > 0)
    // NOTE:Please don't remove this call if you want to debug with Cocos Code IDE
    auto runtimeEngine = RuntimeEngine::getInstance();
    runtimeEngine->addRuntime(RuntimeLuaImpl::create(), kRuntimeEngineLua);
    runtimeEngine->start();
#else
    LuaEngine::getInstance()->executeScriptFile("src/main.lua");
#endif
}


static void s_clear_node_all(Node * node, EventDispatcher * eventDispatcher)
{
	Vector<Node*> vec = node->getChildren();
	for (Vector<Node*>::iterator it = vec.begin(); it != vec.end(); it++)
	{
		(*it)->unscheduleUpdate();
		(*it)->unscheduleAllCallbacks();
		if (eventDispatcher)
			eventDispatcher->resumeEventListenersForTarget((*it), false);
		s_clear_node_all((*it), eventDispatcher);
	}
}

void AppDelegate::reStartGame()
{
	httpNet::getInstance()->DiscardAllPost();

	EventDispatcher * eventDispatcher = Director::getInstance()->getEventDispatcher();
	if (eventDispatcher)
		eventDispatcher->setDiscardAllTouchEndEventToCancelled();

	Node * scene = Director::getInstance()->getRunningScene();
	if (scene)
	{
		s_clear_node_all(scene, eventDispatcher);
		Vector<Node*> vec = scene->getChildren();
		for (Vector<Node*>::iterator it = vec.begin(); it != vec.end(); it++)
			(*it)->removeFromParentAndCleanup(true);
	}

	Scheduler * scheduler = Director::getInstance()->getScheduler();
	if (scheduler)
		scheduler->unscheduleScriptAll();

	luaBindFunction::getInstance()->removeAllLuaFunction();

	lua_gc(LuaEngine::getInstance()->getLuaStack()->getLuaState(), LUA_GCCOLLECT, 0);

	Scene * newScene = Scene::create();
	newScene->addChild(reStartScene::create(this));
	if (Director::getInstance()->getRunningScene())
		Director::getInstance()->replaceScene(newScene);
	else
		Director::getInstance()->runWithScene(newScene);
}

void AppDelegate::exitGame()
{
    Director::getInstance()->end();
#if CC_TARGET_PLATFORM == CC_PLATFORM_IOS
    exit(0);   
#endif
}

