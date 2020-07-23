//
//  FasTAppDelegate.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 12.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTAppDelegate.h"
#import "FasTScannerViewController.h"
#import "FasTTicketVerifier.h"

@import Sentry;

@interface FasTAppDelegate ()
{
    CGFloat previousScreenBrightness;
}

- (void)setupSentry;

@end

@implementation FasTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self setupSentry];
    
    [FasTTicketVerifier init];

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [application setIdleTimerDisabled:YES];
    
    previousScreenBrightness = UIScreen.mainScreen.brightness;
    UIScreen.mainScreen.brightness = 1;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [application setIdleTimerDisabled:NO];
    
    UIScreen.mainScreen.brightness = previousScreenBrightness;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self applicationWillResignActive:application];
}

- (void)setupSentry {
    [SentrySDK startWithConfigureOptions:^(SentryOptions *options) {
        options.dsn = @"https://6bf3236a5b364965bb1008e686e070a7@sentry.a0s.de/5";
    }];
}

@end
