//
//  FasTTicket.h
//  FasT-checkin
//
//  Created by Albrecht Oster on 13.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FasTTicket : NSObject

@property (strong) NSNumber *ticketId;
@property (strong) NSNumber *dateId;
@property (strong) NSString *number;
@property BOOL cancelled;

@end
