/****************************************************************************
Copyright (c) 2008-2010 Ricardo Quesada
Copyright (c) 2010-2012 cocos2d-x.org
Copyright (c) 2011      Zynga Inc.
Copyright (c) 2013-2014 Chukong Technologies Inc.
 
http://www.cocos2d-x.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
****************************************************************************/
package org.game;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.List;
import java.util.Locale;

import javax.microedition.khronos.opengles.GL10;

import org.cocos2dx.lib.Cocos2dxActivity;
import org.cocos2dx.lib.Cocos2dxGLSurfaceView;
import org.extension.ExtensionApi;
import org.ynlib.utils.Utils;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.location.Address;
import android.location.Geocoder;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.net.Uri;
import android.os.Bundle;
import android.os.Environment;
import android.os.Message;
import android.os.PowerManager;
import android.text.ClipboardManager;
import android.text.TextUtils;
import android.util.Log;
import android.widget.Toast;

import com.amap.api.location.AMapLocation;
import com.amap.api.location.AMapLocationClient;
import com.amap.api.location.AMapLocationClientOption;
import com.amap.api.location.AMapLocationClientOption.AMapLocationMode;
import com.amap.api.location.AMapLocationClientOption.AMapLocationProtocol;
import com.amap.api.location.AMapLocationListener;
import com.yunva.im.sdk.lib.core.YunvaImSdk;
import com.yunva.im.sdk.lib.event.MessageEvent;
import com.yunva.im.sdk.lib.event.MessageEventListener;
import com.yunva.im.sdk.lib.event.MessageEventSource;
import com.yunva.im.sdk.lib.event.RespInfo;
import com.yunva.im.sdk.lib.event.msgtype.MessageType;
import com.yunva.im.sdk.lib.model.tool.ImAudioRecordResp;
import com.yunva.im.sdk.lib.model.tool.ImUploadFileResp;
import com.tendcloud.tenddata.TalkingDataGA;
import com.umeng.analytics.MobclickAgent;//umeng sdk by fengjingfeng
import android.media.*; //by hlb
import java.util.Calendar; //by hlb

public class AppActivity extends Cocos2dxActivity implements MessageEventListener {
	public static GL10 gl10;
	private int intLevel; 
    private int intScale;   
	private String mProviderName = null;
	private PowerManager.WakeLock wakeLock;
	
	private AMapLocationClient locationClient = null;
	private AMapLocationClientOption locationOption = new AMapLocationClientOption();
	private String locationInfo;
	public static String roomid = "";
	public static String shareCode = "";
	public static String appVersion = "";
	public static String clipBoardContent = "";
	//by hlb start
    private MediaRecorder mRecorder = null; 
    private MediaPlayer audioMP = null;
    private static String mFilepath = "";
    private static long mBeginTime = 0;
    //by hlb end 

	// 閸掓稑缂揃roadcastReceiver 
    private BroadcastReceiver mBatInfoReveiver = new BroadcastReceiver() { 
 
        @Override 
        public void onReceive(Context context, Intent intent) { 
            // TODO Auto-generated method stub 
            String action = intent.getAction(); 
            // 婵″倹鐏夐幑鏇熷磸閸掔櫘ction閺勭枆CRION_BATTERY_CHANGED 
            // 鐏忚精绻嶇悰瀹眓BatteryInfoReveiver() 
            if (Intent.ACTION_BATTERY_CHANGED.equals(action)) { 
                intLevel = intent.getIntExtra("level", 0); 
                intScale = intent.getIntExtra("scale", 100); 
                onBatteryInfoReceiver(intLevel, intScale); 
            } 
        }

    }; 
    @Override
    public Cocos2dxGLSurfaceView onCreateView() {
        Cocos2dxGLSurfaceView glSurfaceView = new Cocos2dxGLSurfaceView(this);
        // TestCpp should create stencil buffer
        glSurfaceView.setEGLConfigChooser(5, 6, 5, 0, 16, 8);
        ExtensionApi.appActivity = this;
        return glSurfaceView; 
    }     
          
