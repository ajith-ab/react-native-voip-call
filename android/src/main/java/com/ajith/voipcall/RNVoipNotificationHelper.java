package com.ajith.voipcall;

import android.app.Application;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Intent;

import androidx.core.app.NotificationCompat;
import android.content.Context;
import android.media.AudioAttributes;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.Build;
import android.util.Log;
import android.widget.RemoteViews;
import android.widget.TextView;

import com.facebook.react.bridge.ReadableMap;

public class RNVoipNotificationHelper {
    public final String callChannel = "Call";
    public  final  String notificationChannel = "NotificationChannel";
    private Context context;
    public TextView newText;


    public RNVoipNotificationHelper(Application context){
        this.context = context;
    }

    public Class getMainActivityClass() {
        String packageName = context.getPackageName();
        Intent launchIntent = context.getPackageManager().getLaunchIntentForPackage(packageName);
        String className = launchIntent.getComponent().getClassName();
        try {
            return Class.forName(className);
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
            return null;
        }
    }


    public void sendCallNotification(ReadableMap jsonObject){
        if(jsonObject.getBoolean("ringtuneSound") == true){
            RNVoipRingtunePlayer.getInstance(context).playMusic(jsonObject);
        }
        sendNotification(jsonObject);
    }


    public void sendNotification(ReadableMap json){
        int notificationID = json.getInt("notificationId");

        Intent dissmissIntent = new Intent(context, RNVoipBroadcastReciever.class);
        dissmissIntent.setAction("callDismiss");
        dissmissIntent.putExtra("notificationId",notificationID);
        dissmissIntent.putExtra("callerId", json.getString("callerId"));
        dissmissIntent.putExtra("missedCallTitle", json.getString("missedCallTitle"));
        dissmissIntent.putExtra("missedCallBody", json.getString("missedCallBody"));
        // PendingIntent callDismissIntent = PendingIntent.getBroadcast(context,0, dissmissIntent ,PendingIntent.FLAG_UPDATE_CURRENT);
        PendingIntent callDismissIntent = PendingIntent.getBroadcast(context,0, dissmissIntent ,PendingIntent.FLAG_IMMUTABLE);

        Uri sounduri = Uri.parse("android.resource://" + context.getPackageName() + "/"+ R.raw.nosound);

        RemoteViews notificationLayout = new RemoteViews(context.getPackageName(), R.layout.layout);
        
        /**Decline button */
        notificationLayout.setOnClickPendingIntent(R.id.btnDecline, callDismissIntent);
        notificationLayout.setTextViewText(R.id.btnDecline, json.getString("declineActionTitle"));

        /**Accept button */
        notificationLayout.setOnClickPendingIntent(R.id.btnAccept, getPendingIntent(notificationID, "callAnswer",json));
        notificationLayout.setTextViewText(R.id.btnAccept, json.getString("answerActionTitle"));
        
        /**Notification title */
        notificationLayout.setTextViewText(R.id.txtTitle, json.getString("notificationBody"));

        /**Build a notification */
        Notification notification = new NotificationCompat.Builder(context,callChannel)
                .setAutoCancel(true)
                .setDefaults(0)
                .setCategory(Notification.CATEGORY_CALL)
                .setOngoing(true)
                .setTimeoutAfter(json.getInt("duration"))
                .setOnlyAlertOnce(true)
                .setFullScreenIntent(getPendingIntent(notificationID, "fullScreenIntent", json) , true)
                .setContentIntent(getPendingIntent(notificationID, "contentTap", json))
                .setSmallIcon(R.drawable.ic_call_black_24dp)
                .setPriority(Notification.PRIORITY_MAX)
                .setContentTitle(json.getString("notificationTitle"))
                .setSound(sounduri)
                .setContentText(json.getString("notificationBody"))
                .setStyle(new NotificationCompat.DecoratedCustomViewStyle())
                .setCustomContentView(notificationLayout)
                .build();

        NotificationManager notificationManager = notificationManager();
        createCallNotificationChannel(notificationManager, json);
        notificationManager.notify(notificationID,notification);
    }



