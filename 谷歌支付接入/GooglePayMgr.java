package com.utils;

import android.content.Context;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.util.Log;

import com.anjlab.android.iab.v3.BillingProcessor;
import com.anjlab.android.iab.v3.Constants;
import com.anjlab.android.iab.v3.SkuDetails;
import com.anjlab.android.iab.v3.TransactionDetails;

import org.cocos2dx.lib.Cocos2dxHelper;
import org.cocos2dx.lib.Cocos2dxJavascriptJavaBridge;
import org.json.JSONException;
import org.json.JSONObject;
import android.widget.Toast;

import java.util.List;
import java.util.Timer;
import java.util.TimerTask;

import org.cocos2dx.javascript.AppActivity;
import android.content.Intent;

/**
 * Created by ljm on 2018/5/23.
 */

public class GooglePayMgr {
    private static GooglePayMgr mInstace = null;
    BillingProcessor _bp = null;
    Context _tx = null;

    public static AppActivity context = (AppActivity) AppActivity.getContext();
    String IAB_LICENSE_KEY = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAssyxKGgnLj3bZepsis2JbKs+LZIVvuxpeMYaC06/2XY1Af2EUUXuBBaXn7wMSphgHVW/RJ/zwz+BLgPyXDURjESEh8hFFWXPgn7kjxw9OKpoqzBN1lymdNGxbhVndG3T6u3uY3/d7qRIjlGVLuftUrBoKKXU1d1mootFRlKNKiGW0dGzp9OENikxSObAvOPnPBBj4xPyA6/9uj7nyYgdznM32T6R8AvRc19EzFgSKdzpKcZCzQCad0lScVORq6jKrUm+O8dLOMNYFWu3UcCNmXrfYE+s4LVzRM0PCt4AZ7xHD4U/JL3dniMPMIJ6A7/OS8PnPCkwdY7xGIKJejuxmwIDAQAB";
    final int PAY_CODE = 1;

    public static GooglePayMgr getInstance() {
        if (null == mInstace){
            mInstace = new GooglePayMgr();
        }
        return mInstace;
    }

    public String getIabKey(){
        return IAB_LICENSE_KEY;
    }

    public BillingProcessor getBP(){
        return _bp;
    }

    public void setBilProcess(BillingProcessor bp,Context tx){
        _bp = bp;
        _tx = tx;
    }

    public void destoryBP(){
        if (_bp != null) {
            _bp.release();
        }
    }


    //主线程处理消息
    public Handler m_Handler = new Handler() {
        @Override
        public void handleMessage(Message msg) { 
            Log.d("HLB", "=== handleMessage, msg.what = " + msg.what);

            switch (msg.what) {
                case PAY_CODE:
                {
                    // pay result
                    String strResult = msg.getData().getString("result");
                    JSONObject obj = new JSONObject();
                    try{
                        //obj.put("cbName","paySdkCallback");
                        obj.put("result", strResult);
                        if(strResult.equals("1")){
                            String strMsg = msg.getData().getString("message");
                            String strSign = msg.getData().getString("signature");
                            String strPid = msg.getData().getString("pid");

                            obj.put("message",strMsg);
                            obj.put("signature",strSign);
                            obj.put("pid",strPid);
                        }
                        else{
                            String strErr = msg.getData().getString("errInfo");
                            obj.put("errInfo",strErr);
                        }

                        evalString("cc.gv.googleplay.payCallback("+obj+");");

                    }catch (JSONException e){

                    }
                    break;
                }
                default:
                {
                    break;
                }
            }
        }
    };

    //初始化
    public BillingProcessor init(Context tx) {

        if(_bp == null){
            _tx = tx;
            //*
            _bp = new BillingProcessor(tx, IAB_LICENSE_KEY, new BillingProcessor.IBillingHandler() {
                @Override
                public void onProductPurchased(String productId, TransactionDetails details) {
                    Log.d("HLB", "=== onProductPurchased, buy success ");
                    // 购买成功
                    //消耗物品
                    generTranstionMsg(productId,details); 
                }

                @Override
                public void onBillingError(int errorCode, Throwable error) {
                    if (errorCode == Constants.BILLING_RESPONSE_RESULT_USER_CANCELED){
                        // 购买取消
                        Log.d("HLB", "=== onBillingError, buy cancel ");
                        sendErrorMsg("-4", "取消支付");
                        return;
                    }
                    else if(errorCode == Constants.BILLING_RESPONSE_RESULT_ITEM_ALREADY_OWNED){
                        //已经购买了
                        Log.d("HLB", "=== onBillingError, already buy");
                        checkProduct();
                    }

                    // 购买失败
                    sendErrorMsg("-5","支付失败: code= " + Integer.toString(errorCode)); 
                } 

                @Override
                public void onBillingInitialized() { 
                    Log.d("HLB", "=== onBillingInitialized"); 
                    // 初始化成功
                    _bp.loadOwnedPurchasesFromGoogle(); //先去查询谷歌服务端的订单
                }

                @Override
                public void onPurchaseHistoryRestored() {
                    Log.d("HLB", "=== onPurchaseHistoryRestored"); 
                    // 恢复内购
                    _bp.loadOwnedPurchasesFromGoogle(); //先去查询谷歌服务端的订单
                }
            });//*/
            //_bp.initialize();
        }
        return _bp;
    }