    @Override  
	protected void onCreate(Bundle savedInstanceState) {
		// TODO Auto-generated method stub
		super.onCreate(savedInstanceState);	
		keepScreenOn(this, true);
		getAppVersion();
		initLocation();
		getURLParame();
		getClipBoardContent();
    }   
    
    protected void getClipBoardContent() {
    	Runnable runnable = new Runnable() {
            public void run() {
            	ClipboardManager cm = (ClipboardManager) getContext().getSystemService(Context.CLIPBOARD_SERVICE);
            	if(cm.getText() != null)  
                {  
            		AppActivity.clipBoardContent = cm.getText().toString(); 
                } 
            }
        };
        this.runOnUiThread(runnable);
    }

    
    @Override
	protected void onNewIntent(Intent intent) {
		// TODO Auto-generated method stub
		super.onNewIntent(intent);
		setIntent(intent);
		 if(getIntent() != null){
			   getURLParame();
			   getClipBoardContent();
		 }
	}
    
    private void getAppVersion(){
    	try {
	    	PackageManager pm = this.getApplicationContext().getPackageManager();  
	        PackageInfo pi = pm.getPackageInfo(this.getApplicationContext().getPackageName(), 0);  
	        appVersion = pi.versionName; 
		} catch (Exception e) {
			e.printStackTrace();
		}
    }

	private void getURLParame(){
	    Intent intent = getIntent();
	    Uri deeplink = intent.getData();
	    if(deeplink != null){	    	
	    	AppActivity.roomid = deeplink.getQueryParameter("roomid");
			AppActivity.shareCode = deeplink.getQueryParameter("share_code");
	    } 
	}

    /** 
     * 閸掓繂顫愰崠鏍х暰娴ｏ拷 妤傛ê鐥�
     */  
    private void initLocation(){  
        //閸掓繂顫愰崠鏈縧ient  
        locationClient = new AMapLocationClient(this.getApplicationContext());  
        //鐠佸墽鐤嗙�规矮缍呴崣鍌涙殶  
        locationClient.setLocationOption(getDefaultOption());  
        // 鐠佸墽鐤嗙�规矮缍呴惄鎴濇儔  
        locationClient.setLocationListener(locationListener);  
        //閸氼垰濮╃�规矮缍�  
        locationClient.startLocation();  
    }
	
