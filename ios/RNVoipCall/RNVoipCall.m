//
//  RNVoipCall.m
//  RNVoipCall
//
//  Copyright 2019 Ajith A B The  Authors (see the AUTHORS file)
//  SPDX-License-Identifier: ISC, MIT
//

#import "RNVoipCall.h"

#import <React/RCTBridge.h>
#import <React/RCTConvert.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTUtils.h>

#import <AVFoundation/AVAudioSession.h>

#ifdef DEBUG
static int const OUTGOING_CALL_WAKEUP_DELAY = 10;
#else
static int const OUTGOING_CALL_WAKEUP_DELAY = 5;
#endif

static NSString *const RNVoipCallHandleStartCallNotification = @"RNVoipCallHandleStartCallNotification";
static NSString *const RNVoipCallDidReceiveStartCallAction = @"RNVoipCallDidReceiveStartCallAction";
static NSString *const RNVoipCallPerformAnswerCallAction = @"RNVoipCallPerformAnswerCallAction";
static NSString *const RNVoipCallPerformEndCallAction = @"RNVoipCallPerformEndCallAction";
static NSString *const RNVoipCallDidActivateAudioSession = @"RNVoipCallDidActivateAudioSession";
static NSString *const RNVoipCallDidDeactivateAudioSession = @"RNVoipCallDidDeactivateAudioSession";
static NSString *const RNVoipCallDidDisplayIncomingCall = @"RNVoipCallDidDisplayIncomingCall";
static NSString *const RNVoipCallDidPerformSetMutedCallAction = @"RNVoipCallDidPerformSetMutedCallAction";
static NSString *const RNVoipCallPerformPlayDTMFCallAction = @"RNVoipCallDidPerformDTMFAction";
static NSString *const RNVoipCallDidToggleHoldAction = @"RNVoipCallDidToggleHoldAction";
static NSString *const RNVoipCallProviderReset = @"RNVoipCallProviderReset";
static NSString *const RNVoipCallCheckReachability = @"RNVoipCallCheckReachability";

@implementation RNVoipCall
{
    NSOperatingSystemVersion _version;
    BOOL _isStartCallActionEventListenerAdded;
    
    
     }

NSString *callerName;
BOOL callAttended = FALSE;
NSString *callerId;
NSTimer *timer;

static CXProvider* sharedProvider;

// should initialise in AppDelegate.m
RCT_EXPORT_MODULE()

- (instancetype)init
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][init]");
#endif
    if (self = [super init]) {
        _isStartCallActionEventListenerAdded = NO;
    }
    return self;
}

+ (id)allocWithZone:(NSZone *)zone {
    static RNVoipCall *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [super allocWithZone:zone];
    });
    return sharedInstance;
}

- (void)dealloc
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][dealloc]");
#endif
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if (self.callKeepProvider != nil) {
        [self.callKeepProvider invalidate];
    }
    sharedProvider = nil;
}

// Override method of RCTEventEmitter
- (NSArray<NSString *> *)supportedEvents
{
    return @[
        RNVoipCallDidReceiveStartCallAction,
        RNVoipCallPerformAnswerCallAction,
        RNVoipCallPerformEndCallAction,
        RNVoipCallDidActivateAudioSession,
        RNVoipCallDidDeactivateAudioSession,
        RNVoipCallDidDisplayIncomingCall,
        RNVoipCallDidPerformSetMutedCallAction,
        RNVoipCallPerformPlayDTMFCallAction,
        RNVoipCallDidToggleHoldAction,
        RNVoipCallProviderReset,
        RNVoipCallCheckReachability
    ];
}

+ (void)initCallKitProvider {
    if (sharedProvider == nil) {
        NSDictionary *settings = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"RNVoipCallSettings"];
        sharedProvider = [[CXProvider alloc] initWithConfiguration:[RNVoipCall getProviderConfiguration:settings]];
    }
}

RCT_EXPORT_METHOD(initialize:(NSDictionary *)options)
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][initialize] options = %@", options);
#endif
    _version = [[[NSProcessInfo alloc] init] operatingSystemVersion];
    self.callKeepCallController = [[CXCallController alloc] init];
    NSDictionary *settings = [[NSMutableDictionary alloc] initWithDictionary:options];
    // Store settings in NSUserDefault
    [[NSUserDefaults standardUserDefaults] setObject:settings forKey:@"RNVoipCallSettings"];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [RNVoipCall initCallKitProvider];

    self.callKeepProvider = sharedProvider;
    [self.callKeepProvider setDelegate:self queue:nil];
}

