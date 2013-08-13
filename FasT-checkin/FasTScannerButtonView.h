//
//  FasTScannerButtonView.h
//  FasT-checkin
//
//  Created by Albrecht Oster on 13.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FasTScannerViewController.h"

@interface FasTScannerButtonView : UIButton
{
    FasTScannerEntranceDirection direction;
}

@property (nonatomic, readonly) FasTScannerEntranceDirection direction;

- (id)initWithEntranceDirection:(FasTScannerEntranceDirection)direction;
- (void)toggle;

@end