	/** 
     * 妤傛ê鐥塴ister
     */
	AMapLocationListener locationListener = new AMapLocationListener() {  
        @Override  
        public void onLocationChanged(AMapLocation location) {  
            if (location == null) 
            	return;
            
        	if (location.getErrorCode() != 0)
        	{
                //鐎规矮缍呮径杈Е閺冭绱濋崣顖烇拷姘崇箖ErrCode閿涘牓鏁婄拠顖滅垳閿涘淇婇幁顖涙降绾喖鐣炬径杈Е閻ㄥ嫬甯崶鐙呯礉errInfo閺勵垶鏁婄拠顖欎繆閹垽绱濈拠锕侇潌闁挎瑨顕ら惍浣姐�冮妴锟�  
                Log.e("AmapError","location Error, ErrCode:"  
                    + location.getErrorCode() + ", errInfo:"  
                    + location.getErrorInfo()); 
                locationInfo = "";
                return;
        	}

        	try
            {
                // 缂佸嫬鎮庢穱鈩冧紖 閸╁骸灏�-鐞涙浜�-鐞涙浜鹃梻銊у閸欙拷
                String str = "";
                String detailStr = "";
                // 缁绢剙瀹�
                str = java.net.URLEncoder.encode(String.valueOf(location.getLatitude()),"utf-8") + "#";
                //缂佸繐瀹�
                str = str + java.net.URLEncoder.encode(String.valueOf(location.getLongitude()),"utf-8") + "#";
                // 鐠囷妇绮忛崷鎵倞娴ｅ秶鐤�
                detailStr = java.net.URLEncoder.encode(location.getCity() + location.getDistrict() + location.getStreet() + location.getStreetNum());
                str = str + detailStr + "#";
                /*
				//缁儳瀹�
                str = str + java.net.URLEncoder.encode(String.valueOf(location.getAccuracy()),"utf-8") + "#";
                //閸︽澘娼�
                str = str + java.net.URLEncoder.encode(String.valueOf(location.getAddress()),"utf-8") + "#";
                //閸ヨ棄顔嶆穱鈩冧紖
                str = str + java.net.URLEncoder.encode(String.valueOf(location.getCountry()),"utf-8") + "#";
                //n閻椒淇婇幁锟�
                str = str + java.net.URLEncoder.encode(String.valueOf(location.getProvince()),"utf-8") + "#";
                //閸╁骸绔舵穱鈩冧紖
                str = str + java.net.URLEncoder.encode(String.valueOf(location.getCity()),"utf-8") + "#";
                //閸╁骸灏穱鈩冧紖
                str = str + java.net.URLEncoder.encode(String.valueOf(location.getDistrict()),"utf-8") + "#";	
                //鐞涙浜炬穱鈩冧紖
                str = str + java.net.URLEncoder.encode(String.valueOf(location.getStreet()),"utf-8") + "#";
                //鐞涙浜鹃梻銊у閸欒渹淇婇幁锟�
                str = str + java.net.URLEncoder.encode(String.valueOf(location.getStreetNum()),"utf-8") + "#";
                //閸╁骸绔剁紓鏍垳
                str = str + java.net.URLEncoder.encode(String.valueOf(location.getCityCode()),"utf-8") + "#";
                //閸︽澘灏紓鏍垳
                str = str + java.net.URLEncoder.encode(String.valueOf(location.getAdCode()),"utf-8") + "#";
                //鐎规矮缍呴悙绗癘I娣団剝浼�
                str = str + java.net.URLEncoder.encode(String.valueOf(location.getAoiName()),"utf-8");
                //閺冨爼妫�: #
                str = str + java.net.URLEncoder.encode(String.valueOf(location.getTime()),"utf-8") + "#";
				*/
                locationInfo = str;
                locationClient.onDestroy();
                Log.d("LOC", str);  
            } catch (Exception e)
            {
            	e.printStackTrace();
            }

        } 
         
    };
	
