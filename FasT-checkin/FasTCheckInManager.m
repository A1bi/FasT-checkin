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

- (void)dealloc
{
    [checkInsToSubmit release];
    [_lastSubmissionDate release];
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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:checkInsToSubmit] forKey:kCheckInsToSubmitDefaultsKey];
    [defaults setObject:_lastSubmissionDate forKey:kLastSubmissionDateDefaultsKey];
    [defaults synchronize];
}

- (void)submitCheckIns:(void (^)())completion {
    if (checkInsToSubmit.count > 0) {
        NSMutableArray *checkIns = [NSMutableArray array];
        for (FasTCheckIn *checkIn in checkInsToSubmit) {
            NSDictionary *info = @{ @"ticket_id": checkIn.ticketId, @"date": @(checkIn.date.timeIntervalSince1970), @"medium": checkIn.medium };
            [checkIns addObject:info];
        }
        
        NSArray *_checkInsToSubmit = [[checkInsToSubmit copy] autorelease];
        [FasTApi post:nil parameters:@{ @"check_ins": checkIns } success:^(NSURLSessionDataTask *task, id response) {
            if (((NSNumber *)response[@"ok"]).boolValue) {
                [checkInsToSubmit removeObjectsInArray:_checkInsToSubmit];
                [self persistCheckIns];
                [[FasTStatisticsManager sharedManager] addSubmittedCheckIns:_checkInsToSubmit];
            }
            [self scheduleCheckInSubmission];
            
            [_lastSubmissionDate release];
            _lastSubmissionDate = [[NSDate dateWithTimeIntervalSinceNow:0] retain];
            
            if (completion) {
                completion();
            }
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            [self scheduleCheckInSubmission];
        }];
    
    } else {
        [self scheduleCheckInSubmission];
        
        [_lastSubmissionDate release];
        _lastSubmissionDate = [[NSDate dateWithTimeIntervalSinceNow:0] retain];
        
        if (completion) {
            completion();
        }
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
    [checkInsToSubmit release];
    checkInsToSubmit = [[NSKeyedUnarchiver unarchiveObjectWithData:checkInData] retain];
    if (!checkInsToSubmit) {
        checkInsToSubmit = [[NSMutableArray alloc] init];
    }
    
    [_lastSubmissionDate release];
    _lastSubmissionDate = [[defaults objectForKey:kLastSubmissionDateDefaultsKey] retain];
}

@end