RCT_REMAP_METHOD(checkIfBusy,
                 checkIfBusyWithResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][checkIfBusy]");
#endif
    resolve(@(self.callKeepCallController.callObserver.calls.count > 0));
}

RCT_REMAP_METHOD(checkSpeaker,
                 checkSpeakerResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][checkSpeaker]");
#endif
    NSString *output = [AVAudioSession sharedInstance].currentRoute.outputs.count > 0 ? [AVAudioSession sharedInstance].currentRoute.outputs[0].portType : nil;
    resolve(@([output isEqualToString:@"Speaker"]));
}

#pragma mark - CXCallController call actions

// Display the incoming call to the user
RCT_EXPORT_METHOD(displayIncomingCall:(NSString *)uuidString
                               handle:(NSString *)handle
                           handleType:(NSString *)handleType
                             hasVideo:(BOOL)hasVideo
                  localizedCallerName:(NSString * _Nullable)localizedCallerName)
{
    [RNVoipCall reportNewIncomingCall: uuidString handle:handle handleType:handleType hasVideo:hasVideo localizedCallerName:localizedCallerName fromPushKit: NO payload:nil withCompletionHandler:nil];
}

RCT_EXPORT_METHOD(startCall:(NSString *)uuidString
                     handle:(NSString *)handle
          contactIdentifier:(NSString * _Nullable)contactIdentifier
                 handleType:(NSString *)handleType
                      video:(BOOL)video)
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][startCall] uuidString = %@", uuidString);
#endif
    int _handleType = [RNVoipCall getHandleType:handleType];
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    CXHandle *callHandle = [[CXHandle alloc] initWithType:_handleType value:handle];
    CXStartCallAction *startCallAction = [[CXStartCallAction alloc] initWithCallUUID:uuid handle:callHandle];
    [startCallAction setVideo:video];
    [startCallAction setContactIdentifier:contactIdentifier];

    CXTransaction *transaction = [[CXTransaction alloc] initWithAction:startCallAction];

    [self requestTransaction:transaction];
}

RCT_EXPORT_METHOD(endCall:(NSString *)uuidString)
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][endCall] uuidString = %@", uuidString);
#endif
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    CXEndCallAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:uuid];
    CXTransaction *transaction = [[CXTransaction alloc] initWithAction:endCallAction];

    [self requestTransaction:transaction];
}

RCT_EXPORT_METHOD(endAllCalls)
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][endAllCalls] calls = %@", self.callKeepCallController.callObserver.calls);
#endif
    for (CXCall *call in self.callKeepCallController.callObserver.calls) {
        CXEndCallAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:call.UUID];
        CXTransaction *transaction = [[CXTransaction alloc] initWithAction:endCallAction];
        [self requestTransaction:transaction];
    }
}




RCT_EXPORT_METHOD(setOnHold:(NSString *)uuidString :(BOOL)shouldHold)
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][setOnHold] uuidString = %@, shouldHold = %d", uuidString, shouldHold);
#endif
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    CXSetHeldCallAction *setHeldCallAction = [[CXSetHeldCallAction alloc] initWithCallUUID:uuid onHold:shouldHold];
    CXTransaction *transaction = [[CXTransaction alloc] init];
    [transaction addAction:setHeldCallAction];

    [self requestTransaction:transaction];
}

RCT_EXPORT_METHOD(_startCallActionEventListenerAdded)
{
    _isStartCallActionEventListenerAdded = YES;
}

RCT_EXPORT_METHOD(reportConnectingOutgoingCallWithUUID:(NSString *)uuidString)
{
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    [self.callKeepProvider reportOutgoingCallWithUUID:uuid startedConnectingAtDate:[NSDate date]];
}

RCT_EXPORT_METHOD(reportConnectedOutgoingCallWithUUID:(NSString *)uuidString)
{
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    [self.callKeepProvider reportOutgoingCallWithUUID:uuid connectedAtDate:[NSDate date]];
}

