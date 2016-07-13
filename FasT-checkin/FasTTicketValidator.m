//
//  FasTTicketVerifier.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 13.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import "FasTTicketValidator.h"
#import "FasTTicketVerifier.h"

static NSNumber *currentDateId = nil;
static NSDictionary *changedTickets = nil;

@implementation FasTTicketValidator

+ (void)fetchInfo {
    currentDateId = [@(4) retain];
    changedTickets = [@{} retain];
    
    NSDictionary *keys = @{@(1): @"3534fe1286a0a7551395891ff32a8d44d919e19775f555cc5ad410adc8e7bc2d"};
    [FasTTicketVerifier setKeys:keys];
}

+ (NSNumber *)validate:(NSString *)messageData
{
    NSDictionary *ticketInfo = [FasTTicketVerifier verify:messageData];
    NSNumber *ticketId;
    
    if (ticketInfo) {
        @try {
            ticketId = ticketInfo[@"ti"];
            // check if a newer version of the ticket is in the changed tickets
            NSDictionary *changedTicketInfo = changedTickets[ticketId];
            if (changedTicketInfo) {
                ticketInfo = changedTicketInfo;
            }
            
            // check if date matches with today
            if (![ticketInfo[@"da"] isEqualToNumber:currentDateId]) {
                NSLog(@"ticket date doesn't match today");
                return nil;
            }
        
        } @catch (NSException *exception) {
            NSLog(@"ticket could not be validated, exception: %@", exception);
            return nil;
        }
    }
    
    return ticketId;
}

@end
