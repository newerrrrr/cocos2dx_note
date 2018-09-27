/****************************************************************************
 Copyright (c) 2010-2013 cocos2d-x.org
 Copyright (c) 2013-2016 Chukong Technologies Inc.
 
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

#import "AppController.h"
#import "cocos2d.h"
#import "AppDelegate.h"
#import "RootViewController.h"
#import "platform/ios/CCEAGLView-ios.h"
#import "jstools.h"
#import "JSONKit.h"
#import "iospay.h"
#import "yayavoice.h"
#import "Reachability.h"
#import "locationtool.h"

//umeng  add
#include "UMMobClick/MobClick.h"
//TalkingData add
#include "TalkingData.h"

@implementation AppController

@synthesize window;

#pragma mark -
#pragma mark Application lifecycle

// cocos2d application instance
static AppDelegate s_sharedApplication;

static AppController *static_self;

/************************URL Open APP**************************/
static NSString* roomid = NULL;
static NSString* shareCode = NULL;
static bool appIsDidEnterBackground = false;

+(NSString *) getAppVersion{
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

+(NSString *) getRoomId{
    if(roomid != NULL){
        NSString * rte = [NSString stringWithString:roomid];
        [roomid release];
        roomid = NULL;
        return rte;
    }
    return roomid;
}
+(NSString *) getTextFromBoard{
     UIPasteboard* pboard=[UIPasteboard generalPasteboard];
    NSLog(@"%@", pboard.string);
    if (pboard.string !=NULL)
    {
        return pboard.string;
    }
    return @"www";
}

+(NSString *) getShareCode {
	 if(shareCode != NULL){
        NSString * rte = [NSString stringWithString:shareCode];
        [shareCode release];
        shareCode = NULL;
        return rte;
    }
    return shareCode;
}
+ (BOOL)GPSStart
{
    NSLog(@"record Gpsstart");//待测试
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    return true;
    
    
}
+ (BOOL)isGPSStart
{
    NSLog(@"record Gpsstart");
     BOOL isOPen = NO;  
    if ([CLLocationManager locationServicesEnabled] && [CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied) {  
        isOPen = YES;  
    }  
    return isOPen;
    
    
}
+(BOOL) copyTextToClipboard:(NSDictionary *)dict
{
    NSString* text = [dict objectForKey:@"text"];
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = text;
    return 0;
}

+(NSInteger)setOrientation:(NSDictionary *)dict
{
    NSString* strOrien = [dict objectForKey:@"strOrien"];
    NSString* strLanp = @"landscape";

    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationUnknown] forKey:@"orientation"];
    
    if ([strOrien isEqualToString:strLanp]) {//landscape
        static_self.viewController.myOrientation = UIInterfaceOrientationLandscapeRight;
        static_self.viewController.myOrientationMask = UIInterfaceOrientationMaskLandscape;
        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationLandscapeRight] forKey:@"orientation"];
    }
    else{
        static_self.viewController.myOrientation = UIInterfaceOrientationPortrait;
        static_self.viewController.myOrientationMask = UIInterfaceOrientationMaskPortrait;
        [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIInterfaceOrientationPortrait] forKey:@"orientation"];
    }
    return 0;
}

