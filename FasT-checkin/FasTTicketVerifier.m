//
//  FasTMessageVerifier.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 12.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import "FasTTicketVerifier.h"
#import "FasTTicket.h"
#import "FasTSignedInfoBinary.h"
#import "FasTApi.h"
#import <CommonCrypto/CommonHMAC.h>

#define kLastApiResponseDefaultsKey @"lastApiResponse"
#define kLastApiResponseDateDefaultsKey @"lastApiResponseDate"
#define kMinutesBeforeDateAllowedForCheckIn 90
#define kMinutesAfterDateAllowedForCheckIn 45

static NSDictionary *keys = nil;
static NSDictionary *dates = nil;
static NSDictionary *ticketTypes = nil;
static NSDictionary *seatEntrances = nil;
static NSMutableDictionary *ticketsById = nil;
static NSMutableDictionary *ticketsByBarcode = nil;

@interface FasTTicketVerifier ()

+ (FasTSignedInfoBinary *)verify:(NSString *)messageData;
+ (void)processApiResponse:(NSDictionary *)response;

@end

@implementation FasTTicketVerifier

+ (void)init {
    ticketsById = [[NSMutableDictionary alloc] init];
    ticketsByBarcode = [[NSMutableDictionary alloc] init];
    
    NSData *responseData = [[NSUserDefaults standardUserDefaults] objectForKey:kLastApiResponseDefaultsKey];
    NSDictionary *response = (NSDictionary *)[NSKeyedUnarchiver unarchiveObjectWithData:responseData];
    if (response) {
        [self processApiResponse:response];
    } else {
        [self refreshInfo:NULL];
    }
}

+ (FasTTicket *)getTicketByBarcode:(NSString *)messageData signedInfo:(FasTSignedInfoBinary **)_signedInfo {
    // check if this message has already been processed
    FasTTicket *ticket = ticketsByBarcode[messageData];
    if (!ticket) {
        // not yet processed -> verify
        FasTSignedInfoBinary *signedInfo = [self verify:messageData];
        
        if (signedInfo) {
            if (_signedInfo) {
                *_signedInfo = signedInfo;
            }
            
            @try {
                ticket = [[FasTTicket alloc] initWithInfoData:signedInfo.ticketData dates:dates types:ticketTypes entrances:seatEntrances];
                
                // find updated ticket
                FasTTicket *updatedTicket = ticketsById[ticket.ticketId];
                if (updatedTicket) {
                    ticket = updatedTicket;
                } else {
                    ticketsById[ticket.ticketId] = ticket;
                }

            } @catch (NSException *exception) {
                NSLog(@"ticket could not be validated, exception: %@", exception);
            }
        }
        
        ticketsByBarcode[messageData] = ticket ? ticket : [NSNull null];
        
    // message has already been processed and was invalid
    } else if ([ticket isKindOfClass:[NSNull class]]) {
        return nil;
    }
    
    return ticket;
}

