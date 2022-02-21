//
//  AppsFlyerShStListener.h
//  appsflyer-adobe-extension
//
//  Created by Benjamin Winestein on 05/08/2018.
//  Copyright © 2018 Benjamin Winestein. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppsFlyerAdobeExtension.h"


@interface AppsFlyerSharedStateListener: ACPExtensionListener

- (void)hear:(nonnull ACPExtensionEvent*)event;

@end
