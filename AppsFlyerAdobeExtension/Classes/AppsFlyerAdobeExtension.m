//
//  AppsFlyerAdobeExtension.m
//  appsflyer-adobe-extension
//
//  Created by Benjamin Winestein on 05/08/2018.
//  Copyright © 2018 Benjamin Winestein. All rights reserved.
//

#import "AppsFlyerAdobeExtension.h"
#import "AppsFlyerAttribution.h"
#import <objc/message.h>


static AppsFlyerAdobeExtension *__sharedInstance = nil;
static void (^__completionHandler)(NSDictionary*) = nil;
static void (^__errorHandler)(NSError*) = nil;

typedef void (*bypassDidFinishLaunchingWithOption)(id, SEL, NSInteger);

@implementation AppsFlyerAdobeExtension

- (instancetype)init {
    if (self = [super init]) {
        
        static dispatch_once_t once;
        dispatch_once(&once, ^{
            __sharedInstance = self;
        });
        id waitForECIDFlag = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"AppsFlyerWaitForExperienceCloudId"];
        if(waitForECIDFlag){
            _waitForECID = YES;
        }else{
            _waitForECID = NO;
        }
        
        _didReceiveConfigurations = NO;
        _didInit = NO;
        _trackAttributionData = NO;
        _eventSettings = @"action";
        _mayStartSDK = NO;
        
        NSError* error = nil;
        
        // Listener/Dispatcher for shared state events
        if ([self.api registerListener:[AppsFlyerSharedStateListener class]
                             eventType:@"com.adobe.eventType.hub"
                           eventSource:@"com.adobe.eventSource.sharedState"
                                 error:&error]) {
            [self AFLoggr:@"Shared State listener was registered"];
        }
        else if (error) {
            NSLog(@"com.appsflyer.adobeextension Error while registering shared state listener!!\n%@ %ld", [error domain], [error code]);
        }
        
        // Listener for Analytics Event binding
        if ([self.api registerListener:[AppsFlyerEventListener class]
                             eventType:@"com.adobe.eventType.generic.track"
                           eventSource:@"com.adobe.eventSource.requestContent"
                                 error:&error]) {
            NSLog(@"com.appsflyer.adobeextension Analytics Events listener was registered");
        }
        else if (error) {
            NSLog(@"com.appsflyer.adobeextension Error while registering Analytics Events listener!!\n%@ %d", [error domain], (int)[error code]);
        }
    }
    return self;
}

- (NSString*) name {
    return @"com.appsflyer.adobeextension";
}

+ (instancetype)shared {
    if (__sharedInstance) {
        return __sharedInstance;
    }
    else {
        NSLog(@"com.appsflyer.adobeextension was not initialised");
        return nil;
    }
}


+ (void)registerExtension {
    NSError* error = nil;
    if ([ACPCore registerExtension: [AppsFlyerAdobeExtension class] error: &error]) {
        NSLog(@"com.appsflyer.adobeextension was registered");
    }
    else {
        NSLog(@"Error registering com.appsflyer.adobeextension: %@ %d", [error domain], (int)[error code]);
    }
}

+ (void)registerExtension: (BOOL) shouldWait {
    NSError* error = nil;
    if ([ACPCore registerExtension: [AppsFlyerAdobeExtension class] error: &error]) {
        NSLog(@"com.appsflyer.adobeextension was registered");
    }
    else {
        NSLog(@"Error registering com.appsflyer.adobeextension: %@ %d", [error domain], (int)[error code]);
    }
}


- (void)unregister {
    [[self api] unregisterExtension];
}

- (void)onUnregister {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    __sharedInstance = nil;
    
    [self AFLoggr:@"was unregistered"];
}

- (void)unexpectedError : (nonnull NSError*) error {
    //    [super unexpectedError];
    NSLog(@"com.appsflyer.adobeextension unexpectedError %@", error);
}



