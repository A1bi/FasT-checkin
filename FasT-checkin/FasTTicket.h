//
//  FasTTicket.h
//  FasT-checkin
//
//  Created by Albrecht Oster on 13.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FasTCheckIn;

@interface FasTTicket : NSObject

@property (strong) NSNumber *ticketId;
@property (strong) NSDate *date;
@property (strong) NSString *number;
@property (strong) NSString *type;
@property (strong) NSString *entrance;
@property BOOL cancelled;
@property (strong) FasTCheckIn *checkIn;

- (instancetype)initWithInfoData:(NSData *)data dates:(NSDictionary *)dates types:(NSDictionary *)types entrances:(NSDictionary *)entrances;
- (BOOL)isValidForDate:(NSDate *)date;
- (BOOL)isValidAtEntrance:(NSString *)entrance;

@end
