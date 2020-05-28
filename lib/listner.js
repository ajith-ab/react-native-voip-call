import { NativeModules, NativeEventEmitter, Platform } from 'react-native';

const RNVoipCallModule = NativeModules.RNVoipCall;
const eventEmitter = new NativeEventEmitter(RNVoipCallModule);

const RNVoipCallPerformAnswerCallAction = 'RNVoipCallPerformAnswerCallAction';
const RNVoipCallPerformEndCallAction = 'RNVoipCallPerformEndCallAction';
const RNVoipCallMissedCallTap = 'RNVoipCallMissedCallTap';

//Ios
const RNVoipCallDidReceiveStartCallAction = 'RNVoipCallDidReceiveStartCallAction';
const RNVoipCallDidActivateAudioSession = 'RNVoipCallDidActivateAudioSession';
const RNVoipCallDidDeactivateAudioSession = 'RNVoipCallDidDeactivateAudioSession';
const RNVoipCallDidDisplayIncomingCall = 'RNVoipCallDidDisplayIncomingCall';
const RNVoipCallDidPerformSetMutedCallAction = 'RNVoipCallDidPerformSetMutedCallAction';
const RNVoipCallDidToggleHoldAction = 'RNVoipCallDidToggleHoldAction';
const RNVoipCallDidPerformDTMFAction = 'RNVoipCallDidPerformDTMFAction';
const RNVoipCallProviderReset = 'RNVoipCallProviderReset';
const RNVoipCallCheckReachability = 'RNVoipCallCheckReachability';

//Android
const RNVoipCallFullScreenIntent = 'RNVoipCallFullScreenIntent';
const RNVoipCallNotificationTap = 'RNVoipCallNotificationTap';

const isIOS = Platform.OS === 'ios';

const didReceiveStartCallAction = handler => {
  if (isIOS) {
    // Tell CallKeep that we are ready to receive `RNVoipCallDidReceiveStartCallAction` event and prevent delay
    RNVoipCallModule._startCallActionEventListenerAdded();
  }

  return eventEmitter.addListener(RNVoipCallDidReceiveStartCallAction, (data) => handler(data));
};

const answerCall = handler =>
  eventEmitter.addListener(RNVoipCallPerformAnswerCallAction, (data) => {
    let uuids = isIOS ? data.callUUID : data.callerId;
    handler({callerId : uuids})}
  );

const endCall = handler =>
  eventEmitter.addListener(RNVoipCallPerformEndCallAction, (data) =>{
    let uuids = isIOS ? data.callUUID : data.callerId;
    handler({callerId : uuids})}
  );

const didActivateAudioSession = handler =>
  eventEmitter.addListener(RNVoipCallDidActivateAudioSession, handler);

const didDeactivateAudioSession = handler =>
  eventEmitter.addListener(RNVoipCallDidDeactivateAudioSession, handler);

const didDisplayIncomingCall = handler =>
  eventEmitter.addListener(RNVoipCallDidDisplayIncomingCall, (data) => handler(data));

const didPerformSetMutedCallAction = handler =>
  eventEmitter.addListener(RNVoipCallDidPerformSetMutedCallAction, (data) => handler(data));

const didToggleHoldCallAction = handler =>
  eventEmitter.addListener(RNVoipCallDidToggleHoldAction, handler);

const didPerformDTMFAction = handler =>
  eventEmitter.addListener(RNVoipCallDidPerformDTMFAction, (data) => handler(data));

const didResetProvider = handler =>
  eventEmitter.addListener(RNVoipCallProviderReset, handler);

const checkReachability = handler =>
  eventEmitter.addListener(RNVoipCallCheckReachability, handler);  
  
const onMissedCallOpen = handler =>
  eventEmitter.addListener(RNVoipCallMissedCallTap, handler);
  
//Android Only
const onCallOpenAppEvent = handler =>
  eventEmitter.addListener(RNVoipCallFullScreenIntent, handler);
  
const onCallNotificationOpen = handler =>
  eventEmitter.addListener(RNVoipCallNotificationTap, handler);  

export const listeners = {
  didReceiveStartCallAction,
  answerCall,
  endCall,
  didActivateAudioSession,
  didDeactivateAudioSession,
  didDisplayIncomingCall,
  didPerformSetMutedCallAction,
  didToggleHoldCallAction,
  didPerformDTMFAction,
  didResetProvider,
  checkReachability,
  onMissedCallOpen,
  onCallNotificationOpen,
  onCallOpenAppEvent
  
};