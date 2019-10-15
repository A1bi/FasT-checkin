//
//  FasTMessageVerifier.h
//  FasT-checkin
//
//  Created by Albrecht Oster on 12.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FasTTicket, FasTSignedInfoBinary;

@interface FasTTicketVerifier : NSObject

+ (void)init;
+ (FasTTicket *)getTicketByBarcode:(NSString *)messageData signedInfo:(FasTSignedInfoBinary **)signedInfo;
+ (void)refreshInfo:(void (^)(NSError *error))completion;
+ (NSDate *)lastRefresh;
+ (void)clearTickets;
+ (NSDate *)currentDate;

@end
