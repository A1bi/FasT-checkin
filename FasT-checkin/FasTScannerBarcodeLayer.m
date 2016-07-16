//
//  FasTScannerBarcodeView.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 15.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import "FasTScannerBarcodeLayer.h"
#import "FasTTicket.h"

@implementation FasTScannerBarcodeLayer

- (instancetype)init {
    self = [super init];
    if (self) {
        self.opacity = 0.7;
        self.cornerRadius = 5;
    }
    return self;
}

- (void)setCorners:(NSArray *)corners {
    CGMutablePathRef path = CGPathCreateMutable();
    CGPoint point;
    if (corners.count > 0) {
        CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)[corners firstObject], &point);
        CGPathMoveToPoint(path, nil, point.x, point.y);
        int i = 1;
        while (i < corners.count) {
            CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)corners[i], &point);
            CGPathAddLineToPoint(path, nil, point.x, point.y);
            i++;
        }
        CGPathCloseSubpath(path);
    }
    self.path = path;
    CFRelease(path);
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self performSelector:@selector(remove) withObject:nil afterDelay:2];
}

- (void)remove {
    [self removeFromSuperlayer];
}

@end
