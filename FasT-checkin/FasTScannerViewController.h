//
//  FasTScannerViewController.h
//  FasT-checkin
//
//  Created by Albrecht Oster on 11.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "FasTScannerResultViewController.h"

@interface FasTScannerViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate, FasTScannerResultViewControllerDelegate>

@end
