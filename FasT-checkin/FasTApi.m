//
//  FasTApi.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 21.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import "FasTApi.h"
#import <AFNetworking.h>

#ifndef DEBUG
#define API_HOST @"https://www.theater-kaisersesch.de"
#endif

@interface FasTApi ()

+ (NSString *)urlForAction:(NSString *)action;

@end

@implementation FasTApi

+ (void)get:(NSString *)action
 parameters:(id)params
    success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
    failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure
{
    [[AFHTTPSessionManager manager] GET:[self urlForAction:action] parameters:params progress:nil success:success failure:failure];
}

+ (void)post:(NSString *)action
 parameters:(id)params
    success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
    failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure
{
    [[AFHTTPSessionManager manager] GET:[self urlForAction:action] parameters:params progress:nil success:success failure:failure];
}

+ (NSString *)urlForAction:(NSString *)action {
    NSString *url = [NSString stringWithFormat:@"%@/api/check_in", API_HOST];
    if (action) {
        url = [NSString stringWithFormat:@"%@/%@", url, action];
    }
    return url;
}

@end
