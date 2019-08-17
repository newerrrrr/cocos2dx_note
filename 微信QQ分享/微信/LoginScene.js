// Learn cc.Class:
//  - [Chinese] http://docs.cocos.com/creator/manual/zh/scripting/class.html
//  - [English] http://www.cocos2d-x.org/docs/creator/en/scripting/class.html
// Learn Attribute:
//  - [Chinese] http://docs.cocos.com/creator/manual/zh/scripting/reference/attributes.html
//  - [English] http://www.cocos2d-x.org/docs/creator/en/scripting/reference/attributes.html
// Learn life-cycle callbacks:
//  - [Chinese] http://docs.cocos.com/creator/manual/zh/scripting/life-cycle-callbacks.html
//  - [English] http://www.cocos2d-x.org/docs/creator/en/scripting/life-cycle-callbacks.html

var volume = 0;
var loginInfo = {};

cc.Class({
    extends: cc.Component,

    properties: {
        btnWX:cc.Button,
        btnTel:cc.Button,
        btnGuest:cc.Button,
        editbox:cc.EditBox,
    },

    // LIFE-CYCLE CALLBACKS:

    onLoad () {
        //过渡效果
        this.node.opacity = 0;
        this.node.runAction(cc.fadeIn(0.5));

        gt.autoAdaptDevices(); 
        this.addComponent('KeyBackExit'); //按返回键退出游戏
    },

    start () { 
        cc.log('=== LoginScene') 
        //检查正式版是否自动微信登陆 
        this.autoLogin = this.checkAutoLogin(); 
    },

    // update (dt) {},

    /* loginType: 登陆方式: weixin, guest, tel 
     * icon：头像url 
     * sex：性别 1：男 2：女 
     * accessToken, refreshToken：微信相关token 
     */
    startLogin:function(loginType, openId, nick, icon, sex, accessToken, refreshToken) {
        cc.log('=== startLogin: ', loginType, openId, nick, icon, sex, accessToken, refreshToken); 

        // gt.tcp.connect({
        //     host : gt.gateServer.ip,
        //     port : gt.gateServer.port,
        // }, 
        // function(result) { 
        //     cc.log('---------connect result:', result);
        // });        
    },

    //通过userid登陆
    loginByUserId:function(userId) {

    },

    onRcvLogin:function(msgTbl) { 
        cc.log('=== onRcvLogin:');
        gt.removeLoadingTips(); 

    },

    //手机登陆 
    onBtnLoginTel:function(){
        cc.log("===== onBtnLoginTel");
        gt.tcp.connect({
            host : gt.gateServer.ip,
            port : gt.gateServer.port,
        }, 
        function(result) { 
            cc.log('---------connect result:', result);
            gt.tcp.sendMessage('gate.gateHandler.queryEntry', {uid:12345}, function(resp) {
                gt.dump(resp, '-----------resp');
                gt.tcp.disconnect(function() {
                    cc.log('------start connect to connector server')
                    //链接connector
                    gt.tcp.connect({
                        host : resp.host,
                        port : resp.port,
                    }, function(result) {
                        cc.log('connect to connector server ok'); 
                        // gt.tcp.sendMessage('login.loginHandler.login', 'hlbtest', function(resp) {
                        //     gt.dump(resp, '-------------resp');
                        // });
                        cc.log('connect to login server...');
                        gt.tcp.sendMessage('login.loginHandler.login', ' enter...', function(resp) {
                            gt.dump(resp, '----------response');
                            cc.log('connect to login server ok');
                        });
                    });
                });
            });
        }); 
    },

    //游客登陆
    onBtnLoginGuest:function(){ 
        let name = this.editbox.string;
        cc.log('----------name:', name);
        if (name === '') {
            name = gt.getLocal('LoginNick', '');
            if (name === '') {
                name = '游客' + gt.random(1, 9999);
                gt.setLocal('LoginNick', name);
            } 
        } 
        
        if(name.length > 3 && name.substr(0, 2) === '*#') { 
            //输入格式为 *#123456 格式, 其中123456为userid 
            let userId = parseInt(name.substr(2));
            this.loginByUserId(userId);
        } 
        else { 
            this.startLogin('guest', '', name, '', 1);
        } 
    },

    //微信登陆
    onBtnLoginWX:function(){
        cc.log("===== onBtnLoginWX");
        //提示安装微信客户端
        if (!gt.wxMgr.isWXAppInstalled()) {
            gt.ui.toast.show('您还没有安装微信哦！');
            return 
        }

        if (this.autoLogin) return; //当前正在自动登陆 

        gt.showLoadingTips('正在登录游戏...', 6);

        //1.先获取授权 
        gt.wxMgr.getWeixinAuth(function(respJson) { 
            respJson = JSON.parse(respJson);
            if (respJson.status === 'CANCEL') { 
                gt.removeLoadingTips();
                return;
            } 
            if (respJson.status !== 'SUCCESS') { 
                gt.ui.noticeTips.show('微信授权失败', null, null, true); 
                gt.removeLoadingTips(); 
                return;
            } 

            //2.根据授权id来获取 token 
            gt.wxMgr.getTokenByAuthId(respJson.code, function(result, resp) { 
                if (!result) { 
                    gt.removeLoadingTips(); 
                    return;
                }
                gt.setLocal('WX_Refresh_Token_Time', Date.now()*0.001);

                //3.获取微信个人昵称, 性别, 头像url等内容
                this.getWeixinUserInfo(resp.access_token, resp.refresh_token, resp.openid);
            }.bind(this));
        }.bind(this));
    },

    getWeixinUserInfo:function(accessToken, refreshToken, openId) {
        gt.wxMgr.getWeixinUserInfo(accessToken, openId, function(result, resp) {
            if (!result) { 
                gt.removeLoadingTips(); 
                return;
            } 
            //存档信息 
            gt.setLocal('WX_Access_Token_Time', Date.now()*0.001);
            gt.setLocal('WX_Access_Token', accessToken);
            gt.setLocal('WX_Refresh_Token', refreshToken);
            gt.setLocal('WX_Open_ID', openId);

            this.startLogin('weixin', openId, resp.nickname, resp.headimgurl, resp.sex, accessToken, refreshToken);
        }.bind(this));
    },

    //检查微信是否需要自动登陆 
    checkAutoLogin:function() { 
        //获取存档 上次获取到的 token 时间 
        let accessTokenTime = gt.getLocal('WX_Access_Token_Time', ''); 
        let refreshTokenTime = gt.getLocal('WX_Refresh_Token_Time', ''); 
        if (accessTokenTime === '' || refreshTokenTime === '') { //未记录表示第一次登陆 
            return false; 
        } 

        //检测是否超时
        let accessTokenTimeout  = 5400;    //3600*1.5   微信accesstoken默认有效时间为2小时,这里取1.5小时内登录不需要重新取 accesstoken
        let refreshTokenTimeout = 2160000; //3600*24*25 微信refreshtoken默认有效时间为30天,这里取25天内登录不需要重新取 refreshtoken
        let curTime = Date.now()*0.001;
        
        //1.如果refresh token失效则进行一次完整的微信登录流程
        if (curTime - refreshTokenTime >= refreshTokenTimeout) {
            gt.ui.noticeTips.show('您的微信授权信息已失效, 请重新登录！', null, null, true); 
            return false;
        } 

        let accessToken  = gt.getLocal('WX_Access_Token', '');
        let refreshToken = gt.getLocal('WX_Refresh_Token', '');
        let openId       = gt.getLocal('WX_Open_ID', '');
        if (accessToken === '' || refreshToken === '' || openId === '') {
            return false;
        }

        //2.如果 access token 失效则重新请求token 
        if (curTime - accessTokenTime >= accessTokenTimeout) {
            //根据 refresh token 获取access token 
            gt.wxMgr.getAccessTokenByRefreshToken(refreshToken, function(result, resp) {
                if (!result || resp.errcode) {
                    this.autoLogin = false;
                    return;
                } 
                this.getWeixinUserInfo(resp.access_token, resp.refresh_token, resp.openid);
            }.bind(this));
        }
        else {
            cc.log('### start auto login...');
            gt.showLoadingTips('正在登录游戏...', 6);
            this.getWeixinUserInfo(accessToken, refreshToken, openId);
            return true;
        } 
    }, 
});
