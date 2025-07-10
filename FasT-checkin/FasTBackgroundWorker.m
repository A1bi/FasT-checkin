//
//  FasTBackgroundWorker.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 10.10.23.
//  Copyright © 2023 Albisigns. All rights reserved.
//

#import "FasTBackgroundWorker.h"
#import "FasTTicketVerifier.h"

#define kWorkInterval 60

@interface FasTBackgroundWorker ()
{
    NSTimer *timer;
}

- (void)startTimer;
- (void)stopTimer;
- (void)work;

@end

@implementation FasTBackgroundWorker

- (void)start {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(startTimer) name:UIApplicationDidBecomeActiveNotification object:nil];
    [center addObserver:self selector:@selector(stopTimer) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)stop {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopTimer];
}

- (void)dealloc {
    [self stop];
}

- (void)startTimer {
    NSLog(@"background: starting timer");
    timer = [NSTimer scheduledTimerWithTimeInterval:kWorkInterval target:self selector:@selector(work) userInfo:nil repeats:YES];
    [timer fire];
}

- (void)stopTimer {
    [timer invalidate];
    NSLog(@"background: timer stopped");
}

- (void)work {
    [FasTTicketVerifier refreshInfo:NULL];
}

@end
