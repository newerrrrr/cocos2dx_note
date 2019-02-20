
var GooglePlay=cc.Class({
    extends: Object,

    statics:{
        init: function () {
            this.GOOGLE_PALY = 'com/utils/GooglePayUtil';
            this.IOS_Pay = 'PayIPAManager';
            this.productPayCallback = function(msg){};
        },

        refreshPay:function(){
            if (cc.sys.os == cc.sys.OS_ANDROID) {
               
            } else if (cc.sys.os == cc.sys.OS_IOS) {
                jsb.reflection.callStaticMethod(this.IOS_Pay, "refreshPayReceipt");
            } 
        },

        productPay: function (productid,referenceId,productPayCallback) {
            if(productPayCallback && 'function' == typeof productPayCallback){
                this.productPayCallback = productPayCallback;
            }

            if (cc.sys.os == cc.sys.OS_ANDROID) {
                cc.gv.Utils.releaseLog('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ hlb');

                let jsonstring = JSON.stringify({
                    Pid:productid,
                    OrderId:referenceId,
                });
                
                jsb.reflection.callStaticMethod(this.GOOGLE_PALY, "purchase", "(Ljava/lang/String;)V",jsonstring);
            } else if (cc.sys.os == cc.sys.OS_IOS) {
                jsb.reflection.callStaticMethod(this.IOS_Pay, "payProductWithId:",productid);
            }
        },

        payCallback:function(msg){
            cc.gv.Utils.releaseLog('@@@@@@@@@@@@@@@=================payCallback');
            this.productPayCallback(msg);
        },

        onPaySuccess: function (msg) {
            this.productPayCallback(msg);
            if (cc.sys.os == cc.sys.OS_ANDROID) {
               
            } else if (cc.sys.os == cc.sys.OS_IOS) {
                jsb.reflection.callStaticMethod(this.IOS_Pay, "finishPayTransaction");
            }
        },

    }
});
module.exports = GooglePlay;