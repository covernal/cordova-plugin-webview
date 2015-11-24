package com.ebwebview.plugin;

import org.apache.cordova.*;
import org.apache.cordova.PluginResult;

import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONException;

import org.xwalk.core.XWalkView;
import org.xwalk.core.XWalkResourceClient;
import org.xwalk.core.XWalkCookieManager;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.drawable.Drawable;
import android.util.Base64;
import android.util.Log;
import android.view.Gravity;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;

import java.io.ByteArrayOutputStream;

public class InAppBrowserXwalk extends CordovaPlugin {

    private BrowserDialog dialog;
    private XWalkView xWalkWebView;
    private CallbackContext callbackContext;

    @Override
    public boolean execute(String action, JSONArray data, CallbackContext callbackContext) throws JSONException {

        if(action.equals("open")) {
            this.callbackContext = callbackContext;
            this.openBrowser(data);
        } else if(action.equals("load")) {
            this.callbackContext = callbackContext;
            this.loadUrl(data);
        } else if(action.equals("close")) {
            this.closeBrowser();
        } else if(action.equals("show")) {
            this.showBrowser();
        } else if(action.equals("hide")) {
            this.hideBrowser();
        } else if(action.equals("setPosition")) {
            this.setPosition(data);
        } else if(action.equals("setSize")) {
            this.setSize(data);
        } else if(action.equals("getScreenshot")) {
            this.getScreenshot(data, callbackContext);
        } else if (action.equals("injectScriptCode")) {
            String jsWrapper = null;
            if (data.getBoolean(1)) {       // Is Wrapped JS
                jsWrapper = String.format("prompt(JSON.stringify([eval(%%s)]), 'gap-iab://%s')", callbackContext.getCallbackId());
            }
            injectDeferredObject(data.getString(0), jsWrapper);     // JavaScript String
        }  else if (action.equals("injectScriptFile")) {
            String jsWrapper;
            if (data.getBoolean(1)) {
                jsWrapper = String.format("(function(d) { var c = d.createElement('script'); c.src = %%s; c.onload = function() { prompt('', 'gap-iab://%s'); }; d.body.appendChild(c); })(document)", callbackContext.getCallbackId());
            } else {
                jsWrapper = "(function(d) { var c = d.createElement('script'); c.src = %s; d.body.appendChild(c); })(document)";
            }
            injectDeferredObject(data.getString(0), jsWrapper);
        } else if (action.equals("injectStyleCode")) {
            String jsWrapper;
            if (data.getBoolean(1)) {
                jsWrapper = String.format("(function(d) { var c = d.createElement('style'); c.innerHTML = %%s; d.body.appendChild(c); prompt('', 'gap-iab://%s');})(document)", callbackContext.getCallbackId());
            } else {
                jsWrapper = "(function(d) { var c = d.createElement('style'); c.innerHTML = %s; d.body.appendChild(c); })(document)";
            }
            injectDeferredObject(data.getString(0), jsWrapper);
        }  else if (action.equals("injectStyleFile")) {
            String jsWrapper;
            if (data.getBoolean(1)) {
                jsWrapper = String.format("(function(d) { var c = d.createElement('link'); c.rel='stylesheet'; c.type='text/css'; c.href = %%s; d.head.appendChild(c); prompt('', 'gap-iab://%s');})(document)", callbackContext.getCallbackId());
            } else {
                jsWrapper = "(function(d) { var c = d.createElement('link'); c.rel='stylesheet'; c.type='text/css'; c.href = %s; d.head.appendChild(c); })(document)";
            }
            injectDeferredObject(data.getString(0), jsWrapper);
        }

        return true;
    }

    class MyResourceClient extends XWalkResourceClient {
           MyResourceClient(XWalkView view) {
               super(view);
           }

           @Override
           public void onLoadStarted (XWalkView view, String url) {
               try {
                   JSONObject obj = new JSONObject();
                   obj.put("type", "loadstart");
                   obj.put("url", url);
                   PluginResult result = new PluginResult(PluginResult.Status.OK, obj);
                   result.setKeepCallback(true);
                   callbackContext.sendPluginResult(result);
               } catch (JSONException ex) {}
           }

           @Override
           public void onLoadFinished (XWalkView view, String url) {
               try {
                   JSONObject obj = new JSONObject();
                   obj.put("type", "loadstop");
                   obj.put("url", url);
                   PluginResult result = new PluginResult(PluginResult.Status.OK, obj);
                   result.setKeepCallback(true);
                   callbackContext.sendPluginResult(result);
               } catch (JSONException ex) {}
           }

