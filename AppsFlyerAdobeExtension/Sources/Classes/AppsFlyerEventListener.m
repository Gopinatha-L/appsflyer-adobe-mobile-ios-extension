//
//  AppsFlyerEvents.m
//  appsflyer-adobe-extension
//
//  Created by Benjamin Winestein on 21/08/2018.
//  Copyright © 2018 Benjamin Winestein. All rights reserved.
//

#import "AppsFlyerEventListener.h"
#import "AppsFlyerAdobeExtension.h"
#import <AppsFlyerLib/AppsFlyerLib.h>

@interface AppsFlyerEventListener()
@property (weak, nonatomic) AppsFlyerAdobeExtension *extension;
@end

@implementation AppsFlyerEventListener


- (instancetype)initWithExtension:(id)extension
{
    self = [super init];
    if (self) {
        _extension = extension;
        NSLog(@"com.appsflyer.adobeextension Analytics Events listener was initialized");
    }
    return self;
}

- (void)hear:(nonnull ACPExtensionEvent*)event {
    NSString* eventSettings  = [[self extension] getEventSettings];
    BOOL isRevenueEvent = NO;
    
    if ([eventSettings isEqualToString:@"none"]) {
         NSLog(@"com.appsflyer.adobeextension error retreiving event binding state");
        return;
    }
    
    BOOL bindActionEvents = [eventSettings isEqualToString:@"actions"] || [eventSettings isEqualToString:@"all"];
    BOOL bindStateEvents = [eventSettings isEqualToString:@"states"] || [eventSettings isEqualToString:@"all"];
    
    if ([[event eventType] isEqualToString:@"com.adobe.eventType.generic.track"] && [[event eventSource] isEqualToString:@"com.adobe.eventSource.requestContent"]) {
        NSDictionary* eventData = [NSDictionary dictionaryWithDictionary:[event eventData]];
        NSDictionary* nestedData = [eventData objectForKey:@"contextdata"];
        
        NSString* eventAction = [eventData objectForKey:@"action"];
        NSString* eventState = [eventData objectForKey:@"state"];
        
        if ([eventAction isEqualToString:@"AppsFlyer Attribution Data"] || [eventAction isEqualToString:@"AppsFlyer Engagement Data"]) {
            NSLog(@"com.appsflyer.adobeextension Discarding event binding for AppsFlyer Attribution Data event");
            return;
        }
        
        NSNumber* revenue = [self extractRevenue:nestedData withKey:@"revenue"];
        NSString* currency = [self extractCurrency:nestedData withKey:@"currency"];
        
        NSMutableDictionary* af_payload_properties;
        if (revenue) {
            af_payload_properties = [NSMutableDictionary dictionaryWithDictionary: nestedData];
            [af_payload_properties setObject:revenue forKey:@"af_revenue"];
            
            if (currency) {
                [af_payload_properties setObject:currency forKey:@"af_currency"];
            }
            
            isRevenueEvent = YES;
        }
        
        if (bindActionEvents && eventAction.length != 0) {
            if (isRevenueEvent && af_payload_properties != NULL) {
                [[AppsFlyerLib shared] logEvent:eventAction withValues:af_payload_properties];
            } else {
                if (eventAction != nil && [eventAction isKindOfClass:[NSString class]]) {
                        [[AppsFlyerLib shared] logEvent:eventAction withValues:nestedData];
                    }
            }
        }
        
        if (bindStateEvents && eventState.length != 0) {
            if (isRevenueEvent && af_payload_properties != NULL) {
                [[AppsFlyerLib shared] logEvent:eventState withValues:af_payload_properties];
            } else {
                if (eventState != nil && [eventState isKindOfClass:[NSString class]]) {
                    [[AppsFlyerLib shared] logEvent:eventState withValues:nestedData];
                }
            }
        }
    }
}
    
- (NSString *)extractCurrency:(NSDictionary *)dictionary withKey:(NSString *)currencyKey {
    id currencyProperty = dictionary[currencyKey];
    if (currencyProperty) {
        if ([currencyProperty isKindOfClass:[NSString class]]) {
            return currencyProperty;
        }
    }
    // If currency not set, return default USD
    return @"USD";
}

- (NSDecimalNumber *)extractRevenue:(NSDictionary *)dictionary withKey:(NSString *)revenueKey {
    id revenueProperty = dictionary[revenueKey];
    if (revenueProperty) {
        if ([revenueProperty isKindOfClass:[NSString class]]) {
            return [NSDecimalNumber decimalNumberWithString:revenueProperty];
        } else if ([revenueProperty isKindOfClass:[NSNumber class]]) {
            return revenueProperty;
        }
    }
    return nil;
}

@end
