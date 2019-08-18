//
//  FasTCheckInManager.h
//  FasT-checkin
//
//  Created by Albrecht Oster on 13.07.17.
//  Copyright © 2017 Albisigns. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FasTTicket;

@interface FasTCheckInManager : NSObject

@property (nonatomic, readonly) NSMutableArray *checkInsToSubmit;
@property (nonatomic, readonly) NSDate *lastSubmissionDate;

+ (instancetype)sharedManager;

- (void)checkInTicket:(FasTTicket *)ticket withMedium:(NSNumber *)medium;
- (void)submitCheckIns:(void (^)(void))completion;

@end