    //购买
    //data: json格式自己按需解析
    public void purchase(String data){ 
        Log.d("HLB", "=== purchase"); 

        boolean isAvailable = BillingProcessor.isIabServiceAvailable(_tx);
        if(isAvailable){ 
            JSONObject jb = null;
            try{
                jb = new JSONObject(data);
                //商品id
                final String productId = jb.getString("Pid");
                String orderId = jb.getString("OrderId");
                final String payload = "OrderId:"+orderId;

                boolean bNeedDelay = false;
                if(!_bp.isInitialized()){
                    _bp.release();
                    _bp = null;
                    bNeedDelay = true;
                    init(_tx);
                }

                //是否有购买了的商品未消耗, 先通知google消耗才能再次购买
                boolean bBuy = _bp.isPurchased(productId);
                if(bBuy){
                    checkProduct();
                    return ;
                }
                if(bNeedDelay){
                    TimerTask task = new TimerTask() {
                        @Override
                        public void run() {
                            //_bp.purchase(context,productId);
                            boolean res = _bp.purchase(context,productId,payload);
                            if(!res){
                                sendErrorMsg("-3", "未能连接到google服务器");
                            }
                        }
                    };
                    Timer timer = new Timer();
                    timer.schedule(task, 1000);//1秒后执行TimeTask的run方法
                }
                else{
                    boolean res = _bp.purchase(context,productId,payload);
                    if(!res){
                        sendErrorMsg("-3", "未能连接到google服务器");
                    }
                }
            }catch (JSONException e){
                e.printStackTrace();
            }
        }
        else{
            sendErrorMsg("-1", "没有google支付环境");
        } 
    }

    //查询是否有未消耗的产品，有的话，先消耗掉
    public void checkProduct(){
       List<String> ls = _bp.listOwnedProducts();
        for(String attribute : ls) {
            TransactionDetails details = _bp.getPurchaseTransactionDetails(attribute);
            generTranstionMsg(attribute,details);
        }
    }

    //组装购买成功 msg
    private void generTranstionMsg(String productId, TransactionDetails details){
        Log.d("HLB", "=== generTranstionMsg, start transting, productId =" + productId); 

        //消耗物品
        _bp.consumePurchase(productId);

        String strMsg = details.purchaseInfo.responseData;
        String sign = details.purchaseInfo.signature;
        String pid = productId;

        Message msg = m_Handler.obtainMessage(PAY_CODE);
        Bundle bundleMsg = new Bundle();
        bundleMsg.putString("result", "1");
        bundleMsg.putString("message", strMsg);
        bundleMsg.putString("signature", sign);
        bundleMsg.putString("pid", pid);
        Log.d("HLB", "=== message, signature, pid =" + strMsg + ' ' + sign + ' '+ pid); 

        msg.setData(bundleMsg);
        m_Handler.sendMessage(msg);
    }

    //发送错误信息
    private void sendErrorMsg(String errCode,String errInfo){
        Message msg = m_Handler.obtainMessage(PAY_CODE);
        Bundle bundleMsg = new Bundle();
        bundleMsg.putString("result",errCode);
        bundleMsg.putString("errInfo",errInfo);

        msg.setData(bundleMsg);
        m_Handler.sendMessage(msg);
    }

    public void evalString(final String js) {
        Cocos2dxHelper.runOnGLThread(new Runnable() {
            @Override
            public void run() {
                Cocos2dxJavascriptJavaBridge.evalString(js);
            }
        });
    }

    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        _bp.handleActivityResult(requestCode, resultCode, data);
    }

    public void test(){
        Log.d("HLB", "=====test");
        evalString("cc.gv.googleplay.payCallback('kfjdkjfdkfjdk');"); 
    }
}
