//
//  FasTAppDelegate.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 12.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTAppDelegate.h"
#import "FasTScannerViewController.h"

@interface FasTAppDelegate ()
{
    CGFloat previousScreenBrightness;
}

@end

@implementation FasTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
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

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

@end
