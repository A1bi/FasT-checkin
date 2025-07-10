//
//  FasTBackgroundWorker.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 10.10.23.
//  Copyright © 2023 Albisigns. All rights reserved.
//

#import "FasTBackgroundWorker.h"
#import "FasTCheckInManager.h"
#import "FasTTicketVerifier.h"

#define kMaxUpdateInterval 210
#define kMinUpdateInterval 60

@interface FasTBackgroundWorker ()
{
    NSTimer *updateTimer;
}

- (void)startTimers;
- (void)stopTimers;
- (void)updateTicketInfo;

@end

@implementation FasTBackgroundWorker

- (void)start {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(startTimers) name:UIApplicationDidBecomeActiveNotification object:nil];
    [center addObserver:self selector:@selector(stopTimers) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)stop {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopTimers];
}

- (void)dealloc {
    [self stop];
}

- (void)startTimers {
    NSLog(@"background: starting timers");
    updateTimer = [NSTimer scheduledTimerWithTimeInterval:kMaxUpdateInterval target:self selector:@selector(updateTicketInfo) userInfo:nil repeats:YES];
    [updateTimer fire];
}

- (void)stopTimers {
    [updateTimer invalidate];
    NSLog(@"background: timers stopped");
}

- (void)updateTicketInfo {
    NSDate *lastRefresh = [FasTTicketVerifier lastRefresh];
    if (!lastRefresh || -[lastRefresh timeIntervalSinceNow] > kMinUpdateInterval) {
        NSLog(@"background: update");
        [FasTTicketVerifier refreshInfo:NULL];
    } else {
        NSLog(@"background: skipping update");
    }
}

@end