	/** 
     * 妤傛ê鐥夋妯款吇閻ㄥ嫬鐣炬担宥呭棘閺侊拷 
     */
    private AMapLocationClientOption getDefaultOption(){  
        AMapLocationClientOption mOption = new AMapLocationClientOption();  
        mOption.setLocationMode(AMapLocationMode.Hight_Accuracy);//閸欘垶锟藉绱濈拋鍓х枂鐎规矮缍呭Ο鈥崇础閿涘苯褰查柅澶屾畱濡�崇础閺堝鐝划鎯у閵嗕椒绮庣拋鎯ь槵閵嗕椒绮庣純鎴犵捕閵嗗倿绮拋銈勮礋妤傛绨挎惔锔侥佸锟�  
        mOption.setGpsFirst(false);//閸欘垶锟藉绱濈拋鍓х枂閺勵垰鎯乬ps娴兼ê鍘涢敍灞藉涧閸︺劑鐝划鎯у濡�崇础娑撳婀侀弫鍫涳拷鍌炵帛鐠併倕鍙ч梻锟�  
        mOption.setHttpTimeOut(30000);//閸欘垶锟藉绱濈拋鍓х枂缂冩垹绮剁拠閿嬬湴鐡掑懏妞傞弮鍫曟？閵嗗倿绮拋銈勮礋30缁夋帇锟藉倸婀禒鍛邦啎婢跺洦膩瀵繋绗呴弮鐘虫櫏  
        mOption.setInterval(2000);//閸欘垶锟藉绱濈拋鍓х枂鐎规矮缍呴梻鎾閵嗗倿绮拋銈勮礋2缁夛拷  
        mOption.setNeedAddress(true);//閸欘垶锟藉绱濈拋鍓х枂閺勵垰鎯佹潻鏂挎礀闁棗婀撮悶鍡楁勾閸э拷娣団剝浼呴妴鍌炵帛鐠併倖妲竧rue  
        mOption.setOnceLocation(false);//閸欘垶锟藉绱濈拋鍓х枂閺勵垰鎯侀崡鏇燁偧鐎规矮缍呴妴鍌炵帛鐠併倖妲竑alse  
        mOption.setOnceLocationLatest(false);//閸欘垶锟藉绱濈拋鍓х枂閺勵垰鎯佺粵澶婄窡wifi閸掗攱鏌婇敍宀勭帛鐠併倓璐焒alse.婵″倹鐏夌拋鍓х枂娑撶皪rue,娴兼俺鍤滈崝銊ュ綁娑撳搫宕熷▎鈥崇暰娴ｅ稄绱濋幐浣虹敾鐎规矮缍呴弮鏈电瑝鐟曚椒濞囬悽锟�  
        AMapLocationClientOption.setLocationProtocol(AMapLocationProtocol.HTTP);//閸欘垶锟藉绱� 鐠佸墽鐤嗙純鎴犵捕鐠囬攱鐪伴惃鍕礂鐠侇喓锟藉倸褰查柅濉嘥TP閹存牞锟藉専TTPS閵嗗倿绮拋銈勮礋HTTP  
        mOption.setSensorEnable(false);//閸欘垶锟藉绱濈拋鍓х枂閺勵垰鎯佹担璺ㄦ暏娴肩姵鍔呴崳銊ｏ拷鍌炵帛鐠併倖妲竑alse  
        mOption.setWifiScan(true); //閸欘垶锟藉绱濈拋鍓х枂閺勵垰鎯佸锟介崥鐥篿fi閹殿偅寮块妴鍌炵帛鐠併倓璐焧rue閿涘苯顩ч弸婊嗩啎缂冾喕璐焒alse娴兼艾鎮撻弮璺轰粻濮濐澀瀵岄崝銊ュ煕閺傚府绱濋崑婊勵剾娴犮儱鎮楃�瑰苯鍙忔笟婵婄娴滃海閮寸紒鐔峰煕閺傚府绱濈�规矮缍呮担宥囩枂閸欘垵鍏樼�涙ê婀拠顖氭▕  
        mOption.setLocationCacheEnable(true); //閸欘垶锟藉绱濈拋鍓х枂閺勵垰鎯佹担璺ㄦ暏缂傛挸鐡ㄧ�规矮缍呴敍宀勭帛鐠併倓璐焧rue  
        return mOption;  
    }   
	@Override 
	protected void onResume() {
		// TODO Auto-generated method stub
		getClipBoardContent();
		super.onResume();
        MobclickAgent.onResume(this);
        TalkingDataGA.onResume(this);
	}

	@Override
	protected void onPause() {
		// TODO Auto-generated method stub
		super.onPause();
        MobclickAgent.onPause(this);
        TalkingDataGA.onResume(this);
	}

	@Override
	protected void onDestroy() {
		// TODO Auto-generated method stub
		super.onDestroy();  
		keepScreenOn(this, false);  
		
		MessageEventSource.getSingleton().removeLinstener(this);
		YunvaImSdk.getInstance().clearCache();
		YunvaImSdk.getInstance().release();
	} 
	
