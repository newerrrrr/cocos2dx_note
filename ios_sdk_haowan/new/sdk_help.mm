#import "sdk_help.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <FBSDKShareKit/FBSDKShareDialog.h>
#import <FBSDKShareKit/FBSDKShareLinkContent.h>
#import <AppsFlyer/AppsFlyer.h>
#import <Foundation/Foundation.h>
#import <YLSDK/YLSDK.h>
//#import "ReYunTrack.h"
#import "AppController.h"

#include "cocos2d.h"
#include "CCLuaEngine.h"
#include "CCLuaBridge.h"

using namespace cocos2d;


@implementation SdkHelp

static SdkHelp* s_instance = nil;

+ (SdkHelp*) getInstance
{
    if (!s_instance)
    {
        s_instance = [SdkHelp alloc];
        [s_instance init];
    }
    
    return s_instance;
}

+ (void) destroyInstance
{
    [s_instance release];
}

- (void) setScriptHandler:(int)scriptHandler
{
    if (_scriptHandler)
    {
        LuaBridge::releaseLuaFunctionById(_scriptHandler);
        _scriptHandler = 0;
    }
    _scriptHandler = scriptHandler;
}

- (int) getScriptHandler
{
    return _scriptHandler;
}

- (void) setAfScriptHandler:(int)scriptHandler
{
    if (_afScriptHandler)
    {
        LuaBridge::releaseLuaFunctionById(_afScriptHandler);
        _afScriptHandler = 0;
    }
    _afScriptHandler = scriptHandler;
}

- (int) getAfScriptHandler
{
    return _afScriptHandler;
}

+(void) registerAfScriptHandler:(NSDictionary *)dict
{
    [[SdkHelp getInstance] setAfScriptHandler:[[dict objectForKey:@"scriptHandler"] intValue]];
}


+ (void) unregisterAfScriptHandler
{
    [[SdkHelp getInstance] setAfScriptHandler:0];
}

+(void) registerScriptHandler:(NSDictionary *)dict
{
    [[SdkHelp getInstance] setScriptHandler:[[dict objectForKey:@"scriptHandler"] intValue]];
}


+ (void) unregisterScriptHandler
{
    [[SdkHelp getInstance] setScriptHandler:0];
}

+(void) shareToFacebook:(NSDictionary *)dict
{
    [[SdkHelp getInstance] setScriptHandler:[[dict objectForKey:@"scriptHandler"] intValue]];
    
    NSString *title = [dict objectForKey:@"title"];
    NSString *description = [dict objectForKey:@"description"];
    NSString *shareUrl = [dict objectForKey:@"url"];
    NSString *imgUrl = [dict objectForKey:@"image_url"];

    
    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentTitle = title;
    content.contentDescription = description;
    content.contentURL = [NSURL URLWithString:shareUrl];
    content.imageURL = [NSURL URLWithString:imgUrl];
    
    FBSDKShareDialog *dialog = [[FBSDKShareDialog alloc] init];
    dialog.shareContent = content;
    dialog.delegate =[SdkHelp getInstance];
    
    //use app of facebook app installed
    /*dialog.mode = FBSDKShareDialogModeNative;
    if (![dialog canShow]) {
        // fallback presentation when there is no FB app
        dialog.mode = FBSDKShareDialogModeFeedBrowser;
    }*/
    
    //only use web
    dialog.mode =  FBSDKShareDialogModeFeedWeb;
    [dialog show];
    
    /*[FBSDKShareDialog showFromViewController:Nil
                                 withContent:content
                                    delegate:[SdkHelp getInstance]];*/
    
}

