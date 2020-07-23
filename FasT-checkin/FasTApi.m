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

@interface FasTApi ()

+ (void)makeRequestWithMethod:(NSString *)method action:(NSString *)action parameters:(NSDictionary *)params data:(NSDictionary *)data completion:(nullable void (^)(id _Nullable response, NSError * _Nullable error))completion;
+ (NSURLSession *)session;
+ (NSURL *)urlForAction:(NSString *)action params:(NSDictionary *)params;

@end

@implementation FasTApi

+ (void)get:(NSString *)action parameters:(NSDictionary *)params completion:(void (^)(id _Nullable, NSError * _Nullable))completion
{
    [self makeRequestWithMethod:@"GET" action:nil parameters:params data:nil completion:completion];
}

+ (void)post:(NSString *)action data:(NSDictionary *)data completion:(void (^)(id _Nullable, NSError * _Nullable))completion
{
    [self makeRequestWithMethod:@"POST" action:nil parameters:nil data:data completion:completion];
}

+ (void)makeRequestWithMethod:(NSString *)method action:(NSString *)action parameters:(NSDictionary *)params data:(NSDictionary *)data completion:(nullable void (^)(id _Nullable, NSError * _Nullable))completion {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[self urlForAction:action params:params]];
    request.HTTPMethod = method;
    
    if (data) {
        NSData *body = [NSJSONSerialization dataWithJSONObject:data options:kNilOptions error:nil];
        request.HTTPBody = body;
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    }
    
    NSURLSessionDataTask *task = [[self session] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!completion) return;
        
        NSDictionary *jsonResponse;
        if (data) {
            jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        }
        completion(jsonResponse, error);
    }];
    
    [task resume];
}

+ (NSURLSession *)session {
    static NSURLSession *sharedSession = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSString *auth = [NSString stringWithFormat:@"Token %@", NSStringize(API_AUTH_TOKEN)];
        config.HTTPAdditionalHeaders = @{ @"Accept": @"application/json", @"Authorization": auth };
        sharedSession = [NSURLSession sessionWithConfiguration:config];
    });
    return sharedSession;
}

+ (NSURL *)urlForAction:(NSString *)action params:(NSDictionary *)params {
    NSString *url = [NSString stringWithFormat:@"%@/api/ticketing/check_ins", NSStringize(API_HOST)];
    if (action) {
        url = [NSString stringWithFormat:@"%@/%@", url, action];
    }

    NSURLComponents *components = [NSURLComponents componentsWithString:url];

    if (params) {
        NSMutableArray *queryItems = [NSMutableArray array];
        for (NSString *key in params) {
            [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:params[key]]];
        }
        components.queryItems = queryItems;
    }

    return components.URL;
}

@end