RCT_EXPORT_METHOD(reportEndCallWithUUID:(NSString *)uuidString :(int)reason)
{
    [RNVoipCall endCallWithUUID: uuidString reason:reason];
}

RCT_EXPORT_METHOD(updateDisplay:(NSString *)uuidString :(NSString *)displayName :(NSString *)uri)
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][updateDisplay] uuidString = %@ displayName = %@ uri = %@", uuidString, displayName, uri);
#endif
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    CXHandle *callHandle = [[CXHandle alloc] initWithType:CXHandleTypePhoneNumber value:uri];
    CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
    callUpdate.localizedCallerName = displayName;
    callUpdate.remoteHandle = callHandle;
    [self.callKeepProvider reportCallWithUUID:uuid updated:callUpdate];
}

RCT_EXPORT_METHOD(setMutedCall:(NSString *)uuidString :(BOOL)muted)
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][setMutedCall] muted = %i", muted);
#endif
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    CXSetMutedCallAction *setMutedAction = [[CXSetMutedCallAction alloc] initWithCallUUID:uuid muted:muted];
    CXTransaction *transaction = [[CXTransaction alloc] init];
    [transaction addAction:setMutedAction];

    [self requestTransaction:transaction];
}

RCT_EXPORT_METHOD(sendDTMF:(NSString *)uuidString dtmf:(NSString *)key)
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][sendDTMF] key = %@", key);
#endif
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    CXPlayDTMFCallAction *dtmfAction = [[CXPlayDTMFCallAction alloc] initWithCallUUID:uuid digits:key type:CXPlayDTMFCallActionTypeHardPause];
    CXTransaction *transaction = [[CXTransaction alloc] init];
    [transaction addAction:dtmfAction];

    [self requestTransaction:transaction];
}

RCT_EXPORT_METHOD(isCallActive:(NSString *)uuidString)
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][isCallActive] uuid = %@", uuidString);
#endif
    [RNVoipCall isCallActive: uuidString];
}


//missed Call Notification
RCT_EXPORT_METHOD(showMissedCallNotification:
                  (NSString *)title
                  :(NSString *) body
                  :(NSString *) uuid
                  )
{
    
    [RNVoipCall sendMissedCallNotification:title body:body];
}


+ (void) sendMissedCallNotification: (NSString *)title
                               body: (NSString *)body
{
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
        UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
        
        content.title = title;
        content.body = body;
        content.sound = [UNNotificationSound defaultSound];
        
        
        
        UNTimeIntervalNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger
                                                      triggerWithTimeInterval:2 repeats:NO];
        UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:@"FiveSecond"
                                                                              content:content trigger:trigger];
        
        [center addNotificationRequest:request withCompletionHandler:nil];
        
    }
}


- (void)requestTransaction:(CXTransaction *)transaction
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][requestTransaction] transaction = %@", transaction);
#endif
    if (self.callKeepCallController == nil) {
        self.callKeepCallController = [[CXCallController alloc] init];
    }
    [self.callKeepCallController requestTransaction:transaction completion:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"[RNVoipCall][requestTransaction] Error requesting transaction (%@): (%@)", transaction.actions, error);
        } else {
            NSLog(@"[RNVoipCall][requestTransaction] Requested transaction successfully");

            // CXStartCallAction
            if ([[transaction.actions firstObject] isKindOfClass:[CXStartCallAction class]]) {
                CXStartCallAction *startCallAction = [transaction.actions firstObject];
                CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
                callUpdate.remoteHandle = startCallAction.handle;
                callUpdate.hasVideo = startCallAction.video;
                callUpdate.localizedCallerName = startCallAction.contactIdentifier;
                callUpdate.supportsDTMF = YES;
                callUpdate.supportsHolding = YES;
                callUpdate.supportsGrouping = YES;
                callUpdate.supportsUngrouping = YES;
                [self.callKeepProvider reportCallWithUUID:startCallAction.callUUID updated:callUpdate];
            }
        }
    }];
}

