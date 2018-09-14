/**
 * Created by Weex.
 * Copyright (c) 2016, Alibaba, Inc. All rights reserved.
 *
 * This source code is licensed under the Apache Licence 2.0.
 * For the full copyright and license information,please view the LICENSE file in the root directory of this source tree.
 */

#import "WXSDKEngine.h"
#import "WXModuleFactory.h"
#import "WXHandlerFactory.h"
#import "WXComponentFactory.h"
#import "WXBridgeManager.h"

#import "WXAppConfiguration.h"
#import "WXResourceRequestHandlerDefaultImpl.h"
#import "WXNavigationDefaultImpl.h"
#import "WXURLRewriteDefaultImpl.h"
#import "WXWebSocketDefaultImpl.h"

#import "WXSDKManager.h"
#import "WXSDKError.h"
#import "WXMonitor.h"
#import "WXSimulatorShortcutManager.h"
#import "WXAssert.h"
#import "WXLog.h"
#import "WXUtility.h"

@implementation WXSDKEngine

# pragma mark Module Register

// register some default modules when the engine initializes.
+ (void)_registerDefaultModules
{
    [self registerModule:@"dom" withClass:NSClassFromString(@"WXDomModule")];
    [self registerModule:@"navigator" withClass:NSClassFromString(@"WXNavigatorModule")];
    [self registerModule:@"stream" withClass:NSClassFromString(@"WXStreamModule")];
    [self registerModule:@"animation" withClass:NSClassFromString(@"WXAnimationModule")];
    [self registerModule:@"modal" withClass:NSClassFromString(@"WXModalUIModule")];
    [self registerModule:@"webview" withClass:NSClassFromString(@"WXWebViewModule")];
    [self registerModule:@"instanceWrap" withClass:NSClassFromString(@"WXInstanceWrap")];
    [self registerModule:@"timer" withClass:NSClassFromString(@"WXTimerModule")];
    [self registerModule:@"storage" withClass:NSClassFromString(@"WXStorageModule")];
    [self registerModule:@"clipboard" withClass:NSClassFromString(@"WXClipboardModule")];
    [self registerModule:@"globalEvent" withClass:NSClassFromString(@"WXGlobalEventModule")];
    [self registerModule:@"canvas" withClass:NSClassFromString(@"WXCanvasModule")];
    [self registerModule:@"picker" withClass:NSClassFromString(@"WXPickerModule")];
    [self registerModule:@"meta" withClass:NSClassFromString(@"WXMetaModule")];
    [self registerModule:@"webSocket" withClass:NSClassFromString(@"WXWebSocketModule")];
}

+ (void)registerModule:(NSString *)name withClass:(Class)clazz
{
    WXAssert(name && clazz, @"Fail to register the module, please check if the parameters are correct ！");
    
    // 注册模块
    NSString *moduleName = [WXModuleFactory registerModule:name withClass:clazz];
    // 遍历所有同步和异步方法
    NSDictionary *dict = [WXModuleFactory moduleMethodMapsWithName:moduleName];
    
    NSLog(@"组件 = %@ -- %@",moduleName,dict);
    // 把模块注册到WXBridgeManager中
    [[WXSDKManager bridgeMgr] registerModules:dict];
}

# pragma mark Component Register

// register some default components when the engine initializes.
+ (void)_registerDefaultComponents
{
    // 为了调试，故意写在前面来的
    [self registerComponent:@"web" withClass:NSClassFromString(@"WXWebComponent")];
    
    [self registerComponent:@"container" withClass:NSClassFromString(@"WXDivComponent") withProperties:nil];
    [self registerComponent:@"div" withClass:NSClassFromString(@"WXComponent") withProperties:nil];
    [self registerComponent:@"text" withClass:NSClassFromString(@"WXTextComponent") withProperties:nil];
    [self registerComponent:@"image" withClass:NSClassFromString(@"WXImageComponent") withProperties:nil];
    [self registerComponent:@"scroller" withClass:NSClassFromString(@"WXScrollerComponent") withProperties:nil];
    [self registerComponent:@"list" withClass:NSClassFromString(@"WXListComponent") withProperties:nil];
    
    [self registerComponent:@"header" withClass:NSClassFromString(@"WXHeaderComponent")];
    [self registerComponent:@"cell" withClass:NSClassFromString(@"WXCellComponent")];
    [self registerComponent:@"embed" withClass:NSClassFromString(@"WXEmbedComponent")];
    [self registerComponent:@"a" withClass:NSClassFromString(@"WXAComponent")];
    
    [self registerComponent:@"select" withClass:NSClassFromString(@"WXSelectComponent")];
    [self registerComponent:@"switch" withClass:NSClassFromString(@"WXSwitchComponent")];
    [self registerComponent:@"input" withClass:NSClassFromString(@"WXTextInputComponent")];
    [self registerComponent:@"video" withClass:NSClassFromString(@"WXVideoComponent")];
    [self registerComponent:@"indicator" withClass:NSClassFromString(@"WXIndicatorComponent")];
    [self registerComponent:@"slider" withClass:NSClassFromString(@"WXSliderComponent")];
    [self registerComponent:@"web" withClass:NSClassFromString(@"WXWebComponent")];
    [self registerComponent:@"loading" withClass:NSClassFromString(@"WXLoadingComponent")];
    [self registerComponent:@"loading-indicator" withClass:NSClassFromString(@"WXLoadingIndicator")];
    [self registerComponent:@"refresh" withClass:NSClassFromString(@"WXRefreshComponent")];
    [self registerComponent:@"textarea" withClass:NSClassFromString(@"WXTextAreaComponent")];
	[self registerComponent:@"canvas" withClass:NSClassFromString(@"WXCanvasComponent")];
    [self registerComponent:@"slider-neighbor" withClass:NSClassFromString(@"WXSliderNeighborComponent")];
}

