//
//  FasTInfoManager.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 21.07.17.
//  Copyright © 2017 Albisigns. All rights reserved.
//

#import "FasTStatisticsManager.h"

#define kStatisticsDefaultsKey @"statistics"
#define kStatisticsLaunchedDefaultsKey @"launched"

@interface FasTStatisticsManager ()

- (void)persistStatistics;

@end

@implementation FasTStatisticsManager

+ (instancetype)sharedManager
{
    static FasTStatisticsManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[FasTStatisticsManager alloc] init];
    });
    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
        
        NSDictionary *stats = [defaults objectForKey:kStatisticsDefaultsKey];

        _scanAttempts = [stats[@"scanAttempts"] integerValue];
        _deniedScans = [stats[@"deniedScans"] integerValue];
        _crashs = [stats[@"crashs"] integerValue];
        
        NSData *checkIns = stats[@"checkIns"];
        if (checkIns) {
            _checkIns = [NSKeyedUnarchiver unarchiveObjectWithData:checkIns];
        } else {
            _checkIns = [[NSMutableArray alloc] init];
        }
        checkIns = stats[@"duplicateCheckIns"];
        if (checkIns) {
            _duplicateCheckIns = [NSKeyedUnarchiver unarchiveObjectWithData:checkIns];
        } else {
            _duplicateCheckIns = [[NSMutableArray alloc] init];
        }
        checkIns = stats[@"submittedCheckIns"];
        if (checkIns) {
            _submittedCheckIns = [NSKeyedUnarchiver unarchiveObjectWithData:checkIns];
        } else {
            _submittedCheckIns = [[NSMutableArray alloc] init];
        }
        
        if ([[defaults objectForKey:kStatisticsLaunchedDefaultsKey] boolValue] == YES) {
            _crashs++;
        } else {
            [defaults setBool:YES forKey:kStatisticsLaunchedDefaultsKey];
        }
        [self persistStatistics];
        
        NSNotificationCenter* defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            [self persistStatistics];
            [defaults removeObjectForKey:kStatisticsLaunchedDefaultsKey];
        }];
    }
    return self;
}

- (void)persistStatistics
{
    NSData *checkIns = [NSKeyedArchiver archivedDataWithRootObject:_checkIns];
    NSData *duplicateCheckIns = [NSKeyedArchiver archivedDataWithRootObject:_duplicateCheckIns];
    NSData *submittedCheckIns = [NSKeyedArchiver archivedDataWithRootObject:_submittedCheckIns];
    NSDictionary *stats = @{ @"scanAttempts": @(_scanAttempts), @"checkIns": checkIns, @"duplicateCheckIns": duplicateCheckIns, @"submittedCheckIns": submittedCheckIns, @"deniedScans": @(_deniedScans), @"crashs": @(_crashs) };
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:stats forKey:kStatisticsDefaultsKey];
    [defaults synchronize];
}

- (void)increaseScanAttempts
{
    _scanAttempts++;
}

- (void)addCheckIn:(FasTCheckIn *)checkIn
{
    [_checkIns addObject:checkIn];
}

- (void)addDuplicateCheckIn:(FasTCheckIn *)checkIn
{
    [_duplicateCheckIns addObject:checkIn];
}

- (void)increaseDeniedScans
{
    _deniedScans++;
}

- (void)addSubmittedCheckIns:(NSArray *)checkIns
{
    [_submittedCheckIns addObjectsFromArray:checkIns];
}

@end
