
#import <Foundation/Foundation.h>

@interface SDKNdCom : NSObject {
    BOOL notificationEnabled_;
    int scriptHandlerId_;
    NSMutableDictionary *avatarDownloads_;
}

+ (SDKNdCom *) sharedInstance;
+ (void) purgeSharedInstance;

- (void) init:(int)appId appKey:(NSString *)appKey delegate:(id)delegate isDebug:(BOOL)isDebug;
- (void) setNotificationEnabled:(BOOL)enabled;
- (void) setScreenOrientation:(UIInterfaceOrientation)orientation autoRotation:(BOOL)autoRotation;

+ (void) registerScriptHandler:(NSDictionary *)dict;
+ (void) unregisterScriptHandler;
        
+ (void) login;
+ (void) loginEx;
+ (void) logout:(NSDictionary *)dict;
+ (void) guestRegister;
+ (BOOL) isLogined;
+ (int) getCurrentLoginState;
+ (NSDictionary *) getUserinfo;
+ (void) switchAccount;
+ (void) enterAccountManager;

+ (int) userFeedback;
+ (void) enterPlatform;
+ (NSDictionary *) payForCoins:(NSDictionary *)dict;

+ (BOOL) getAvatar:(NSDictionary *)dict;

+ (void) share:(NSDictionary *)dict;
+ (void) localNotification:(NSDictionary *)dict;
+ (void) cleanLocalNotification;

@end
