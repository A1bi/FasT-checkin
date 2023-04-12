//
//  FasTVibrationManager.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 13.10.19.
//  Copyright © 2019 Albisigns. All rights reserved.
//

#import "FasTAudioFeedbackManager.h"

#import <AVFAudio/AVFAudio.h>
#import <AudioToolbox/AudioServices.h>

void AudioServicesPlaySystemSoundWithVibration(SystemSoundID soundId, id arg, NSDictionary *vibrationPattern);

static NSDictionary *successVibrationPattern;
static NSDictionary *warningVibrationPattern;
static NSDictionary *errorVibrationPattern;
static AVAudioPlayer *successSound, *warningSound, *failureSound;

@interface FasTAudioFeedbackManager ()

+ (void)vibrateWithPattern:(NSDictionary *)pattern;
+ (AVAudioPlayer *)preparePlayerForSound:(NSString *)soundName;

@end

@implementation FasTAudioFeedbackManager

+ (void)initialize {
    successVibrationPattern = @{ @"Intensity": @0.5, @"VibePattern": @[ @YES, @100 ] };
    warningVibrationPattern = @{ @"Intensity": @0.5, @"VibePattern": @[ @YES, @50, @NO, @50, @YES, @50, @NO, @50, @YES, @50 ] };
    errorVibrationPattern = @{ @"Intensity": @1.0, @"VibePattern": @[ @YES, @500 ] };
    
    successSound = [self preparePlayerForSound:@"success"];
    warningSound = [self preparePlayerForSound:@"warning"];
    failureSound = [self preparePlayerForSound:@"failure"];
}

+ (void)vibrateWithPattern:(NSDictionary *)pattern {
    AudioServicesPlaySystemSoundWithVibration(kSystemSoundID_Vibrate, nil, pattern);
}

+ (AVAudioPlayer *)preparePlayerForSound:(NSString *)soundName {
    NSURL *soundFile = [[NSBundle mainBundle] URLForResource:soundName withExtension:@"aif"];
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFile error:nil];
    [player prepareToPlay];
    return player;
}

+ (void)indicateSuccess {
    [self vibrateWithPattern:successVibrationPattern];
    [successSound play];
}

+ (void)indicateWarning {
    [self vibrateWithPattern:warningVibrationPattern];
    [warningSound play];
}

+ (void)indicateError {
    [self vibrateWithPattern:errorVibrationPattern];
    [failureSound play];
}
@end