+(BOOL) checkAppLink : (NSURL *)url{
    NSString *query = url.query;
    NSLog(@"url: %@", [url absoluteString]);
    NSLog(@"url query: %@", query);
    NSArray * pairs=[query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params=[[NSMutableDictionary alloc] init];
    for (NSString *pair in pairs) {
        NSArray *kv=[pair componentsSeparatedByString:@"="];
        if(kv.count==2)
        {
            NSString *val=[[kv objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [params setObject:val forKey:[kv objectAtIndex:0]];
        }
    }
    NSString *roomidStr=[params objectForKey:@"roomid"];
    if(roomidStr){
        if(appIsDidEnterBackground){
            NSMutableDictionary *data  = [[NSMutableDictionary alloc] init];
            [data setValue:@"urlOpen" forKey:@"type"];
            NSString * roomdata = [NSString stringWithFormat:@"a%@", roomidStr];
            [data setValue:roomdata forKey:@"code"];
            [jstools sendToLuaByWxCode:[data JSONString]];
            [data release];
        }else{
            roomid = roomidStr;
            [roomid retain];
        }
    }
	
	NSString *shareCodeStr=[params objectForKey:@"share_code"];
    if(shareCodeStr){
        if(appIsDidEnterBackground){
            NSMutableDictionary *data  = [[NSMutableDictionary alloc] init];
            [data setValue:@"urlOpen" forKey:@"type"];
            NSString * shareCodedata = [NSString stringWithFormat:@"a%@", shareCodeStr];
            [data setValue:shareCodedata forKey:@"share_code"];
            [jstools sendToLuaByWxCode:[data JSONString]];
            [data release];
        }else{
            shareCode = shareCodeStr;
            [shareCode retain];
        }
    }
	
    return YES;
}

-(BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler{
    if([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]){
        NSURL *webpageURL = userActivity.webpageURL;
        [AppController checkAppLink:webpageURL];
    }
    return YES;
}
/*************************************************/
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
 {
     static_self = self;
     
    cocos2d::Application *app = cocos2d::Application::getInstance();
    
    // Initialize the GLView attributes
    app->initGLContextAttrs();
    cocos2d::GLViewImpl::convertAttrs();
    
    // Override point for customization after application launch.

    // Add the view controller's view to the window and display.
    window = [[UIWindow alloc] initWithFrame: [[UIScreen mainScreen] bounds]];

    // Use RootViewController to manage CCEAGLView
    _viewController = [[RootViewController alloc]init];
    _viewController.wantsFullScreenLayout = YES;
    

    // Set RootViewController to window
    if ( [[UIDevice currentDevice].systemVersion floatValue] < 6.0)
    {
        // warning: addSubView doesn't work on iOS6
        [window addSubview: _viewController.view];
    }
    else
    {
        // use this method on ios6
        [window setRootViewController:_viewController];
    }

    [window makeKeyAndVisible];

    [[UIApplication sharedApplication] setStatusBarHidden:true];
    
    // IMPORTANT: Setting the GLView should be done after creating the RootViewController
    cocos2d::GLView *glview = cocos2d::GLViewImpl::createWithEAGLView((__bridge void *)_viewController.view);
    cocos2d::Director::getInstance()->setOpenGLView(glview);
    
    //run the cocos2d-x game scene
    app->run();
	
	[WXApi registerApp:@"wx9414dec2b7f66ebc" withDescription:@"demo 2.0"];
     
    //umeng init
    UMConfigInstance.appKey = @"59faba06f43e4803090002b5";
    UMConfigInstance.channelId = @"App Store";
    UMConfigInstance.eSType = E_UM_GAME;
    [MobClick startWithConfigure:UMConfigInstance];

    //TalkingData add
    //TDCCTalkingDataGA::onStart("A10390F538F94664B1BC4612428008E4", "App Store");
    //TDCCAccount * account = TDCCAccount::setAccount("1111");
    //account->setAccountName("anonymous");
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    // We don't need to call this method any more. It will interrupt user defined game pause&resume logic
    /* cocos2d::Director::getInstance()->pause(); */
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    // We don't need to call this method any more. It will interrupt user defined game pause&resume logic
    /* cocos2d::Director::getInstance()->resume(); */
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


-(void) onReq:(BaseReq*)req
{
    NSLog(@"onReq receive ball");
}


-(void) onResp:(BaseResp*)resp
{
    NSLog(@" get BaseResp...");
    
    if([resp isKindOfClass:[SendMessageToWXResp class]])
    {
        NSString *strErrCode = [NSString stringWithFormat:@"%d", resp.errCode];
        NSLog(@"send message errcode: %@", strErrCode);
        NSMutableDictionary *data2;
        data2 = [[NSMutableDictionary alloc] init];
        
        //        NSLog(@"iiiiii%@",payErrCodestr);
        [data2 setValue:@"weixin_message" forKey:@"type"];
        if(resp.errCode == 0){
            [data2 setValue:@"1" forKey:@"status"];
        }else{
            [data2 setValue:@"0" forKey:@"status"];
        }
        [data2 setValue:@"ok" forKey:@"code"];
        //
        [jstools sendToLuaByWxCode:[data2 JSONString]];
        NSLog(@"%@",@"ok");
        [data2 release];
        
        
    }else if([resp isKindOfClass:[SendAuthResp class]])
    {
        
        NSMutableDictionary *data;
        data = [[NSMutableDictionary alloc] init];
        SendAuthResp *temp = (SendAuthResp*)resp;
        if (temp.code)
        {
            NSLog(@" wxlogin success %@",temp.code);
            
            [data setValue:@"weixin_token" forKey:@"type"];
            [data setValue:@"1" forKey:@"status"];
            [data setValue:temp.code forKey:@"code"];
            
            [jstools sendToLuaByWxCode:[data JSONString]];
            
        }else
        {
            NSString *errCode = [NSString stringWithFormat:@"%d", resp.errCode];
            
            NSLog(@" wxlogin error %@",errCode);
            [data setValue:@"weixin_token" forKey:@"type"];
            [data setValue:@"0" forKey:@"status"];
            [data setValue:@"-1" forKey:@"code"];
            
            [jstools sendToLuaByWxCode:[data JSONString]];
        }
        [data release];
        
    }else if([resp isKindOfClass:[PayResp class]]){
        NSLog(@"come");
        NSString * payErrCodestr = [NSString stringWithFormat:@"%d", resp.errCode];
        NSMutableDictionary *data1;
        data1 = [[NSMutableDictionary alloc] init];
        
        NSLog(@"iiiiii%@",payErrCodestr);
        [data1 setValue:@"weixin_pay" forKey:@"type"];
        if(resp.errCode == 0){
            [data1 setValue:@"1" forKey:@"status"];
        }else{
            [data1 setValue:@"0" forKey:@"status"];
        }
        [data1 setValue:@"-1" forKey:@"code"];
        
        [jstools sendToLuaByWxCode:[data1 JSONString]];
        NSLog(@"%@",@"ok");
        [data1 release];
    }
  
    
}
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return [WXApi handleOpenURL:url delegate:self];
    
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
   
    [WXApi handleOpenURL:url delegate:self];
    
    [AppController checkAppLink:url];
    return  YES;
}
/*!
 * Called by Reachability whenever status changes.
 */
- (void) reachabilityChanged:(NSNotification *)note
{
    NSLog(@"net changed......");
    Reachability * readh = [note object];
    if([readh isKindOfClass:[Reachability class]] ){
        NetworkStatus status = [readh currentReachabilityStatus];
        switch (status) {
            case NotReachable:
            {
                NSLog(@"not reachable");
                break;
            }
            default:
                break;
        }
    }
}

-(void) getPastContent
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    NSLog(@"content:%@",pasteboard.string);
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


#if __has_feature(objc_arc)
#else
- (void)dealloc {
    [window release];
    [_viewController release];
    [super dealloc];
}
#endif


@end
