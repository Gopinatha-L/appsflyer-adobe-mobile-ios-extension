//
//  AppsFlyerAppDelegate.m
//  AppsFlyerAdobeExtension
//
//  Created by benjamin on 10/15/2018.
//  Copyright (c) 2018 benjamin. All rights reserved.
//

#import "AppsFlyerAppDelegate.h"
#import "AppsFlyerAppDelegate.h"
#import <ACPCore/ACPCore.h>
#import "AppsFlyerAdobeExtension.h"

#import <ACPCore/ACPIdentity.h>
#import <ACPCore/ACPLifecycle.h>
#import <ACPCore/ACPSignal.h>
#import <ACPAnalytics/ACPAnalytics.h>


@implementation AppsFlyerAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [ACPCore setLogLevel:ACPMobileLogLevelVerbose];
    [ACPCore configureWithAppId:@"cc3f5fb64390/1e339b77b5d2/launch-29205c76e794-development"];

    
    [AppsFlyerAdobeExtension registerExtension];
    [ACPAnalytics registerExtension];
    [ACPIdentity registerExtension];
    [ACPLifecycle registerExtension];
    [ACPSignal registerExtension];
    
    [ACPCore start:^{
        [ACPCore lifecycleStart:nil];
    }];

    [AppsFlyerAdobeExtension registerCallbacks:^(NSDictionary *dictionary) {
        NSLog(@"[AppsFlyerAdobeExtension] Received callback: %@", dictionary);
    }];
    
    [AppsFlyerAdobeExtension callbacksErrorHandler:^(NSError *error) {
        NSLog(@"[AppsFlyerAdobeExtension] Error receivng callback: %@" , error);
    }];

    return YES;
}

// Deep Link reporting using Univeral Links.
 - (BOOL) application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *restorableObjects))restorationHandler {
     [AppsFlyerAdobeExtension continueUserActivity:userActivity restorationHandler:restorationHandler];
    return YES;
}

// Deep Link reporting for URL Schemes.
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary *) options {
    [AppsFlyerAdobeExtension openURL:url options:options];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
