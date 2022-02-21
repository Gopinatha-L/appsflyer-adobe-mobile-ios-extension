//
//  AppsFlyerEvents.h
//  appsflyer-adobe-extension
//
//  Created by Benjamin Winestein on 21/08/2018.
//  Copyright © 2018 Benjamin Winestein. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ACPCore/ACPExtensionEvent.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppsFlyerEventListener: ACPExtensionEvent

- (void)hear:(nonnull ACPExtensionEvent*)event;

- (NSString *)extractCurrency:(NSDictionary *)dictionary withKey:(NSString *)currencyKey;
- (NSDecimalNumber *)extractRevenue:(NSDictionary *)dictionary withKey:(NSString *)revenueKey;

@end

NS_ASSUME_NONNULL_END