+ (BOOL)isCallActive:(NSString *)uuidString
{
    CXCallObserver *callObserver = [[CXCallObserver alloc] init];
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];

    for(CXCall *call in callObserver.calls){
        NSLog(@"[RNVoipCall] isCallActive %@ %d ?", call.UUID, [call.UUID isEqual:uuid]);
        if([call.UUID isEqual:[[NSUUID alloc] initWithUUIDString:uuidString]] && !call.hasConnected){
            return true;
        }
    }
    return false;
}

+ (void)showMissedCallNotification:(NSString *)title
                              body:(NSString *)body
                              uuid:(NSString *)uuid
{
    [RNVoipCall sendMissedCallNotification:title body:body];
}


+ (void)endCallWithUUID:(NSString *)uuidString
                 reason:(int)reason
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][reportEndCallWithUUID] uuidString = %@ reason = %d", uuidString, reason);
#endif
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    switch (reason) {
        case 1:
            [sharedProvider reportCallWithUUID:uuid endedAtDate:[NSDate date] reason:CXCallEndedReasonFailed];
            break;
        case 2:
        case 6:
            [sharedProvider reportCallWithUUID:uuid endedAtDate:[NSDate date] reason:CXCallEndedReasonRemoteEnded];
            break;
        case 3:
            [sharedProvider reportCallWithUUID:uuid endedAtDate:[NSDate date] reason:CXCallEndedReasonUnanswered];
            break;
        case 4:
            [sharedProvider reportCallWithUUID:uuid endedAtDate:[NSDate date] reason:CXCallEndedReasonAnsweredElsewhere];
            break;
        case 5:
            [sharedProvider reportCallWithUUID:uuid endedAtDate:[NSDate date] reason:CXCallEndedReasonDeclinedElsewhere];
            break;
        default:
            break;
    }
}

+ (void)reportNewIncomingCall:(NSString *)uuidString
                       handle:(NSString *)handle
                   handleType:(NSString *)handleType
                     hasVideo:(BOOL)hasVideo
          localizedCallerName:(NSString * _Nullable)localizedCallerName
                  fromPushKit:(BOOL)fromPushKit
                      payload:(NSDictionary * _Nullable)payload
{
    
    [RNVoipCall reportNewIncomingCall:uuidString handle:handle handleType:handleType hasVideo:hasVideo localizedCallerName:localizedCallerName fromPushKit:fromPushKit payload:payload withCompletionHandler:nil];
}





+ (void)reportNewIncomingCall:(NSString *)uuidString
                       handle:(NSString *)handle
                   handleType:(NSString *)handleType
                     hasVideo:(BOOL)hasVideo
          localizedCallerName:(NSString * _Nullable)localizedCallerName
                  fromPushKit:(BOOL)fromPushKit
                      payload:(NSDictionary * _Nullable)payload
        withCompletionHandler:(void (^_Nullable)(void))completion
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][reportNewIncomingCall] uuidString = %@", uuidString);
#endif
    callerName = [localizedCallerName stringByReplacingOccurrencesOfString:@"is Calling" withString:@" "];
    callerId = uuidString;
   

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 30000 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        [RNVoipCall callEndTimeout:uuidString];
    });
    
    
    
    int _handleType = [RNVoipCall getHandleType:handleType];
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
    callUpdate.remoteHandle = [[CXHandle alloc] initWithType:_handleType value:handle];
    callUpdate.supportsDTMF = YES;
    callUpdate.supportsHolding = YES;
    callUpdate.supportsGrouping = YES;
    callUpdate.supportsUngrouping = YES;
    callUpdate.hasVideo = hasVideo;
    callUpdate.localizedCallerName = localizedCallerName;

    [RNVoipCall initCallKitProvider];
    [sharedProvider reportNewIncomingCallWithUUID:uuid update:callUpdate completion:^(NSError * _Nullable error) {
        RNVoipCall *callKeep = [RNVoipCall allocWithZone: nil];
        [callKeep sendEventWithName:RNVoipCallDidDisplayIncomingCall body:@{
            @"error": error && error.localizedDescription ? error.localizedDescription : @"",
            @"callUUID": uuidString,
            @"handle": handle,
            @"localizedCallerName": localizedCallerName ? localizedCallerName : @"",
            @"hasVideo": hasVideo ? @"1" : @"0",
            @"fromPushKit": fromPushKit ? @"1" : @"0",
            @"payload": payload ? payload : @"",
        }];
        if (error == nil) {
            // Workaround per https://forums.developer.apple.com/message/169511
            if ([callKeep lessThanIos10_2]) {
                [callKeep configureAudioSession];
            }
        }
        if (completion != nil) {
            completion();
        }
    }];
}

