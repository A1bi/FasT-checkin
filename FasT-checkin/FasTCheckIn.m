//
//  FasTCheckIn.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 21.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import "FasTCheckIn.h"
#import "FasTTicket.h"

@implementation FasTCheckIn

- (instancetype)initWithTicketId:(NSNumber *)ticketId medium:(NSNumber *)medium date:(NSDate *)date {
    self = [super init];
    if (self) {
        _ticketId = [ticketId retain];
        _medium = [medium retain];
        _date = [date retain];
    }
    return self;
}

- (instancetype)initWithTicket:(FasTTicket *)ticket medium:(NSNumber *)medium {
    self = [self initWithTicketId:ticket.ticketId medium:medium date:[NSDate date]];
    if (self) {
        _ticket = [ticket retain];
    }
    return self;
}

@end
