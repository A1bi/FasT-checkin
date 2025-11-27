//
//  FasTVibrationManager.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 13.10.19.
//  Copyright © 2019 Albisigns. All rights reserved.
//

#import "FasTAudioFeedbackManager.h"

#import <AVFAudio/AVFAudio.h>

static AVAudioPlayer *successSound, *warningSound, *failureSound;
static UINotificationFeedbackGenerator *feedbackGenerator;

@interface FasTAudioFeedbackManager ()

+ (AVAudioPlayer *)preparePlayerForSound:(NSString *)soundName;

@end

@implementation FasTAudioFeedbackManager

+ (void)initialize {
    successSound = [self preparePlayerForSound:@"success"];
    warningSound = [self preparePlayerForSound:@"warning"];
    failureSound = [self preparePlayerForSound:@"failure"];
    
    feedbackGenerator = [[UINotificationFeedbackGenerator alloc] init];
    [feedbackGenerator prepare];
}

+ (AVAudioPlayer *)preparePlayerForSound:(NSString *)soundName {
    NSURL *soundFile = [[NSBundle mainBundle] URLForResource:soundName withExtension:@"aif"];
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFile error:nil];
    [player prepareToPlay];
    return player;
}

+ (void)indicateSuccess {
    [feedbackGenerator notificationOccurred:UINotificationFeedbackTypeSuccess];
    [successSound play];
}

+ (void)indicateWarning {
    [feedbackGenerator notificationOccurred:UINotificationFeedbackTypeWarning];
    [warningSound play];
}

+ (void)indicateError {
    [feedbackGenerator notificationOccurred:UINotificationFeedbackTypeError];
    [failureSound play];
}
@end
