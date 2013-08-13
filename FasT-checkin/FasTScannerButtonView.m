//
//  FasTScannerButtonView.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 13.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTScannerButtonView.h"

@implementation FasTScannerButtonView

@synthesize direction;

- (id)initWithEntranceDirection:(FasTScannerEntranceDirection)d
{
    self = [super init];
    if (self) {
        direction = d;
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", (direction == FasTScannerEntranceDirectionIn) ? @"in" : @"out"]];
        [self setImage:image forState:UIControlStateNormal];
        [self setFrame:CGRectMake(0, 0, image.size.width, image.size.height)];
    }
    return self;
}

- (void)toggle
{
    [self setAlpha:([self alpha] == 1) ? .5 : 1];
}

@end
