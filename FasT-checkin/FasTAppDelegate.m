//
//  FasTAppDelegate.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 12.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTAppDelegate.h"
#import "FasTScannerViewController.h"
#import "FasTApi.h"

@implementation FasTAppDelegate

- (void)dealloc
{
    [_window release];
    [alert release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    [self.window makeKeyAndVisible];
    
    FasTScannerViewController *scanner = [[[FasTScannerViewController alloc] init] autorelease];
    self.window.rootViewController = scanner;
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSString *checkinId = [[NSUserDefaults standardUserDefaults] valueForKey:@"checkinId"];
    if (checkinId && [checkinId length] > 0) {
        [FasTApi defaultApiWithClientType:nil clientId:checkinId];
    } else {
        alert = [[UIAlertView alloc] initWithTitle:@"Checkin ID fehlt" message:@"Bitte tragen Sie eine Checkin ID ein." delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [alert dismissWithClickedButtonIndex:0 animated:NO];
}

@end
