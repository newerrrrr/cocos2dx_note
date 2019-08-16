package com.happy9.kuaizhuan.xiaomi;

import org.game.AppActivity;
import android.app.ActivityManager;
import android.app.ActivityManager.RunningAppProcessInfo;
import android.app.Application;
import android.content.Context;
import android.os.Message;
import android.os.Process;
import android.util.Log;
import java.util.List;
import com.xiaomi.channel.commonutils.logger.LoggerInterface;
import com.xiaomi.mipush.sdk.Logger;
import com.xiaomi.mipush.sdk.MiPushClient;


public class MiPushMgr {
	private static final String TAG = "MiPush";
	public static final String APP_ID = "2882303761518111304";
    public static final String APP_KEY = "5271811187304";
	private static AppActivity mContext = null;
	
    //在 AppActivity.java 中调用初始化
    public static void init(AppActivity context) {
        Log.d(TAG, "==== MiPushMgr init");
		mContext = context;
		
		//1.初始化push推送服务
        if(shouldInit()) {
			Log.d(TAG, "==== MiPushMgr registerPush");
            MiPushClient.registerPush(context, APP_ID, APP_KEY);
			
			//给自己打个标签,用于接收该类标签的推送。
			setPushTopic("android"); 
        }
		
		//2. 打开Logcat调试日志
		//默认情况下，我们会将日志内容写入SDCard/Android/data/app pkgname/files/MiPushLog目录下的文件。
		//如果app需要关闭写日志文件功能（不建议关闭），只需要调用Logger.disablePushFileLog(context)即可。
		LoggerInterface newLogger = new LoggerInterface() {
			@Override
			public void setTag(String tag) {
			 // ignore
			}
			@Override
			public void log(String content, Throwable t) {
			 Log.d(TAG, content, t);
			}
			@Override
			public void log(String content) {
			 Log.d(TAG, content);
			}
		};
		Logger.setLogger(context, newLogger);
    }

	private static boolean shouldInit() {
		Application app = (Application)mContext.getApplication();
        ActivityManager am = ((ActivityManager) mContext.getSystemService(Context.ACTIVITY_SERVICE));
        List<RunningAppProcessInfo> processInfos = am.getRunningAppProcesses();
        //String mainProcessName = mContext.getApplicationInfo().processName();
        int myPid = Process.myPid();
	
        for (RunningAppProcessInfo info : processInfos) {
            //if (info.pid == myPid && mainProcessName.equals(info.processName)) {
			if (info.pid == myPid){
                return true;
            }
        }
        return false;
    }
	
	//供外部调用来注册账号，方便推送的时候针对某个id精准推送。
	public static void setPushUserId(final String uid) {
		MiPushClient.setUserAccount(mContext, uid, null);
	}
	
	//供外部调用来注册账号，方便推送的时候针对某类标签推送.
	public static void setPushTopic(final String topic) {
		MiPushClient.subscribe(mContext, topic, null);
	}
}
