//
//  FasTBackgroundWorker.h
//  FasT-checkin
//
//  Created by Albrecht Oster on 10.10.23.
//  Copyright © 2023 Albisigns. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FasTBackgroundWorker : NSObject

- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
