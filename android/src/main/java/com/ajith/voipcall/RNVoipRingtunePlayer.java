package com.ajith.voipcall;

import android.content.Context;
import android.content.Intent;
import android.media.MediaPlayer;
import android.net.Uri;

import com.facebook.react.bridge.ReadableMap;

public class RNVoipRingtunePlayer {
    private static RNVoipRingtunePlayer sInstance;
        private Context mContext;
        private MediaPlayer mMediaPlayer;

        public RNVoipRingtunePlayer(Context context) {
            mContext = context;
        }

        public static RNVoipRingtunePlayer getInstance(Context context) {
            if (sInstance == null) {
                sInstance = new RNVoipRingtunePlayer(context);
            }
            return sInstance;
        }

        public void playMusic(ReadableMap jsonObject) {
            String fileName = jsonObject.getString("ringtune");
            notificationRingtune(fileName);
            mMediaPlayer.setLooping(true);
            if(!mMediaPlayer.isPlaying()){
                mMediaPlayer.start();
                cancelWithTimeOut(jsonObject);
            }
        }

        public void notificationRingtune(String fileName){
            int resId;
            Uri sounduri;
            try{
                resId = mContext.getResources().getIdentifier(fileName, "raw", mContext.getPackageName());
                if(resId != 0){
                    sounduri = Uri.parse("android.resource://" + mContext.getPackageName() + "/"+resId);
                }else {
                    sounduri = Uri.parse("android.resource://" + mContext.getPackageName() + "/"+ R.raw.ringtune);
                }

            }catch (Exception e){
                sounduri = Uri.parse("android.resource://" + mContext.getPackageName() + "/"+ R.raw.ringtune);
            }

            mMediaPlayer = MediaPlayer.create(mContext, sounduri);

        }



        public void playRingtune(String fileName,Boolean isLooping){
            notificationRingtune(fileName);
            if(!mMediaPlayer.isPlaying()){
                mMediaPlayer.setLooping(isLooping);
                mMediaPlayer.start();
            }
        }

        public void cancelWithTimeOut(ReadableMap jsonObject){
            int duration = jsonObject.getInt("duration");
            final ReadableMap json = jsonObject;
            new android.os.Handler().postDelayed(
                    new Runnable() {
                        public void run() {
                            if(mMediaPlayer.isPlaying()) {
                                Intent intent = new Intent(mContext, RNVoipBroadcastReciever.class);
                                intent.setAction("callTimeOut");
                                intent.putExtra("callerId", json.getString("callerId"));
                                intent.putExtra("missedCallTitle", json.getString("missedCallTitle"));
                                intent.putExtra("missedCallBody", json.getString("missedCallBody"));
                                mContext.sendBroadcast(intent);
                                stopMusic();
                            }
                        }
                    }, duration);
        }

        public void stopMusic() {
            if(mMediaPlayer != null) {
                mMediaPlayer.stop();
                mMediaPlayer.seekTo(0);
            }
        }
}
