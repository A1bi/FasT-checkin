//
//  FasTVibrationManager.h
//  FasT-checkin
//
//  Created by Albrecht Oster on 13.10.19.
//  Copyright © 2019 Albisigns. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FasTAudioFeedbackManager : NSObject

+ (void)indicateSuccess;
+ (void)indicateWarning;
+ (void)indicateError;

@end
