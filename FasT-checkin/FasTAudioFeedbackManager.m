//
//  FasTVibrationManager.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 13.10.19.
//  Copyright © 2019 Albisigns. All rights reserved.
//

#import "FasTAudioFeedbackManager.h"

#import <AudioToolbox/AudioToolbox.h>

void AudioServicesStopSystemSound(SystemSoundID soundId);
void AudioServicesPlaySystemSoundWithVibration(SystemSoundID soundId, id arg, NSDictionary *vibrationPattern);

static NSDictionary *successVibrationPattern;
static NSDictionary *warningVibrationPattern;
static NSDictionary *errorVibrationPattern;

@interface FasTAudioFeedbackManager ()

+ (void)vibrateWithPattern:(NSDictionary *)pattern;

@end

@implementation FasTAudioFeedbackManager

+ (void)initialize {
    successVibrationPattern = @{ @"Intensity": @0.5, @"VibePattern": @[ @YES, @100 ] };
    [successVibrationPattern retain];

    warningVibrationPattern = @{ @"Intensity": @0.5, @"VibePattern": @[ @YES, @50, @NO, @50, @YES, @50, @NO, @50, @YES, @50 ] };
    [warningVibrationPattern retain];

    errorVibrationPattern = @{ @"Intensity": @1.0, @"VibePattern": @[ @YES, @500 ] };
    [errorVibrationPattern retain];
}

+ (void)vibrateWithPattern:(NSDictionary *)pattern {
    AudioServicesPlaySystemSoundWithVibration(kSystemSoundID_Vibrate, nil, pattern);
}

+ (void)indicateSuccess {
    [self vibrateWithPattern:successVibrationPattern];
}

+ (void)indicateWarning {
    [self vibrateWithPattern:warningVibrationPattern];
}

+ (void)indicateError {
    [self vibrateWithPattern:errorVibrationPattern];
}
@end
