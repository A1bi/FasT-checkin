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

+ (instancetype)sharedManager;

- (void)checkInTicket:(FasTTicket *)ticket withMedium:(NSNumber *)medium;

@end