	@Override
	public void handleMessageEvent(MessageEvent event) {
		RespInfo  msg=event.getMessage();
		Message chatmsg=new Message();
		switch (event.getbCode()) {
		case MessageType.IM_THIRD_LOGIN_RESP:
			break; 
			     
		case MessageType.IM_RECORD_STOP_RESP:			
			ImAudioRecordResp imAudioRecordResp = (ImAudioRecordResp) event.getMessage().getResultBody();
			 
			if (imAudioRecordResp != null){
				String path = imAudioRecordResp.getStrfilepath();
				int time = imAudioRecordResp.getTime();
				  
				String code = path + "#" + time;
				ExtensionApi.callBackOnGLThread(this.bindMsg(ExtensionApi.voice_finish, 1, code)); 
			}else{
				Toast.makeText(this, "瑜版洟鐓舵径杈Е", Toast.LENGTH_SHORT).show();
			} 
			     
			break; 
			 
		case MessageType.IM_UPLOAD_FILE_RESP:			
			ImUploadFileResp imuploadFileResp = (ImUploadFileResp) event.getMessage().getResultBody();
			
			if (imuploadFileResp != null && 0 != imuploadFileResp.getPercent() ){
				//Toast.makeText(this, "瑜版洟鐓舵稉濠佺炊鏉╂柨娲�"+ imuploadFileResp.getResult(), Toast.LENGTH_SHORT).show();
				String code = imuploadFileResp.getFileUrl() + "#" + imuploadFileResp.getFileId();
				ExtensionApi.callBackOnGLThread(this.bindMsg(ExtensionApi.voice_get_url, 1, code));
				
			}else{
				//Toast.makeText(this, "娑撳﹣绱舵径杈Е", Toast.LENGTH_SHORT).show();
			}
				 
			break; 
			 
		case MessageType.IM_SPEECH_STOP_RESP:
			break;
		case MessageType.IM_NET_STATE_NOTIFY:
			break;
						
		case MessageType.IM_RECORD_PLAY_PERCENT_NOTIFY:
			break;		
			 
		case MessageType.IM_RECORD_FINISHPLAY_RESP:
			ExtensionApi.callBackOnGLThread(this.bindMsg(ExtensionApi.voice_finish_play, 1, "0"));
			break;
		 
			 
		default:
			break;     
		} 
	}  
	  
    public void initYunvaImSdk(String appid, boolean istest) { 
    	com.yunva.im.sdk.lib.YvLoginInit.context = this;
		com.yunva.im.sdk.lib.YvLoginInit.initApplicationOnCreate(
				this.getApplication(), appid);
		  
    	String path =Environment.getExternalStorageDirectory().toString() + "/yunva_sdk_lite";
    	String voice_path = path + "/voice";
    	boolean m = YunvaImSdk.getInstance().init(this, appid, voice_path, istest);
    	if (m != true) {
    		Log.w("Voice", "YunvaImSdk init fail");  
    	}
    	YunvaImSdk.getInstance().setRecordMaxDuration(20, false);
    	MessageEventSource.getSingleton().addLinstener(	MessageType.IM_THIRD_LOGIN_RESP, this);
    	MessageEventSource.getSingleton().addLinstener(	MessageType.IM_LOGIN_RESP, this);
		MessageEventSource.getSingleton().addLinstener( MessageType.IM_THIRD_LOGIN_RESP, this);
		MessageEventSource.getSingleton().addLinstener( MessageType.IM_RECORD_STOP_RESP, this);
		MessageEventSource.getSingleton().addLinstener( MessageType.IM_UPLOAD_FILE_RESP, this);
		MessageEventSource.getSingleton().addLinstener( MessageType.IM_RECORD_FINISHPLAY_RESP, this);
		MessageEventSource.getSingleton().addLinstener( MessageType.IM_RECORD_PLAY_PERCENT_NOTIFY, this);
    }     
              
    public boolean voiceStart() { 
    	boolean start = YunvaImSdk.getInstance().startAudioRecord("", "lite", (byte)0);
    	if (!start){
    		//Toast.makeText(this, "鐠囧嘲绱戦崥顖氱秿闂婅櫕娼堥梽锟�", Toast.LENGTH_SHORT).show();
    	}  
    	return start;  
    }      
           
