/****************************************************************************
 Copyright (c) 2010-2013 cocos2d-x.org
 Copyright (c) 2013-2014 Chukong Technologies Inc.

 http://www.cocos2d-x.org

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 ****************************************************************************/

#import <UIKit/UIKit.h>
#import "cocos2d.h"

#import "AppController.h"
#import "AppDelegate.h"
#import "RootViewController.h"
#import "platform/ios/CCEAGLView-ios.h"
#include "../../Classes/platform/ios/ClientInfo.h"
#include "../../Classes/platform/ios/asynchronousBox_ios.h"
#include "../../Classes/sdkHelp/ios/sdk_help.h"
#include "forLua/cToolsForLua.h"

//#import "ReYunTrack.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <YLSDK/YLSDK.h>
//#import <QWKit/QWKit.h>

//#import "AppsFlyerTracker.h"

@implementation AppController

#pragma mark -
#pragma mark Application lifecycle

// cocos2d application instance
static AppDelegate s_sharedApplication;
static RootViewController *s_rootview;
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    
    //qw
    //[self initQW];

    //haowan
    [self initHW];

    //facebook
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];

    cocos2d::Application *app = cocos2d::Application::getInstance();
    app->initGLContextAttrs();
    cocos2d::GLViewImpl::convertAttrs();

    // Override point for customization after application launch.

    // Add the view controller's view to the window and display.
    window = [[UIWindow alloc] initWithFrame: [[UIScreen mainScreen] bounds]];
    CCEAGLView *eaglView = [CCEAGLView viewWithFrame: [window bounds]
                                     pixelFormat: (NSString*)cocos2d::GLViewImpl::_pixelFormat
                                     depthFormat: cocos2d::GLViewImpl::_depthFormat
                              preserveBackbuffer: NO
                                      sharegroup: nil
                                   multiSampling: NO
                                 numberOfSamples: 0 ];

    [eaglView setMultipleTouchEnabled:YES];
    
    // Use RootViewController manage CCEAGLView
    viewController = [[RootViewController alloc] initWithNibName:nil bundle:nil];
    viewController.wantsFullScreenLayout = YES;
    viewController.view = eaglView;
    s_rootview = viewController;
    asynchronousBox_ios::setWindows(window);
    
    
    // Set RootViewController to window
    if ( [[UIDevice currentDevice].systemVersion floatValue] < 6.0)
    {
        // warning: addSubView doesn't work on iOS6
        [window addSubview: viewController.view];
    }
    else
    {
        // use this method on ios6
        [window setRootViewController:viewController];
    }
    
    [window makeKeyAndVisible];

    [[UIApplication sharedApplication] setStatusBarHidden: YES];

    // IMPORTANT: Setting the GLView should be done after creating the RootViewController
    cocos2d::GLView *glview = cocos2d::GLViewImpl::createWithEAGLView(eaglView);
    cocos2d::Director::getInstance()->setOpenGLView(glview);

    
    //          appId  appKey  appSecret   SDK
    [GeTuiSdk startSdkWithAppId:kGtAppId appKey:kGtAppKey appSecret:kGtAppSecret
                       delegate:self];
    
    //appsflyer
    [AppsFlyerTracker sharedTracker].appsFlyerDevKey = @"oGb6cApNBeVH4iGMYPW2cW";
    [AppsFlyerTracker sharedTracker].appleAppID = @"1233585940";
    
    //   APNS
    [self registerUserNotification];
    
    //reyun sdk
    //[ReYunChannel initWithappKey:@"72c6691d3bb1cfd89621a0eda8514096"
                   //withChannelId:@"_default_"];
    
    
    
    
	// Send device information to DSUC
	NSThread *thread= [[[NSThread alloc] initWithTarget:self selector:@selector(collectInformation) object:nil] autorelease];
    [thread start];
	
    app->run();
    return YES;
}





- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation
            ];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options {
    return [[FBSDKApplicationDelegate sharedInstance] application:app
                                                          openURL:url
                                                sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                                                       annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    cocos2d::Director::getInstance()->pause();
}


- (void) onConversionDataReceived:(NSDictionary*) installData
{
    NSLog(@"\n>>>[appsFlyer onConversionDataReceived]");
    
    id status = [installData objectForKey:@"af_status"];
    if([status isEqualToString:@"Non-organic"]) {
        id sourceID = [installData objectForKey:@"media_source"];
        id campaign = [installData objectForKey:@"campaign"];
        NSLog(@"This is a none organic install. Media source: %@  Campaign: %@",sourceID,campaign);
        [SdkHelp setAppInstallData:installData];
    } else if([status isEqualToString:@"Organic"]) {
        NSLog(@"This is an organic install.");
        [SdkHelp setAppInstallData:installData];
    }
    
}

- (void) onConversionDataRequestFailure:(NSError *)error
{
     NSLog(@"\n>>>[appsFlyer onConversionDataRequestFailure error]:%@\n\n", [error localizedDescription]);
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    
    //appsflyer
    
    // load the conversion data
    [AppsFlyerTracker sharedTracker].delegate = self;
    
    // Track Installs, updates & sessions(app opens)
    [[AppsFlyerTracker sharedTracker] trackAppLaunch];
    
    //Facebook 记录应用激活
    [FBSDKAppEvents activateApp];
    
    cocos2d::Director::getInstance()->resume();
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
    cocos2d::Application::getInstance()->applicationDidEnterBackground();
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
    cocos2d::Application::getInstance()->applicationWillEnterForeground();
}

- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}


