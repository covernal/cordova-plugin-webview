/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
var app = {
    // Application Constructor
    initialize: function() {
        this.bindEvents();
    },
    // Bind Event Listeners
    //
    // Bind any events that are required on startup. Common events are:
    // 'load', 'deviceready', 'offline', and 'online'.
    bindEvents: function() {
        document.addEventListener('deviceready', this.onDeviceReady, false);
    },
    // deviceready Event Handler
    //
    // The scope of 'this' is the event. In order to call the 'receivedEvent'
    // function, we must explicitly call 'app.receivedEvent(...);'
    onDeviceReady: function() {
        app.receivedEvent('deviceready');
        document.getElementById("bttOpen").addEventListener("click", app.openInAppBrowser);
        document.getElementById("bttScreen").addEventListener("click", app.getScreen);        
        document.getElementById("bttLoad").addEventListener("click", app.loadURL);        
        document.getElementById("bttMove").addEventListener("click", app.moveInAppBrowser);        
        document.getElementById("bttClose").addEventListener("click", app.closeInAppBrowser);
        document.getElementById("bttShow").addEventListener("click", app.showWebview);
        document.getElementById("bttHide").addEventListener("click", app.hideWebview);
    },
    // Update DOM on a Received Event
    receivedEvent: function(id) {
        console.log('Received Event: ' + id);
    },
    left : 0,
    top: 150,
    webview: null,
    openInAppBrowser: function() {
        app.left = 0;
        app.top = 150;
        app.webview = cordova.EbWebview.open(encodeURI('http://www.bing.com'), 'left='+app.left+',top='+app.top+',width=320,height=200');
        app.webview.setPosition(0, 150);
        app.webview.setSize(320, 200);

        app.webview.addEventListener("loadstart", function(evt) {
            console.log("app.webview event - loadstart " + evt.url);
        });
        app.webview.addEventListener("loadstop", function(evt) {
            console.log("app.webview event - loadstop " + evt.url);
        });
        app.webview.addEventListener("loaderror", function(evt) {
            console.log("app.webview event - loaderror " + evt.message);
        });
    },
    getScreen: function() {
        if (app.webview == null) return;
        app.webview.getScreenshot(0.85, function (base64) {
            console.log(base64);
            alert(base64);
        });
    },
    loadURL: function() {
        if (app.webview == null) return;
        app.webview.load(encodeURI('http://www.google.com'));
    },
    moveInAppBrowser: function() {
        if (app.webview == null) return;
        app.left += 20;
        app.top += 20;
        app.webview.setPosition(app.left, app.top);
        app.webview.setSize(320, 200 + app.left * 4);
    },
    closeInAppBrowser: function() {
        if (app.webview != null)
            app.webview.close();
        app.webview = null;
    },
    showWebview: function() {
        if (app.webview != null)
            app.webview.show();
    },
    hideWebview: function() {
        if (app.webview != null)
            app.webview.hide();
    }
};

app.initialize();