+ (void)reportNewIncomingCall:(NSString *)uuidString
                       handle:(NSString *)handle
                   handleType:(NSString *)handleType
                     hasVideo:(BOOL)hasVideo
          localizedCallerName:(NSString * _Nullable)localizedCallerName
                  fromPushKit:(BOOL)fromPushKit
{
    [RNVoipCall reportNewIncomingCall: uuidString handle:handle handleType:handleType hasVideo:hasVideo localizedCallerName:localizedCallerName fromPushKit: fromPushKit payload:nil withCompletionHandler:nil];
}




+ (void) callEndTimeout:
            (NSString *) uuidString

{
        if(!callAttended){
            [RNVoipCall endCallWithUUID: uuidString reason:3];
//              [RNVoipCall sendMissedCallNotification:callerName body:[@"You Have Missed Call from " stringByAppendingString:callerName]];
            callerName = @"";
            callerId = @"";
        }
    NSLog(@"fired!");
}



- (BOOL)lessThanIos10_2
{
    if (_version.majorVersion < 10) {
        return YES;
    } else if (_version.majorVersion > 10) {
        return NO;
    } else {
        return _version.minorVersion < 2;
    }
}

+ (int)getHandleType:(NSString *)handleType
{
    int _handleType;
    if ([handleType isEqualToString:@"generic"]) {
        _handleType = CXHandleTypeGeneric;
    } else if ([handleType isEqualToString:@"number"]) {
        _handleType = CXHandleTypePhoneNumber;
    } else if ([handleType isEqualToString:@"email"]) {
        _handleType = CXHandleTypeEmailAddress;
    } else {
        _handleType = CXHandleTypeGeneric;
    }
    return _handleType;
}

+ (CXProviderConfiguration *)getProviderConfiguration:(NSDictionary*)settings
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][getProviderConfiguration]");
#endif
    CXProviderConfiguration *providerConfiguration = [[CXProviderConfiguration alloc] initWithLocalizedName:settings[@"appName"]];
    providerConfiguration.supportsVideo = YES;
    providerConfiguration.maximumCallGroups = 3;
    providerConfiguration.maximumCallsPerCallGroup = 1;
    if(settings[@"handleType"]){
        int _handleType = [RNVoipCall getHandleType:settings[@"handleType"]];
        providerConfiguration.supportedHandleTypes = [NSSet setWithObjects:[NSNumber numberWithInteger:_handleType], nil];
    }else{
        providerConfiguration.supportedHandleTypes = [NSSet setWithObjects:[NSNumber numberWithInteger:CXHandleTypeGeneric], nil];
    }
    if (settings[@"supportsVideo"]) {
        providerConfiguration.supportsVideo = [settings[@"supportsVideo"] boolValue];
    }
    if (settings[@"maximumCallGroups"]) {
        providerConfiguration.maximumCallGroups = [settings[@"maximumCallGroups"] integerValue];
    }
    if (settings[@"maximumCallsPerCallGroup"]) {
        providerConfiguration.maximumCallsPerCallGroup = [settings[@"maximumCallsPerCallGroup"] integerValue];
    }
    if (settings[@"imageName"]) {
        providerConfiguration.iconTemplateImageData = UIImagePNGRepresentation([UIImage imageNamed:settings[@"imageName"]]);
    }
    if (settings[@"ringtoneSound"]) {
        providerConfiguration.ringtoneSound = settings[@"ringtoneSound"];
    }
    if (@available(iOS 11.0, *)) {
        if (settings[@"includesCallsInRecents"]) {
            providerConfiguration.includesCallsInRecents = [settings[@"includesCallsInRecents"] boolValue];
        }
    }
    return providerConfiguration;
}

- (void)configureAudioSession
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][configureAudioSession] Activating audio session");
#endif

    AVAudioSession* audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionAllowBluetooth error:nil];

    [audioSession setMode:AVAudioSessionModeVoiceChat error:nil];

    double sampleRate = 44100.0;
    [audioSession setPreferredSampleRate:sampleRate error:nil];

    NSTimeInterval bufferDuration = .005;
    [audioSession setPreferredIOBufferDuration:bufferDuration error:nil];
    [audioSession setActive:TRUE error:nil];
}

