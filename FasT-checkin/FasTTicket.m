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
        _ticketId = @(values[0] << 8 | values[1]);
        
        // order number - bits 16-35
        unsigned long orderNumber = values[2] << 12 | values[3] << 4 | values[4] >> 4;
        // order index - bits 36-43
        char orderIndex = (char)(values[4] << 4 | values[5] >> 4);
        _number = [NSString stringWithFormat:@"%lu-%d", orderNumber, orderIndex];
        
        // date id - bits 44-51
        char dateId = (char)(values[5] << 4 | values[6] >> 4);
        _date = dates[@(dateId)];
        // type id - bits 52-59
        char typeId = (char)(values[6] << 4 | values[7] >> 4);
        _type = types[@(typeId)];
        // seat id - bits 60-71
//        short seatId = (char)(values[7] << 4 | values[8]);
    }
    return self;
}

- (BOOL)isValidToday {
    NSCalendar *cal = [NSCalendar currentCalendar];
    
    // iOS 8+
    if ([cal respondsToSelector:@selector(isDateInToday:)]) {
        return [cal isDateInToday:_date];
        
    } else {
        NSDateComponents *components = [cal components:(NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:[NSDate date]];
        
        NSDate *today = [cal dateFromComponents:components];
        components = [cal components:(NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:_date];
        NSDate *date = [cal dateFromComponents:components];
        
        return [today isEqualToDate:date];
    }
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