            public void onLoadError (XWalkView view, String url) {
                try {
                    JSONObject obj = new JSONObject();
                    obj.put("type", "loaderror");
                    obj.put("url", url);
                    PluginResult result = new PluginResult(PluginResult.Status.ERROR, obj);
                    result.setKeepCallback(true);
                    callbackContext.sendPluginResult(result);
                } catch (JSONException ex) {}
            }
    }

    private void openBrowser(final JSONArray data) throws JSONException {
        final String url = data.getString(0);
        this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                // Create Dialogs.
                if(xWalkWebView == null) {
                    dialog = new BrowserDialog(cordova.getActivity(), android.R.style.Theme_NoTitleBar);
                    xWalkWebView = new XWalkView(cordova.getActivity(), cordova.getActivity());
                    XWalkCookieManager mCookieManager = new XWalkCookieManager();
                    mCookieManager.setAcceptCookie(true);
                    mCookieManager.setAcceptFileSchemeCookies(true);
                    xWalkWebView.setResourceClient(new MyResourceClient(xWalkWebView));
                }
                xWalkWebView.load(url, "");

                int left=0, top=0, width=0, height=0;
                float alpha=1f;
                if(data != null && data.length() > 1) {
                    try {
                        // Options will be like : left=0,top=150,width=320,height=200
                        String paramString = data.getString(1);
                        String[] params = paramString.split(",");

                        for (int i = 0; i < params.length; i++) {
                            String[] keyValue = params[i].split("=");

                            String paramKey = keyValue[0];
                            String paramVal = keyValue[1];

                            if (paramKey.compareTo("left") == 0) {
                                left = Integer.parseInt(paramVal);
                            } else if (paramKey.compareTo("top") == 0) {
                                top = Integer.parseInt(paramVal);
                            } else if (paramKey.compareTo("width") == 0) {
                                width = Integer.parseInt(paramVal);
                            } else if (paramKey.compareTo("height") == 0) {
                                height = Integer.parseInt(paramVal);
                            } else if (paramKey.compareTo("alpha") == 0) {
                                alpha = Float.parseFloat(paramVal);
                            }
                        }
                    }catch (JSONException ex){
                         String msg = ex.getMessage();
                    }
                }

                dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
                Window dialogWindow = dialog.getWindow();

                // Set dialog as modaless
                dialogWindow.addFlags(WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL);
                dialogWindow.clearFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND);

                dialogWindow.getAttributes().windowAnimations = android.R.style.Animation_Dialog;
                WindowManager.LayoutParams lp = dialogWindow.getAttributes();
                dialogWindow.setGravity(Gravity.LEFT | Gravity.TOP);

                lp.x = left; // The new position of the X coordinates
                lp.y = top; // The new position of the Y coordinates
                lp.width = width; // Width
                lp.height = height; // Height
                lp.alpha = alpha; // Transparency
                dialogWindow.setAttributes(lp);