/** APNS */
- (void)registerUserNotification {
#ifdef __IPHONE_8_0
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        UIUserNotificationType types = (UIUserNotificationTypeAlert |
                                        UIUserNotificationTypeSound |
                                        UIUserNotificationTypeBadge);
        UIUserNotificationSettings *settings;
        settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    } else {
        UIRemoteNotificationType apn_type = (UIRemoteNotificationType)(UIRemoteNotificationTypeAlert |UIRemoteNotificationTypeSound | UIRemoteNotificationTypeBadge);
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:apn_type];
    }
#else
    UIRemoteNotificationType apn_type = (UIRemoteNotificationType)(UIRemoteNotificationTypeAlert |UIRemoteNotificationTypeSound | UIRemoteNotificationTypeBadge);
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:apn_type];
#endif
}

/** 远程通知注册成功委托 */
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"\n>>>[DeviceToken Success]:%@\n\n", token);
    // [3]:向个推服务器注册deviceToken
    [GeTuiSdk registerDeviceToken:token];
    if (token)
    {
        const char * pUtf8 = [token UTF8String];
        if (pUtf8)
            cToolsForLua::s_ios_deviceToken = pUtf8;
    }
}

//后台刷新数据
-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler
{
    //background fetch 恢复sdk 运行
    [GeTuiSdk resume];
    completionHandler(UIBackgroundFetchResultNewData);
}

/** SDK      cid */
- (void)GeTuiSdkDidRegisterClient:(NSString *)clientId {
    NSLog(@"\n>>>[GeTuiSdk RegisterClient]:%@\n\n", clientId);
}

/** SDK遇到错误回调 */
- (void)GeTuiSdkDidOccurError:(NSError *)error {
    NSLog(@"\n>>>[GexinSdk error]:%@\n\n", [error localizedDescription]);
}

/** 抢玩登录 */
+ (void)loginQW:(NSDictionary *)dict{
    NSLog(@"登录成功");
    
    if( s_rootview != nil)
    {
        [[YLApi YL_sharedInstance] YL_addLoginView:s_rootview.view
            completion:^(NSDictionary *resultDic) {
            NSLog(@"[showLogin] resultDic = %@", resultDic);
            NSNumber *loginresult = [resultDic objectForKey:@"loginresult"];
            if([loginresult intValue] == YLLOGINSuccess){
                NSLog(@"登录成功");
                NSString *uid = [resultDic objectForKey:@"userId"];
                NSString *token = [resultDic objectForKey:@"token"];
                NSLog(@"uid = %@",uid);
                NSLog(@"token = %@",token);
                
                [SdkHelp loginQWToLua:dict tokenStr:token uidStr:uid];
                //[[YLApi YL_sharedInstance] YL_cplPlayerInfo:YL_CreateRoleColl uid:@"1" server_name:@"1" player_name:@"1" player_level:@"1" ctime:@"1"];
                //----------如需二次验证可向服务端验证uid和token---------
            }
        }];
        
    }
    else
        NSLog(@"rootview is nil");
    
    //退出登录的回调方法,需要在这里处理游戏返回到登录页面的逻辑，如果实现了返回登录页面的逻辑，请记得一定要调用[[YLApi YL_sharedInstance] YL_mcLogout];方法注销账户
    [[YLApi YL_sharedInstance] YL_exitLogin:^(NSDictionary *resultDic) {
        NSLog(@"resultDic:%@",resultDic);
        NSLog(@"退出登录");
        [SdkHelp logoutQWToLua:dict];
        [[YLApi YL_sharedInstance] YL_mcLogout]; //如果没有实现了返回登录页面的逻辑，请注释掉此方法
        //下面处理回到游戏登录页面的方法
        
    }];
    
}


