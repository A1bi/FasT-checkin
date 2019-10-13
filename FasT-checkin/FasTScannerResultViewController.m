//
//  FasTScannerResultViewController.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 12.10.19.
//  Copyright © 2019 Albisigns. All rights reserved.
//

#import "FasTCheckInManager.h"
#import "FasTScannerResultViewController.h"
#import "FasTSignedInfoBinary.h"
#import "FasTStatisticsManager.h"
#import "FasTTicket.h"
#import "FasTTicketVerifier.h"

#define kMinutesBeforeDateAllowedForCheckIn 90
#define kMinutesAfterDateAllowedForCheckIn 45

typedef enum {
    FasTScannerResultTypeSuccess,
    FasTScannerResultTypeWarning,
    FasTScannerResultTypeError
} FasTScannerResultType;

@interface FasTScannerResultViewController () {
    CGRect originalFrame;
}

@property (retain, nonatomic) IBOutlet UILabel *titleLabel;
@property (retain, nonatomic) IBOutlet UIButton *dismissButton;

- (void)setSuccessTitle:(NSString *)title description:(NSString *)description;
- (void)setErrorTitle:(NSString *)title description:(NSString *)description;
- (void)setResultType:(FasTScannerResultType)type;
- (void)setTitle:(NSString *)title description:(NSString *)description;
- (void)toggleDetailedView:(BOOL)toggle;
- (NSDate *)currentDate;

@end

@implementation FasTScannerResultViewController

- (instancetype)init {
    return [super initWithNibName:@"FasTScannerResultViewController" bundle:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    originalFrame = self.view.layer.frame;

    self.view.layer.hidden = YES;
    self.view.layer.anchorPoint = CGPointZero;
}

- (void)presentInCorners:(NSArray *)corners {
    if (corners.count < 1) return;

    CGPoint points[corners.count];
    for (int i = 0; i < corners.count; i++) {
        CGPoint point;
        CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)corners[i], &point);
        points[i] = point;
    }

    // we assume that these rects are all squares so we calculate only width and use it as height
    CGFloat width = sqrt(pow(points[3].x - points[0].x, 2) + pow(points[3].y - points[0].y, 2));
    CGFloat scale = width / originalFrame.size.width;
    CGAffineTransform scaling = CGAffineTransformMakeScale(scale, scale);

    CGAffineTransform translation = CGAffineTransformMakeTranslation(-CGRectGetMidX(originalFrame) + points[0].x,
                                                                     -CGRectGetMidY(originalFrame) + points[0].y);

    CGFloat deltaX = points[0].x - points[1].x;
    CGFloat deltaY = points[0].y - points[1].y;
    double angle = -atan(deltaX / deltaY);
    if (deltaY > 0) {
        angle += M_PI;
    }
    CGAffineTransform rotation = CGAffineTransformMakeRotation(angle);

    CGAffineTransform transform = CGAffineTransformConcat(rotation, scaling);
    transform = CGAffineTransformConcat(transform, translation);

    NSTimeInterval duration = self.view.layer.hidden ? 0 : 0.2;
    [UIView animateWithDuration:duration animations:^{
        self.view.layer.affineTransform = transform;
    } completion:NULL];

    self.view.layer.hidden = NO;
}

- (void)showForBarcodeContent:(NSString *)content {
    FasTStatisticsManager *stats = [FasTStatisticsManager sharedManager];

    FasTSignedInfoBinary *signedInfo;
    FasTTicket *ticket = [FasTTicketVerifier getTicketByBarcode:content signedInfo:&signedInfo];
    if (!ticket) {
        [self setErrorTitle:@"Ticket ungültig" description:@"Barcode ungültig."];

    } else {
        if (![ticket isValidForDate:[self currentDate]]) {
            [self setErrorTitle:@"Ticket ungültig" description:@"Ticket gilt für einen anderen Termin."];

        } else if (ticket.cancelled) {
            [self setErrorTitle:@"Ticket ungültig" description:@"Ticket wurde storniert."];

        } else {
            if (!ticket.checkIn) {
                [[FasTCheckInManager sharedManager] checkInTicket:ticket withMedium:signedInfo.medium];

                [self setErrorTitle:@"Ticket gültig" description:[NSString stringWithFormat:@"%@ – %@ – OK", ticket.number, ticket.type]];
//                vibration = successVibration;

                [stats addCheckIn:ticket.checkIn];

            } else {
                [self setResultType:FasTScannerResultTypeWarning];
//                vibration = warningVibration;

                [stats addDuplicateCheckIn:ticket.checkIn];
            }
        }
    }

//    if (fillColor == UIColor.redColor) {
//        [stats increaseDeniedScans];
//    }
}

- (void)setSuccessTitle:(NSString *)title description:(NSString *)description {
    [self setResultType:FasTScannerResultTypeSuccess];
    [self setTitle:title description:description];
}

- (void)setErrorTitle:(NSString *)title description:(NSString *)description {
    [self setResultType:FasTScannerResultTypeError];
    [self setTitle:title description:description];
}

- (void)setResultType:(FasTScannerResultType)type {
    UIColor *color;
    switch (type) {
        case FasTScannerResultTypeSuccess:
            color = [UIColor systemGreenColor];
            break;

        case FasTScannerResultTypeWarning:
            color = [UIColor systemYellowColor];
            break;

        default:
            color = [UIColor systemRedColor];
    }
    self.view.backgroundColor = color;
}

- (void)setTitle:(NSString *)title description:(NSString *)description {
    _titleLabel.text = title;
}

- (void)toggleDetailedView:(BOOL)toggle {
    [UIView animateWithDuration:1.0 delay:1.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        _titleLabel.layer.opacity = 1.0;
        _dismissButton.layer.opacity = 1.0;
    } completion:NULL];
}

- (NSDate *)currentDate
{
    for (NSDate *date in [FasTTicketVerifier dates]) {
        NSDate *startDate = [NSDate dateWithTimeInterval:-kMinutesBeforeDateAllowedForCheckIn * 60 sinceDate:date];
        NSDate *endDate = [NSDate dateWithTimeInterval:kMinutesAfterDateAllowedForCheckIn * 60 sinceDate:date];
        NSDateInterval *interval = [[[NSDateInterval alloc] initWithStartDate:startDate endDate:endDate] autorelease];
        if ([interval containsDate:NSDate.date]) return date;
    }

    return nil;
}

- (void)dealloc {
    [_titleLabel release];
    [_dismissButton release];
    [super dealloc];
}
@end