+(void) login:(NSDictionary *)dict
{
    [[SdkHelp getInstance] setScriptHandler:[[dict objectForKey:@"scriptHandler"] intValue]];
    
    FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
    [login
     logInWithReadPermissions: @[@"public_profile"]
     fromViewController:Nil
     handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
         
         int scriptHandler = [[SdkHelp getInstance] getScriptHandler];
         if (scriptHandler){
             
             NSString *statusStr = @"";
             NSString *tokenStr = @"";
             LuaBridge::pushLuaFunctionById(scriptHandler);
             LuaStack *stack = LuaBridge::getStack();
             
             if (error) {
                 NSLog(@"Process error");
                 statusStr = @"error";
                 [login logOut];
             } else if (result.isCancelled) {
                 NSLog(@"Cancelled");
                 statusStr = @"cancelled";
             } else {
                 NSLog(@"Logged in");
                 statusStr = @"success";
                 tokenStr = result.token.userID;//facebook use userid
             }
             
             stack->pushString([statusStr cStringUsingEncoding:NSASCIIStringEncoding]);
             stack->pushString([tokenStr cStringUsingEncoding:NSASCIIStringEncoding]);
             stack->executeFunction(2);
             
         }
     
     }];
}

//qw login
+(void) loginQWToLua:(NSDictionary *)dict tokenStr:(NSString *)token uidStr:(NSString *)uid
{
    [[SdkHelp getInstance] setScriptHandler:[[dict objectForKey:@"scriptHandler"] intValue]];
    //[AppController loginQW];
    int scriptHandler = [[SdkHelp getInstance] getScriptHandler];
    if (scriptHandler){
        LuaBridge::pushLuaFunctionById(scriptHandler);
        LuaStack *stack = LuaBridge::getStack();
        stack->pushString([token cStringUsingEncoding:NSASCIIStringEncoding]);
        stack->pushString([uid cStringUsingEncoding:NSASCIIStringEncoding]);
        stack->executeFunction(2);
        
        //NSLog(@"this is qw scriptHandler");
    }
    //NSLog(@"this is qw login");
}

+(void) logoutQWToLua:(NSDictionary *)dict{
    [[SdkHelp getInstance] setScriptHandler:[[dict objectForKey:@"testHandler"] intValue]];
    int scriptHandler = [[SdkHelp getInstance] getScriptHandler];
    if(scriptHandler){
        LuaBridge::pushLuaFunctionById(scriptHandler);
        LuaStack *stack = LuaBridge::getStack();
        stack->pushString([@"this is test" cStringUsingEncoding:NSASCIIStringEncoding]);
        stack->executeFunction(1);
    }
    
}

//haowan login
+(void) loginHWToLua:(NSDictionary *)dict tokenStr:(NSString *)token uidStr:(NSString *)uid
{
    [[SdkHelp getInstance] setScriptHandler:[[dict objectForKey:@"scriptHandler"] intValue]];
    int scriptHandler = [[SdkHelp getInstance] getScriptHandler];
    if (scriptHandler){
        LuaBridge::pushLuaFunctionById(scriptHandler);
        LuaStack *stack = LuaBridge::getStack();
        stack->pushString([token cStringUsingEncoding:NSASCIIStringEncoding]);
        stack->pushString([uid cStringUsingEncoding:NSASCIIStringEncoding]);
        stack->executeFunction(2);
        
        //NSLog(@"this is hw scriptHandler");
    }
    //NSLog(@"this is hw login");
}

+(void) logoutHWToLua:(NSDictionary *)dict{
    [[SdkHelp getInstance] setScriptHandler:[[dict objectForKey:@"testHandler"] intValue]];
    int scriptHandler = [[SdkHelp getInstance] getScriptHandler];
    if(scriptHandler){
        LuaBridge::pushLuaFunctionById(scriptHandler);
        LuaStack *stack = LuaBridge::getStack();
        stack->pushString([@"this is test" cStringUsingEncoding:NSASCIIStringEncoding]);
        stack->executeFunction(1);
    }
    
}

