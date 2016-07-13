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
// barcode cache contains ticket info by barcode content
static NSMutableDictionary *ticketCache = nil;
static NSMutableArray *ticketCacheEntryOrder = nil;

@interface FasTTicketValidator ()

+ (NSNumber *)verifyAndValidate:(NSString *)messageData;
+ (void)clearCache;

@end

@implementation FasTTicketValidator

+ (void)init {
    [ticketCache release];
    ticketCache = [[NSMutableDictionary alloc] init];
    
    [ticketCacheEntryOrder release];
    ticketCacheEntryOrder = [[NSMutableArray alloc] init];
    
    currentDateId = [@(4) retain];
    changedTickets = [@{} retain];
    
    NSDictionary *keys = @{@(1): @"3534fe1286a0a7551395891ff32a8d44d919e19775f555cc5ad410adc8e7bc2d"};
    [FasTTicketVerifier setKeys:keys];
}

+ (NSDictionary *)validate:(NSString *)messageData
{
    // check if this barcode is in cache
    id ticketInfo = ticketCache[messageData];
    if (!ticketInfo) {
        // not in cache -> validate
        NSLog(@"barcode cache miss");
        ticketInfo = [self verifyAndValidate:messageData];
        if (!ticketInfo) {
            // invalid -> store NSNull in cache
            ticketInfo = [NSNull null];
        }
        
        ticketCache[messageData] = ticketInfo;
        [ticketCacheEntryOrder addObject:messageData];
        
        [self clearCache];
        
    } else {
        NSLog(@"barcode cache hit");
    }
    
    if (![ticketInfo isKindOfClass:[NSNumber class]]) {
        NSLog(@"ticket invalid");
        return nil;
    }
    
    return ticketInfo;
}

+ (NSNumber *)verifyAndValidate:(NSString *)messageData {
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

+ (void)clearCache {
    // clear oldest cache entries
    if (ticketCacheEntryOrder.count > 5) {
        NSLog(@"clearing oldest cache entries");
        NSRange cacheRange = NSMakeRange(0, 3);
        NSArray *entriesToRemove = [ticketCacheEntryOrder subarrayWithRange:cacheRange];
        [ticketCache removeObjectsForKeys:entriesToRemove];
        [ticketCacheEntryOrder removeObjectsInRange:cacheRange];
    }
}

@end
