//
//  AppsFlyerAdobeExtension.h
//  appsflyer-adobe-extension
//
//  Created by Benjamin Winestein on 05/08/2018.
//  Copyright © 2018 Benjamin Winestein. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ACPCore/ACPCore.h>
#import <ACPCore/ACPExtension.h>
#import <ACPCore/ACPIdentity.h>
#import "AppsFlyerEventListener.h"
#import "AppsFlyerSharedStateListener.h"
#import <AppsFlyerLib/AppsFlyerLib.h>

#define APPSFLYER_ID     @"appsflyer_id"
#define SDK_VERSION      @"sdk_version"
#define MEDIA_SOURCE     @"media_source"
#define IS_FIRST_LAUNCH  @"is_first_launch"
#define CALLBACK_TYPE    @"callback_type"

static BOOL absd;
NS_ASSUME_NONNULL_BEGIN
@interface AppsFlyerAdobeExtension : ACPExtension <AppsFlyerLibDelegate> {}

@property (atomic) BOOL didReceiveConfigurations;
@property (atomic) BOOL didInit;
@property (atomic) BOOL trackAttributionData;
@property (atomic) NSString* eventSettings;
@property (atomic) NSString* ecid;
@property (atomic) NSDictionary* gcd;
@property(atomic) BOOL waitForECID;
@property (atomic) BOOL mayStartSDK;

+ (nullable instancetype)shared;
+ (void)registerExtension;
+ (void)registerExtension:(BOOL) shouldWait;

- (NSString*)name;
- (void)unregister;
- (void)onUnregister;
- (void)unexpectedError: (NSError*) error;

- (void)setupAppsFlyerTrackingWithAppId:(NSString*)appId appsFlyerDevKey:(NSString*)appsFlyerDevKey isDebug:(BOOL)isDebug trackAttrData:(BOOL)trackAttrData eventSettings:(NSString*)eventSettings;
+ (void)registerCallbacks:(void (^ _Nullable)(NSDictionary *dictionary))completionHandler;
+ (void)callbacksErrorHandler:(void (^ _Nullable)(NSError *error))errorHandler;
- (NSMutableDictionary*)setKeyPrefix:(NSDictionary *)attributionData;
- (NSString*) getEventSettings;

+ (void)continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *restorableObjects))restorationHandler;
+ (void)openURL:(NSURL *)url options:(NSDictionary *)options;

- (NSDictionary*)getConversionData;
- (void) AFLoggr:(NSString*)msg;
@end
NS_ASSUME_NONNULL_END

