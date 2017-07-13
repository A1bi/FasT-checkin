//
//  FasTTicket.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 13.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import "FasTTicket.h"

@implementation FasTTicket

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
