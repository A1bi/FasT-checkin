//
//  FasTScannerResultViewController.h
//  FasT-checkin
//
//  Created by Albrecht Oster on 12.10.19.
//  Copyright © 2019 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FasTTicket;

typedef enum {
    FasTScannerResultAlertTypeSuccess,
    FasTScannerResultAlertTypeWarning,
    FasTScannerResultAlertTypeError
} FasTScannerResultAlertType;

@interface FasTScannerResultViewController : UIViewController

- (void)presentInCorners:(NSArray *)corners;
- (void)showForBarcodeContent:(NSString *)content;

@end
