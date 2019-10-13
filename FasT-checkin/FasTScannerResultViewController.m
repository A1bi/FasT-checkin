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
#import "FasTAudioFeedbackManager.h"

#define kMinutesBeforeDateAllowedForCheckIn 90
#define kMinutesAfterDateAllowedForCheckIn 45
#define kFrameMargin 20

typedef enum {
    FasTScannerResultTypeSuccess,
    FasTScannerResultTypeWarning,
    FasTScannerResultTypeError
} FasTScannerResultType;

typedef enum {
    FasTScannerResultViewStateHidden,
    FasTScannerResultViewStateSimple,
    FasTScannerResultViewStateDetailed
} FasTScannerResultViewState;

@interface FasTScannerResultViewController () {
    CGRect originalFrame;
    FasTScannerResultViewState viewState;
}

@property (retain, nonatomic) IBOutlet UILabel *titleLabel;
@property (retain, nonatomic) IBOutlet UIButton *dismissButton;

- (void)setSuccessTitle:(NSString *)title description:(NSString *)description;
- (void)setErrorTitle:(NSString *)title description:(NSString *)description;
- (void)setResultType:(FasTScannerResultType)type;
- (void)setTitle:(NSString *)title description:(NSString *)description;
- (void)toggleSimpleView:(BOOL)toggle;
- (void)toggleDetailedView:(BOOL)toggle;
- (void)updateDetailedSize;
- (NSDate *)currentDate;
- (IBAction)dismissDetailedView;

@end

@implementation FasTScannerResultViewController

- (instancetype)init {
    self = [super initWithNibName:@"FasTScannerResultViewController" bundle:nil];
    if (self) {
        [FasTAudioFeedbackManager initialize];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.layer.anchorPoint = CGPointZero;
    [self toggleSimpleView:NO];
    [self dismissDetailedView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self updateDetailedSize];
}

- (void)presentInCorners:(NSArray *)corners {
    if (corners.count < 1 || viewState == FasTScannerResultViewStateDetailed) return;

    CGPoint points[corners.count];
    for (int i = 0; i < corners.count; i++) {
        CGPoint point;
        CGPointMakeWithDictionaryRepresentation((CFDictionaryRef)corners[i], &point);
        points[i] = point;
    }

    // I'm using 3D transforms because with 2D transform I encountered an
    // animation bug that caused the animation to jump at the start
    // see https://stackoverflow.com/questions/27931421
    // seems to be fixed in iOS 13, though, so we could go back to CGAffineTransform

    // we assume that these rects are all squares so we calculate only width and use it as height
    CGFloat width = sqrt(pow(points[3].x - points[0].x, 2) + pow(points[3].y - points[0].y, 2));
    CGFloat scale = width / originalFrame.size.width;
    CATransform3D scaling = CATransform3DMakeScale(scale, scale, 1);
    CATransform3D translation = CATransform3DMakeTranslation(points[0].x, points[0].y, 1);

    CGFloat deltaX = points[0].x - points[1].x;
    CGFloat deltaY = points[0].y - points[1].y;
    double angle = -atan(deltaX / deltaY);
    if (deltaY > 0) {
        angle += M_PI;
    }
    CATransform3D rotation = CATransform3DMakeRotation(angle, 0, 0, 1);

    CATransform3D transform = CATransform3DConcat(rotation, scaling);
    transform = CATransform3DConcat(transform, translation);

    NSTimeInterval duration = viewState == FasTScannerResultViewStateHidden ? 0 : 0.2;
    [UIView animateWithDuration:duration animations:^{
        self.view.layer.transform = transform;
    } completion:NULL];

    if (viewState == FasTScannerResultViewStateHidden) {
        [self toggleSimpleView:YES];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self toggleDetailedView:YES];
        });
    }
}

