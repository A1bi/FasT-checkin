//
//  FasTMessageVerifier.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 12.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import "FasTMessageVerifier.h"
#import <CommonCrypto/CommonHMAC.h>

static NSArray *keys = nil;

@implementation FasTMessageVerifier

+ (void)fetchKeys {
    NSMutableArray *_keys = [NSMutableArray array];
    for (NSInteger i = 0; i < 10; i++) {
        NSString *key = @"12345676";
        [_keys addObject:[key dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [keys release];
    keys = [[_keys copy] retain];
}

+ (NSDictionary *)verify:(NSString *)message {
    message = [message stringByReplacingOccurrencesOfString:@"~" withString:@"+"];
    message = [message stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
    message = [message stringByReplacingOccurrencesOfString:@"," withString:@"="];
    
    NSArray *parts = [message componentsSeparatedByString:@"--"];
    if (parts.count < 2) {
        NSLog(@"ticket parts not found");
        return nil;
    }
    NSString *ticketData = parts[0];
    NSString *signature = parts[1];

    NSError *error = nil;
    NSData *ticketDataJson = [[NSData alloc] initWithBase64EncodedString:ticketData options:0];
    NSDictionary *ticketInfo = [NSJSONSerialization JSONObjectWithData:ticketDataJson options:0 error:&error];
    if (error) {
        NSLog(@"error parsing ticket json data: %@", error);
        return nil;
    }
    
    NSNumber *keyId = ticketInfo[@"k"];
    NSDictionary *ticketInfoPayload = ticketInfo[@"d"];
    if (!keyId || !ticketInfoPayload) {
        NSLog(@"ticket lacks essential info");
        return nil;
    }
    
    NSData *keyData = nil;
    if ([keyId isKindOfClass:[NSNumber class]]) {
        keyData = keys[keyId.integerValue];
    }
    if (!keyData) {
        NSLog(@"signing key not found");
        return nil;
    }
    
    char digest[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, keyData.bytes, keyData.length, ticketData.UTF8String, ticketData.length, digest);
    
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
