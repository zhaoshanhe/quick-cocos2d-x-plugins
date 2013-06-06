
#import "SDKNdCom.h"

#import <NdComPlatform/NDComPlatform.h>
#import <NdComPlatform/NdComPlatformAPIResponse.h>
#import <NdComPlatform/NdCPNotifications.h>

#include "cocos2d.h"
#include "CCLuaEngine.h"
#include "CCLuaBridge.h"

using namespace cocos2d;

@implementation SDKNdCom

static SDKNdCom *s_sharedInstance = nil;

+ (SDKNdCom *) sharedInstance
{
    if (!s_sharedInstance)
    {
        s_sharedInstance = [[SDKNdCom alloc] init];
    }
    return s_sharedInstance;
}

+ (void) purgeSharedInstance
{
    [s_sharedInstance release];
}

- (void) dealloc
{
    [self setNotificationEnabled:NO];
    [self setScriptHandlerId:0];
    [avatarDownloads_ release];
    
    s_sharedInstance = nil;
    [super dealloc];
}

- (void) init:(int)appId appKey:(NSString *)appKey delegate:(id)delegate isDebug:(BOOL)isDebug
{
    notificationEnabled_ = NO;
    scriptHandlerId_ = 0;
    avatarDownloads_ = [[NSMutableDictionary dictionary] retain];
    
    if (isDebug)
    {
        [[NdComPlatform defaultPlatform] NdSetDebugMode:0];
    }
    [[NdComPlatform defaultPlatform] setAppId:appId];
    [[NdComPlatform defaultPlatform] setAppKey:appKey];
    
    [[NdComPlatform defaultPlatform] NdAppVersionUpdate:0 delegate:delegate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onLeavePlatform)
                                                 name:kNdCPLeavePlatformNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onLogin:)
                                                 name:kNdCPLoginNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onSessionInvalid)
                                                 name:kNdCPSessionInvalidNotification
                                               object:nil];
}

- (void) setNotificationEnabled:(BOOL)enabled
{
    notificationEnabled_ = enabled;
}

- (void) setScreenOrientation:(UIInterfaceOrientation)orientation autoRotation:(BOOL)autoRotation
{
    [[NdComPlatform defaultPlatform] NdSetScreenOrientation:orientation];
    [[NdComPlatform defaultPlatform] NdSetAutoRotation:autoRotation];
}


#pragma mark -
#pragma mark script support

- (void) setScriptHandlerId:(int)handlerId
{
    if (scriptHandlerId_)
    {
        CCLuaBridge::releaseLuaFunctionById(scriptHandlerId_);
        scriptHandlerId_ = 0;
    }
    scriptHandlerId_ = handlerId;
}

+ (void) registerScriptHandler:(NSDictionary *)dict
{
    [[SDKNdCom sharedInstance] setScriptHandlerId:[[dict objectForKey:@"listener"] intValue]];
}

+ (void) unregisterScriptHandler
{
    [[SDKNdCom sharedInstance] setScriptHandlerId:0];
}


#pragma mark -
#pragma mark login

+ (void) login
{
    [[NdComPlatform defaultPlatform] NdLogin:0];
}

+ (void) loginEx
{
    [[NdComPlatform defaultPlatform] NdLoginEx:0];
}

+ (void) logout:(NSDictionary *)dict
{
    int clean = [[dict objectForKey:@"clean"] intValue];
    [[NdComPlatform defaultPlatform] NdLogout:clean];
}

+ (void) guestRegister
{
    [[NdComPlatform defaultPlatform] NdGuestRegist:0];
}

+ (BOOL) isLogined
{
    return [[NdComPlatform defaultPlatform] isLogined];
}

+ (int) getCurrentLoginState
{
    return [[NdComPlatform defaultPlatform] getCurrentLoginState];
}

+ (NSDictionary *) getUserinfo
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSString *loginUin = [[NdComPlatform defaultPlatform] loginUin];
    NSString *sessionId = [[NdComPlatform defaultPlatform] sessionId];
    NSString *nickname = [[NdComPlatform defaultPlatform] nickName];
    
    [dict setObject:loginUin ? loginUin : @"" forKey:@"uin"];
    [dict setObject:sessionId ? sessionId : @"" forKey:@"sessionId"];
    [dict setObject:nickname ? nickname : @"" forKey:@"nickname"];
    
    NdMyUserInfo *info = [[NdComPlatform defaultPlatform] NdGetMyInfo];
    if (info && info.baseInfo && info.baseInfo.checkSum)
    {
        [dict setObject:info.baseInfo.checkSum forKey:@"headCheckSum"];
    }

    return dict;
}