+ (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options NS_AVAILABLE_IOS(9_0)
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][application:openURL]");
#endif
    /*
    NSString *handle = [url startCallHandle];
    if (handle != nil && handle.length > 0 ){
        NSDictionary *userInfo = @{
            @"handle": handle,
            @"video": @NO
        };
        [[NSNotificationCenter defaultCenter] postNotificationName:RNVoipCallHandleStartCallNotification
                                                            object:self
                                                          userInfo:userInfo];
        return YES;
    }
    return NO;
    */
    return YES;
}

+ (BOOL)application:(UIApplication *)application
continueUserActivity:(NSUserActivity *)userActivity
 restorationHandler:(void(^)(NSArray * __nullable restorableObjects))restorationHandler
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][application:continueUserActivity]");
#endif
    INInteraction *interaction = userActivity.interaction;
    INPerson *contact;
    NSString *handle;
    BOOL isAudioCall;
    BOOL isVideoCall;

//HACK TO AVOID XCODE 10 COMPILE CRASH
//REMOVE ON NEXT MAJOR RELEASE OF RNCALLKIT
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    //XCode 11
    // iOS 13 returns an INStartCallIntent userActivity type
    if (@available(iOS 13, *)) {
        INStartCallIntent *intent = (INStartCallIntent*)interaction.intent;
        // callCapability is not available on iOS > 13.2, but it is in 13.1 weirdly...
        if ([intent respondsToSelector:@selector(callCapability)]) {
            isAudioCall = intent.callCapability == INCallCapabilityAudioCall;
            isVideoCall = intent.callCapability == INCallCapabilityVideoCall;
        } else {
            isAudioCall = [userActivity.activityType isEqualToString:INStartAudioCallIntentIdentifier];
            isVideoCall = [userActivity.activityType isEqualToString:INStartVideoCallIntentIdentifier];
        }
    } else {
#endif
        //XCode 10 and below
        isAudioCall = [userActivity.activityType isEqualToString:INStartAudioCallIntentIdentifier];
        isVideoCall = [userActivity.activityType isEqualToString:INStartVideoCallIntentIdentifier];
//HACK TO AVOID XCODE 10 COMPILE CRASH
//REMOVE ON NEXT MAJOR RELEASE OF RNCALLKIT
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    }
#endif

    if (isAudioCall) {
        INStartAudioCallIntent *startAudioCallIntent = (INStartAudioCallIntent *)interaction.intent;
        contact = [startAudioCallIntent.contacts firstObject];
    } else if (isVideoCall) {
        INStartVideoCallIntent *startVideoCallIntent = (INStartVideoCallIntent *)interaction.intent;
        contact = [startVideoCallIntent.contacts firstObject];
    }

    if (contact != nil) {
        handle = contact.personHandle.value;
    }

    if (handle != nil && handle.length > 0 ){
        NSDictionary *userInfo = @{
            @"handle": handle,
            @"video": @(isVideoCall)
        };

        RNVoipCall *callKeep = [RNVoipCall allocWithZone: nil];
        [callKeep handleStartCallNotification: userInfo];
        return YES;
    }
    return NO;
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

- (void)handleStartCallNotification:(NSDictionary *)userInfo
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][handleStartCallNotification] userInfo = %@", userInfo);
#endif
    int delayInSeconds;
    if (!_isStartCallActionEventListenerAdded) {
        // Workaround for when app is just launched and JS side hasn't registered to the event properly
        delayInSeconds = OUTGOING_CALL_WAKEUP_DELAY;
    } else {
        delayInSeconds = 0;
    }
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        [self sendEventWithName:RNVoipCallDidReceiveStartCallAction body:userInfo];
    });
}

#pragma mark - CXProviderDelegate

- (void)providerDidReset:(CXProvider *)provider{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][providerDidReset]");
#endif
    //this means something big changed, so tell the JS. The JS should
    //probably respond by hanging up all calls.
    [self sendEventWithName:RNVoipCallProviderReset body:nil];
}

