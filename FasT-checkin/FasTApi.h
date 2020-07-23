//
//  FasTApi.h
//  FasT-checkin
//
//  Created by Albrecht Oster on 21.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FasTApi : NSObject

+ (void)get:(nullable NSString *)action parameters:(nullable NSDictionary *)params completion:(nullable void (^)(id _Nullable data, NSError * _Nullable error))completion;

+ (void)post:(nullable NSString *)action data:(nullable NSDictionary *)data completion:(nullable void (^)(id _Nullable data, NSError * _Nullable error))completion;

@end
