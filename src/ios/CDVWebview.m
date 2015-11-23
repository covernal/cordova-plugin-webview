/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "CDVWebview.h"
#import <Cordova/CDVPluginResult.h>
#import <Cordova/CDVUserAgentUtil.h>

#define    kInAppBrowserTargetSelf @"_self"
#define    kInAppBrowserTargetSystem @"_system"
#define    kInAppBrowserTargetBlank @"_blank"

#define    kInAppBrowserToolbarBarPositionBottom @"bottom"
#define    kInAppBrowserToolbarBarPositionTop @"top"

#define    TOOLBAR_HEIGHT 44.0
#define    LOCATIONBAR_HEIGHT 21.0
#define    FOOTER_HEIGHT ((TOOLBAR_HEIGHT) + (LOCATIONBAR_HEIGHT))

#pragma mark CDVInAppBrowser

@interface CDVEmbeddedWebView () {
    NSInteger _previousStatusBarStyle;
}
@end

@implementation CDVEmbeddedWebView

- (void)pluginInitialize
{
    _previousStatusBarStyle = -1;
    _callbackIdPattern = nil;
}

- (void)open:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult;
    
    NSString* url = [command argumentAtIndex:0];
    NSString* options = [command argumentAtIndex:1 withDefault:@"" andClass:[NSString class]];
    
    if (url != nil) {
#ifdef __CORDOVA_4_0_0
        NSURL* baseUrl = [self.webViewEngine URL];
#else
        NSURL* baseUrl = [self.webView.request URL];
#endif
        NSURL* absoluteUrl = [[NSURL URLWithString:url relativeToURL:baseUrl] absoluteURL];
        
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        
        [self openInWebPlug:absoluteUrl withOptions:options];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"incorrect number of arguments"];
    }
    
    [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];
    self.callbackId = command.callbackId;
}

- (void)load:(CDVInvokedUrlCommand*)command
{
    if (self.webplug == nil) {
        NSLog(@"Tried to show IAB after it was closed.");
        return;
    }

    NSString* url = [command argumentAtIndex:0];
    
    if (url != nil) {
#ifdef __CORDOVA_4_0_0
        NSURL* baseUrl = [self.webViewEngine URL];
#else
        NSURL* baseUrl = [self.webView.request URL];
#endif
        NSURL* absoluteUrl = [[NSURL URLWithString:url relativeToURL:baseUrl] absoluteURL];
        
        [self.webplug navigateTo:absoluteUrl];
    }
    // else {
    //     pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"incorrect number of arguments"];
    // }
}

- (void)close:(CDVInvokedUrlCommand*)command
{
    if (self.webplug == nil) {
        NSLog(@"Tried to show IAB after it was closed.");
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.webplug removeFromSuperview];
        self.webplug = nil;
    });
}

- (void)show:(CDVInvokedUrlCommand*)command
{
    if (self.webplug == nil) {
        NSLog(@"Tried to show IAB after it was closed.");
        return;
    }
    self.webplug.hidden = NO;
}

- (void)hide:(CDVInvokedUrlCommand*)command
{
    if (self.webplug == nil) {
        NSLog(@"Tried to show IAB after it was closed.");
        return;
    }
    self.webplug.hidden = YES;
}

- (void)setPosition:(CDVInvokedUrlCommand*)command
{
    if (self.webplug == nil) {
        NSLog(@"Tried to show IAB after it was closed.");
        return;
    }
    if (command.arguments.count < 2) {
        NSLog(@"Parameters is not enough.");
        return;
    }
    
    NSString* sl = [command argumentAtIndex:0];
    NSString* st = [command argumentAtIndex:1];
    
    float fl = [sl floatValue];
    float ft = [st floatValue];
    
    CGRect frame = self.webplug.frame;
    frame.origin.x = fl;
    frame.origin.y = ft;
    self.webplug.frame = frame;
}

- (void)setSize:(CDVInvokedUrlCommand*)command
{
    if (self.webplug == nil) {
        NSLog(@"Tried to show IAB after it was closed.");
        return;
    }
    if (command.arguments.count < 2) {
        NSLog(@"Parameters is not enough.");
        return;
    }
    
    NSString* sw = [command argumentAtIndex:0];
    NSString* sh = [command argumentAtIndex:1];
    
    float fw = [sw floatValue];
    float fh = [sh floatValue];
    
    CGRect frame = self.webplug.frame;
    frame.size.width = fw;
    frame.size.height = fh;
    self.webplug.frame = frame;
}