-(void)initQW{
    //初始化“抢玩”SDK,传入游戏信息
    GameAppInfo *game = [[GameAppInfo alloc] init];
    game.gameId = @"492";//应用id
    game.gameName = @"掠夺三国";//应用名称
    game.gameAppId = @"BD8EDD83734FBE7C2";//应用Appid
    game.promoteId = @"2737";//正式（提审）推广id
    game.promoteAccount = @"QW0489";//正式（提审）推广名称
    game.is_test = @"1";//是否测试，0 正式（提审）版 |  1 测试版
    //------------此处trackKey要替换为相应的热云key----------------------------------
    //------------创建角色调用[[QWApi qw_sharedInstance] qw_createRoleSuccess]方法-------------------
    [[YLApi YL_sharedInstance] YL_setYLApiWithInfo:game trackKey:@"0bdfbd8462aeacd50591a70454b8e4ae" completion:^(NSDictionary *resultDic) {
        NSLog(@"[init] resultDic:%@",resultDic);
        NSNumber *statusCode = [resultDic objectForKey:@"statusCode"];
        if ([statusCode intValue] == YLINITSuccess) {
            //初始化成功
            //如需自动登录，在此处处理自动登录逻辑
        }
    }];

}

/** 好玩登录 */
+ (void)loginHW:(NSDictionary *)dict{
    NSLog(@"登录成功");
    
    if( s_rootview != nil)
    {
        [[YLApi YL_sharedInstance] YL_addLoginView:s_rootview.view
            completion:^(NSDictionary *resultDic) {
            NSLog(@"[showLogin] resultDic = %@", resultDic);
            NSNumber *loginresult = [resultDic objectForKey:@"loginresult"];
            if([loginresult intValue] == YLLOGINSuccess){
                NSLog(@"登录成功");
                NSString *uid = [resultDic objectForKey:@"userId"];
                NSString *token = [resultDic objectForKey:@"token"];
                NSLog(@"uid = %@",uid);
                NSLog(@"token = %@",token);
                
                [SdkHelp loginHWToLua:dict tokenStr:token uidStr:uid];
                //[[YLApi YL_sharedInstance] YL_cplPlayerInfo:YL_CreateRoleColl uid:@"1" server_name:@"1" player_name:@"1" player_level:@"1" ctime:@"1"];
                //----------如需二次验证可向服务端验证uid和token---------
            }
        }];
        
    }
    else
        NSLog(@"rootview is nil");
    
    //退出登录的回调方法,需要在这里处理游戏返回到登录页面的逻辑，如果实现了返回登录页面的逻辑，请记得一定要调用[[YLApi YL_sharedInstance] YL_mcLogout];方法注销账户
    [[YLApi YL_sharedInstance] YL_exitLogin:^(NSDictionary *resultDic) {
        NSLog(@"resultDic:%@",resultDic);
        NSLog(@"退出登录");
        [SdkHelp logoutHWToLua:dict];
        [[YLApi YL_sharedInstance] YL_mcLogout]; //如果没有实现了返回登录页面的逻辑，请注释掉此方法
        //下面处理回到游戏登录页面的方法
        
    }];
    
}


-(void)initHW{
    //初始化“抢玩”SDK,传入游戏信息
    GameAppInfo *game = [[GameAppInfo alloc] init];
    game.gameId = @"492";//应用id
    game.gameName = @"掠夺三国";//应用名称
    game.gameAppId = @"BD8EDD83734FBE7C2";//应用Appid
    game.promoteId = @"2737";//正式（提审）推广id
    game.promoteAccount = @"QW0489";//正式（提审）推广名称
    game.is_test = @"1";//是否测试，0 正式（提审）版 |  1 测试版
    //------------此处trackKey要替换为相应的热云key----------------------------------
    //------------创建角色调用[[YLApi YL_sharedInstance] YL_createRoleSuccess]方法-------------------
    [[YLApi YL_sharedInstance] YL_setYLApiWithInfo:game trackKey:@"0bdfbd8462aeacd50591a70454b8e4ae" completion:^(NSDictionary *resultDic) {
        NSLog(@"[init] resultDic:%@",resultDic);
        NSNumber *statusCode = [resultDic objectForKey:@"statusCode"];
        if ([statusCode intValue] == YLINITSuccess) {
            //初始化成功
            //如需自动登录，在此处处理自动登录逻辑
        }
    }];

}


-(void) collectInformation{
    ClientInfo *info = [[ClientInfo sharedClientInfo] autorelease];
    info.payHost = @"pay.m543.com";
    info.gameHost= @"s1001.sanguomobile2.com";
	std::string dsucUrl = "http://u.m543.com";
    dsucUrl += "/device/record";
    info.postUrl = [NSString stringWithUTF8String:dsucUrl.c_str()];
    [info ping:info.gameHost];
}

#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
     cocos2d::Director::getInstance()->purgeCachedData();
}


- (void)dealloc {
    [super dealloc];
}


@end