    public void createCallNotificationChannel(NotificationManager manager, ReadableMap json){
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Uri sounduri = Uri.parse("android.resource://" + context.getPackageName() + "/"+ R.raw.nosound);
            NotificationChannel channel = new NotificationChannel(callChannel, json.getString("channel_name"), NotificationManager.IMPORTANCE_HIGH);
            channel.setDescription("Call Notifications");
            channel.setSound(sounduri ,
                    new AudioAttributes.Builder().setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .setUsage(AudioAttributes.USAGE_UNKNOWN).build());
            channel.setVibrationPattern(new long[]{0, 1000, 500, 1000, 0, 1000, 500, 1000, 0, 1000, 500, 1000, 0, 1000, 500, 1000, 0, 1000, 500, 1000, 0, 1000, 500, 1000});
            channel.enableVibration(json.getBoolean("vibration"));
            manager.createNotificationChannel(channel);
        }
    }


    public PendingIntent getPendingIntent(int notificationID , String type, ReadableMap json){
        Class intentClass = getMainActivityClass();
        Intent intent = new Intent(context, intentClass);
        intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
        intent.putExtra("notificationId",notificationID);
        intent.putExtra("callerId", json.getString("callerId"));
        intent.putExtra("action", type);
        intent.setAction(type);
        // PendingIntent pendingIntent = PendingIntent.getActivity(context, notificationID, intent, PendingIntent.FLAG_UPDATE_CURRENT);
        PendingIntent pendingIntent = PendingIntent.getActivity(context, notificationID, intent, PendingIntent.FLAG_IMMUTABLE);
        return pendingIntent;
    }


    //Missed Call Notification
    public void showMissCallNotification(String title , String body, String callerId){
        Log.i("WebrtcPushNotification", title + " ======  " + body);
        int missNotification = 123;
        Uri missedCallSound= RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);

        Class intentClass = getMainActivityClass();
        Intent intent = new Intent(context, intentClass);
        intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
        intent.putExtra("notificationId",missNotification);
        intent.putExtra("callerId", callerId);
        intent.setAction("missedCallTape");
        // PendingIntent contentIntent = PendingIntent.getActivity(context, missNotification, intent, PendingIntent.FLAG_UPDATE_CURRENT);
        PendingIntent contentIntent = PendingIntent.getActivity(context, missNotification, intent, PendingIntent.FLAG_IMMUTABLE);

        Notification notification = new NotificationCompat.Builder(context, notificationChannel)
                .setContentTitle(title)
                .setContentText(body)
                .setSmallIcon(R.drawable.ic_phone_missed_black_24dp)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setSound(missedCallSound)
                .setContentIntent(contentIntent)
                .build();
        NotificationManager notificationManager = notificationManager();
        createNotificationChannel(notificationManager,missedCallSound);
        notificationManager.notify(missNotification,notification);
    }


    public void createNotificationChannel(NotificationManager manager , Uri sounduri){
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(notificationChannel, "missed call", NotificationManager.IMPORTANCE_HIGH);
            channel.setDescription("Call Notifications");
            channel.setSound(sounduri ,
                    new AudioAttributes.Builder().setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .setUsage(AudioAttributes.USAGE_UNKNOWN).build());
            channel.setVibrationPattern(new long[]{0, 1000});
            channel.enableVibration(true);
            manager.createNotificationChannel(channel);
        }
    }




    public void clearNotification(int notificationID) {
        NotificationManager notificationManager = notificationManager();
        notificationManager.cancel(notificationID);
    }


    public void clearAllNorifications(){
        NotificationManager manager = notificationManager();
        manager.cancelAll();
    }


    private NotificationManager notificationManager() {
        return (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
    }


}