+ (void) switchAccount
{
    [[NdComPlatform defaultPlatform] NdSwitchAccount];
}

+ (void) enterAccountManager
{
    [[NdComPlatform defaultPlatform] NdEnterAccountManage];
}


#pragma mark -
#pragma mark platform functions

+ (int) userFeedback
{
    return [[NdComPlatform defaultPlatform] NdUserFeedBack];
}

+ (void) enterPlatform
{
    [[NdComPlatform defaultPlatform] NdEnterPlatform:0];
}

+ (NSDictionary *) payForCoins:(NSDictionary *)dict
{
    NSString *orderId = [dict objectForKey:@"orderId"];
    if (!orderId || [orderId length] == 0)
    {
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFStringRef string = CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        orderId = [(NSString *)string autorelease];
    }
    
    int coins = 0;
    if ([dict objectForKey:@"coins"])
    {
        coins = [[dict objectForKey:@"coins"] intValue];
    }
    
    NSString *description = [dict objectForKey:@"description"];
    if (!description)
    {
        description = @"";
    }
    
    int ret = [[NdComPlatform defaultPlatform] NdUniPayForCoin:orderId
                                                  needPayCoins:coins
                                                payDescription:description];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:orderId, @"orderId",
            [NSNumber numberWithInt:ret], @"error", nil];
}

- (BOOL) getAvatar:(NSString *)uin
           imgType:(ND_PHOTO_SIZE_TYPE)imgType
          checksum:(NSString *)checksum
          callback:(NSNumber *)callback
{
    if ([avatarDownloads_ objectForKey:uin]) return NO;
    
    [avatarDownloads_ setObject:callback forKey:uin];
    [[NdComPlatform defaultPlatform] NdGetPortraitPath:uin
                                             imageType:imgType
                                              checkSum:checksum
                                              delegate:[SDKNdCom sharedInstance]];
    return YES;
}

+ (BOOL) getAvatar:(NSDictionary *)dict
{
    NSNumber *nsCallback = [dict objectForKey:@"callback"];
    NSString *nsUin      = [dict objectForKey:@"uin"];
    NSString *nsChecksum = [dict objectForKey:@"checksum"];
    NSString *nsImgType  = [dict objectForKey:@"type"];
    
    ND_PHOTO_SIZE_TYPE imgType = ND_PHOTO_SIZE_MIDDLE;
    if (nsImgType)
    {
        if ([nsImgType compare:@"tiny" options:NSCaseInsensitiveSearch] == NSOrderedSame)
        {
            imgType = ND_PHOTO_SIZE_TINY;
        }
        else if ([nsImgType compare:@"small" options:NSCaseInsensitiveSearch] == NSOrderedSame)
        {
            imgType = ND_PHOTO_SIZE_TINY;
        }
        else if ([nsImgType compare:@"big" options:NSCaseInsensitiveSearch] == NSOrderedSame)
        {
            imgType = ND_PHOTO_SIZE_BIG;
        }
    }
    
    return [[SDKNdCom sharedInstance] getAvatar:nsUin
                                        imgType:imgType
                                       checksum:nsChecksum
                                       callback:nsCallback];
}

+ (void) share:(NSDictionary *)dict
{
    NSString *message = [dict objectForKey:@"message"];
    NSString *image = [dict objectForKey:@"image"];
    [[NdComPlatform defaultPlatform] NdShareToThirdPlatform:message
                                                  imageInfo:[NdImageInfo imageInfoWithFile:image]];
}

+ (void) localNotification:(NSDictionary *)dict
{
    int delay = [[dict objectForKey:@"delay"] intValue];
    NSString *message = [dict objectForKey:@"message"];
    [[NdComPlatform defaultPlatform] NdSetLocalNotification:delay alertBody:message];
}

+ (void) cleanLocalNotification
{
    [[NdComPlatform defaultPlatform] NdCancelAllLocalNotification];
}


#pragma mark -
#pragma mark delegate

- (void) onLeavePlatform
{
    if (scriptHandlerId_)
    {
        CCLuaBridge::pushLuaFunctionById(scriptHandlerId_);
        CCLuaStack *stack = CCLuaBridge::getStack();
        stack->pushString("SDKNDCOM_LEAVE_PLATFORM");
        stack->executeFunction(1);
    }
    if (notificationEnabled_)
    {
        CCNotificationCenter::sharedNotificationCenter()->postNotification("SDKNDCOM_LEAVE_PLATFORM");
    }
}

