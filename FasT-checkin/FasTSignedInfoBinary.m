//
//  FasTSignedInfoBinary.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 12.07.18.
//  Copyright © 2018 Albisigns. All rights reserved.
//

#import "FasTSignedInfoBinary.h"

@implementation FasTSignedInfoBinary

- (instancetype)initWithData:(NSData *)data {
    self = [super init];
    if (self) {
        char part;
        [data getBytes:&part range:NSMakeRange(0, 1)];
        
        // format version - bits 0-3
        char version = part >> 4;
        if (version != 1) {
            NSLog(@"Unknown version of signed info format.");
            return nil;
        }
        
        // signing key id - bits 4-11
        // set first nibble
        short signingKeyId = part & 0xf;
        // set second nibble from second byte
        [data getBytes:&part range:NSMakeRange(1, 1)];
        signingKeyId |= (part >> 4);
        _signingKeyId = @(signingKeyId);
        
        // info type id - bits 12-15
        char infoType = part & 0xf;
        if (infoType != 0) {
            NSLog(@"Unsupported ticket info type.");
            return nil;
        }
        
        // ticket data - 9 bytes
        _ticketData = [data subdataWithRange:NSMakeRange(2, 9)];
        
        [data getBytes:&part range:NSMakeRange(11, 1)];
        
        // authenticated - bits 88-91
        _authenticated = (part >> 4) == 1;
        
        // medium - bits 92-95
        _medium = @(part);
        
        // signature - 20 bytes
        _signature = [data subdataWithRange:NSMakeRange(12, 20)];
        
        // signed data - everything except the signature
        _signedData = [data subdataWithRange:NSMakeRange(0, 12)];
    }
    return self;
}

@end
