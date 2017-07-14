//
//  FasTMessageVerifier.h
//  FasT-checkin
//
//  Created by Albrecht Oster on 12.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FasTTicket;

@interface FasTTicketVerifier : NSObject

+ (void)init;
+ (FasTTicket *)getTicketByBarcode:(NSString *)messageData;
+ (void)clearTickets;

@end
