package com.happy9.pyqps.wxapi;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;

import com.tencent.mm.opensdk.constants.ConstantsAPI;
import com.tencent.mm.opensdk.modelbase.BaseReq;
import com.tencent.mm.opensdk.modelbase.BaseResp;
import com.tencent.mm.opensdk.modelmsg.SendAuth;
import com.tencent.mm.opensdk.modelmsg.ShowMessageFromWX;
import com.tencent.mm.opensdk.openapi.IWXAPI;
import com.tencent.mm.opensdk.openapi.IWXAPIEventHandler;
import com.tencent.mm.opensdk.openapi.WXAPIFactory;

import android.util.Log;

import org.cocos2dx.lib.Cocos2dxJavascriptJavaBridge;

import static org.cocos2dx.lib.Cocos2dxHelper.runOnGLThread;


//此文件必须放在 包名下的wxapi/目录下,比如 com.happy9.pyqps.wxapi.WXEntryActivity,  同时 Androidmanifest.xml 必须将此 Activity 导出 exported="true"
//否则无法启用此Activity
public class WXEntryActivity extends Activity implements IWXAPIEventHandler {
    private IWXAPI api;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.d(Constant.LOG_TAG, "------ WXEntryActivity:onCreate");
        api = WXAPIFactory.createWXAPI(this, Constant.WX_APPID, false);//false:不检查签名
        try {
            Intent intent = getIntent();
            api.handleIntent(intent, this);
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);

        setIntent(intent);
        api.handleIntent(intent, this);
    }

    @Override
    public void onReq(BaseReq baseReq) {
        Log.d(Constant.LOG_TAG, "------ WXEntryActivity:onReq" + baseReq.toString());

        switch (baseReq.getType()) {
            case ConstantsAPI.COMMAND_GETMESSAGE_FROM_WX:
//                goToGetMsg();
                break;
            case ConstantsAPI.COMMAND_SHOWMESSAGE_FROM_WX:
//                goToShowMsg((ShowMessageFromWX.Req) baseReq);
                break;
            default:
                break;
        }
        finish();
    }

    @Override
    public void onResp(BaseResp baseResp) {
        Log.d(Constant.LOG_TAG, "------ WXEntryActivity:onResp:" + baseResp.toString());

        int type = baseResp.getType();
        String tagStr = ""; //用于区分JS 函数的用户callback
        if(type == ConstantsAPI.COMMAND_SENDAUTH) {
            tagStr = Constant.TYPE_WEIXIN_TOKEN;
        }
        else if(type == ConstantsAPI.COMMAND_SENDMESSAGE_TO_WX) {
            tagStr = Constant.TYPE_WEIXIN_SHARE;
        }
        else if(type == ConstantsAPI.COMMAND_PAY_BY_WX) {
            tagStr = Constant.TYPE_WEIXIN_PAY;
        }
        Log.d(Constant.LOG_TAG, "------ onResp, type:" + type);
        Log.d(Constant.LOG_TAG, "------ onResp, errCode:" + baseResp.errCode);

        switch (baseResp.errCode){
            case BaseResp.ErrCode.ERR_OK: //用户同意
                Log.d(Constant.LOG_TAG, "Resp OK");
                String jsFuncPara = "";
                if(type == ConstantsAPI.COMMAND_SENDAUTH){
                    SendAuth.Resp tempResp = (SendAuth.Resp) baseResp;
                    String code = tempResp.code;
                    jsFuncPara =  this.bindMsg(tagStr, "SUCCESS", code );
                }
                else if(type == ConstantsAPI.COMMAND_SENDMESSAGE_TO_WX || type == ConstantsAPI.COMMAND_SENDMESSAGE_TO_WX){
                    jsFuncPara = this.bindMsg(tagStr, "SUCCESS", "");
                }
                else{
                    Log.d(Constant.LOG_TAG, "onResp type is else");
                }

                //将结果返回给 JS 端
                if (!jsFuncPara.equals("")) {
                    String sb = "gt.wxMgr.execCallback(";
                    sb += ("'" + tagStr + "',");
                    sb += ("'" + jsFuncPara + "')");
                    evalString(sb);
                }
                break;

            case BaseResp.ErrCode.ERR_USER_CANCEL: //用户取消
                Log.d(Constant.LOG_TAG, "CANCEL");
                String jsPara = "";
                jsPara = this.bindMsg(tagStr, "CANCEL", "");
//                if(type == ConstantsAPI.COMMAND_SENDAUTH) {
//                    jsPara = this.bindMsg(tagStr, "CANCEL", "");
//                }
//                else {
//                    jsPara = this.bindMsg(tagStr, -2, "");
//                }
                //将结果返回给 JS 端
                if (!jsPara.equals("")) {
                    String sb = "gt.wxMgr.execCallback(";
                    sb += ("'" + tagStr + "',");
                    sb += ("'" + jsPara + "')");
                    evalString(sb);
                }
                break;

            case BaseResp.ErrCode.ERR_AUTH_DENIED:  //用户拒绝
                Log.d(Constant.LOG_TAG, "ERR_AUTH_DENIED");
                String para = "";
                jsPara = this.bindMsg(tagStr, "DENIED", "");
//                if(type == ConstantsAPI.COMMAND_SENDAUTH) {
//                    para = this.bindMsg(tagStr, 0, "");
//                }
//                else {
//                    para = this.bindMsg(tagStr, -4, "");
//                }
                //将结果返回给 JS 端
                if (!para.equals("")) {
                    String sb = "gt.wxMgr.execCallback(";
                    sb += ("'" + tagStr + "',");
                    sb += ("'" + para + "')");
                    evalString(sb);
                }
                break;

            default:
                Log.d(Constant.LOG_TAG, "default");
                String paras = this.bindMsg(tagStr, "Fail", "");
                String sb = "gt.wxMgr.execCallback(";
                sb += ("'" + tagStr + "',");
                sb += ("'" + paras + "')");
                evalString(sb);
                break;
        }
        this.finish();
    }

    private String bindMsg(String type, String status, String code) {
        return "{\"type\":\"" + type + "\", \"status\":\"" + status +"\", \"code\":\""+ code + "\"}";
    }

    //在 GL 线程调用JS 脚本
    public void evalString(final String js) {
        runOnGLThread(new Runnable() {
            @Override
            public void run() {
                Cocos2dxJavascriptJavaBridge.evalString(js);
            }
        });
    }
}