- (void)setupAppsFlyerTrackingWithAppId:(NSString*)appId appsFlyerDevKey:(NSString*)appsFlyerDevKey
                                isDebug:(BOOL)isDebug trackAttrData:(BOOL)trackAttrData
                          eventSettings:(nonnull NSString *)eventSettings {
    if (appsFlyerDevKey != nil) {
        if (![self didReceiveConfigurations]) {
            
            if ([self waitForECID]) {
                [self AFLoggr:@"waiting for ECID"];
                self->_mayStartSDK = NO;
            }else{
                [self AFLoggr:@"not waiting for ECID"];
                self->_mayStartSDK = YES;
            }
            
            
            SEL SKSel = NSSelectorFromString(@"__willResolveSKRules:");
            id AppsFlyer = [AppsFlyerLib shared];
            if ([AppsFlyer respondsToSelector:SKSel]) {
                bypassDidFinishLaunchingWithOption msgSend = (bypassDidFinishLaunchingWithOption)objc_msgSend;
                msgSend(AppsFlyer, SKSel, 2);
            }
            
            if (appId && ![appId isEqualToString: @""]){
                [AppsFlyerLib shared].appleAppID = appId;
            }
            
            [AppsFlyerLib shared].appsFlyerDevKey = appsFlyerDevKey;
            [AppsFlyerLib shared].delegate = self;
            [AppsFlyerLib shared].isDebug = isDebug;
            
            [ACPIdentity getExperienceCloudId:^(NSString * _Nullable retrievedCloudId) {
                if (retrievedCloudId) {
                    self->_ecid = retrievedCloudId;
                    [[AppsFlyerLib shared] setCustomerUserID:retrievedCloudId];
                    [self AFLoggr:[NSString stringWithFormat:@"%@ %@", @"ExperienceCloudId is" ,retrievedCloudId]];
                    
                } else {
                    [self AFLoggr:@"ExperienceCloudId is null"];
                }
                if(self->_waitForECID){
                    self->_mayStartSDK = YES;
                    [self appDidBecomeActive];
                }
            }];
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
            
            [self setTrackAttributionData:trackAttrData];
            [self setEventSettings: eventSettings];
            [self setDidReceiveConfigurations:YES];
            
            if (![self didInit]) {
                [self appDidBecomeActive];
                [AppsFlyerAttribution shared].isBridgeReady = YES;
                [[NSNotificationCenter defaultCenter] postNotificationName:AF_BRIDGE_SET object:self];
                [self setDidInit:YES];
            }
        } else {
            NSLog(@"com.appsflyer.adobeextension rejecting re-init of previously initialized tracker");
        }
    }
}

- (void) appDidBecomeActive {
    [self AFLoggr: @"appDidBecomeActive"];
    if ([self didReceiveConfigurations] && self->_mayStartSDK) {
        [self AFLoggr: @"AF Start"];
        [[NSNotificationCenter defaultCenter] postNotificationName:AF_BRIDGE_SET object:self];
        [[AppsFlyerLib shared] start];
        [self setDidInit:YES];
    }
}

+ (void)continueUserActivity:(NSUserActivity *)userActivity
          restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *restorableObjects))restorationHandler {
    [[AppsFlyerAttribution shared] continueUserActivity:userActivity restorationHandler:restorationHandler];
}

+ (void)openURL:(NSURL *)url options:(NSDictionary *)options {
    [[AppsFlyerAttribution shared] handleOpenUrl:url options:options];
}

- (void) onAppOpenAttribution:(NSDictionary *)attributionData {
    [self AFLoggr: @"onAppOpenAttribution"];
    NSDictionary* newAttributionData = [self returnParsedAttribution:attributionData];
    NSMutableDictionary* appendedAttributionData = [NSMutableDictionary dictionaryWithDictionary:attributionData];
    [appendedAttributionData setObject:@"onAppOpenAttribution" forKey:@"callback_type"];
    
    if(_ecid){
        [appendedAttributionData setObject:_ecid forKey:@"ecid"];
    }
    
    [ACPCore trackAction:@"AppsFlyer Engagement Data" data:[self setKeyPrefix:[self setKeyPrefixOnAppOpenAttribution:newAttributionData]]];
    if (__completionHandler) {
        __completionHandler(appendedAttributionData);
    }
}

- (NSString*) getEventSettings {
    return _eventSettings;
}

- (void) onAppOpenAttributionFailure:(NSError *)error {
    [self AFLoggr: @"onAppOpenAttributionFailure"];
    if (__errorHandler) {
        __errorHandler(error);
    }
}

- (void)onConversionDataSuccess:(nonnull NSDictionary *)installData {
    [self AFLoggr: @"onConversionDataSuccess"];
    NSMutableDictionary* appendedInstallData = [NSMutableDictionary dictionaryWithDictionary:installData];
    
    
    if (_trackAttributionData) {
        id isFirstData = [installData objectForKey:@"is_first_launch"];
        BOOL firstData = [isFirstData isKindOfClass:[NSNumber class]] && [isFirstData integerValue] == 1;
        if (firstData) {
            
            NSError* error = nil;
            if (![self.api setSharedEventState:[self getSaredEventState:installData] event:nil error:&error] && error) {
                NSLog(@"Error setting shared state %@:%ld", [error domain], [error code]);
            }
            
            NSString* appsflyer_id = [[AppsFlyerLib shared] getAppsFlyerUID];
            [appendedInstallData setObject:appsflyer_id forKey:@"appsflyer_id"];
            
            if(_ecid){
                [appendedInstallData setObject:_ecid forKey:@"ecid"];
            }
            
            [ACPCore trackAction:@"AppsFlyer Attribution Data" data:[self setKeyPrefix:appendedInstallData]];
        }
    }
    
    
    [appendedInstallData setObject:@"onConversionDataReceived" forKey:@"callback_type"];
    _gcd = appendedInstallData;
    if (__completionHandler) {
        __completionHandler(appendedInstallData);
    }
}

