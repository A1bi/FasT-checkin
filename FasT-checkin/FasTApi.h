//
//  FasTApi.h
//  FasT-checkin
//
//  Created by Albrecht Oster on 21.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FasTApi : NSObject

+ (void)get:(nullable NSString *)action
 parameters:(nullable id)params
    success:(nullable void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
    failure:(nullable void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure;

+ (void)post:(nullable NSString *)action
 parameters:(nullable id)params
    success:(nullable void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
    failure:(nullable void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure;

@end