// Starting outgoing call
- (void)provider:(CXProvider *)provider performStartCallAction:(CXStartCallAction *)action
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][CXProviderDelegate][provider:performStartCallAction]");
#endif
    //do this first, audio sessions are flakey
    [self configureAudioSession];
    //tell the JS to actually make the call
    [self sendEventWithName:RNVoipCallDidReceiveStartCallAction body:@{ @"callUUID": [action.callUUID.UUIDString lowercaseString], @"handle": action.handle.value }];
    [action fulfill];
}

// Update call contact info
// @deprecated
RCT_EXPORT_METHOD(reportUpdatedCall:(NSString *)uuidString contactIdentifier:(NSString *)contactIdentifier)
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][reportUpdatedCall] contactIdentifier = %i", contactIdentifier);
#endif
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:uuidString];
    CXCallUpdate *callUpdate = [[CXCallUpdate alloc] init];
    callUpdate.localizedCallerName = contactIdentifier;

    [self.callKeepProvider reportCallWithUUID:uuid updated:callUpdate];
}

// Answering incoming call
- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][CXProviderDelegate][provider:performAnswerCallAction]");
#endif
    callAttended = TRUE;
    [self configureAudioSession];
    [self sendEventWithName:RNVoipCallPerformAnswerCallAction body:@{ @"callUUID": [action.callUUID.UUIDString lowercaseString] }];
    [action fulfill];
}

// Ending incoming call
- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][CXProviderDelegate][provider:performEndCallAction]%@", action);
#endif
    
//    if(!callAttended){
//        [RNVoipCall sendMissedCallNotification:callerName body:[@"You Have Missed Call from " stringByAppendingString:callerName]];
//    }
    callerName = @"";
    callerId = @"";
    callAttended = FALSE;
    
    [self sendEventWithName:RNVoipCallPerformEndCallAction body:@{ @"callUUID": [action.callUUID.UUIDString lowercaseString] }];
    [action fulfill];
}

-(void)provider:(CXProvider *)provider performSetHeldCallAction:(CXSetHeldCallAction *)action
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][CXProviderDelegate][provider:performSetHeldCallAction]");
#endif

    [self sendEventWithName:RNVoipCallDidToggleHoldAction body:@{ @"hold": @(action.onHold), @"callUUID": [action.callUUID.UUIDString lowercaseString] }];
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performPlayDTMFCallAction:(CXPlayDTMFCallAction *)action {
#ifdef DEBUG
    NSLog(@"[RNVoipCall][CXProviderDelegate][provider:performPlayDTMFCallAction]");
#endif
    [self sendEventWithName:RNVoipCallPerformPlayDTMFCallAction body:@{ @"digits": action.digits, @"callUUID": [action.callUUID.UUIDString lowercaseString] }];
    [action fulfill];
}

-(void)provider:(CXProvider *)provider performSetMutedCallAction:(CXSetMutedCallAction *)action
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][CXProviderDelegate][provider:performSetMutedCallAction]");
#endif

    [self sendEventWithName:RNVoipCallDidPerformSetMutedCallAction body:@{ @"muted": @(action.muted), @"callUUID": [action.callUUID.UUIDString lowercaseString] }];
    [action fulfill];
}

- (void)provider:(CXProvider *)provider timedOutPerformingAction:(CXAction *)action
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][CXProviderDelegate][provider:timedOutPerformingAction]");
#endif
}

- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][CXProviderDelegate][provider:didActivateAudioSession]");
#endif
    NSDictionary *userInfo
    = @{
        AVAudioSessionInterruptionTypeKey: [NSNumber numberWithInt:AVAudioSessionInterruptionTypeEnded],
        AVAudioSessionInterruptionOptionKey: [NSNumber numberWithInt:AVAudioSessionInterruptionOptionShouldResume]
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:AVAudioSessionInterruptionNotification object:nil userInfo:userInfo];

    [self configureAudioSession];
    [self sendEventWithName:RNVoipCallDidActivateAudioSession body:nil];
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession
{
#ifdef DEBUG
    NSLog(@"[RNVoipCall][CXProviderDelegate][provider:didDeactivateAudioSession]");
#endif
    [self sendEventWithName:RNVoipCallDidDeactivateAudioSession body:nil];
}

@end