+ (void)registerComponent:(NSString *)name withClass:(Class)clazz
{
    //NSLog(@"%@-----%@",name,clazz);
    [self registerComponent:name withClass:clazz withProperties: @{@"append":@"tree"}];
}

+ (void)registerComponent:(NSString *)name withClass:(Class)clazz withProperties:(NSDictionary *)properties
{
    if (!name || !clazz) {
        return;
    }

    WXAssert(name && clazz, @"Fail to register the component, please check if the parameters are correct ！");
    
    // 注册组件的方法
    [WXComponentFactory registerComponent:name withClass:clazz withPros:properties];
    // 遍历出所有异步的方法
    NSMutableDictionary *dict = [WXComponentFactory componentMethodMapsWithName:name];
    dict[@"type"] = name;
    
    // 把组件注册到WXBridgeManager中
    if (properties) {
        NSMutableDictionary *props = [properties mutableCopy];
        if ([dict[@"methods"] count]) {
            [props addEntriesFromDictionary:dict];
        }
        
        NSLog(@"props = %@ , name = %@ , clazz = %@",props,name,clazz);
        [[WXSDKManager bridgeMgr] registerComponents:@[props]];
    } else {
        
        NSLog(@"dict = %@ , name = %@ , clazz = %@",dict,name,clazz);
        [[WXSDKManager bridgeMgr] registerComponents:@[dict]];
    }
}


# pragma mark Service Register
+ (void)registerService:(NSString *)name withScript:(NSString *)serviceScript withOptions:(NSDictionary *)options
{
    [[WXSDKManager bridgeMgr] registerService:name withService:serviceScript withOptions:options];
}

+ (void)registerService:(NSString *)name withScriptUrl:(NSURL *)serviceScriptUrl WithOptions:(NSDictionary *)options
{
    [[WXSDKManager bridgeMgr] registerService:name withServiceUrl:serviceScriptUrl withOptions:options];
}

+ (void)unregisterService:(NSString *)name
{
    [[WXSDKManager bridgeMgr] unregisterService:name];
}

# pragma mark Handler Register

// register some default handlers when the engine initializes.
+ (void)_registerDefaultHandlers
{
    [self registerHandler:[WXResourceRequestHandlerDefaultImpl new] withProtocol:@protocol(WXResourceRequestHandler)];
    [self registerHandler:[WXNavigationDefaultImpl new] withProtocol:@protocol(WXNavigationProtocol)];
    [self registerHandler:[WXURLRewriteDefaultImpl new] withProtocol:@protocol(WXURLRewriteProtocol)];
    [self registerHandler:[WXWebSocketDefaultImpl new] withProtocol:@protocol(WXWebSocketHandler)];

}

+ (void)registerHandler:(id)handler withProtocol:(Protocol *)protocol
{
    WXAssert(handler && protocol, @"Fail to register the handler, please check if the parameters are correct ！");
    
    [WXHandlerFactory registerHandler:handler withProtocol:protocol];
}

+ (id)handlerForProtocol:(Protocol *)protocol
{
    WXAssert(protocol, @"Fail to get the handler, please check if the parameters are correct ！");
    
    return  [WXHandlerFactory handlerForProtocol:protocol];
}

# pragma mark SDK Initialize

