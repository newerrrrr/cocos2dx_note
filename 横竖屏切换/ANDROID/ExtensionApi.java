package org.extension;

import org.game.AppActivity;
import org.game.Constant;
import org.game.VibratorUtil;
import org.pay.AlipayFunc;
import org.pay.WxpayFunc;
import org.weixin.WeixinShare;
import org.weixin.WeixinToken;
import org.ynlib.utils.Utils;
import org.cocos2dx.lib.Cocos2dxLuaJavaBridge;

import com.tencent.mm.sdk.openapi.IWXAPI;
import com.tencent.mm.sdk.openapi.WXAPIFactory;

import android.net.Uri;
import android.app.AlertDialog;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.location.LocationManager;
import android.media.audiofx.BassBoost.Settings;
import android.text.ClipboardManager;
import android.util.Log;

/**
 * 闂佸湱顣介弲娑㈡儓瀹ュ绠抽柕澶堝劚缂嶏拷 闂佸湱绮崝鎺旀缁�绺柣鐘差儏閸熶即寮敓锟�
 * @author yangyi
 */ 
public class ExtensionApi {
	public final static String TYPE_WEIXIN_TOKEN = "weixin_token";
    public final static String TYPE_WEIXIN_SHARE = "weixin_share";
    public final static String TYPE_WEIXIN_PAY = "weixin_pay";
    public final static String TYPE_ALI_PAY = "ali_pay";
    
    public final static String voice_get_url 		= "voice_url";
    public final static String voice_finish 		= "voice_finish";
    public final static String voice_finish_play 	= "voice_finishplay";
    public final static String voice_init        	= "voice_init";
    
    public final static String close_socket        	= "close_socket";

    public final static String getBattery       	= "getBattery";
    public final static String getNetType           = "getNetType";
    public final static String getLocation          = "location";
    
    public final static String downLoadApk          = "apkDownload";
    public final static String urlOpen              = "urlOpen";
	/**
	 * 婵炴垶鎹佸畷鐢垫偖閻滄竷tivity
	 */
	public static AppActivity appActivity = null;
	
	/**
	 * 闂佹悶鍎抽崑鐘绘儍閿燂拷
	 * @param jsonStr
	 */
	public static void callBackOnGLThread(final String jsonStr) {
		Log.i(Constant.LOG_TAG, jsonStr);
		appActivity.runOnGLThread(new Runnable() {
            @Override
            public void run() {
                Cocos2dxLuaJavaBridge.callLuaGlobalFunctionWithString("extension_callback", jsonStr);
            }
        });
	}
	