- (void)openInWebPlug:(NSURL*)url withOptions:(NSString*)options
{
    CDVWebviewOptions* browserOptions = [CDVWebviewOptions parseOptions:options];
    
    if (browserOptions.clearcache) {
        NSHTTPCookie *cookie;
        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (cookie in [storage cookies])
        {
            if (![cookie.domain isEqual: @".^filecookies^"]) {
                [storage deleteCookie:cookie];
            }
        }
    }
    
    if (browserOptions.clearsessioncache) {
        NSHTTPCookie *cookie;
        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (cookie in [storage cookies])
        {
            if (![cookie.domain isEqual: @".^filecookies^"] && cookie.isSessionOnly) {
                [storage deleteCookie:cookie];
            }
        }
    }
    
    if (self.webplug == nil) {
        NSString* originalUA = [CDVUserAgentUtil originalUserAgent];
        
        self.webplug = [[CDVEmbeddedWebViewPlug alloc] initWithUserAgent:originalUA prevUserAgent:[self.commandDelegate userAgent] browserOptions:browserOptions];
        self.webplug.navigationDelegate = self;
    }
    
    
    // prevent webView from bouncing
    if (browserOptions.disallowoverscroll) {
        if ([self.webplug respondsToSelector:@selector(scrollView)]) {
            ((UIScrollView*)[self.webplug scrollView]).bounces = NO;
        } else {
            for (id subview in self.webplug.subviews) {
                if ([[subview class] isSubclassOfClass:[UIScrollView class]]) {
                    ((UIScrollView*)subview).bounces = NO;
                }
            }
        }
    }
    
    
    // UIWebView options
    self.webplug.scalesPageToFit = browserOptions.enableviewportscale;
    self.webplug.mediaPlaybackRequiresUserAction = browserOptions.mediaplaybackrequiresuseraction;
    self.webplug.allowsInlineMediaPlayback = browserOptions.allowinlinemediaplayback;
    if (IsAtLeastiOSVersion(@"6.0")) {
        self.webplug.keyboardDisplayRequiresUserAction = browserOptions.keyboarddisplayrequiresuseraction;
        self.webplug.suppressesIncrementalRendering = browserOptions.suppressesincrementalrendering;
    }
    
    self.webplug.frame = CGRectMake(
                                    browserOptions.left.floatValue,
                                    browserOptions.top.floatValue,
                                    browserOptions.width.floatValue,
                                    browserOptions.height.floatValue
                                    );
    
    [self.webplug navigateTo:url];
    // if (!browserOptions.hidden) {
    //     self.webplug.hidden = YES;
    // }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.webplug removeFromSuperview];
        self.webplug.hidden = NO;
        [self.webView.superview addSubview:self.webplug];
        [self.webView.superview bringSubviewToFront:self.webplug];
    });
}

// Image from uiwebview
- (UIImage *) imageFromWebView:(UIWebView *)view
{
    // tempframe to reset view size after image was created
    CGRect tmpFrame         = view.frame;

    // set new Frame
    CGRect aFrame               = view.frame;
    aFrame.size.height  = [view sizeThatFits:[[UIScreen mainScreen] bounds].size].height;
    view.frame              = aFrame;

    // do image magic
    UIGraphicsBeginImageContext([view sizeThatFits:[[UIScreen mainScreen] bounds].size]);

    CGContextRef resizedContext = UIGraphicsGetCurrentContext();
    [view.layer renderInContext:resizedContext];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    // reset Frame of view to origin
    view.frame = tmpFrame;
    return image;
}

- (void)getScreenshot:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult;

    NSString *encodedString = @"";

    if (self.webplug == nil) {
    }
    else {
        float fq = 1;
        if (command.arguments.count < 2) {
            NSString* sq = [command argumentAtIndex:0];
            fq = [sq floatValue];
        }

        UIImage* image = [self imageFromWebView:self.webplug];
        NSData *imageData = UIImageJPEGRepresentation(image, fq);
        encodedString = [imageData base64Encoding];
    }

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK  messageAsString:encodedString];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

// This is a helper method for the inject{Script|Style}{Code|File} API calls, which
// provides a consistent method for injecting JavaScript code into the document.
//
// If a wrapper string is supplied, then the source string will be JSON-encoded (adding
// quotes) and wrapped using string formatting. (The wrapper string should have a single
// '%@' marker).
//
// If no wrapper is supplied, then the source string is executed directly.