+ (void)initSDKEnvironment
{
    // 打点记录状态
    WX_MONITOR_PERF_START(WXPTInitalize)
    WX_MONITOR_PERF_START(WXPTInitalizeSync)
    
    // 加载本地的main.js
    NSString *filePath = [[NSBundle bundleForClass:self] pathForResource:@"main" ofType:@"js"];
    NSString *script = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    // 初始化SDK环境
    [WXSDKEngine initSDKEnvironment:script];
    
    // 打点记录状态
    WX_MONITOR_PERF_END(WXPTInitalizeSync)
    
    // 模拟器版本特殊代码
#if TARGET_OS_SIMULATOR
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [WXSimulatorShortcutManager registerSimulatorShortcutWithKey:@"i" modifierFlags:UIKeyModifierCommand | UIKeyModifierAlternate action:^{
            NSURL *URL = [NSURL URLWithString:@"http://localhost:8687/launchDebugger"];
            NSURLRequest *request = [NSURLRequest requestWithURL:URL];
            
            NSURLSession *session = [NSURLSession sharedSession];
            NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                                    completionHandler:
                                          ^(NSData *data, NSURLResponse *response, NSError *error) {
                                              // ...
                                          }];
            
            [task resume];
            WXLogInfo(@"Launching browser...");
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self connectDebugServer:@"ws://localhost:8687/debugger/0/renderer"];
            });
            
        }];
    });
#endif
}

+ (void)initSDKEnvironment:(NSString *)script
{
    if (!script || script.length <= 0) {
        WX_MONITOR_FAIL(WXMTJSFramework, WX_ERR_JSFRAMEWORK_LOAD, @"framework loading is failure!");
        return;
    }
    
    // 注册Components，Modules，Handlers
    [self registerDefaults];
    
    // 执行JsFramework
    [[WXSDKManager bridgeMgr] executeJsFramework:script];
}

+ (void)registerDefaults
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self _registerDefaultComponents];
        [self _registerDefaultModules];
        [self _registerDefaultHandlers];
    });
}

+ (NSString*)SDKEngineVersion
{
    return WX_SDK_VERSION;
}

+ (WXSDKInstance *)topInstance
{
    return [WXSDKManager bridgeMgr].topInstance;
}


static NSDictionary *_customEnvironment;
+ (void)setCustomEnvironment:(NSDictionary *)environment
{
    _customEnvironment = environment;
}

+ (NSDictionary *)customEnvironment
{
    return _customEnvironment;
}

# pragma mark Debug

+ (void)unload
{
    [WXSDKManager unload];
    [WXComponentFactory unregisterAllComponents];
}

+ (void)restart
{
    NSDictionary *components = [WXComponentFactory componentConfigs];
    NSDictionary *modules = [WXModuleFactory moduleConfigs];
    NSDictionary *handlers = [WXHandlerFactory handlerConfigs];
    [WXSDKManager unload];
    [WXComponentFactory unregisterAllComponents];
    NSString *filePath = [[NSBundle bundleForClass:self] pathForResource:@"main" ofType:@"js"];
    NSString *script = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    [self _originalRegisterComponents:components];
    [self _originalRegisterModules:modules];
    [self _originalRegisterHandlers:handlers];
    
    [[WXSDKManager bridgeMgr] executeJsFramework:script];
}

+ (void)connectDebugServer:(NSString*)URL
{
    [[WXSDKManager bridgeMgr] connectToWebSocket:[NSURL URLWithString:URL]];
}

+ (void)connectDevToolServer:(NSString *)URL
{
    [[WXSDKManager bridgeMgr] connectToDevToolWithUrl:[NSURL URLWithString:URL]];
}

+ (void)_originalRegisterComponents:(NSDictionary *)components {
    void (^componentBlock)(id, id, BOOL *) = ^(id mKey, id mObj, BOOL * mStop) {
        
        NSString *name = mObj[@"name"];
        NSString *componentClass = mObj[@"clazz"];
        NSDictionary *pros = nil;
        if (mObj[@"pros"]) {
            pros = mObj[@""];
        }
        [self registerComponent:name withClass:NSClassFromString(componentClass) withProperties:pros];
    };
    [components enumerateKeysAndObjectsUsingBlock:componentBlock];
    
}

+ (void)_originalRegisterModules:(NSDictionary *)modules {
    void (^moduleBlock)(id, id, BOOL *) = ^(id mKey, id mObj, BOOL * mStop) {
        
        [self registerModule:mKey withClass:NSClassFromString(mObj)];
    };
    [modules enumerateKeysAndObjectsUsingBlock:moduleBlock];
}

+ (void)_originalRegisterHandlers:(NSDictionary *)handlers {
    void (^handlerBlock)(id, id, BOOL *) = ^(id mKey, id mObj, BOOL * mStop) {
        [self registerHandler:mObj withProtocol:NSProtocolFromString(mKey)];
    };
    [handlers enumerateKeysAndObjectsUsingBlock:handlerBlock];
}

@end

@implementation WXSDKEngine (Deprecated)

+ (void)initSDKEnviroment
{
    [self initSDKEnvironment];
}

+ (void)initSDKEnviroment:(NSString *)script
{
    [self initSDKEnvironment:script];
}

@end