- (void)showForBarcodeContent:(NSString *)content {
    FasTStatisticsManager *stats = [FasTStatisticsManager sharedManager];

    FasTSignedInfoBinary *signedInfo;
    FasTTicket *ticket = [FasTTicketVerifier getTicketByBarcode:content signedInfo:&signedInfo];
    if (!ticket) {
        [self setErrorTitle:@"Ticket ungültig" description:@"Barcode ungültig."];
        [stats increaseDeniedScans];

    } else {
        if (![ticket isValidForDate:[self currentDate]]) {
            [self setErrorTitle:@"Ticket ungültig" description:@"Ticket gilt für einen anderen Termin."];
            [stats increaseDeniedScans];

        } else if (ticket.cancelled) {
            [self setErrorTitle:@"Ticket ungültig" description:@"Ticket wurde storniert."];
            [stats increaseDeniedScans];

        } else {
            if (!ticket.checkIn) {
                [[FasTCheckInManager sharedManager] checkInTicket:ticket withMedium:signedInfo.medium];
                [stats addCheckIn:ticket.checkIn];

                [self setErrorTitle:@"Ticket gültig" description:[NSString stringWithFormat:@"%@ – %@ – OK", ticket.number, ticket.type]];

            } else {
                [self setResultType:FasTScannerResultTypeWarning];

                [stats addDuplicateCheckIn:ticket.checkIn];
            }
        }
    }

    [self cancelFadeOut];
}

- (void)fadeOutWithCompletion {
    if (viewState != FasTScannerResultViewStateSimple) return;

    [UIView animateWithDuration:1.0 animations:^{
        self.view.layer.opacity = 0;

    } completion:^(BOOL finished) {
        // animation was cancelled midway?
        if (!finished) {
            // restore layer
            [self toggleSimpleView:YES];
            return;
        }
        
        [self toggleSimpleView:NO];
    }];
}

- (void)cancelFadeOut {
    [self.view.layer removeAllAnimations];
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
            [FasTAudioFeedbackManager indicateSuccess];
            break;

        case FasTScannerResultTypeWarning:
            color = [UIColor systemYellowColor];
            [FasTAudioFeedbackManager indicateWarning];
            break;

        default:
            color = [UIColor systemRedColor];
            [FasTAudioFeedbackManager indicateError];
    }
    self.view.backgroundColor = color;
}

- (void)setTitle:(NSString *)title description:(NSString *)description {
    _titleLabel.text = title;
}

- (void)toggleSimpleView:(BOOL)toggle {
    viewState = toggle ? FasTScannerResultViewStateSimple : FasTScannerResultViewStateHidden;

    self.view.layer.opacity = toggle ? 0.9 : 0;
    self.view.userInteractionEnabled = NO;
    _titleLabel.layer.opacity = 0;
    _dismissButton.layer.opacity = 0;
}

- (void)toggleDetailedView:(BOOL)toggle {
    viewState = toggle ? FasTScannerResultViewStateDetailed : FasTScannerResultViewStateHidden;

    if (toggle) {
        [UIView animateWithDuration:0.7 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            CGFloat y = (self.view.superview.frame.size.height - originalFrame.size.width) / 2;

            CATransform3D transform = CATransform3DIdentity;
            transform = CATransform3DScale(transform, 1, 1, 1);
            transform = CATransform3DTranslate(transform, kFrameMargin, y, 1);
            self.view.layer.transform = transform;
        } completion:NULL];
    }

    [UIView animateWithDuration:0.3 animations:^{
        self.view.layer.opacity = toggle ? 1 : 0;
        _titleLabel.layer.opacity = toggle ? 1 : 0;
        _dismissButton.layer.opacity = toggle ? 1 : 0;
    } completion:NULL];

    self.view.userInteractionEnabled = toggle;
}

- (IBAction)dismissDetailedView {
    [self toggleDetailedView:NO];
}

- (void)updateDetailedSize {
    CGSize parentSize = self.view.superview.frame.size;
    CGFloat width = parentSize.width - kFrameMargin * 2;
    self.view.frame = CGRectMake(0, 0, width, width);
    originalFrame = self.view.frame;
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