- (void)injectDeferredObject:(NSString*)source withWrapper:(NSString*)jsWrapper
{
    if (!_injectedIframeBridge) {
        _injectedIframeBridge = YES;
        // Create an iframe bridge in the new document to communicate with the CDVInAppBrowserViewController
        [self.webplug stringByEvaluatingJavaScriptFromString:@"(function(d){var e = _cdvIframeBridge = d.createElement('iframe');e.style.display='none';d.body.appendChild(e);})(document)"];
    }
    
    if (jsWrapper != nil) {
        NSData* jsonData = [NSJSONSerialization dataWithJSONObject:@[source] options:0 error:nil];
        NSString* sourceArrayString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        if (sourceArrayString) {
            NSString* sourceString = [sourceArrayString substringWithRange:NSMakeRange(1, [sourceArrayString length] - 2)];
            NSString* jsToInject = [NSString stringWithFormat:jsWrapper, sourceString];
            [self.webplug stringByEvaluatingJavaScriptFromString:jsToInject];
        }
    } else {
        [self.webplug stringByEvaluatingJavaScriptFromString:source];
    }
}

- (void)injectScriptCode:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper = nil;
    
    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"_cdvIframeBridge.src='gap-iab://%@/'+encodeURIComponent(JSON.stringify([eval(%%@)]));", command.callbackId];
    }
    [self injectDeferredObject:[command argumentAtIndex:0] withWrapper:jsWrapper];
}

- (void)injectScriptFile:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper;
    
    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"(function(d) { var c = d.createElement('script'); c.src = %%@; c.onload = function() { _cdvIframeBridge.src='gap-iab://%@'; }; d.body.appendChild(c); })(document)", command.callbackId];
    } else {
        jsWrapper = @"(function(d) { var c = d.createElement('script'); c.src = %@; d.body.appendChild(c); })(document)";
    }
    [self injectDeferredObject:[command argumentAtIndex:0] withWrapper:jsWrapper];
}

- (void)injectStyleCode:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper;
    
    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"(function(d) { var c = d.createElement('style'); c.innerHTML = %%@; c.onload = function() { _cdvIframeBridge.src='gap-iab://%@'; }; d.body.appendChild(c); })(document)", command.callbackId];
    } else {
        jsWrapper = @"(function(d) { var c = d.createElement('style'); c.innerHTML = %@; d.body.appendChild(c); })(document)";
    }
    [self injectDeferredObject:[command argumentAtIndex:0] withWrapper:jsWrapper];
}

- (void)injectStyleFile:(CDVInvokedUrlCommand*)command
{
    NSString* jsWrapper;
    
    if ((command.callbackId != nil) && ![command.callbackId isEqualToString:@"INVALID"]) {
        jsWrapper = [NSString stringWithFormat:@"(function(d) { var c = d.createElement('link'); c.rel='stylesheet'; c.type='text/css'; c.href = %%@; c.onload = function() { _cdvIframeBridge.src='gap-iab://%@'; }; d.body.appendChild(c); })(document)", command.callbackId];
    } else {
        jsWrapper = @"(function(d) { var c = d.createElement('link'); c.rel='stylesheet', c.type='text/css'; c.href = %@; d.body.appendChild(c); })(document)";
    }
    [self injectDeferredObject:[command argumentAtIndex:0] withWrapper:jsWrapper];
}

- (BOOL)isValidCallbackId:(NSString *)callbackId
{
    NSError *err = nil;
    // Initialize on first use
    if (self.callbackIdPattern == nil) {
        self.callbackIdPattern = [NSRegularExpression regularExpressionWithPattern:@"^InAppBrowser[0-9]{1,10}$" options:0 error:&err];
        if (err != nil) {
            // Couldn't initialize Regex; No is safer than Yes.
            return NO;
        }
    }
    if ([self.callbackIdPattern firstMatchInString:callbackId options:0 range:NSMakeRange(0, [callbackId length])]) {
        return YES;
    }
    return NO;
}

