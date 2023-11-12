//
//  FasTMessageVerifier.h
//  FasT-checkin
//
//  Created by Albrecht Oster on 12.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FasTScanResult;

@interface FasTTicketVerifier : NSObject

+ (void)init;
+ (FasTScanResult *)getScanResultByBarcodeContent:(NSString *)messageData;
+ (void)refreshInfo:(void (^)(NSError *error))completion;
+ (NSDate *)lastRefresh;
+ (void)clearTickets;
+ (NSDate *)currentDate;

@end
