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
        options.dsn = @"https://897b1d6771e14f6eb657133429cde4e1@glitchtip.a0s.de/8";
    }];
}

@end