	/**
	 * 闂佺儵鍋撻崝瀣姳椤掞拷闇夐悗锝庡幘濡叉悂鏌￠崟闈涚仩闁诡垯鑳堕幏顐﹀礃椤曞棙瀚�
	 */
	public static void test() {
		appActivity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				AlertDialog alertDialog = new AlertDialog.Builder(appActivity).create();
				alertDialog.setTitle("title");
				alertDialog.setMessage("message");
				alertDialog.show();
			}
		});
	}
	 
	/**
	 * 闂佸吋鍎抽崲鑼躲亹閸モ晜濯奸柟顖嗗本鈻嬮梺鍝ュ剱閸垳绮╃壕鍢�
	 */
	public static String getDeviceId() {
		return Utils.getDeviceId(appActivity);
	}

    public static String getAppVersion(){
    	return AppActivity.appVersion;
    }
	
    public static String getRoomId(){
        Log.e(Constant.LOG_TAG, "====JSXXX====roomid:"+ AppActivity.roomid);
        if(AppActivity.roomid != "")
        {
            String roomid = AppActivity.roomid;
            AppActivity.roomid = ""; 
            return roomid;
        }
        return ""; 
    }
	
	public static String getShareCode(){
        Log.e(Constant.LOG_TAG, "====JSXXX====shareCode:"+ AppActivity.shareCode);
        if(AppActivity.shareCode != "")
        {
            String shareCode = AppActivity.shareCode;
            AppActivity.shareCode = ""; 
            return shareCode;
        }
        return ""; 
    }
	
	public static boolean hasOpenGPS() {
		LocationManager locationManager = (LocationManager) appActivity.getSystemService(Context.LOCATION_SERVICE);
		return locationManager.isProviderEnabled(android.location.LocationManager.GPS_PROVIDER);
	}
	
	public static void gotoOpenGPS(){
        Intent intent = new Intent( android.provider.Settings.ACTION_LOCATION_SOURCE_SETTINGS);
        appActivity.startActivityForResult(intent, 0); 
    }
    
    public static void gotoOpenDetailGPS(){
        Uri packageURI = Uri.parse("package:" + "com.happy9.pyqps");
        Intent intent1 = new Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS, packageURI); 
        appActivity.startActivityForResult(intent1, 0); 
	}
	
	public static String getClipBoardContent() {
        Log.e(Constant.LOG_TAG, "====JSXXX====getClipBoardContent" + AppActivity.clipBoardContent);  
		if(AppActivity.clipBoardContent != "")
        {
            String clipBoardContent = AppActivity.clipBoardContent;
            AppActivity.clipBoardContent = ""; 
            return clipBoardContent;
        }
    	return "";
	}
	 
	public static void openWechat() {
		Intent intent = new Intent(Intent.ACTION_MAIN);
		intent.addCategory(Intent.CATEGORY_LAUNCHER);
		intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
		
		ComponentName cmp = new ComponentName("com.tencent.mm","com.tencent.mm.ui.LauncherUI");
		intent.setComponent(cmp);
        appActivity.startActivityForResult(intent, 0);
	}

	/**
	 * 闂佸吋鍎抽崲鑼躲亹閸パ屽殫妞ゆ棁顔婄换鍡涙煟瑜嶉…宄邦瀶閻ㄥken
	 */
	public static void getWeixinToken(final String weixinId) {
		Log.i(Constant.LOG_TAG, "call getWeixinToken");
		appActivity.runOnUiThread(new Runnable() {
            @Override
            public void run() { 
                new WeixinToken().getWeiXinToken(weixinId);
            }
        });   
	}   
	    
	/**     
	 * 闂佺尨鎷锋い鏍ㄧ懅鐢盯鎮楃憴鍕畺闁轰緡鍠楃粋鎺楁晸閿燂拷
	 */
	public static void alipay(final String orderInfo) {
		Log.i(Constant.LOG_TAG, "call alipay");
		appActivity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
            	new AlipayFunc().startPay(orderInfo);
            }
        });
	}    
	/**
	 * 闂傚洤娲ゆ慨鈺呭箳閵夈儱缍�
	 */
	public static void vibrator(){
		VibratorUtil.Vibrate(appActivity, 100); 		
	}
	
	/** 
	 * 濠碘槅鍋撻幏椋庣矈閹绢喖鍙婃い鏍ㄧ閸庡﹪鎮楅悷閭︽Ъ妞ゃ儲鐗曢銉╊敊鐠佸磭绠�
	 * @return
	 */
	public static boolean checkInstallWeixin() {
		try {
			Log.i(Constant.LOG_TAG, "call WxSimpleFunc begin");
			String weixinId = Utils.getMetaData(ExtensionApi.appActivity, Constant.WX_APPID_KEY);
			IWXAPI api = WXAPIFactory.createWXAPI(ExtensionApi.appActivity, weixinId, false);
			if(api.isWXAppInstalled()) {
				return true;
			}else {
				return false;
			}
		} catch (Exception e) {
			Log.e(Constant.LOG_TAG, e.toString(), e);
		}
		return false;
	}
	 
	/**
	 * 閻庣敻鍋婇崰鏇熺┍婵犲洤缁╂い鏍ㄧ懅鐢拷
	 */
	public static void weixinPay(final String orderInfo) {
		Log.i(Constant.LOG_TAG, "call weixinPay");
		appActivity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
            	new WxpayFunc().startPay(orderInfo);
            }
        });
	} 
	 
	/** 
	 * 闂佹悶鍎辨晶鑺ユ櫠閺嶎厼绀嗛柛鈩冩礋閻擄拷
	 */
	public static void weixinShareImg(final String shareTo, final String filePath) {
		Log.i(Constant.LOG_TAG, "call weixinPay");
		
		appActivity.runOnGLThread(new Runnable() {
			@Override
			public void run() {
				new WeixinShare().shareImg(shareTo, filePath);
			}
		});
	}
	 
	/**
	 * 闂佹悶鍎辨晶鑺ユ櫠閺堢磥p婵烇絽娲犻崜婵囧閿燂拷
	 */
	public static void weixinShareApp(
			final String shareTo, 
			final String title, 
			final String message,   
			final String url
	) {
		Log.i(Constant.LOG_TAG, "call weixinPay");
		appActivity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
            	new WeixinShare().shareAppInfo(shareTo, title, message, url);
            }
        });
	}	  
     
    /**
     * 濠碘槅鍋撻幏椋庣矈鐎靛摜纾鹃柟瀵稿Х閹规洟鏌￠崟闈涚仩闁诡垯绶氬畷锝夘敍濠婂嫭娈�
     * @return
     */
    public static boolean isNetworkAvailable() {
    	return Utils.isNetworkAvailable(appActivity);
    }
    
    /** 
    *    閻犲浂鍙冮悡鍫曞礆濠靛棭娼楅柛鏍垫嫹
    */
    public static void voiceInit(String appid) {    	
    	appActivity.initYunvaImSdk(appid, false);
    }
      
    /**  
    *    閻犲浂鍙冮悡鍫曟儌鐠囪尙绉�
    */    
    public static void yayaLogin(String uid, String unick) {   
    	appActivity.yayaLogin(uid, unick);
    }
    
    /**  
     * 鐎殿噯鎷峰┑顔碱儏缂嶅秹妫呴幇浣猴拷锟�
     */
    public static boolean voiceStart() {   
    	return appActivity.voiceStart();
    }
    
    /**
     * 闁稿绮嶉娑溿亹閺囥垻鍙� 
     */
    public static void voiceStop() {   
    	appActivity.voiceStop();
    } 
    
    /**
     * 濞戞挸锕ｇ槐鎯般亹閺囥垻鍙炬い顒婃嫹
     */
    public static void voiceupload(String path, String time) {   
    	appActivity.voiceupload(path, time);
    }
    
    /**
     * 闁圭虎鍘介弬浣姐亹閺囥垻鍙�
     */
    public static void voicePlay(String url) {
    	appActivity.voicePlay(url);
    }    

    //by hlb begin, fixed crash in android-huawei hornor v10
    public static boolean voiceStartEx(final String fullpath) { 
        return appActivity.startRecord(fullpath);
    } 

    public static void voiceStopEx() {   
        appActivity.stopRecord();
    } 

    public static void voicePlayEx(String url) {   
        appActivity.startPlayVoice(url);
    }     
    //by hlb end 

    /**
     * 闁告瑦鍨块敓鎴掔窔閺佸﹦鎷犻娑欙級闊浄鎷�
     * @return
     */
    public static void SendError(String log) {
    	appActivity.sendError(log);
    }
    
    /**
     * 闁兼儳鍢茶ぐ鍥偨閸偆娼ㄩ柛鎾櫃缂嶆垿鎮介悽绋挎 
     * @return
     */
    public static void GetBattery() {
    	appActivity.getBattery();
    }
    
    /**
     * 闁兼儳鍢茶ぐ鍥╃磾閹寸姷鎹曠紒顐ヮ嚙閻庯拷
     * @return
     */
    public static void GetNetType() {
    	appActivity.getNet();
    }
    
    /**
     * 闁兼儳鍢茶ぐ鍥╋拷瑙勭煯缂嶏拷
     * @return 
     */
    public static void GetLocation() {
    	Log.e("enter getlocation", "test");
    	appActivity.getLocation();
    }
    
    /**
     * 濞戞挸顑堝ù鍢噋k
     * @return
     */
    public static void downloadApk(String url, String writablePath) {
    	appActivity.DownloadApk(url, writablePath);
    }
    
    public static void copyTextToClipboard(final String str) {
        Runnable runnable = new Runnable() {
            public void run() {
            	ClipboardManager cm = (ClipboardManager) appActivity.getSystemService(Context.CLIPBOARD_SERVICE);
                cm.setText(str);
            }
        };
        appActivity.runOnUiThread(runnable);
    }

    //by hlb, set phone ration 1：landscape 2：portrait 
    public static int setOrientation(int orientation) {
        return appActivity.setOrientation(orientation);
    }
}