+ (FasTSignedInfoBinary *)verify:(NSString *)messageData {
    NSLog(@"verifying barcode");
    
    // remove url
    messageData = [messageData componentsSeparatedByString:@"/"].lastObject;
    
    // revert url encoding
    messageData = [messageData stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
    messageData = [messageData stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
    
    // add padding
    messageData = [messageData stringByAppendingString:@"="];

    // decode base64
    NSData *signedInfoData = [[NSData alloc] initWithBase64EncodedString:messageData options:NSDataBase64DecodingIgnoreUnknownCharacters];
    
    // parse info data
    FasTSignedInfoBinary *signedInfo = [[FasTSignedInfoBinary alloc] initWithData:signedInfoData];
    if (!signedInfoData) {
        NSLog(@"error parsing signed info");
        return nil;
    }
    
    // find signing key data
    NSData *keyData = nil;
    keyData = keys[signedInfo.signingKeyId];
    if (!keyData) {
        NSLog(@"signing key not found");
        return nil;
    }
    
    // generate hmac digest
    char digest[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, keyData.bytes, keyData.length, signedInfo.signedData.bytes, signedInfo.signedData.length, digest);
    
    // compare generated with given digest (encoded as a hex string)
    if (strncmp(digest, signedInfo.signature.bytes, CC_SHA1_DIGEST_LENGTH)) {
        NSLog(@"signature invalid");
        return nil;
    }

    return signedInfo;
}

+ (void)refreshInfo:(void (^)(NSError *error))completion {
    [FasTApi get:nil parameters:nil completion:^(id _Nullable response, NSError * _Nullable error) {
        if (error) {
            if (completion) completion(error);
            return;
        }
        
        [self processApiResponse:response];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        // we can't save the dictionary directly in user defaults since it doesn't allow null values
        // some IDs in the response might be null
        // we therefore need to convert it to data first
        NSData *responseData = [NSKeyedArchiver archivedDataWithRootObject:response];
        [defaults setObject:responseData forKey:kLastApiResponseDefaultsKey];
        [defaults setObject:[NSDate date] forKey:kLastApiResponseDateDefaultsKey];
        [defaults synchronize];

        if (completion) completion(nil);
    }];
}

+ (void)processApiResponse:(NSDictionary *)response {
    // signing keys
    NSMutableDictionary *_keys = [NSMutableDictionary dictionary];
    for (NSDictionary *key in response[@"signing_keys"]) {
        _keys[key[@"id"]] = [key[@"secret"] dataUsingEncoding:NSUTF8StringEncoding];
    }
    keys = [_keys copy];
    
    // dates
    NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
    [formatter setFormatOptions:NSISO8601DateFormatWithInternetDateTime + NSISO8601DateFormatWithFractionalSeconds];

    NSMutableDictionary *_dates = [NSMutableDictionary dictionary];
    for (NSDictionary *date in response[@"dates"]) {
        _dates[date[@"id"]] = [formatter dateFromString:date[@"date"]];
    }
    dates = [_dates copy];
    
    NSMutableDictionary *_ticketTypes = [NSMutableDictionary dictionary];
    for (NSDictionary *type in response[@"ticket_types"]) {
        _ticketTypes[type[@"id"]] = type[@"name"];
    }
    ticketTypes = [_ticketTypes copy];

    NSMutableDictionary *blockEntrances = [NSMutableDictionary dictionary];
    for (NSDictionary *block in response[@"blocks"]) {
        if ([block[@"entrance"] isKindOfClass:[NSNull class]]) continue;
        
        blockEntrances[block[@"id"]] = block[@"entrance"];
    }

    NSMutableDictionary *_seatEntrances = [NSMutableDictionary dictionary];
    for (NSDictionary *seat in response[@"seats"]) {
        _seatEntrances[seat[@"id"]] = blockEntrances[seat[@"block_id"]];
    }
    seatEntrances = [_seatEntrances copy];
    
    // changed tickets
    for (NSDictionary *ticketInfo in response[@"changed_tickets"]) {
        FasTTicket *ticket = ticketsById[ticketInfo[@"id"]];
        if (!ticket) {
            ticket = [[FasTTicket alloc] init];
            ticketsById[ticketInfo[@"id"]] = ticket;
        }
        ticket.ticketId = ticketInfo[@"id"];
        ticket.date = dates[ticketInfo[@"date_id"]];
        ticket.type = ticketTypes[ticketInfo[@"type_id"]];
        ticket.entrance = seatEntrances[ticketInfo[@"seat_id"]];
        ticket.number = ticketInfo[@"number"];
        ticket.cancelled = ((NSNumber *)ticketInfo[@"cancelled"]).boolValue;
        ticket.seatRange = ticketInfo[@"seat_range"];
    }
}

+ (NSDate *)lastRefresh
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kLastApiResponseDateDefaultsKey];
}

+ (void)clearTickets
{
    [ticketsById removeAllObjects];
    [ticketsByBarcode removeAllObjects];
}

+ (NSDate *)currentDate
{
    for (NSDate *date in dates.allValues) {
        NSDate *startDate = [NSDate dateWithTimeInterval:-kMinutesBeforeDateAllowedForCheckIn * 60 sinceDate:date];
        NSDate *endDate = [NSDate dateWithTimeInterval:kMinutesAfterDateAllowedForCheckIn * 60 sinceDate:date];
        NSDateInterval *interval = [[NSDateInterval alloc] initWithStartDate:startDate endDate:endDate];
        if ([interval containsDate:NSDate.date]) return date;
    }

    return nil;
}

@end