- (void) onLogin:(NSNotification *)notify
{
    NSDictionary *dict = [notify userInfo];
    BOOL success = [[dict objectForKey:@"result"] boolValue];
    NdGuestAccountStatus* guestStatus = (NdGuestAccountStatus*)[dict objectForKey:@"NdGuestAccountStatus"];
    const char *message = NULL;
    
    if ([[NdComPlatform defaultPlatform] isLogined] && success)
    {
        if (guestStatus)
        {
            if ([guestStatus isGuestLogined])
            {
                // 游客账号登录成功
                message = "SDKNDCOM_GUEST_LOGINED";
            }
            else if ([guestStatus isGuestRegistered])
            {
                // 游客成功注册为普通账号
                message = "SDKNDCOM_GUEST_REGISTERED";
            }
        }
        else
        {
            // 普通账号登录成功
            message = "SDKNDCOM_LOGINED";
        }
    }
    else
    {
        // 登录失败
        int error = [[dict objectForKey:@"error"] intValue];
        switch (error)
        {
            case ND_COM_PLATFORM_ERROR_USER_CANCEL:
                // 用户取消登录
                if (([[NdComPlatform defaultPlatform] getCurrentLoginState] == ND_LOGIN_STATE_GUEST_LOGIN))
                {
                    // 当前仍处于游客登录状态
                    message = "SDKNDCOM_GUEST_LOGINED";
                }
                else
                {
                    // 用户未登录
                    message = "SDKNDCOM_NOT_LOGINED";
                }
                break;
                
            case ND_COM_PLATFORM_ERROR_APP_KEY_INVALID:
                // appId 未授权接入, 或 appKey 无效
                message = "SDKNDCOM_INVALID_APPID_OR_APPKEY";
                break;
                
            case ND_COM_PLATFORM_ERROR_CLIENT_APP_ID_INVALID:
                // 无效的 appId
                message = "SDKNDCOM_INVALID_APPID";
                break;
                
            case ND_COM_PLATFORM_ERROR_HAS_ASSOCIATE_91:
                // 有关联的91账号，不能以游客方式登录
                message = "SDKNDCOM_HAS_ASSOCIATE";
                break;
                
            default:
                message = "SDKNDCOM_UNKNOWN_LOGIN_ERROR";
        }
    }
    
    if (scriptHandlerId_)
    {
        CCLuaBridge::pushLuaFunctionById(scriptHandlerId_);
        CCLuaStack *stack = CCLuaBridge::getStack();
        stack->pushString(message);
        stack->executeFunction(1);
    }
    if (notificationEnabled_)
    {
        CCNotificationCenter::sharedNotificationCenter()->postNotification(message);
    }
}

- (void) onSessionInvalid
{
    if (scriptHandlerId_)
    {
        CCLuaBridge::pushLuaFunctionById(scriptHandlerId_);
        CCLuaStack *stack = CCLuaBridge::getStack();
        stack->pushString("SDKNDCOM_SESSION_INVALID");
        stack->executeFunction(1);
    }
    if (notificationEnabled_)
    {
        CCNotificationCenter::sharedNotificationCenter()->postNotification("SDKNDCOM_SESSION_INVALID");
    }
}

- (void)getPortraitPathDidFinish:(int)error
                             uin:(NSString *)uin
                    portraitPath:(NSString *)portraitPath
                        checkSum:(NSString *)checksum
{
    NSNumber *callback = [avatarDownloads_ objectForKey:uin];
    [avatarDownloads_ removeObjectForKey:uin];
    if (!callback) return;
    
    int callbackId = [callback intValue];
    CCLuaValueDict item;
    if (error || !portraitPath)
    {
        item["uin"] = CCLuaValue::stringValue([uin cStringUsingEncoding:NSUTF8StringEncoding]);
        item["error"] = CCLuaValue::intValue(error);
    }
    else
    {
        item["uin"] = CCLuaValue::stringValue([uin cStringUsingEncoding:NSUTF8StringEncoding]);
        item["path"] = CCLuaValue::stringValue([portraitPath cStringUsingEncoding:NSUTF8StringEncoding]);
        if (checksum)
        {
            item["checksum"] = CCLuaValue::stringValue([checksum cStringUsingEncoding:NSUTF8StringEncoding]);
        }
    }
    
//    NSLog(@"GET AVATAR\nCHECKSUM: %@\nPATH: %@", checksum, portraitPath);
 
    CCLuaBridge::pushLuaFunctionById(callbackId);
    CCLuaStack *stack = CCLuaBridge::getStack();
    stack->pushCCLuaValueDict(item);
    stack->executeFunction(1);
    CCLuaBridge::releaseLuaFunctionById(callbackId);
}

@end
