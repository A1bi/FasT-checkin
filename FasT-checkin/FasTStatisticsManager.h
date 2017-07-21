//
//  FasTInfoManager.h
//  FasT-checkin
//
//  Created by Albrecht Oster on 21.07.17.
//  Copyright © 2017 Albisigns. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FasTCheckIn;

@interface FasTStatisticsManager : NSObject

+ (instancetype)sharedManager;
- (void)increaseScanAttempts;
- (void)addCheckIn:(FasTCheckIn *)checkIn;
- (void)addDuplicateCheckIn:(FasTCheckIn *)checkIn;
- (void)increaseDeniedScans;
- (void)addSubmittedCheckIns:(NSArray *)checkIns;

@property (nonatomic, readonly) NSInteger scanAttempts, deniedScans, crashs;
@property (nonatomic, readonly) NSMutableArray *checkIns, *duplicateCheckIns, *submittedCheckIns;

@end
