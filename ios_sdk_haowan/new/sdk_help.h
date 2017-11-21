#ifndef __SDK_HELP_H__
#define __SDK_HELP_H__

#import <FBSDKShareKit/FBSDKSharing.h>
#import "GeTuiSdk.h"

@interface SdkHelp : NSObject <FBSDKSharingDelegate> {
    int _scriptHandler;
    int _afScriptHandler;
}
+ (SdkHelp*) getInstance;
+ (void) destroyInstance;

+ (void) registerScriptHandler:(NSDictionary *)dict;
+ (void) unregisterScriptHandler;
+ (void) registerAfScriptHandler:(NSDictionary *)dict;
+ (void) unregisterAfScriptHandler;

+ (void) login:(NSDictionary *)dict;
+ (void) loginQWToLua:(NSDictionary *)dict tokenStr:(NSString *)token uidStr:(NSString *)uid;
+ (void) logoutQWToLua:(NSDictionary *)dict;
+ (void) loginHWToLua:(NSDictionary *)dict tokenStr:(NSString *)token uidStr:(NSString *)uid;
+ (void) logoutHWToLua:(NSDictionary *)dict;
+ (void) payAction:(NSDictionary *)dict;
+ (void) shareToFacebook:(NSDictionary *)dict;
+ (void) trackLoginEvent:(NSDictionary *)dict;
+ (void) trackCreateRoleEvent:(NSDictionary *)dict;
+ (void) trackPurchaseEvent:(NSDictionary *)dict;
+ (void) trackTutorialCompletionEvent:(NSDictionary *)dict;

+ (void) trackLoginEventReyun:(NSDictionary *)dict;
+ (void) trackCreateRoleEventReyun:(NSDictionary *)dict;
+ (void) trackPurchaseStartEventReyun:(NSDictionary *)dict;
+ (void) trackPurchaseEventReyun:(NSDictionary *)dict;
+ (void) trackTutorialCompletionEventReyun:(NSDictionary *)dict;

+ (void) setAppInstallData:(NSDictionary *)installData;
+ (NSString*) getAppsFlyerUID:(NSDictionary *)dict;
+ (void) getAppsFlyerData:(NSDictionary *)dict;
+ (NSString*) getGetuiClientId:(NSDictionary *)dict;


- (id) init;

- (NSString *) jsonStringWithDictionary:(NSDictionary *)dictionary;
- (NSString *) jsonStringWithArray:(NSArray *)array;
- (NSString *) jsonStringWithString:(NSString *) string;
- (NSString *) jsonStringWithObject:(id) object;


@end

#endif
