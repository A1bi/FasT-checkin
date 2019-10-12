//
//  FasTTicket.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 13.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import "FasTTicket.h"

@implementation FasTTicket

- (instancetype)initWithInfoData:(NSData *)data dates:(NSDictionary *)dates types:(NSDictionary *)types {
    self = [super init];
    if (self) {
        unsigned char *values = (unsigned char *)data.bytes;
        
        // ticket id - bits 0-15
        self.ticketId = @(values[0] << 8 | values[1]);
        
        // order number - bits 16-35
        unsigned long orderNumber = values[2] << 12 | values[3] << 4 | values[4] >> 4;
        // order index - bits 36-43
        char orderIndex = (char)(values[4] << 4 | values[5] >> 4);
        self.number = [NSString stringWithFormat:@"%lu-%d", orderNumber, orderIndex];
        
        // date id - bits 44-51
        char dateId = (char)(values[5] << 4 | values[6] >> 4);
        self.date = dates[@(dateId)];
        // type id - bits 52-59
        char typeId = (char)(values[6] << 4 | values[7] >> 4);
        self.type = types[@(typeId)];
        // seat id - bits 60-71
//        short seatId = (char)(values[7] << 4 | values[8]);
    }
    return self;
}

- (BOOL)isValidForDate:(NSDate *)date {
    return [_date isEqualToDate:date];
}

- (void)dealloc
{
    [_ticketId release];
    [_date release];
    [_number release];
    [_type release];
    [_checkIn release];
    [super dealloc];
}

@end