                dialog.setCancelable(true);
                dialog.addContentView(xWalkWebView, lp);
                dialog.show();
            }
        });
    }

    public void loadUrl(final JSONArray data) throws JSONException {
        if(dialog == null) {
            openBrowser(data);
            return;
        }
        final String url = data.getString(0);
        this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                xWalkWebView.load(url, "");
                dialog.show();
            }
        });
    }

    public void hideBrowser() {

        this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if(dialog != null) {
                    dialog.hide();
                }
            }
        });
    }

    public void showBrowser() {
        this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if(dialog != null) {
                    dialog.show();
                }
            }
        });
    }

    public void closeBrowser() {
        this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if(dialog == null)
                    return;

                xWalkWebView.onDestroy();
                dialog.dismiss();
                try {
                    JSONObject obj = new JSONObject();
                    obj.put("type", "exit");
                    PluginResult result = new PluginResult(PluginResult.Status.OK, obj);
                    result.setKeepCallback(true);
                    callbackContext.sendPluginResult(result);
                } catch (JSONException ex) {}

                xWalkWebView = null;
                dialog = null;
            }
        });
    }

    // Set the left and top parameter. Data : LEFT, TOP
    public void setPosition(JSONArray data) throws JSONException {
        final int left = data.getInt(0);
        final int top = data.getInt(1);

        this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                    if(dialog == null)
                        return;

                    Window dialogWindow = dialog.getWindow();
                    WindowManager.LayoutParams lp = dialogWindow.getAttributes();
                    lp.x = left; // The new position of the X coordinates
                    lp.y = top; // The new position of the Y coordinates
                    dialogWindow.setAttributes(lp);
                    dialog.setContentView(xWalkWebView, lp);
                    dialog.show();

            }
        });
    }

    // Set the width and height parameter. Data : WIDTH, HIGHT
    public void setSize(JSONArray data)  throws JSONException {
        final int width = data.getInt(0);
        final int height = data.getInt(1);
        this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if(dialog == null)
                    return;
                Window dialogWindow = dialog.getWindow();

                WindowManager.LayoutParams lp = dialogWindow.getAttributes();
                lp.width = width; // The new position of the X coordinates
                lp.height = height; // The new position of the Y coordinates
                dialogWindow.setAttributes(lp);
                dialog.setContentView(xWalkWebView, lp);
                dialog.show();
            }
        });
    }


    // Set the width and height parameter. Data : ALPHA
    public void setAlpha(JSONArray data)   throws JSONException {
        final float alpha = (float) data.getDouble(0);
        this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if(dialog == null)
                    return;

                Window dialogWindow = dialog.getWindow();

                WindowManager.LayoutParams lp = dialogWindow.getAttributes();
                lp.alpha = alpha; // The new position of the X coordinates
                dialogWindow.setAttributes(lp);
                dialog.setContentView(xWalkWebView, lp);
                dialog.show();
            }
        });
    }


    private void injectDeferredObject(String source, String jsWrapper) {
        String scriptToInject;
        if (jsWrapper != null) {
            org.json.JSONArray jsonEsc = new org.json.JSONArray();
            jsonEsc.put(source);
            String jsonRepr = jsonEsc.toString();
            String jsonSourceString = jsonRepr.substring(1, jsonRepr.length()-1);
            scriptToInject = String.format(jsWrapper, jsonSourceString);
        } else {
            scriptToInject = source;
        }
        final String finalScriptToInject = scriptToInject;
        this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                    xWalkWebView.evaluateJavascript(finalScriptToInject, null);
            }
        });
    }
    // Get the screenshot of the browser dialog.
    // Params : JPEG Quality, and what to do callback.
    public void getScreenshot(JSONArray data, CallbackContext _callbackContext)  throws JSONException {
        float fq =  (float) data.getDouble(0);
        callbackContext = _callbackContext;
        this.cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {

                if(dialog == null)
                    return;

                Window dialogWindow = dialog.getWindow();

                Bitmap bitmap;

                bitmap = getBitmapFromView(xWalkWebView);
                String base64Image = bitMapToString(bitmap);

                // Call callback for the Javascript.
                PluginResult result = new PluginResult(PluginResult.Status.OK, base64Image);
                result.setKeepCallback(true);
                callbackContext.sendPluginResult(result);
            }
        });
    }

    // Helper method for getting bitmap.
    private Bitmap getBitmapFromView(View view) {
        //Define a bitmap with the same size as the view
        Bitmap returnedBitmap = Bitmap.createBitmap(view.getWidth(), view.getHeight(), Bitmap.Config.ARGB_8888);
        //Bind a canvas to it
        Canvas canvas = new Canvas(returnedBitmap);
        //Get the view's background
        Drawable bgDrawable = view.getBackground();
        if (bgDrawable != null)
            //has background drawable, then draw it on the canvas
            bgDrawable.draw(canvas);
        else
            //does not have background drawable, then draw white background on the canvas
            canvas.drawColor(Color.WHITE);

        // draw the view on the canvas
        view.draw(canvas);
        //return the bitmap
        return returnedBitmap;
    }

    // Helper method for storing the bitmap image for JPEG base64.
    private String bitMapToString(Bitmap bitmap) {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, 100, baos);
        byte[] b = baos.toByteArray();
        String temp = null;
        try {
            System.gc();
            temp = Base64.encodeToString(b, Base64.DEFAULT);
        } catch (Exception e) {
            e.printStackTrace();
        } catch (OutOfMemoryError e) {
            baos = new ByteArrayOutputStream();
            bitmap.compress(Bitmap.CompressFormat.JPEG, 50, baos);
            b = baos.toByteArray();
            temp = Base64.encodeToString(b, Base64.DEFAULT);
            Log.e("EWN", "Out of memory error catched");
        }
        return temp;
    }
}
