//
//  FasTApi.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 21.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#ifndef API_AUTH_TOKEN
#error "API Auth Token not set"
#endif

#import "FasTApi.h"

@import AFNetworking;

@interface FasTApi ()

+ (AFHTTPSessionManager *)sessionManager;
+ (NSString *)urlForAction:(NSString *)action;

@end

@implementation FasTApi

+ (void)get:(NSString *)action
 parameters:(id)params
    success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
    failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure
{
    [[self sessionManager] GET:[self urlForAction:action] parameters:params progress:nil success:success failure:failure];
}

+ (void)post:(NSString *)action
 parameters:(id)params
    success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success
    failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure
{
    [[self sessionManager] POST:[self urlForAction:action] parameters:params progress:nil success:success failure:failure];
}

+ (AFHTTPSessionManager *)sessionManager
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
        
    NSString *auth = [NSString stringWithFormat:@"Token %@", NSStringize(API_AUTH_TOKEN)];
    [manager.requestSerializer setValue:auth forHTTPHeaderField:@"Authorization"];
    
    return manager;
}

+ (NSString *)urlForAction:(NSString *)action {
    NSString *url = [NSString stringWithFormat:@"%@/api/ticketing/check_ins", NSStringize(API_HOST)];
    if (action) {
        url = [NSString stringWithFormat:@"%@/%@", url, action];
    }
    return url;
}

@end
