//
//  AppsFlyerAdobeShStListener.m
//  appsflyer-adobe-extension
//
//  Created by Benjamin Winestein on 05/08/2018.
//  Copyright © 2018 Benjamin Winestein. All rights reserved.
//

#import "AppsFlyerSharedStateListener.h"
#import <ACPCore/ACPExtensionEvent.h>

@implementation AppsFlyerSharedStateListener

- (instancetype)init {
    self = [super init];
    if (self) {
        
        NSLog(@"com.appsflyer.adobeextension Shared State listener was initialized");
    }
    return self;
}

- (void)hear:(nonnull ACPExtensionEvent*)event {
    
    NSDictionary* jsonEventData = [event eventData];
    
    if (!jsonEventData) {
        NSLog(@"com.appsflyer.adobeextension Retrieved event data is nil");
    }
    
    if ([jsonEventData[@"stateowner"] isEqualToString:@"com.adobe.module.configuration"]) {
        NSError* error = nil;
        NSDictionary* configSharedState = [[[self extension] api] getSharedEventState:@"com.adobe.module.configuration" event:event error:&error];
        if (error) {
            NSLog(@"com.appsflyer.adobeextension Error retrieving shared state %@:%ld.", [error domain], [error code]);
            return;
        }
        
        if (configSharedState) {
            if ([configSharedState objectForKey:@"appsFlyerDevKey"]) {
                NSString* appsFlyerAppId = [configSharedState objectForKey:@"appsFlyerAppId"];
                NSString* appsFlyerDevKey = [configSharedState objectForKey:@"appsFlyerDevKey"];
                NSString* eventSettings = [configSharedState objectForKey:@"inAppEventSetting"];
                id appsFlyerIsDebug = [configSharedState objectForKey:@"appsFlyerIsDebug"];
                id appsFlyerTrackAttrData = [configSharedState objectForKey:@"appsFlyerTrackAttrData"];
                id appsFlyerWaitForECID = [configSharedState objectForKey:@"appsFlyerWaitForECID"];
                
                BOOL isDebug = [appsFlyerIsDebug isKindOfClass:[NSNumber class]] && [appsFlyerIsDebug integerValue] == 1;
                BOOL trackAttrData = [appsFlyerTrackAttrData isKindOfClass:[NSNumber class]] && [appsFlyerTrackAttrData integerValue] == 1;
                BOOL waitForECID = [appsFlyerWaitForECID isKindOfClass:[NSNumber class]] && [appsFlyerWaitForECID integerValue] == 1;
                
                
                [[AppsFlyerAdobeExtension shared] setupAppsFlyerTrackingWithAppId:appsFlyerAppId
                                                                  appsFlyerDevKey:appsFlyerDevKey
                                                                          isDebug:isDebug
                                                                    trackAttrData:trackAttrData
                                                                    eventSettings:eventSettings
                                                                      waitForECID:waitForECID];
                
                NSLog(@"com.appsflyer.adobeextension Received credentials for app: %@", [configSharedState objectForKey:@"appsFlyerAppId"]);
            } else {
                NSLog(@"com.appsflyer.adobeextension Cannot initilalise AppsFlyer tracking without an appId or devKey");
            }
        } else {
            NSLog(@"com.appsflyer.adobeextension Cannot initilalise AppsFlyer without settings");
        }
    }
}

@end
