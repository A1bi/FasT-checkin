//
//  FasTMessageVerifier.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 12.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import "FasTTicketVerifier.h"
#import "FasTTicket.h"
#import "FasTApi.h"
#import <CommonCrypto/CommonHMAC.h>

#define kLastApiResponseDefaultsKey @"lastApiResponse"

static NSDictionary *keys = nil;
static NSDictionary *dates = nil;
static NSDictionary *ticketTypes = nil;
static NSMutableDictionary *ticketsById = nil;
static NSMutableDictionary *ticketsByBarcode = nil;

@interface FasTTicketVerifier ()

+ (NSDictionary *)verify:(NSString *)messageData;
+ (void)fetchInfoFromServer;
+ (void)processApiResponse:(NSDictionary *)response;

@end

@implementation FasTTicketVerifier

+ (void)init {
    [ticketsById release];
    ticketsById = [[NSMutableDictionary alloc] init];
    
    [ticketsByBarcode release];
    ticketsByBarcode = [[NSMutableDictionary alloc] init];
    
    [self fetchInfoFromServer];
}

+ (FasTTicket *)getTicketByBarcode:(NSString *)messageData {
    // check if this message has already been processed
    FasTTicket *ticket = ticketsByBarcode[messageData];
    if (!ticket) {
        // not yet processed -> verify
        NSDictionary *ticketInfo = [self verify:messageData];
        
        if (ticketInfo) {
            @try {
                NSNumber *ticketId = ticketInfo[@"ti"];
                // check if ticket is already in memory
                ticket = ticketsById[ticketId];
                if (!ticket) {
                    // create new ticket instance
                    ticket = [[[FasTTicket alloc] init] autorelease];
                    ticket.ticketId = ticketId;
                    ticket.date = dates[ticketInfo[@"da"]];
                    ticket.type = ticketTypes[ticketInfo[@"ty"]];
                    ticket.number = ticketInfo[@"no"];
                    ticketsById[ticketId] = ticket;
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

+ (NSDictionary *)verify:(NSString *)messageData {
    NSLog(@"verifying barcode");
    
    // remove url
    messageData = [messageData componentsSeparatedByString:@"/"].lastObject;
    
    // revert url encoding
    messageData = [messageData stringByReplacingOccurrencesOfString:@"~" withString:@"+"];
    messageData = [messageData stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
    messageData = [messageData stringByReplacingOccurrencesOfString:@"," withString:@"="];
    
    // separate data and digest
    NSArray *parts = [messageData componentsSeparatedByString:@"--"];
    if (parts.count < 2) {
        NSLog(@"ticket parts not found");
        return nil;
    }
    NSString *ticketData = parts[0];
    NSString *signature = parts[1];

    // decode ticket base64 and json data
    NSError *error = nil;
    NSData *ticketDataJson = [[[NSData alloc] initWithBase64EncodedString:ticketData options:0] autorelease];
    NSDictionary *ticketInfo = [NSJSONSerialization JSONObjectWithData:ticketDataJson options:0 error:&error];
    if (error) {
        NSLog(@"error parsing ticket json data: %@", error);
        return nil;
    }
    
    // get key id from ticket data
    NSNumber *keyId = ticketInfo[@"k"];
    NSDictionary *ticketInfoPayload = ticketInfo[@"d"];
    if (!keyId || !ticketInfoPayload) {
        NSLog(@"ticket lacks essential info");
        return nil;
    }
    
    NSData *keyData = nil;
    if ([keyId isKindOfClass:[NSNumber class]]) {
        keyData = keys[keyId];
    }
    if (!keyData) {
        NSLog(@"signing key not found");
        return nil;
    }
    
    // generate hmac digest
    char digest[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, keyData.bytes, keyData.length, ticketData.UTF8String, ticketData.length, digest);
    
    // compare generated with given digest (encoded as a hex string)
    char signatureByte[3] = "";
    char byte;
    for (NSInteger i = 0; i < sizeof(digest); i++) {
        signatureByte[0] = [signature characterAtIndex:i*2];
        signatureByte[1] = [signature characterAtIndex:i*2+1];
        byte = (char)strtol(signatureByte, NULL, 16);
        if (byte != digest[i]) {
            NSLog(@"signature invalid");
            return nil;
        }
    }

    return ticketInfoPayload;
}

+ (void)fetchInfoFromServer {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [FasTApi get:nil parameters:nil success:^(NSURLSessionDataTask *task, id response) {
        [self processApiResponse:response];
        [defaults setObject:response forKey:kLastApiResponseDefaultsKey];
        [defaults synchronize];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSDictionary *response = [defaults objectForKey:kLastApiResponseDefaultsKey];
        if (response) {
            [self processApiResponse:response];
        }
    }];
}

+ (void)processApiResponse:(NSDictionary *)response {
    // signing keys
    NSMutableDictionary *_keys = [NSMutableDictionary dictionary];
    for (NSDictionary *key in response[@"signing_keys"]) {
        _keys[key[@"id"]] = [key[@"secret"] dataUsingEncoding:NSUTF8StringEncoding];
    }
    [keys release];
    keys = [_keys copy];
    
    // dates
    NSMutableDictionary *_dates = [NSMutableDictionary dictionary];
    for (NSDictionary *date in response[@"dates"]) {
        _dates[date[@"id"]] = [NSDate dateWithTimeIntervalSince1970:((NSNumber *)date[@"date"]).integerValue];
    }
    [dates release];
    dates = [_dates copy];
    
    NSMutableDictionary *_ticketTypes = [NSMutableDictionary dictionary];
    for (NSDictionary *type in response[@"ticket_types"]) {
        _ticketTypes[type[@"id"]] = type[@"name"];
    }
    [ticketTypes release];
    ticketTypes = [_ticketTypes copy];
    
    // changed tickets
    for (NSDictionary *ticketInfo in response[@"changed_tickets"]) {
        FasTTicket *ticket = ticketsById[ticketInfo[@"id"]];
        if (!ticket) {
            ticket = [[[FasTTicket alloc] init] autorelease];
            ticketsById[ticketInfo[@"id"]] = ticket;
        }
        ticket.ticketId = ticketInfo[@"id"];
        ticket.date = dates[ticketInfo[@"date_id"]];
        ticket.type = ticketTypes[ticketInfo[@"type_id"]];
        ticket.number = ticketInfo[@"number"];
        ticket.cancelled = ((NSNumber *)ticketInfo[@"cancelled"]).boolValue;
    }
}

@end
