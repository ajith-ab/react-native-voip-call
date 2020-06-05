import { NativeModules, Platform, NativeEventEmitter } from 'react-native';
import { listeners }  from './listner';

var RNVoipCall = NativeModules.RNVoipCall;

const IsIOS = Platform.OS === 'ios';


class RNVoipCallNativeModule {

    constructor() {
        this.rnVoipCallEventHandlers = new Map();
    }


    addEventListener = (type, handler) => {
        const listener = listeners[type](handler);

        this.rnVoipCallEventHandlers.set(type, listener);
    };


    removeEventListener = (type) => {
        const listener = this.rnVoipCallEventHandlers.get(type);
        if (!listener) {
            return;
        }

        listener.remove();
        this.rnVoipCallEventHandlers.delete(type);
    };


    initializeCall = async (options) => new Promise((resolve, reject) => {
        if (!options.appName) {
            reject({ error: true, message: 'appName is required' });
        }
        if (typeof options.appName !== 'string') {
            reject({ error: true, message: 'appName should be of type "string"' });
        }
        if (!IsIOS) {
            reject({ error: true, message: 'Android not required' })
        }
        resolve(RNVoipCall.initialize(options));

    });

    
    
    displayIncomingCall = (options) => new Promise((resolve, reject)=>{
        if(!options.ios || !options.android){
            reject({error:true, message:'ios and android object is required'});
        }
        if(!options.callerId){
            reject({error:true, message:'Caller Id Must be required'});
        }
        
        if(!IsIOS){
            let androidOptions = this.getDefualtValues(options.android);
            RNVoipCall.displayIncomingCall({callerId:options.callerId, ...androidOptions})
        }else{
            let iosOptions = this.getDefualtValues(options.ios);
            RNVoipCall.endAllCalls();
            resolve(
            RNVoipCall.displayIncomingCall(options.callerId, iosOptions.phoneNumber, iosOptions.handleType , iosOptions.hasVideo , iosOptions.name))
        }
        
    })

    getDefualtValues = (object) => {
        let finalData = {};
        if(IsIOS){
            finalData['phoneNumber'] = object.phoneNumber ? object.phoneNumber : '1234567890';
            finalData['handleType'] = object.handleType ? object.handleType : 'number';
            finalData['hasVideo'] = object.hasVideo ? object.hasVideo : false;
            finalData['name'] = object.name ? object.name : 'Caller Name';
            return finalData;
        }else{
            
            return object;
        }
    }
    
    
    getInitialNotificationActions = () => new Promise((resolve, reject) => {
        if(!IsIOS){
            RNVoipCall.getInitialNotificationActions().then(data=>resolve(data)).catch(e=>reject(e));
        }else{
            reject({error:true, message:"ios not supported"});
        }
    });
    
   

    //Event Listner
    
    onCallAnswer = (handler) => {  
        this.addEventListener('answerCall', handler);
    }
    
    onEndCall = (handler) => {
        this.addEventListener('endCall', handler);
    }
    
    //android
    onCallOpenAppEvent = (handler) => {
        if(!IsIOS){
            this.addEventListener('onCallOpenAppEvent', handler);
        }
        
    }
    
    onCallNotificationOpen = (handler) => {
        if(!IsIOS){
            this.addEventListener('onCallNotificationOpen', handler);
        }
    }
    
    
    onMissedCallOpen =  (handler) => {
        if(!IsIOS){
            this.addEventListener('onMissedCallOpen', handler);
        }
    }
    
    
    //IOS Only
    rejectCall = (uuid) => {
        if (IsIOS) {
           RNVoipCall.endCall(uuid);
        } 
      };
    
      isCallActive = async(uuid) => IsIOS ? await RNVoipCall.isCallActive(uuid) : null;
    
      endCall = (uuid) => IsIOS ?  RNVoipCall.endCall(uuid) : RNVoipCall.clearNotificationById(uuid);
    
      endAllCalls = () => IsIOS ?   RNVoipCall.endAllCalls() : RNVoipCall.clearAllNotifications();
    
      
      //Android Only
      
      playRingtune = (name, loop) => {
          if(!IsIOS){
            let fileName = name ? name : 'ringtune';
            let looping = loop || loop === false ? loop : false;
            RNVoipCall.playRingtune(fileName, looping);
          }
      }
      
      stopRingtune = () => !IsIOS ? RNVoipCall.stopRingtune() : null;
      
      //Missed Call
      showMissedCallNotification = (title, body, uuid) => RNVoipCall.showMissedCallNotification(title,body,uuid);
    
    
}

export default new RNVoipCallNativeModule();