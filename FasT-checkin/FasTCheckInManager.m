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
    NSMutableArray *checkInsToSubmit;
}

- (void)scheduleCheckInSubmission;
- (void)persistCheckIns;
- (void)loadPersistedCheckIns;

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
        checkInsToSubmit = [[NSMutableArray alloc] init];
        
        [self loadPersistedCheckIns];
//        [self submitCheckIns:NULL];
        
        NSNotificationCenter* defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            [self persistCheckIns];
        }];
    }
    return self;
}

- (void)checkInTicket:(FasTTicket *)ticket withMedium:(NSNumber *)medium
{
    FasTCheckIn *checkIn = [[FasTCheckIn alloc] initWithTicket:ticket medium:medium];
    ticket.checkIn = checkIn;
    [checkInsToSubmit addObject:ticket.checkIn];
}

// if internet connection is not available save check ins for later submission
- (void)persistCheckIns {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:checkInsToSubmit] forKey:kCheckInsToSubmitDefaultsKey];
    [defaults setObject:_lastSubmissionDate forKey:kLastSubmissionDateDefaultsKey];
    [defaults synchronize];
}

- (void)submitCheckIns:(void (^)(NSError *error))completion {
    if (checkInsToSubmit.count > 0) {
        NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
        NSMutableArray *checkIns = [NSMutableArray array];
        for (FasTCheckIn *checkIn in checkInsToSubmit) {
            NSDictionary *info = @{ @"ticket_id": checkIn.ticketId, @"date": [formatter stringFromDate:checkIn.date], @"medium": checkIn.medium };
            [checkIns addObject:info];
        }
        
        NSArray *_checkInsToSubmit = [checkInsToSubmit copy];
        [FasTApi post:nil parameters:@{ @"check_ins": checkIns } success:^(NSURLSessionDataTask *task, id response) {
            [self->checkInsToSubmit removeObjectsInArray:_checkInsToSubmit];
            [self persistCheckIns];
            [[FasTStatisticsManager sharedManager] addSubmittedCheckIns:_checkInsToSubmit];

            [self scheduleCheckInSubmission];
            
            self->_lastSubmissionDate = [NSDate dateWithTimeIntervalSinceNow:0];
            
            if (completion) completion(nil);
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            if (completion) completion(error);
        }];
    
    } else {
        [self scheduleCheckInSubmission];
        
        _lastSubmissionDate = [NSDate dateWithTimeIntervalSinceNow:0];
        
        if (completion) completion(nil);
    }
}

- (void)scheduleCheckInSubmission {
//    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scheduleCheckInSubmission) object:nil];
//    [self performSelector:@selector(submitCheckIns:) withObject:nil afterDelay:10];
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
