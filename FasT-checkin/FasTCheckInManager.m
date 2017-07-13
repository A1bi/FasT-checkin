//
//  FasTCheckInManager.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 13.07.17.
//  Copyright © 2017 Albisigns. All rights reserved.
//

#import "FasTCheckInManager.h"
#import "FasTCheckIn.h"
#import "FasTTicket.h"
#import "FasTApi.h"

#define kCheckInsToSubmitDefaultsKey @"checkInsToSubmit"

@interface FasTCheckInManager ()
{
    NSMutableArray *checkInsToSubmit;
}

- (void)submitCheckIns;
- (void)scheduleCheckInSubmission;
- (void)persistCheckIns;
- (void)loadPersistedCheckIns;

@end

@implementation FasTCheckInManager

+ (instancetype)sharedManager
{
    static FasTCheckInManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[FasTCheckInManager alloc] init];
    });
    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        checkInsToSubmit = [[NSMutableArray alloc] init];
        
        [self loadPersistedCheckIns];
        [self submitCheckIns];
        
        NSNotificationCenter* defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            [self persistCheckIns];
        }];
        [defaultCenter addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            [self loadPersistedCheckIns];
        }];
    }
    return self;
}

- (void)dealloc
{
    [checkInsToSubmit release];
    [super dealloc];
}

- (void)checkInTicket:(FasTTicket *)ticket withMedium:(NSNumber *)medium
{
    FasTCheckIn *checkIn = [[[FasTCheckIn alloc] initWithTicket:ticket medium:medium] autorelease];
    ticket.checkIn = checkIn;
    [checkInsToSubmit addObject:ticket.checkIn];
}

// if internet connection is not available save check ins for later submission
- (void)persistCheckIns {
    if (checkInsToSubmit.count < 1) {
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *checkInsToPersist = [[[defaults objectForKey:kCheckInsToSubmitDefaultsKey] mutableCopy] autorelease];
    if (!checkInsToPersist) {
        checkInsToPersist = [NSMutableArray array];
    }
    
    for (FasTCheckIn *checkIn in checkInsToSubmit) {
        NSDictionary *info = @{ @"ticketId": checkIn.ticketId, @"date": checkIn.date, @"medium": checkIn.medium };
        [checkInsToPersist addObject:info];
    }
    [checkInsToSubmit removeAllObjects];
    
    [defaults setObject:checkInsToPersist forKey:kCheckInsToSubmitDefaultsKey];
    [defaults synchronize];
}

- (void)submitCheckIns {
    NSMutableArray *checkIns = [NSMutableArray array];
    for (FasTCheckIn *checkIn in checkInsToSubmit) {
        NSDictionary *info = @{ @"ticket_id": checkIn.ticketId, @"date": @(checkIn.date.timeIntervalSince1970), @"medium": checkIn.medium };
        [checkIns addObject:info];
    }
    
    if (checkIns.count < 1) {
        [self scheduleCheckInSubmission];
        return;
    }
    
    NSArray *_checkInsToSubmit = [[checkInsToSubmit copy] autorelease];
    [FasTApi post:nil parameters:@{ @"check_ins": checkIns } success:^(NSURLSessionDataTask *task, id response) {
        if (((NSNumber *)response[@"ok"]).boolValue) {
            [checkInsToSubmit removeObjectsInArray:_checkInsToSubmit];
        }
        [self scheduleCheckInSubmission];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [self scheduleCheckInSubmission];
    }];
}

- (void)scheduleCheckInSubmission {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scheduleCheckInSubmission) object:nil];
    [self performSelector:@selector(submitCheckIns) withObject:nil afterDelay:60];
}

- (void)loadPersistedCheckIns {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // are there check ins from older sessions yet to submit ?
    NSArray *checkInsLeftOver = [defaults objectForKey:kCheckInsToSubmitDefaultsKey];
    for (NSDictionary *checkInInfo in checkInsLeftOver) {
        FasTCheckIn *checkIn = [[[FasTCheckIn alloc] initWithTicketId:checkInInfo[@"ticketId"] medium:checkInInfo[@"medium"] date:checkInInfo[@"date"]] autorelease];
        [checkInsToSubmit addObject:checkIn];
    }
    [defaults removeObjectForKey:kCheckInsToSubmitDefaultsKey];
}

@end
