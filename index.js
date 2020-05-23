'use strict';

import { NativeModules, DeviceEventEmitter, Platform } from 'react-native';

import RNVoipPushKitNativeModule from './lib/iosPushKit';
import RNVoipCallNativeModule from './lib/RNVoipCall';

export const RNVoipPushKit = RNVoipPushKitNativeModule;

export default RNVoipCallNativeModule;