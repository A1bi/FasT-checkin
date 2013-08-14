//
//  FasTScannerViewController.h
//  FasT-checkin
//
//  Created by Albrecht Oster on 12.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ZBarSDK/ZBarReaderViewController.h>

@class AVAudioPlayer;

typedef enum {
    FasTScannerEntranceDirectionIn,
    FasTScannerEntranceDirectionOut
} FasTScannerEntranceDirection;

@interface FasTScannerViewController : ZBarReaderViewController <ZBarReaderDelegate>
{
    NSArray *buttons;
    UIView *colorOverlay;
    FasTScannerEntranceDirection direction;
    AVAudioPlayer *successSound, *errorSound;
}

@end