    public boolean voiceStop() {
    	boolean retAutio = YunvaImSdk.getInstance().stopPlayAudio();
    	boolean retRecord = YunvaImSdk.getInstance().stopAudioRecord();
    	return true;  
    }   
    
    public void voiceupload(String path, String time) {
    	YunvaImSdk.getInstance().uploadFile(path, time);
    }
      
    public void voicePlay(String url) {
    	YunvaImSdk.getInstance().stopPlayAudio();
    	YunvaImSdk.getInstance().playAudio(url, "", "");
    }
    
    public void yayaLogin(String uid, String unick) {
    	String tt = "{\"uid\":\""+ uid + "\",\"nickname\"" + unick + "\"}";
    	YunvaImSdk.getInstance().Binding(tt, "1", null);
    }
    
    private String bindMsg(String type, int status, String code) {
    	return "{\"type\":\"" + type + "\", \"status\":" + status +", \"code\":\""+ code + "\"}";
    }
    
    public void sendError(String log) {
    }
    
    public void getBattery(){
    	// 濞夈劌鍞芥稉锟芥稉鐙焤oadcastReceiver閿涘奔缍旀稉楦款問闂傤喚鏁稿Ч鐘侯吀闁插繋绠ｉ悽锟� 
    	registerReceiver(mBatInfoReveiver, new IntentFilter(Intent.ACTION_BATTERY_CHANGED));
    }
    
    public void onBatteryInfoReceiver(int intLevel, int intScale) {  
        // TODO Auto-generated method stub
	    // 閸欐牗绉峰▔銊ュ斀閿涘苯鑻熼崗鎶芥４鐎电鐦藉锟� 
    	String code = intLevel+"";  
	    unregisterReceiver(mBatInfoReveiver);
    	ExtensionApi.callBackOnGLThread(this.bindMsg(ExtensionApi.getBattery, 1, code)); 
    };    

    /**
     * 閸掋倖鏌囩純鎴犵捕缁鐎�
     * @param context  
     * @return     
     */

    public void getNet() {
        ConnectivityManager cm = (ConnectivityManager) this
                .getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo networkINfo = cm.getActiveNetworkInfo();
        if (networkINfo != null
                && networkINfo.getType() == ConnectivityManager.TYPE_WIFI) {
        	ExtensionApi.callBackOnGLThread(this.bindMsg(ExtensionApi.getNetType, 1, "0")); 
        }else if (networkINfo != null
            && networkINfo.getType() == ConnectivityManager.TYPE_MOBILE) {
    		String subTypeName = networkINfo.getSubtypeName();
    		if(subTypeName.equals("GPRS") || subTypeName.equals("EDGE") || subTypeName.equals("CDMA") || subTypeName.equals("1xRTT") 
    		|| subTypeName.equals("IDEN")){
    			ExtensionApi.callBackOnGLThread(this.bindMsg(ExtensionApi.getNetType, 1, "1")); 
    		};
    		if(subTypeName.equals("UMTS")|| subTypeName.equals("EVDO_0") || subTypeName.equals("EVDO_A") || subTypeName.equals("HSDPA")
            || subTypeName.equals("HSUPA")|| subTypeName.equals("HSPA")|| subTypeName.equals("EVDO_B") || subTypeName.equals("EHRPD")
            || subTypeName.equals("HSPAP")){
    			ExtensionApi.callBackOnGLThread(this.bindMsg(ExtensionApi.getNetType, 1, "2")); 
    		};
    		if(subTypeName.equals("LTE")){
    			ExtensionApi.callBackOnGLThread(this.bindMsg(ExtensionApi.getNetType, 1, "3")); 
    		};
        }else{
        	ExtensionApi.callBackOnGLThread(this.bindMsg(ExtensionApi.getNetType, 1, "-1")); 
        }  
    }
      
