//
//  FasTSignedInfoBinary.h
//  FasT-checkin
//
//  Created by Albrecht Oster on 12.07.18.
//  Copyright © 2018 Albisigns. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FasTSignedInfoBinary : NSObject

@property (nonatomic, readonly) NSNumber *signingKeyId;
@property (nonatomic, readonly) NSData *ticketData;
@property (nonatomic, readonly) BOOL authenticated;
@property (nonatomic, readonly) NSNumber *medium;
@property (nonatomic, readonly) NSData *signature;
@property (nonatomic, readonly) NSData *signedData;

- (instancetype)initWithData:(NSData *)data;

@end