- (void)onConversionDataFail:(nonnull NSError *)error {
    [self AFLoggr: @"onConversionDataFail"];
    if (__errorHandler) {
        __errorHandler(error);
    }
}

+ (void)registerCallbacks:(void (^)(NSDictionary *dictionary))completionHandler {
    __completionHandler = completionHandler;
}

+ (void)callbacksErrorHandler:(void (^) (NSError *error))errorHandler {
    __errorHandler = errorHandler;
}

-(NSMutableDictionary *) setKeyPrefix:(NSDictionary *)attributionData {
    NSMutableDictionary* withPrefix = [[NSMutableDictionary alloc] init];
    for(id key in attributionData) {
        if (![key isEqualToString:@"callback_type"]) {
            NSString* newKey = [NSString stringWithFormat: @"%@%@", @"appsflyer.", key];
            NSString* newValue = [NSString stringWithFormat: @"%@", [attributionData objectForKey:key]];
            [withPrefix setObject:newValue  forKey:newKey];
        }
    }
    return withPrefix;
}

- (NSMutableDictionary *) setKeyPrefixOnAppOpenAttribution:(NSDictionary *)attributionData {
    NSMutableDictionary* withPrefix = [[NSMutableDictionary alloc] init];
    for(id key in attributionData) {
        if (![key isEqualToString:@"callback_type"]) {
            NSString* newKey = [NSString stringWithFormat: @"%@%@", @"af_engagement_", key];
            NSString* newValue = [NSString stringWithFormat: @"%@", [attributionData objectForKey:key]];
            [withPrefix setObject:newValue  forKey:newKey];
        }
    }
    return withPrefix;
}

- (NSMutableDictionary *) getSaredEventState:(NSDictionary *)attributionData {
    NSMutableDictionary* sharedEventState = [attributionData mutableCopy];
    NSString* appsflyer_id = [[AppsFlyerLib shared] getAppsFlyerUID];
    NSString* sdk_verision = [[AppsFlyerLib shared] getSDKVersion];
    
    [sharedEventState setObject:appsflyer_id  forKey:APPSFLYER_ID];
    [sharedEventState setObject:sdk_verision  forKey:SDK_VERSION];
    
    if(![sharedEventState objectForKey:MEDIA_SOURCE]){
        [sharedEventState setObject:@"organic"  forKey:MEDIA_SOURCE];
    }
    
    [sharedEventState removeObjectForKey:CALLBACK_TYPE];
    [sharedEventState removeObjectForKey:IS_FIRST_LAUNCH];
    
    return sharedEventState;
}


- (NSMutableDictionary<NSString *, NSString *> *)queryParametersFromURL:(NSURL *)url {
    NSURLComponents *urlComponents = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    NSMutableDictionary<NSString *, NSString *> *queryParams = [NSMutableDictionary<NSString *, NSString *> new];
    for (NSURLQueryItem *queryItem in [urlComponents queryItems]) {
        if (queryItem.value == nil) {
            continue;
        }
        [queryParams setObject:queryItem.value forKey:queryItem.name];
    }
    return queryParams;
}

- (NSDictionary*)returnParsedAttribution:(NSDictionary*)attributionData {
    if (attributionData) {
        NSUInteger keyCount = [attributionData count];
        if (keyCount == 1 && [[attributionData allKeys] containsObject:@"link"]) {
            NSString *urlString = attributionData[@"link"];
            if (urlString) {
                NSURL *url = [NSURL URLWithString:urlString];
                if (url) {
                    NSMutableDictionary *dictionary = [self queryParametersFromURL:url];
                    [dictionary setValue:urlString forKey:@"link"];
                    return dictionary;
                }
            }
        }
    }
    
    return attributionData;
}

- (NSDictionary*)getConversionData {
    return _gcd;
}


- (void) AFLoggr:(NSString*)msg{
    NSLog(@"com.appsflyer.adobeextension %@" , msg);
}

@end
