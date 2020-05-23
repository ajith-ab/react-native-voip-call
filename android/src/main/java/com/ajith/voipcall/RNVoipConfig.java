package com.ajith.voipcall;

import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;

import java.util.Random;

public class RNVoipConfig {
    public static WritableMap callNotificationConfig(ReadableMap json) {

        WritableMap config = new WritableNativeMap();

        if(checkType(json , "notificationId", "Number")){
            config.putInt("notificationId", json.getInt("notificationId"));
        }else{
            int id = new Random().nextInt(10000);
            config.putInt("notificationId", id);
        }
        if(checkType(json , "ringtuneSound", "Boolean")){
            config.putBoolean("ringtuneSound", json.getBoolean("ringtuneSound"));
        }else{
            config.putBoolean("ringtuneSound", false);
        }
        if(checkType(json , "vibration", "Boolean")){
            config.putBoolean("vibration", json.getBoolean("vibration"));
        }else{
            config.putBoolean("vibration", false);
        }
        if(checkType(json , "ringtune", "String")){
            config.putString("ringtune", json.getString("ringtune"));
        }else{
            config.putString("ringtune", "defualt");
        }
        if(checkType(json , "channel_name", "String")){
            config.putString("channel_name", json.getString("channel_name"));
        }else{
            config.putString("channel_name", "call");
        }
        if(checkType(json , "duration", "Number")){
            config.putInt("duration", json.getInt("duration"));
        }else{
            config.putInt("duration", 30000);
        }

        //Notification Contents

        if(checkType(json , "notificationTitle", "String")){
            config.putString("notificationTitle", json.getString("notificationTitle"));
        }else{
            config.putString("notificationTitle", "Incomming Call");
        }
        if(checkType(json , "notificationBody", "String")){
            config.putString("notificationBody", json.getString("notificationBody"));
        }else{
            config.putString("notificationBody", "Some one is Calling uuuu...");
        }
        if(checkType(json , "answerActionTitle", "String")){
            config.putString("answerActionTitle", json.getString("answerActionTitle"));
        }else{
            config.putString("answerActionTitle", "ANSWER");
        }
        if(checkType(json , "declineActionTitle", "String")){
            config.putString("declineActionTitle", json.getString("declineActionTitle"));
        }else{
            config.putString("declineActionTitle", "DECLINE");
        }

        //Missed Call
        if(checkType(json , "missedCallTitle", "String")){
            config.putString("missedCallTitle", json.getString("missedCallTitle"));
        }else{
            config.putString("missedCallTitle", "Missed Call");
        }
        if(checkType(json , "missedCallBody", "String")){
            config.putString("missedCallBody", json.getString("missedCallBody"));
        }else{
            config.putString("missedCallBody", "You have a Missed call from Someone.");
        }

        //Caller Data
        if(checkType(json , "callerId", "String")){
            config.putString("callerId", json.getString("callerId"));
        }else{
            config.putString("callerId", "123456789");
        }
        return config;
    }

    public static boolean checkType(ReadableMap json, String key , String type){
        try{
            if(json.hasKey(key) && json.getType(key).toString().equals(type)){
                if(type.equals("String") && json.getType(key).toString().equals("String") && json.getString(key).toString().isEmpty()){
                    return false;
                }
                return  true;
            }
        }catch (Exception e){
            return false;
        }
        return false;
    };
}