/**
 * The iframe bridge provided for the InAppBrowser is capable of executing any oustanding callback belonging
 * to the InAppBrowser plugin. Care has been taken that other callbacks cannot be triggered, and that no
 * other code execution is possible.
 *
 * To trigger the bridge, the iframe (or any other resource) should attempt to load a url of the form:
 *
 * gap-iab://<callbackId>/<arguments>
 *
 * where <callbackId> is the string id of the callback to trigger (something like "InAppBrowser0123456789")
 *
 * If present, the path component of the special gap-iab:// url is expected to be a URL-escaped JSON-encoded
 * value to pass to the callback. [NSURL path] should take care of the URL-unescaping, and a JSON_EXCEPTION
 * is returned if the JSON is invalid.
 */
- (BOOL)webView:(UIWebView*)theWebView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL* url = request.URL;
    BOOL isTopLevelNavigation = [request.URL isEqual:[request mainDocumentURL]];

    // See if the url uses the 'gap-iab' protocol. If so, the host should be the id of a callback to execute,
    // and the path, if present, should be a JSON-encoded value to pass to the callback.
    if ([[url scheme] isEqualToString:@"gap-iab"]) {
        NSString* scriptCallbackId = [url host];
        CDVPluginResult* pluginResult = nil;

        if ([self isValidCallbackId:scriptCallbackId]) {
            NSString* scriptResult = [url path];
            NSError* __autoreleasing error = nil;

            // The message should be a JSON-encoded array of the result of the script which executed.
            if ((scriptResult != nil) && ([scriptResult length] > 1)) {
                scriptResult = [scriptResult substringFromIndex:1];
                NSData* decodedResult = [NSJSONSerialization JSONObjectWithData:[scriptResult dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
                if ((error == nil) && [decodedResult isKindOfClass:[NSArray class]]) {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:(NSArray*)decodedResult];
                } else {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_JSON_EXCEPTION];
                }
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:@[]];
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:scriptCallbackId];
            return NO;
        }
    } else if ((self.callbackId != nil) && isTopLevelNavigation) {
        // Send a loadstart event for each top-level navigation (includes redirects).
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:@{@"type":@"loadstart", @"url":[url absoluteString]}];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];

        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }

    return YES;
}

- (void)webViewDidStartLoad:(UIWebView*)theWebView
{
    _injectedIframeBridge = NO;
}

- (void)webViewDidFinishLoad:(UIWebView*)theWebView
{
    if (self.callbackId != nil) {
        // TODO: It would be more useful to return the URL the page is actually on (e.g. if it's been redirected).
        NSString* url = [self.webplug.currentURL absoluteString];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:@{@"type":@"loadstop", @"url":url}];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];

        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }
}

- (void)webView:(UIWebView*)theWebView didFailLoadWithError:(NSError*)error
{
    if (self.callbackId != nil) {
        NSString* url = [self.webplug.currentURL absoluteString];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                      messageAsDictionary:@{@"type":@"loaderror", @"url":url, @"code": [NSNumber numberWithInteger:error.code], @"message": error.localizedDescription}];
        [pluginResult setKeepCallback:[NSNumber numberWithBool:YES]];

        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];
    }
}

@end


@implementation CDVWebviewOptions

- (id)init
{
    if (self = [super init]) {
        // default values
        self.location = YES;
        self.toolbar = YES;
        self.closebuttoncaption = nil;
        self.toolbarposition = kInAppBrowserToolbarBarPositionBottom;
        self.clearcache = NO;
        self.clearsessioncache = NO;

        self.enableviewportscale = NO;
        self.mediaplaybackrequiresuseraction = NO;
        self.allowinlinemediaplayback = NO;
        self.keyboarddisplayrequiresuseraction = YES;
        self.suppressesincrementalrendering = NO;
        self.hidden = NO;
        self.disallowoverscroll = NO;
    }

    return self;
}

+ (CDVWebviewOptions*)parseOptions:(NSString*)options
{
    CDVWebviewOptions* obj = [[CDVWebviewOptions alloc] init];

    // NOTE: this parsing does not handle quotes within values
    NSArray* pairs = [options componentsSeparatedByString:@","];

    // parse keys and values, set the properties
    for (NSString* pair in pairs) {
        NSArray* keyvalue = [pair componentsSeparatedByString:@"="];

        if ([keyvalue count] == 2) {
            NSString* key = [[keyvalue objectAtIndex:0] lowercaseString];
            NSString* value = [keyvalue objectAtIndex:1];
            NSString* value_lc = [value lowercaseString];

            BOOL isBoolean = [value_lc isEqualToString:@"yes"] || [value_lc isEqualToString:@"no"];
            NSNumberFormatter* numberFormatter = [[NSNumberFormatter alloc] init];
            [numberFormatter setAllowsFloats:YES];
            BOOL isNumber = [numberFormatter numberFromString:value_lc] != nil;

            // set the property according to the key name
            if ([obj respondsToSelector:NSSelectorFromString(key)]) {
                if (isNumber) {
                    [obj setValue:[numberFormatter numberFromString:value_lc] forKey:key];
                } else if (isBoolean) {
                    [obj setValue:[NSNumber numberWithBool:[value_lc isEqualToString:@"yes"]] forKey:key];
                } else {
                    [obj setValue:value forKey:key];
                }
            }
        }
    }

    return obj;
}

