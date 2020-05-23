import React, {useEffect, useState } from 'react';
import {
  View,
  Text,
  Platform,
  Button
} from 'react-native';
import RNVoipCall, { RNVoipPushKit } from 'react-native-voip-call';



const IsIos = Platform.OS === 'ios';

const log = (data) => console.log('RNVoipCall===> ',data);


const App = () => {
  const [pushkitToken, setPushkitToken] = useState(''); 
  const [callStatus ,setCallStatus] = useState('no call initlized');
  
  
  useEffect(()=>{  
    iosPushKit(); 
    callKit();
    rnVoipCallListners();
  },[])
  
  
  
  const rnVoipCallListners = async () => {
    RNVoipCall.onCallAnswer(data => {
     setCallStatus('call Answed')
      console.log(data);
    });
    
    RNVoipCall.onEndCall(data=> {
     setCallStatus('call Ended');
     console.log("call endede",data);
    })
  } 
  
  
  
  const iosPushKit = () => {
    if(IsIos){
      //For Push Kit
      RNVoipPushKit.requestPermissions();              // --- optional, you can use another library to request permissions
       //Ios PushKit device token Listner
      RNVoipPushKit.getPushKitDeviceToken((res) => {
        if(res.platform === 'ios'){
            setPushkitToken(res.deviceToken)
        }
       });
       //On Remote Push notification Recived in Forground
       RNVoipPushKit.RemotePushKitNotificationReceived((notification)=>{
           log(notification);
       });
    }
  }
  
  
  const callKit = () => { 
    let options = {
      appName:'RNVoip App',
    }
    // Initlize Call Kit IOS is Required
    RNVoipCall.initializeCall(options).then(()=>{
     //Success Call Back
    }).catch(e=>console.log(e));
  
  }
  
  const displayIncommingCall = () => {
    let callOptions = {
      callerId:'825f4094-a674-4765-96a7-1ac512c02a71', // Important uuid must in this format
       ios:{
        phoneNumber:'12344', // Caller Mobile Number
        name:'Ajith', // caller Name
        hasVideo:true
       },
       android:{
        ringtuneSound: true, // defualt true
        ringtune: 'ringtune', // add file inside Project_folder/android/app/res/raw
        duration: 20000, // defualt 30000
        vibration: true, // defualt is true
        channel_name: 'call1asd', // 
        notificationId: 1121,
        notificationTitle: 'Incomming Call',
        notificationBody: 'Some One is Calling...',
        answerActionTitle: 'Answer',
        declineActionTitle: 'Decline',
    
        missedCallTitle: 'Ajith A B',
        missedCallBody: 'You have a Missed Call From Ajith A B'
       }
     }

     RNVoipCall.displayIncomingCall(callOptions).then((data)=>{
       console.log(data)
     }).catch(e=>console.log(e))
    
    
  }
  
  
  const showMissedCall = () => {
    RNVoipCall.showMissedCallNotification("title","body");
  }
  
  
  
  
  return (
      <View>
        <Text>
          {"push kit token:" + pushkitToken}
        </Text>
        <Text>{`call Status: ${callStatus}`}</Text>
        <Button onPress={()=>displayIncommingCall()} title="Show Incomming Call" />
        <Button onPress={()=>showMissedCall()} title="Show Missed Call" />
      </View>
  );
};

const styles = StyleSheet.create({

});

export default App;
