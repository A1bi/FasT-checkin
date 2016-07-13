//
//  FasTMessageVerifier.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 12.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import "FasTTicketVerifier.h"
#import <CommonCrypto/CommonHMAC.h>

static NSDictionary *keys = nil;

@implementation FasTTicketVerifier

+ (void)setKeys:(NSDictionary *)k {
    NSMutableDictionary *_keys = [NSMutableDictionary dictionary];
    for (NSNumber *keyId in k) {
        _keys[keyId] = [k[keyId] dataUsingEncoding:NSUTF8StringEncoding];
    }
    [keys release];
    keys = [[_keys copy] retain];
}

+ (NSDictionary *)verify:(NSString *)messageData {
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

@end