    public void getLocation() {  
        int status = 1;
        if (locationInfo == "")
        	status = -1;
        String code = locationInfo;
        ExtensionApi.callBackOnGLThread(this.bindMsg(ExtensionApi.getLocation, status, code)); 
    }
    
    public void keepScreenOn(Context context, boolean on) {  
        if (on) {  
            PowerManager pm = (PowerManager) context.getSystemService(Context.POWER_SERVICE);  
            wakeLock = pm.newWakeLock(PowerManager.SCREEN_BRIGHT_WAKE_LOCK | PowerManager.ON_AFTER_RELEASE, "==KeepScreenOn==");  
            wakeLock.acquire();  
        } else {  
            if (wakeLock != null) {  
                wakeLock.release();  
                wakeLock = null;  
            }  
        }  
    }  
    
	public void DownloadApk(final String url, final String save_path) {
		new Thread(new Runnable() {
			@Override
			public void run() {
				InstallApk(DownLoadFile(url, save_path));
			}
		}).start();
	} 
 
	protected File DownLoadFile(final String httpUrl, final String save_path) {
		// TODO Auto-generated method stub
		final String fileName = "updata.apk";
        File tmpFile = new File("/sdcard/"+this.getPackageName());
        if (!tmpFile.exists()) {
                tmpFile.mkdir();
        }
        final File file = new File(tmpFile + "/" + fileName);

		try {
			URL url = new URL(httpUrl);
			try {
				HttpURLConnection conn = (HttpURLConnection) url
						.openConnection();
				InputStream is = conn.getInputStream();
				if (is == null) { // 濞屸剝婀佹稉瀣祰濞达拷
					throw new RuntimeException("閺冪姵纭堕懢宄板絿閺傚洣娆�");
				}
				int filesize = conn.getContentLength();
				if (filesize <= 0) { // 閼惧嘲褰囬崘鍛啇闂�鍨娑擄拷0
					throw new RuntimeException("閺冪姵纭堕懢椋庣叀閺傚洣娆㈡径褍鐨� ");
				}
				FileOutputStream fos = new FileOutputStream(file);
				byte[] buf = new byte[512];
				conn.connect();
				double count = 0;
				if (conn.getResponseCode() >= 400) {
					// 闁剧偓甯寸搾鍛
					ExtensionApi.callBackOnGLThread(this.bindMsg(ExtensionApi.downLoadApk, 3, ""));
				} else {
					int numread;
					int old_persent = 0;
					while ((numread = is.read(buf)) != -1) {
						fos.write(buf, 0, numread);
						count += numread;
						int persent = (int) (((float) (count) / (float) (filesize)) * 100);
						if (old_persent != persent) {
							ExtensionApi.callBackOnGLThread(this.bindMsg(ExtensionApi.downLoadApk, 1, String.valueOf(persent))); 
							old_persent = persent;
						} 

						if (persent == 100) {
							ExtensionApi.callBackOnGLThread(this.bindMsg(ExtensionApi.downLoadApk, 2, ""));
						} 
					}
					conn.disconnect();
					fos.close();
					is.close();
				}
			} catch (IOException e) {
				e.printStackTrace();
				ExtensionApi.callBackOnGLThread(this.bindMsg(ExtensionApi.downLoadApk, -1, "")); 
			}
		} catch (MalformedURLException e) {
			e.printStackTrace();
			ExtensionApi.callBackOnGLThread(this.bindMsg(ExtensionApi.downLoadApk, -1, "")); 
		}

		return file;
	}

	// 閹垫挸绱慉PK缁嬪绨禒锝囩垳

	private void InstallApk(File file) {
		Intent intent = new Intent();
		intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
		intent.setAction(android.content.Intent.ACTION_VIEW);
		intent.setDataAndType(Uri.fromFile(file),
				"application/vnd.android.package-archive");
		startActivity(intent);
	}  