@end


@implementation CDVEmbeddedWebViewPlug

@synthesize currentURL;

- (id)initWithUserAgent:(NSString*)userAgent prevUserAgent:(NSString*)prevUserAgent browserOptions: (CDVWebviewOptions*) browserOptions
{
    self = [super init];
    if (self != nil) {
        _userAgent = userAgent;
        _prevUserAgent = prevUserAgent;
        _browserOptions = browserOptions;
#ifdef __CORDOVA_4_0_0
        _webViewDelegate = [[CDVUIWebViewDelegate alloc] initWithDelegate:self];
#else
        _webViewDelegate = [[CDVWebViewDelegate alloc] initWithDelegate:self];
#endif
        
        self.delegate = _webViewDelegate;
        self.backgroundColor = [UIColor whiteColor];
        
        self.clearsContextBeforeDrawing = YES;
        self.clipsToBounds = YES;
        self.contentMode = UIViewContentModeScaleToFill;
        self.multipleTouchEnabled = YES;
        self.opaque = YES;
        self.scalesPageToFit = NO;
        self.userInteractionEnabled = YES;
    }
    
    return self;
}

- (void)navigateTo:(NSURL*)url
{
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
    //if (_userAgentLockToken != 0)
    //{
        [self loadRequest:request];
    //}
    // else
    // {
    //     [CDVUserAgentUtil acquireLock:^(NSInteger lockToken) {
    //         _userAgentLockToken = lockToken;
    //         [CDVUserAgentUtil setUserAgent:_userAgent lockToken:lockToken];
    //         [self loadRequest:request];
    //     }];
    // }
}

- (void)webViewDidStartLoad:(UIWebView*)theWebView
{
    // loading url, start spinner, update back/forward

    
    return [self.navigationDelegate webViewDidStartLoad:theWebView];
}

- (BOOL)webView:(UIWebView*)theWebView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType
{
    BOOL isTopLevelNavigation = [request.URL isEqual:[request mainDocumentURL]];
    
    if (isTopLevelNavigation) {
        self.currentURL = request.URL;
    }
    return [self.navigationDelegate webView:theWebView shouldStartLoadWithRequest:request navigationType:navigationType];
}

- (void)webViewDidFinishLoad:(UIWebView*)theWebView
{
    // update url, stop spinner, update back/forward

    
    // Work around a bug where the first time a PDF is opened, all UIWebViews
    // reload their User-Agent from NSUserDefaults.
    // This work-around makes the following assumptions:
    // 1. The app has only a single Cordova Webview. If not, then the app should
    //    take it upon themselves to load a PDF in the background as a part of
    //    their start-up flow.
    // 2. That the PDF does not require any additional network requests. We change
    //    the user-agent here back to that of the CDVViewController, so requests
    //    from it must pass through its white-list. This *does* break PDFs that
    //    contain links to other remote PDF/websites.
    // More info at https://issues.apache.org/jira/browse/CB-2225
    BOOL isPDF = [@"true" isEqualToString :[theWebView stringByEvaluatingJavaScriptFromString:@"document.body==null"]];
    if (isPDF) {
        [CDVUserAgentUtil setUserAgent:_prevUserAgent lockToken:_userAgentLockToken];
    }
    
    [self.navigationDelegate webViewDidFinishLoad:theWebView];
}

- (void)webView:(UIWebView*)theWebView didFailLoadWithError:(NSError*)error
{
    // log fail message, stop spinner, update back/forward
    NSLog(@"webView:didFailLoadWithError - %ld: %@", (long)error.code, [error localizedDescription]);
    
    [self.navigationDelegate webView:theWebView didFailLoadWithError:error];
}

@end
