//
//  FasTScanResult.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 12.11.23.
//  Copyright © 2023 Albisigns. All rights reserved.
//

#import "FasTScanResult.h"
#import "FasTSignedInfoBinary.h"
#import "FasTTicket.h"

@implementation FasTScanResult

- (instancetype)initWithSignedInfoBinary:(FasTSignedInfoBinary *)signedInfo ticket:(FasTTicket *)ticket {
    self = [super init];
    if (self) {
        _signedInfoBinary = signedInfo;
        _ticket = ticket;
    }
    return self;
}

@end
