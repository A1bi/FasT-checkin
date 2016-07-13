//
//  FasTTicketVerifier.h
//  FasT-checkin
//
//  Created by Albrecht Oster on 13.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FasTTicketValidator : NSObject

+ (void)fetchInfo;
+ (NSNumber *)validate:(NSString *)messageData;

@end
