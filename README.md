
# cordova-plugin-webview
embeded webview for cordova app

This plugin is different with inappbrowser, You can load html page or external urls in the embeded webview, and control it directly.

### Background
This plugin is originally commissioned by [ZeGenie Inc] [ze]. Please check and contact us to use this plugin.

### Install
    cordova plugin add cordova-plugin-inappbrowser

### Method
  - cordova.EbWebview.open(url, param)
```sh    
app.webview = cordova.EbWebview.open(encodeURI('http://www.bing.com'), 'left='+app.left+',top='+app.top+',width=320,height=200');
```
  - load(url)
  - show(), hide()
  - setPosition(left, top)
  - setSize(width, height)
  - addEventListener(eventName, callback)
  - removeEventListenenr(eventName, callback)
  - executScript(injection, callback)

### Sample
[Here is sample javascript file] [sample]

   [PlDb]: <https://github.com/joemccann/dillinger/tree/master/plugins/dropbox/README.md>
   [sample]: <https://github.com/covernal/cordova-plugin-webview/blob/master/sample/index.js>
   [ze]: <http://www.zegenie.com>
