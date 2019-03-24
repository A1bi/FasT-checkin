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
    [self initWithTicketId:ticket.ticketId medium:medium date:[NSDate date]];
    _ticket = [ticket retain];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    return [self initWithTicketId:[decoder decodeObjectForKey:@"ticketId"] medium:[decoder decodeObjectForKey:@"medium"] date:[decoder decodeObjectForKey:@"date"]];
}

- (NSString *)ticketNumberWithIdFallback {
    return _ticket ? _ticket.number : [NSString stringWithFormat:@"%@", _ticketId];
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_ticketId forKey:@"ticketId"];
    [encoder encodeObject:_medium forKey:@"medium"];
    [encoder encodeObject:_date forKey:@"date"];
}

- (void)dealloc
{
    [_ticket release];
    [_ticketId release];
    [_medium release];
    [_date release];
    [super dealloc];
}

@end
