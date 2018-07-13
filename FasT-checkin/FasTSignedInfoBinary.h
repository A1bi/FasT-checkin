//
//  FasTSignedInfoBinary.h
//  FasT-checkin
//
//  Created by Albrecht Oster on 12.07.18.
//  Copyright © 2018 Albisigns. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FasTSignedInfoBinary : NSObject

@property (readonly) NSNumber *signingKeyId;
@property (readonly) NSData *ticketData;
@property (readonly) BOOL authenticated;
@property (readonly) NSNumber *medium;
@property (readonly) NSData *signature;
@property (readonly) NSData *signedData;

- (instancetype)initWithData:(NSData *)data;

@end
