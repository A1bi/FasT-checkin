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

@property (nonatomic) NSNumber *ticketId;
@property (nonatomic) NSDate *date;
@property (nonatomic) NSString *number;
@property (nonatomic) NSString *type;
@property (nonatomic) NSArray *seatRange;
@property (nonatomic) NSString *entrance;
@property BOOL cancelled;
@property (nonatomic, weak) FasTCheckIn *checkIn;

- (instancetype)initWithInfoData:(NSData *)data dates:(NSDictionary *)dates types:(NSDictionary *)types entrances:(NSDictionary *)entrances;
- (BOOL)isValidForDate:(NSDate *)date;
- (BOOL)isValidAtEntrance:(NSString *)entrance;

@end
