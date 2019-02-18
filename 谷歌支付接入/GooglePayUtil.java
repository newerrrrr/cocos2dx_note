package com.utils;
import android.util.Log;

import com.utils.GooglePayMgr;


public final class GooglePayUtil {

    public static void purchase(String data) {
        GooglePayMgr.getInstance().purchase(data);
    }

    public static void hlbtest() {

        GooglePayMgr.getInstance().test();
    }

}