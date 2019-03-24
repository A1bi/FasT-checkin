//
//  FasTCheckIn.h
//  FasT-checkin
//
//  Created by Albrecht Oster on 21.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FasTTicket;

@interface FasTCheckIn : NSObject <NSCoding>

@property (readonly) NSDate *date;
@property (readonly) FasTTicket *ticket;
@property (readonly) NSNumber *ticketId;
@property (readonly) NSNumber *medium;

- (instancetype)initWithTicketId:(NSNumber *)ticketId medium:(NSNumber *)medium date:(NSDate *)date;
- (instancetype)initWithTicket:(FasTTicket *)ticket medium:(NSNumber *)medium;
- (NSString *)ticketNumberWithIdFallback;

@end
