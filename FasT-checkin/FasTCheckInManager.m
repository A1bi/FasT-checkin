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
#import "FasTStatisticsManager.h"

#define kCheckInsToSubmitDefaultsKey @"checkInsToSubmit"
#define kLastSubmissionDateDefaultsKey @"lastSubmissionDate"

@interface FasTCheckInManager ()
{
    NSLock *submissionLock;
    NSMutableArray *checkInsToSubmit;
}

- (void)persistCheckIns;
- (void)loadPersistedCheckIns;
- (void)submitCheckIns;

@end

@implementation FasTCheckInManager

@synthesize checkInsToSubmit;

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
        submissionLock = [[NSLock alloc] init];
        [self loadPersistedCheckIns];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(persistCheckIns) name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)checkInTicket:(FasTTicket *)ticket withMedium:(NSNumber *)medium
{
    FasTCheckIn *checkIn = [[FasTCheckIn alloc] initWithTicket:ticket medium:medium];
    ticket.checkIn = checkIn;
    
    @synchronized(checkInsToSubmit) {
        [checkInsToSubmit addObject:ticket.checkIn];
    }
    
    [self submitCheckIns];
}

// if internet connection is not available save check ins for later submission
- (void)persistCheckIns {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    @synchronized(checkInsToSubmit) {
        [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:checkInsToSubmit] forKey:kCheckInsToSubmitDefaultsKey];
    }
    
    [defaults setObject:_lastSubmissionDate forKey:kLastSubmissionDateDefaultsKey];
    [defaults synchronize];
}

- (void)submitCheckIns {
    if (![submissionLock tryLock]) return;
    
    NSArray *checkInsInSubmission;
    
    @synchronized(checkInsToSubmit) {
        checkInsInSubmission = [NSArray arrayWithArray:checkInsToSubmit];
    }
    
    if (checkInsInSubmission.count < 1) {
        [submissionLock unlock];
        return;
    }
    
    NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
    NSMutableArray *checkIns = [NSMutableArray array];
    for (FasTCheckIn *checkIn in checkInsInSubmission) {
        NSDictionary *info = @{ @"ticket_id": checkIn.ticketId, @"date": [formatter stringFromDate:checkIn.date], @"medium": checkIn.medium };
        [checkIns addObject:info];
    }
    
    [FasTApi post:nil data:@{ @"check_ins": checkIns } completion:^(id  _Nullable data, NSError * _Nullable error) {
        if (error) {
            [self->submissionLock unlock];
            [self performSelector:@selector(submitCheckIns) withObject:nil afterDelay:5];
            
        } else {
            @synchronized(self->checkInsToSubmit) {
                [self->checkInsToSubmit removeObjectsInArray:checkInsInSubmission];
            }
            
            [self persistCheckIns];
            [[FasTStatisticsManager sharedManager] addSubmittedCheckIns:checkInsInSubmission];
            
            self->_lastSubmissionDate = [NSDate dateWithTimeIntervalSinceNow:0];
            
            [self->submissionLock unlock];
            [self submitCheckIns];
        }
    }];
}

- (void)loadPersistedCheckIns {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // are there check ins from older sessions yet to submit ?
    NSData *checkInData = [defaults objectForKey:kCheckInsToSubmitDefaultsKey];
    checkInsToSubmit = [NSKeyedUnarchiver unarchiveObjectWithData:checkInData];
    if (!checkInsToSubmit) {
        checkInsToSubmit = [[NSMutableArray alloc] init];
    }
    
    _lastSubmissionDate = [defaults objectForKey:kLastSubmissionDateDefaultsKey];
}

@end