+(void)payAction:(NSDictionary *)dict{
    
    NSString *goodsName = [dict objectForKey:@"goodsName"];
    NSString *goodsPrice = [dict objectForKey:@"goodsPrice"];
    NSString *goodsDesc = [dict objectForKey:@"goodsDesc"];
    NSString *extendInfo = [dict objectForKey:@"extendInfo"];
    NSString *productId = [dict objectForKey:@"productId"];
    NSString *player_server = [dict objectForKey:@"player_server"];
    NSString *player_role = [dict objectForKey:@"player_role"];
    NSString *cp_trade_no = [dict objectForKey:@"cp_trade_no"];
    
    NSLog(@"goodsName:%@"    ,goodsName);
    NSLog(@"goodsPrice:%@"   ,goodsPrice);
    NSLog(@"goodsDesc:%@"    ,goodsDesc);
    NSLog(@"extendInfo:%@"   ,extendInfo);
    NSLog(@"productId:%@"    ,productId);
    NSLog(@"player_server:%@",player_server);
    NSLog(@"player_role:%@"  ,player_role);
    NSLog(@"cp_trade_no:%@"  ,cp_trade_no);
    
    OrderInfo *orderInfo = [[OrderInfo alloc] init];
    orderInfo.goodsName = goodsName;
    orderInfo.goodsPrice = [goodsPrice intValue];
    //[goodsPrice intValue];//单位为分
    orderInfo.goodsDesc = goodsDesc;//商品描述
    orderInfo.extendInfo = extendInfo;
    //extendInfo;//此字段会透传到游戏服务器，可拼接订单信息和其它信息等
    orderInfo.productId = productId;//虚拟商品在APP Store中的ID
    //-------注意：此处需要传入的是区服的名称，而不是区服编号-------------------------
    orderInfo.player_server = player_server;//玩家所在区服名称（跟游戏内显示的区服保持一致）
    orderInfo.player_role = player_role;// 玩家角色名称
    orderInfo.cp_trade_no = cp_trade_no;//CP订单号
    
    [[YLApi YL_sharedInstance] YL_pay:orderInfo completionBlock:^(NSDictionary *resultDic) {
        NSLog(@"[pay] resultDic = %@", resultDic);
        NSNumber *payresult = [resultDic objectForKey:@"payresult"];
        if ([payresult intValue] == YLTreatedOrderSuccess) {
            NSLog(@"支付成功");
            //**************为了减少漏单几率，不要在这个回调里面处理加钻逻辑，支付成功我们服务************
            //**************器会通知cp服务器，cp服务器收到通知以后客户端再进行加钻。************
        }
    }];
}



- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results
{
    NSLog(@"FB: SHARE RESULTS=%@\n",[results debugDescription]);
    
    int scriptHandler = [[SdkHelp getInstance] getScriptHandler];
    if (scriptHandler){
        
        NSString *statusStr = @"success";
        
        LuaBridge::pushLuaFunctionById(scriptHandler);
        LuaStack *stack = LuaBridge::getStack();
        
        stack->pushString([statusStr cStringUsingEncoding:NSASCIIStringEncoding]);
        stack->executeFunction(1);
        
    }
    
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error
{
    NSLog(@"FB: ERROR=%@\n",[error debugDescription]);
    
    int scriptHandler = [[SdkHelp getInstance] getScriptHandler];
    if (scriptHandler){
        
        NSString *statusStr = @"error";
        LuaBridge::pushLuaFunctionById(scriptHandler);
        LuaStack *stack = LuaBridge::getStack();
        
        stack->pushString([statusStr cStringUsingEncoding:NSASCIIStringEncoding]);
        stack->executeFunction(1);
        
    }

}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer
{
    NSLog(@"FB: CANCELED SHARER=%@\n",[sharer debugDescription]);
    
    int scriptHandler = [[SdkHelp getInstance] getScriptHandler];
    if (scriptHandler){
        
        NSString *statusStr = @"cancled";
        LuaBridge::pushLuaFunctionById(scriptHandler);
        LuaStack *stack = LuaBridge::getStack();
        
        stack->pushString([statusStr cStringUsingEncoding:NSASCIIStringEncoding]);
        stack->executeFunction(1);
        
    }

}

/*reyun in app track
+ (void) trackLoginEventReyun:(NSDictionary *)dict
{
    NSString *accountId = [dict objectForKey:@"account_id"];
    [ReYunChannel setLoginWithAccountID:accountId];
    
}

+ (void) trackCreateRoleEventReyun:(NSDictionary *)dict
{
    NSString *accountId = [dict objectForKey:@"account_id"];
    [ReYunChannel setRegisterWithAccountID:accountId];
}
+ (void) trackPurchaseStartEventReyun:(NSDictionary *)dict
{
    NSString *transactionId = [dict objectForKey:@"transaction_id"];
    NSString *payWay = [dict objectForKey:@"payway"];
    NSNumber *revenue = [dict objectForKey:@"revenue"];
    NSString *currencyType = [dict objectForKey:@"currency_type"];
    
    [ReYunChannel setryzfStart:transactionId ryzfType:payWay currentType:currencyType currencyAmount:revenue.floatValue];
}

+ (void) trackPurchaseEventReyun:(NSDictionary *)dict
{
    
    NSString *transactionId = [dict objectForKey:@"transaction_id"];
    NSString *payWay = [dict objectForKey:@"payway"];
    NSNumber *revenue = [dict objectForKey:@"revenue"];
    NSString *currencyType = [dict objectForKey:@"currency_type"];
    
    [ReYunChannel setryzf:transactionId ryzfType:payWay currentType:currencyType currencyAmount:revenue.floatValue];
    
}

+ (void) trackTutorialCompletionEventReyun:(NSDictionary *)dict
{
    [ReYunChannel setEvent:@"event_1"];
}
*/


//appsflyer in app track
+ (void) trackLoginEvent:(NSDictionary *)dict
{
    [[AppsFlyerTracker sharedTracker] trackEvent: AFEventLogin withValues:@{}];
}

+ (void) trackCreateRoleEvent:(NSDictionary *)dict
{
    [[AppsFlyerTracker sharedTracker] trackEvent: AFEventCompleteRegistration withValues:@{}];
}

+ (void) trackPurchaseEvent:(NSDictionary *)dict
{
    
    NSString *contentId = [dict objectForKey:@"content_id"];
    NSString *contentType = [dict objectForKey:@"content_type"];
    NSString *revenue = [dict objectForKey:@"revenue"];
    NSString *currencyType = [dict objectForKey:@"currency_type"];
    
    
    [[AppsFlyerTracker sharedTracker] trackEvent:AFEventPurchase withValues: @{
                                                                               AFEventParamContentId:contentId,
                                                                               AFEventParamContentType:contentType,
                                                                               AFEventParamRevenue:revenue,
                                                                               AFEventParamCurrency:currencyType}];
    
}

+ (void) trackTutorialCompletionEvent:(NSDictionary *)dict
{
    [[AppsFlyerTracker sharedTracker] trackEvent: AFEventTutorial_completion withValues:@{}];
}


- (NSString *) jsonStringWithString:(NSString *) string{
    return [NSString stringWithFormat:@"\"%@\"",
            [[string stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]
            ];
}

- (NSString *) jsonStringWithArray:(NSArray *)array{
    NSMutableString *reString = [NSMutableString string];
    [reString appendString:@"["];
    NSMutableArray *values = [NSMutableArray array];
    for (id valueObj in array) {
        NSString *value = [[SdkHelp getInstance] jsonStringWithObject:valueObj];
        //NSString *value = [NSString jsonStringWithObject:valueObj];
        if (value) {
            [values addObject:[NSString stringWithFormat:@"%@",value]];
        }
    }
    [reString appendFormat:@"%@",[values componentsJoinedByString:@","]];
    [reString appendString:@"]"];
    return reString;
}

- (NSString *) jsonStringWithDictionary:(NSDictionary *)dictionary{
    NSArray *keys = [dictionary allKeys];
    NSMutableString *reString = [NSMutableString string];
    [reString appendString:@"{"];
    NSMutableArray *keyValues = [NSMutableArray array];
    for (int i=0; i<[keys count]; i++) {
        NSString *name = [keys objectAtIndex:i];
        id valueObj = [dictionary objectForKey:name];
        //NSString *value = [NSString jsonStringWithObject:valueObj];
        NSString *value = [[SdkHelp getInstance] jsonStringWithObject:valueObj];
        if (value) {
            [keyValues addObject:[NSString stringWithFormat:@"\"%@\":%@",name,value]];
        }
    }
    [reString appendFormat:@"%@",[keyValues componentsJoinedByString:@","]];
    [reString appendString:@"}"];
    return reString;
}
- (NSString *) jsonStringWithObject:(id) object
{
    NSString *value = nil;
    if (!object) {
        return value;
    }
    if ([object isKindOfClass:[NSString class]]) {
        //value = [NSString jsonStringWithString:object];
        value = [[SdkHelp getInstance] jsonStringWithString:object];
    }else if([object isKindOfClass:[NSDictionary class]]){
        //value = [NSString jsonStringWithDictionary:object];
        value = [[SdkHelp getInstance] jsonStringWithDictionary:object];
    }else if([object isKindOfClass:[NSArray class]]){
        //value = [NSString jsonStringWithArray:object];
        value = [[SdkHelp getInstance] jsonStringWithArray:object];
    }
    return value;
}

+ (void) setAppInstallData:(NSDictionary *)installData
{
    /*NSString *jsonStr = @"{";
     
     NSArray * keys = [installData allKeys];
     
     for (NSString * key in keys) {
     
     jsonStr = [NSString stringWithFormat:@"%@\"%@\":\"%@\",",jsonStr,key,[installData objectForKey:key]];
     
     }
     
     jsonStr = [NSString stringWithFormat:@"%@%@",[jsonStr substringWithRange:NSMakeRange(0, jsonStr.length-1)],@"}"];
     
     m_installDataJsonStr = jsonStr;*/
    
    NSLog(@"\n>>>[appsFlyer setAppInstallData]");
    for (NSString *key in installData) {
        NSLog(@"key=%@,vaule=%@",key,[installData objectForKey:key]);
    }
    NSString * s_afData = [[SdkHelp getInstance] jsonStringWithDictionary:installData];
    
    
    NSUserDefaults *userDef=[NSUserDefaults standardUserDefaults];//这个对象其实类似字典，着也是一个单例的例子
    [userDef setObject:s_afData forKey:@"afdata"];
    [userDef synchronize];//把数据同步到本地
    
    NSLog(@"installStr=%@",s_afData);

}

+ (void) getAppsFlyerData:(NSDictionary *)dict
{
    NSUserDefaults *userDefault=[NSUserDefaults standardUserDefaults];
    NSString *s_afData=(NSString*)[userDefault objectForKey:@"afdata"];
  

    int scriptHandler = [[SdkHelp getInstance] getAfScriptHandler];
    if (s_afData && scriptHandler){
        LuaBridge::pushLuaFunctionById(scriptHandler);
        LuaStack *stack = LuaBridge::getStack();
        stack->pushString([s_afData cStringUsingEncoding:NSASCIIStringEncoding]);
        stack->executeFunction(1);
    }

}


+ (NSString*) getAppsFlyerUID:(NSDictionary *)dict
{
    
    NSString * ret = (NSString*)[[AppsFlyerTracker sharedTracker] getAppsFlyerUID];
    return ret;
    
}

+ (NSString*) getGetuiClientId:(NSDictionary *)dict
{
    NSString * ret = [GeTuiSdk clientId];
    if(!ret)
    {
        ret =@"";
    }
    return ret;
}


- (id)init
{
    _scriptHandler = 0;
    _afScriptHandler = 0;
    return self;
}

@end
