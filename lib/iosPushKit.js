'use strict';

import {
    NativeModules,
    DeviceEventEmitter,
    Platform,
} from 'react-native';

var RNVoipPushKit = NativeModules.RNVoipPushKit;

var invariant = require('fbjs/lib/invariant');
var _notifHandlers = new Map();

const IsIOS =  Platform.OS === 'ios';

export default class RNVoipCallNativeModule {
    // voip ios 
    static getPushKitDeviceToken(handler) {
        if(IsIOS){
            RNVoipPushKit.registerVoipToken();
            let type = 'register'
            invariant(
                type === 'register' ,
                'RNVoipCall only supports `register` events'
            );
            var listener;
          if (type === 'register') {
                listener = DeviceEventEmitter.addListener(
                    "voipRemoteNotificationsRegistered",
                    (registrationInfo) => {
                        handler({...registrationInfo, platform:Platform.OS });
                        this.removeEventListener('register')
                    }
                );
            }
            _notifHandlers.set(handler, listener);
        }else{
            handler({ platform:Platform.OS })
        }
    }
    
    
    static RemotePushKitNotificationReceived(handler){
        if(IsIOS){
            let type = 'notification'
            invariant(
                type === 'notification' ,
                'RNVoipCall only supports `register` events'
            );
            var listener;
          if (type === 'notification') {
                listener = DeviceEventEmitter.addListener(
                    'voipRemoteNotificationReceived',
                    (registrationInfo) => {
                        console.log('voipRemoteNotificationReceived' ,registrationInfo);
                        handler({...registrationInfo, platform:Platform.OS });
                        this.removeEventListener('notification')
                    }
                );
            }
            _notifHandlers.set(handler, listener);
        }else{
            handler({ platform:Platform.OS })
        }
        
        
    }
    
    
    /**
     * Removes the event listener. Do this in `componentWillUnmount` to prevent
     * memory leaks
     */
    static removeEventListener(type, handler) {
        invariant(
            type === 'notification' || type === 'register' ,
            'RNVoipPushNotification only supports `notification`, `register` and `localNotification` events'
        );
        var listener = _notifHandlers.get(handler);
        if (!listener) {
            return;
        }
        listener.remove();
        _notifHandlers.delete(handler);
    }

    static requestPermissions(permissions) {
        var requestedPermissions = {};
        if (permissions) {
            requestedPermissions = {
                alert: !!permissions.alert,
                badge: !!permissions.badge,
                sound: !!permissions.sound
            };
        } else {
            requestedPermissions = {
                alert: true,
                badge: true,
                sound: true
            };
        }
        
        if(IsIOS){
            RNVoipPushKit.requestPermissions(requestedPermissions);
        }else{
            return null;
        }
       
    }
    
}