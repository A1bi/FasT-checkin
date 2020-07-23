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

@property (nonatomic, readonly) NSDate *date;
@property (nonatomic, readonly) FasTTicket *ticket;
@property (nonatomic, readonly) NSNumber *ticketId;
@property (nonatomic, readonly) NSNumber *medium;

- (instancetype)initWithTicketId:(NSNumber *)ticketId medium:(NSNumber *)medium date:(NSDate *)date;
- (instancetype)initWithTicket:(FasTTicket *)ticket medium:(NSNumber *)medium;
- (NSString *)ticketNumberWithIdFallback;

@end
