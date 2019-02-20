cc.Class({
    extends: cc.Component,

    statics: {
        uuid: function () {
            var s = [];
            var hexDigits = "0123456789abcdef";
            for (var i = 0; i < 36; i++) {
                s[i] = hexDigits.substr(Math.floor(Math.random() * 0x10), 1);
            }
            s[14] = "4";  // bits 12-15 of the time_hi_and_version field to 0010
            s[19] = hexDigits.substr((s[19] & 0x3) | 0x8, 1);  // bits 6-7 of the clock_seq_hi_and_reserved to 01
            s[8] = s[13] = s[18] = s[23] = "-";
         
            var uuid = s.join("");
            return uuid;
        },

        getRandom:function(start, end) 
        {
            return Math.floor(Math.random()*(end-start))+start; 
        },

        //获取牌值
        getCardCalue:function(card){
            return card % 16; 
        },

        //获取花色 0x0梅花  0x1方块 0x2红桃  0x3黑桃
        getCardColor : function(card)
        {
            return Math.floor(card / 16);
        },


        getCardTypeName: function(cardType,card_v) {
            switch (cardType){
                case cc.gv.CardType.FLUSH:
                return cc.gv.i18n.t('FLUSH');
                break;

                case cc.gv.CardType.STRAIGHT:
                return cc.gv.i18n.t('STRAIGHT');
                break;

                case cc.gv.CardType.PAIR:
                return cc.gv.i18n.t('PAIR');
                break;

                case cc.gv.CardType.STRAIGHTFLUSH1:
                return cc.gv.i18n.t('STRAIGHTFLUSH1');
                break;

                case cc.gv.CardType.STRAIGHTFLUSH2:
                return cc.gv.i18n.t('STRAIGHTFLUSH2');
                break;

                case cc.gv.CardType.HIGHCARD:
                if (card_v == 0) {
                    return cc.gv.i18n.t('bod');
                }else{
                    return card_v +' '+ cc.gv.i18n.t('score');
                }
                break;

                case cc.gv.CardType.TYPE_HIGHCARD:
                return cc.gv.i18n.t('TYPE_HIGHCARD');
                break;

                case cc.gv.CardType.TYPE_ONE_PAIR:
                return cc.gv.i18n.t('TYPE_ONE_PAIR');
                break;

                case cc.gv.CardType.TYPE_TWO_PAIR:
                return cc.gv.i18n.t('TYPE_TWO_PAIR');
                break;

                case cc.gv.CardType.TYPE_THREE_KIND:
                return cc.gv.i18n.t('TYPE_THREE_KIND');
                break;

                case cc.gv.CardType.TYPE_STRAIGHT:
                return cc.gv.i18n.t('TYPE_STRAIGHT');
                break;

                case cc.gv.CardType.TYPE_FLUSH:
                return cc.gv.i18n.t('TYPE_FLUSH');
                break;

                case cc.gv.CardType.TYPE_FULLHUOSE:
                return cc.gv.i18n.t('TYPE_FULLHUOSE');
                break;

                case cc.gv.CardType.TYPE_FOUR_KIND:
                return cc.gv.i18n.t('TYPE_FOUR_KIND');
                break;

                case cc.gv.CardType.TYPE_STRAIGHT_FLUSH:
                return cc.gv.i18n.t('TYPE_STRAIGHT_FLUSH');
                break;

                case cc.gv.CardType.TYPE_ROYAL_FLUSH:
                return cc.gv.i18n.t('TYPE_ROYAL_FLUSH');
                break;
            }

            return '';
        },
    
        formatMoney: function(number, places, symbol, thousand, decimal) {
            var unit = '';
            number = number || 0;
            if (number >= 1000000) {
                number /= 1000000;
                unit = ' M';
            }else if(number >= 10000){
                number /= 1000;
                unit = ' K';
            }
  
            if (number.toString().split(".").length <= 1 ){
                places = 0;
            }

            places = !isNaN(places = Math.abs(places)) ? places : 2;
            symbol = symbol !== undefined ? symbol : "$";
            thousand = thousand || ",";
            decimal = decimal || ".";
            var negative = number < 0 ? "-" : "",
                i = parseInt(number = Math.abs(+number || 0).toFixed(places), 10) + "",
                j = (j = i.length) > 3 ? j % 3 : 0;
            return symbol + negative + (j ? i.substr(0, j) + thousand : "") +
             i.substr(j).replace(/(\d{3})(?=\d)/g, "$1" + thousand) + 
             (places ? decimal + Math.abs(number - i).toFixed(places).slice(2) : "") +
             unit;
        },

        setNodeString: function(node,txt) {
            for(var i= 0; i< node.children.length; i++)
            {
                var child = node.children[i];
                var label = child.getComponent(cc.Label);
                label.string = txt;
            }
        },

        getChipValues: function(value) {
            var values = [];
            var num = 0;
            var datas = [10000,5000,1000,500,200,100,50];
            
            for (var i=0; i<datas.length; i++){
                var data = datas[i];
                if (value > data || value == 50){
                    var result = Math.floor(value/data);
                    values[values.length] = {value:data, num:result};
                    value -= (result*data);
                    num += result;
                }

                if (value <= 0){
                    break;
                }
            }

            return {values:values,num:num};
        },

        getAngle: function(px,py,mx,my){//获得人物中心和鼠标坐标连线，与y轴正半轴之间的夹角
            var x = Math.abs(px-mx);
            var y = Math.abs(py-my);
            var z = Math.sqrt(Math.pow(x,2)+Math.pow(y,2));
            var cos = y/z;
            var radina = Math.acos(cos);//用反三角函数求弧度
            var angle = Math.floor(180/(Math.PI/radina));//将弧度转换成角度

            if(mx>px&&my>py){//鼠标在第四象限
                angle = 180 - angle;
            }

            if(mx==px&&my>py){//鼠标在y轴负方向上
                angle = 180;
            }

            if(mx>px&&my==py){//鼠标在x轴正方向上
                angle = 90;
            }

            if(mx<px&&my>py){//鼠标在第三象限
                angle = 180+angle;
            }

            if(mx<px&&my==py){//鼠标在x轴负方向
                angle = 270;
            }

            if(mx<px&&my<py){//鼠标在第二象限
                angle = 360 - angle;
            }

            return angle;
        },

         /**
         * 时间格式化 返回格式化的时间
         * @param date {object}  可选参数，要格式化的data对象，没有则为当前时间
         * @param fomat {string} 格式化字符串，例如：'YYYY年MM月DD日 hh时mm分ss秒 星期' 'YYYY/MM/DD week' (中文为星期，英文为week)
         * @return {string} 返回格式化的字符串
         * 
         * 例子:
         * formatDate(new Date("january 01,2012"));
         * formatDate(new Date());
         * formatDate('YYYY年MM月DD日 hh时mm分ss秒 星期 YYYY-MM-DD week');
         * formatDate(new Date("january 01,2012"),'YYYY年MM月DD日 hh时mm分ss秒 星期 YYYY/MM/DD week');
         * 
         * 格式：   
         *    YYYY：4位年,如1993
    　　 *　　YY：2位年,如93
    　　 *　　MM：月份
    　　 *　　DD：日期
    　　 *　　hh：小时
    　　 *　　mm：分钟
    　　 *　　ss：秒钟
    　　 *　　星期：星期，返回如 星期二
    　　 *　　周：返回如 周二
    　　 *　　week：英文星期全称，返回如 Saturday
    　　 *　　www：三位英文星期，返回如 Sat
        */
        formatDate: function(date, format) {
            if (arguments.length < 2 && !date.getTime) {
                format = date;
                date = new Date();
            }
            typeof format != 'string' && (format = 'YYYY年MM月DD日 hh时mm分ss秒');
            var week = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', '日', '一', '二', '三', '四', '五', '六'];
            return format.replace(/YYYY|YY|MM|DD|hh|mm|ss|星期|周|www|week/g, function(a) {
                switch (a) {
                case "YYYY": return date.getFullYear();
                case "YY": return (date.getFullYear()+"").slice(2);
                case "MM":
                    if (date.getMonth() + 1 < 10) {
                        return '0' + (date.getMonth() + 1);
                    } else {
                        return date.getMonth() + 1;
                    }
                case "DD":
                    if (date.getDate() < 10) {
                        return '0' + date.getDate();
                    } else {
                        return date.getDate();
                    }
                case "hh": return date.getHours();
                case "mm": 
                    if(date.getMinutes()<10){ 
                        return "0"+ date.getMinutes();
                    }
                    else{
                        return date.getMinutes();
                    }                    
                case "ss": return date.getSeconds();
                case "星期": return "星期" + week[date.getDay() + 7];
                case "周": return "周" +  week[date.getDay() + 7];
                case "week": return week[date.getDay()];
                case "www": return week[date.getDay()].slice(0,3);
                }
            });
        },

        copyToClipBoard:function(str) {  
            if (cc.sys.isBrowser) { 
                var input = str;
                const el = document.createElement('textarea');
                el.value = input;
                el.setAttribute('readonly', '');
                el.style.contain = 'strict';
                el.style.position = 'absolute';
                el.style.left = '-9999px';
                el.style.fontSize = '12pt'; // Prevent zooming on iOS

                const selection = getSelection();
                var originalRange = false;
                if (selection.rangeCount > 0) {
                    originalRange = selection.getRangeAt(0);
                }
                document.body.appendChild(el);
                el.select();
                el.selectionStart = 0;
                el.selectionEnd = input.length;

                var success = false;
                try {
                    success = document.execCommand('copy');
                } catch (err) {}

                document.body.removeChild(el);

                if (originalRange) {
                    selection.removeAllRanges();
                    selection.addRange(originalRange);
                }

                return success;
            }else{
                return cc.gv.system.copyToClipBoard(str);
            }
        },

        share: function(desc,callback) {
            if (cc.gv.UserMgr.ac_from == 'facebook') {
                cc.gv.facebook.share(desc,function(){
                    if(callback){
                       cc.gv.NetMgr.sendShareSuccess();
                    }                    
                    //if (callback) callback();
                });
            }
            // else if (cc.gv.UserMgr.ac_from == 'line') {
            //     cc.gv.line.share(function(){
            //         cc.gv.NetMgr.sendShareSuccess();   
            //     });
            // }
            else{
                cc.gv.popupMgr.showAlert(cc.gv.i18n.t('PleaseLogin'));
            }
        },

        loadNative: function(url, callback) {
            var dirpath =  jsb.fileUtils.getWritablePath() + 'img/';
            var filepath = dirpath + MD5(url) + '.png';

            function loadEnd(){
                cc.loader.load(filepath, function(err, tex){
                    if( err ){
                        cc.error(err);
                    }else{
                        var spriteFrame = new cc.SpriteFrame(tex);
                        if( spriteFrame ){
                            spriteFrame.retain();
                            callback(spriteFrame);
                        }
                    }
                });
            }

            if( jsb.fileUtils.isFileExist(filepath) ){
                cc.log('Remote is find' + filepath);
                loadEnd();
                return;
            }

            var saveFile = function(data){
                if( typeof data !== 'undefined' ){
                    if( !jsb.fileUtils.isDirectoryExist(dirpath) ){
                        jsb.fileUtils.createDirectory(dirpath);
                    }

                    if( jsb.fileUtils.writeDataToFile(  new Uint8Array(data) , filepath) ){
                        cc.log('Remote write file succeed.');
                        loadEnd();
                    }else{
                        cc.log('Remote write file failed.');
                    }
                }else{
                    cc.log('Remote download file failed.');
                }
            };
            
            var xhr = new XMLHttpRequest();

            xhr.onreadystatechange = function () {
                cc.log("xhr.readyState  " +xhr.readyState);
                cc.log("xhr.status  " +xhr.status);
                if (xhr.readyState === 4 ) {
                    if(xhr.status === 200){
                        xhr.responseType = 'arraybuffer';
                        saveFile(xhr.response);
                    }else{
                        saveFile(null);
                    }
                }
            }.bind(this);
            xhr.open("GET", url, true);
            xhr.send();
        },

        downFile: function(url, callback) {
            var dirpath =  jsb.fileUtils.getWritablePath() + 'img/';
            var filepath = dirpath + MD5(url) + '.png';

            if( jsb.fileUtils.isFileExist(filepath) ){
                cc.log('Remote is find' + filepath);
                if (callback) {
                    callback(filepath);
                }
                return;
            }

            var saveFile = function(data){
                if( typeof data !== 'undefined' ){
                    if( !jsb.fileUtils.isDirectoryExist(dirpath) ){
                        jsb.fileUtils.createDirectory(dirpath);
                    }

                    if( jsb.fileUtils.writeDataToFile(  new Uint8Array(data) , filepath) ){
                        cc.log('Remote write file succeed.');
                        if (callback) {
                            callback(filepath);
                        }
                    }else{
                        cc.log('Remote write file failed.');
                    }
                }else{
                    cc.log('Remote download file failed.');
                }
            };
            
            var xhr = new XMLHttpRequest();

            xhr.onreadystatechange = function () {
                cc.log("xhr.readyState  " +xhr.readyState);
                cc.log("xhr.status  " +xhr.status);
                if (xhr.readyState === 4 ) {
                    if(xhr.status === 200){
                        xhr.responseType = 'arraybuffer';
                        saveFile(xhr.response);
                    }else{
                        saveFile(null);
                    }
                }
            }.bind(this);
            xhr.open("GET", url, true);
            xhr.send();
        },

        // capture: function() {
        //     var targetTexture = cc.Camera.main.targetTexture;
        //     let texture = new cc.RenderTexture();
        //     texture.initWithSize(cc.visibleRect.width, cc.visibleRect.height);
        //     cc.Camera.main.targetTexture = texture;

        //     let spriteFrame = new cc.SpriteFrame();
        //     spriteFrame.setTexture(texture);

        //     spr.spriteFrame = spriteFrame;
        //     cc.Camera.main.targetTexture = targetTexture;
            
        // },

        captureScreenshot: function(callback) {
            var self = this;
            function afcallback() {
                var canvas = document.getElementById("GameCanvas");
                var base64 = canvas.toDataURL("imagea/png");
                cc.director.off(cc.Director.EVENT_AFTER_DRAW);
                // var href = base64.replace(/^data:image[^;]*/, "data:image/octet-stream");
                // document.location.href = href;
                // var url = document.URL+href;
                var img = new Image();
                img.src = base64;
                img.onload = function () {
                    if (callback) callback(img);
                };
            }
            cc.director.on(cc.Director.EVENT_AFTER_DRAW, afcallback);
        },


        base64ToSpriteFrame: function(base64, callback) {
            var img = new Image();
            img.src = base64;
            img.onload = function () {
                // var texture = new cc.Texture2D();
                // texture.initWithElement(img);
                // texture.handleLoadedTexture();
                // var newframe = new cc.SpriteFrame(texture);
                if (callback) callback(img);
            }
        },

        releaseLog: function(text) {
            if (cc.sys.os == cc.sys.OS_ANDROID) {
                jsb.reflection.callStaticMethod('com/utils/LogDebug', "printLog", "(Ljava/lang/String;)V", text); 
            }
        },
    },
});
