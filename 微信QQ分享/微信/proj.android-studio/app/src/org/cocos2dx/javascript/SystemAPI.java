package org.cocos2dx.javascript;

import android.content.BroadcastReceiver;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.location.LocationManager;
import android.nfc.Tag;
import android.os.Vibrator;
import android.util.Log;

import org.cocos2dx.lib.Cocos2dxJavascriptJavaBridge;



public final class SystemAPI {
    private static String TAG = "SystemAPI";
    private static AppActivity app = null;
    private static BroadcastReceiver mBatInfoReveiver = null;


    //在 AppActivity 中调用初始化
    public static void init(AppActivity context) {
        Log.d(TAG,"==== SystemAPI init");
        app = context;
    }

    //============================================================================================//
    //在 GL 线程调用JS 脚本
    public static void evalString(final String js) {
        Log.d(TAG, js);
        app.runOnGLThread(new Runnable() {
            @Override
            public void run() {
                Cocos2dxJavascriptJavaBridge.evalString(js);
            }
        });
    }

    //拷贝到剪贴板, 也可以清空,此时 content传入空字串接口
    public static void copyToClipboard(final String content) {
        app.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                ClipboardManager clipboard = (ClipboardManager) app.getSystemService(Context.CLIPBOARD_SERVICE);
                if (clipboard != null) {
                    clipboard.setPrimaryClip(ClipData.newPlainText(null, content));//参数一：标签，可为空，参数二：要复制到剪贴板的文本
                }
            }
        });
    }

    public static void getClipboardContent(final String tagCallback, final String clearAfterRead) {
        app.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                String str = "";
                ClipboardManager clipboard = (ClipboardManager) app.getSystemService(Context.CLIPBOARD_SERVICE);
                if (clipboard.hasPrimaryClip()) {
                    str = clipboard.getPrimaryClip().getItemAt(0).getText().toString();
                    if ( clearAfterRead.equals("true")){
                        clipboard.setPrimaryClip(ClipData.newPlainText(null, ""));
                    }
                }
                String sb = "gt.deviceApi.execCallback(";
                sb += ("'" + tagCallback + "',");
                sb += ("'" + str + "')");
                evalString(sb);
            }
        });
    }

    public static void getBattery(final String tagCallback) {
        final Context intance = app.getApplication();

        if (mBatInfoReveiver == null) {
            mBatInfoReveiver = new BroadcastReceiver() {
                @Override
                public void onReceive(Context context, Intent intent) {
                    String action = intent.getAction();
                    if (Intent.ACTION_BATTERY_CHANGED.equals(action)) {
                        intance.unregisterReceiver(mBatInfoReveiver);

                        int intLevel = intent.getIntExtra("level", 0);//获取当前电量
                        //int intScale = intent.getIntExtra("scale", 100);//获取总电量

                        String sb ="gt.deviceApi.execCallback(";
                    }
                }
            };
        }
//        intance.unregisterReceiver(mBatInfoReveiver);
        intance.registerReceiver(mBatInfoReveiver, new IntentFilter(Intent.ACTION_BATTERY_CHANGED));
    }

    public static String getUUID() {
        String identity;
        try {
            SharedPreferences sp = app.getSharedPreferences(TAG, AppActivity.MODE_PRIVATE);
            identity = sp.getString("KEY_UUID", "");
            if (identity.equals("")) {
                identity = java.util.UUID.randomUUID().toString();
                SharedPreferences.Editor editor = sp.edit();
                editor.putString("KEY_UUID", identity);
                editor.apply();
            }
        }
        catch (Exception e) {
            identity = "";
        }
        return identity;
    }

    //获取网页url传入的分享码.
    //流程：在包含“pyqps://pyqps.com”内容的短信或者网页中都可以打开我们的app (AndroidManifest.xml中配置)
    //参数放在url中：pyqps://pyqps.com?share_code=123456 , 启动APP后会出发 AppActivity 中的 onNewIntent(), 可在哪里解析参数
    public static String getShareCode() {
        Log.d(TAG, "--------------getShareCode:" + AppActivity.shareCode );
        if(AppActivity.shareCode != "")
        {
            String shareCode = AppActivity.shareCode;
            AppActivity.shareCode = "";
            return shareCode;
        }
        return "";
    }

    public static boolean isGpsOPen() {
        LocationManager locationManager = (LocationManager) app.getSystemService(Context.LOCATION_SERVICE);
        // 通过GPS卫星定位，定位级别可以精确到街（通过24颗卫星定位，在室外和空旷的地方定位准确、速度快）
        boolean gps = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER);
        // 通过WLAN或移动网络(3G/2G)确定的位置（也称作AGPS，辅助GPS定位。主要用于在室内或遮盖物（建筑群或茂密的深林等）密集的地方定位）
        boolean network = locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER);
        return (gps || network);
    }

    public static void gotoOpenGps(){
        Intent intent = new Intent( android.provider.Settings.ACTION_LOCATION_SOURCE_SETTINGS);
        app.startActivityForResult(intent, 0);
    }

    public static void vibrate(int millisecond){
        Vibrator vib = (Vibrator) app.getSystemService(Context.VIBRATOR_SERVICE);
        vib.vibrate(millisecond);
    }




}
