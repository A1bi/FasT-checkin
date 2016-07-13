//
//  FasTMessageVerifier.h
//  FasT-checkin
//
//  Created by Albrecht Oster on 12.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FasTTicketVerifier : NSObject

+ (void)setKeys:(NSDictionary *)k;
+ (NSDictionary *)verify:(NSString *)messageData;

@end