    //by hlb begin, fixed crash in android-huawei hornor v10 
    private void initRecorder()
    {
        Log.d("AmrRecord", "initRecorder"); 
        try{
            mRecorder = new MediaRecorder();
            mRecorder.reset();
            mRecorder.setAudioSource(MediaRecorder.AudioSource.MIC);
            mRecorder.setOutputFormat(MediaRecorder.OutputFormat.AMR_NB);
            mRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB);
            mRecorder.setOutputFile(mFilepath);
            //如下两个设置很重要!否则即使录制2秒钟,某些机器录制出来的音频文件会非常大!!
            mRecorder.setMaxDuration(20000); 
            mRecorder.setMaxFileSize(100*1024); 
        }
        catch(Exception e){                
            Log.d("AmrRecord", "has error in initRecorder...");
            e.printStackTrace();
        }
    } 

    public boolean startRecord(final String fullpath) 
    {
        Log.d("AmrRecord", "startRecord...");

        mFilepath = fullpath; //Environment.getExternalStorageDirectory()+"/hlb.amr";  
        
        File file = new File(mFilepath);
        if(file.exists()) {
            if(file.delete()){
                try {
                    file.createNewFile();
                }
                catch(IOException e) {
                    e.printStackTrace();
                }
            }
            else {
                try {
                    file.createNewFile();
                }
                catch(IOException e) {
                    e.printStackTrace();
                }
            }
        }

        this.initRecorder();

        try {
            mRecorder.prepare();
            mRecorder.start();
            mBeginTime = Calendar.getInstance().getTimeInMillis();
        }           
        catch (IOException e) {
            Log.d("AmrRecord", " has error in startRecord !!!");
            e.printStackTrace();
            return false; 
        } 
        return true;    
    }    

    public void stopRecord() 
    {
        Log.d("AmrRecord", "stopRecord");

        if(mRecorder != null)
        {
            try {
                mRecorder.stop();
                mRecorder.release();
                mRecorder = null; 

                String path = mFilepath;
                long time = Calendar.getInstance().getTimeInMillis() - mBeginTime;
                String code = path + "#" + time;
                Log.d("AmrRecord", "stopRecord..." + code);
                ExtensionApi.callBackOnGLThread(this.bindMsg(ExtensionApi.voice_finish, 1, code));  
            }
            catch(Exception e){
                Log.d("AmrRecord", " has error in stopRecord...");
                e.printStackTrace();
                mRecorder.release();
                mRecorder = null; 
            } 
        } 
    } 

    public void startPlayVoice(final String fullpath) {

        this.stopPlayVoice();

        audioMP = new MediaPlayer();
        try {
            if("" != fullpath) {
                audioMP.reset();
                audioMP.setDataSource(fullpath);
                audioMP.setAudioStreamType(AudioManager.STREAM_MUSIC);
                audioMP.prepareAsync();
                audioMP.setOnPreparedListener(new MediaPlayer.OnPreparedListener() {                   
                    @Override
                    public void onPrepared(MediaPlayer mp) {
                        audioMP.start();
                    }
                });
            } 
            else {
                audioMP.setDataSource(mFilepath);
                audioMP.prepare();
                audioMP.start();
            }
            audioMP.setVolume(1.0f, 1.0f);
        }
        catch(IOException e) {
            e.printStackTrace();
        }
    }
    
    public void stopPlayVoice() {
        if(null != audioMP) {
            audioMP.stop();
            audioMP.release();
            audioMP = null;
        }
    }

    //set phone ration 1：landscape 2：portrait
    public int setOrientation(int orientation){
        if ( orientation == 1 ) {
            this.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
            //setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE);
        }
        else if (orientation == 2 ){
            this.setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_PORTRAIT);
            //setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_PORTRAIT);
        }
        return 0;
    }

    //by hlb end 


} 
