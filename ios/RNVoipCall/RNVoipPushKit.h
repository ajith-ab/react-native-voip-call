
#if __has_include("RCTBridgeModule.h")
#import "RCTBridgeModule.h"
#else
#import <React/RCTBridgeModule.h>
#endif  
#import <Foundation/Foundation.h>
#import <PushKit/PushKit.h>

@interface RNVoipPushKit : NSObject <RCTBridgeModule>

typedef void (^RNVoipPushNotificationCompletion)(void);

@property (nonatomic, strong) NSMutableDictionary<NSString *, RNVoipPushNotificationCompletion> *completionHandlers;

- (void)voipRegistration;
- (void)registerUserNotification:(NSDictionary *)permissions;
- (NSDictionary *)checkPermissions;
+ (void)didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type;
+ (void)didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type;
+ (NSString *)getCurrentAppBackgroundState;
+ (void)addCompletionHandler:(NSString *)uuid completionHandler:(RNVoipPushNotificationCompletion)completionHandler;
+ (void)removeCompletionHandler:(NSString *)uuid;

@end  
