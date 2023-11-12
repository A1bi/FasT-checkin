//
//  FasTScanResult.h
//  FasT-checkin
//
//  Created by Albrecht Oster on 12.11.23.
//  Copyright © 2023 Albisigns. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class FasTSignedInfoBinary, FasTTicket;

@interface FasTScanResult : NSObject

@property (nonatomic, readonly) FasTSignedInfoBinary *signedInfoBinary;
@property (nonatomic, readonly) FasTTicket *ticket;

- (instancetype)initWithSignedInfoBinary:(FasTSignedInfoBinary *)signedInfo ticket:(FasTTicket *)ticket;

@end

NS_ASSUME_NONNULL_END
