package com.happy9.pyqps.wxapi;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Log;
import org.cocos2dx.javascript.AppActivity;
import org.json.JSONException;
import org.json.JSONObject;

import com.happy9.pyqps.R;
import com.tencent.mm.opensdk.modelmsg.SendAuth;
import com.tencent.mm.opensdk.modelmsg.SendMessageToWX;
import com.tencent.mm.opensdk.modelmsg.WXImageObject;
import com.tencent.mm.opensdk.modelmsg.WXMediaMessage;
import com.tencent.mm.opensdk.modelmsg.WXWebpageObject;
import com.tencent.mm.opensdk.modelpay.PayReq;
import com.tencent.mm.opensdk.openapi.WXAPIFactory;
import com.tencent.mm.opensdk.openapi.IWXAPI;
import java.io.ByteArrayOutputStream;
import java.io.File;

//开放给 JS 的外部接口
public class WXUtils {
    private static AppActivity app = null;
    private static IWXAPI api = null;
    
    //在 AppActivity.java 中调用初始化并注册微信
    public static void init(AppActivity context) {
        Log.d(Constant.LOG_TAG,"==== WXUtils init");
        app = context;

        /// 通过WXAPIFactory工厂，获取IWXAPI的实例
        api = WXAPIFactory.createWXAPI(app, Constant.WX_APPID, false);
        // 将应用的appId注册到微信
        api.registerApp(Constant.WX_APPID);
    }


    //******************************** 以下为 JS 端 调用接口 **********************************//

    //是否已安装微信
    public static boolean isWXAppInstalled() {
        return api.isWXAppInstalled();
    }

    //申请用户授权
    public static void getWeixinAuth() {
        Log.d(Constant.LOG_TAG, "WXUtils:getWeixinAuth");
        app.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                try {
                    SendAuth.Req req = new SendAuth.Req();
                    req.scope = "snsapi_userinfo";
                    req.state = "klqpdn";
                    api.sendReq(req);
                }
                catch (Exception e) {
                    Log.e(Constant.LOG_TAG, e.toString(), e);
                }
            }
        });
    }

    //分享图片
    //shareTo ：timeline（朋友圈）
    public static void shareImage(final String shareTo, final String filePath) {
        app.runOnGLThread(new Runnable() {
            @Override
            public void run() {
                Log.d(Constant.LOG_TAG, "shareImage:"+ shareTo + ", " + filePath);

                try {
                    Bitmap bmp = null;
                    try {
                        File file = new File(filePath);
                        if(file.exists())
                        {
                            bmp = BitmapFactory.decodeFile(filePath);
                        }
                    }
                    catch (Exception e) {
                        Log.e(Constant.LOG_TAG, " share image not exist", e);
                        return;
                    }

                    //初始化 WXImageObject 和 WXMediaMessage 对象
                    WXImageObject imgObj = new WXImageObject(bmp);
                    WXMediaMessage msg = new WXMediaMessage();
                    msg.mediaObject = imgObj;

                    //设置缩略图
                    int THUMB_SIZE = 140; //缩略图大小
                    int w = bmp.getWidth() * THUMB_SIZE / bmp.getHeight();
                    Bitmap thumbBmp = Bitmap.createScaledBitmap(bmp, w, THUMB_SIZE, true);
                    msg.thumbData = bmpToByteArray(thumbBmp, true);
                    bmp.recycle();

                    //构造一个Req
                    SendMessageToWX.Req req = new SendMessageToWX.Req();
                    req.transaction = shareTo + String.valueOf(System.currentTimeMillis()); //标识一个唯一请求
                    req.message = msg;

                    if (shareTo.equals("timeline")) { //分享到朋友圈
                        req.scene = SendMessageToWX.Req.WXSceneTimeline;
                    }
                    else { //分享到对话
                        req.scene = SendMessageToWX.Req.WXSceneSession;
                    }
                    api.sendReq(req);
                }
                catch (Exception e) {
                    Log.e(Constant.LOG_TAG, "WeixinImageMessage->", e);
                }
            }
        });
    }

    //分享APP url
    public static void shareAppInfo(final String shareTo, final String title, final String message, final String url) {
        app.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                WXWebpageObject webpage = new WXWebpageObject();
                webpage.webpageUrl = url;
                WXMediaMessage msg = new WXMediaMessage(webpage);
                msg.title = title;
                msg.description = message;

                //缩略图
                Bitmap thumb = BitmapFactory.decodeResource(app.getResources(), R.mipmap.ic_launcher);
                msg.thumbData = bmpToByteArray(thumb, true);

                SendMessageToWX.Req req = new SendMessageToWX.Req();
                req.transaction = String.valueOf(System.currentTimeMillis());
                req.message = msg;
                if (shareTo.equals("timeline")) { //朋友圈
                    req.scene = SendMessageToWX.Req.WXSceneTimeline;
                } else { //会话
                    req.scene = SendMessageToWX.Req.WXSceneSession;
                }
                api.sendReq(req);
            }
        });
    }

    //微信支付
    public static void weixinPay(final String orderInfo) {
        app.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                try {
                    JSONObject data = new JSONObject(orderInfo);
                    PayReq req = new PayReq();
                    req.appId = data.getString("appid");
                    req.partnerId = data.getString("partnerid");
                    req.prepayId = data.getString("prepayid");
                    req.packageValue = data.getString("package");
                    req.nonceStr = data.getString("noncestr");
                    req.timeStamp = data.getString("timestamp");
                    req.sign = data.getString("sign");
                    api.sendReq(req);
                }
                catch (JSONException e) {
                    e.printStackTrace();
                    Log.e(Constant.LOG_TAG, e.toString(), e);
                }
            }
        });
    }

    public static byte[] bmpToByteArray(final Bitmap bmp, final boolean needRecycle) {
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        bmp.compress(Bitmap.CompressFormat.JPEG, 60, output);
        if (needRecycle) {
            bmp.recycle();
        }

        byte[] result = output.toByteArray();
        try {
            output.close();
        } catch (Exception e) {
            e.printStackTrace();
        }

        return result;
    }
}
