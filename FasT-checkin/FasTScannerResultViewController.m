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

#define kFrameMargin 20
#define kCurrentEntranceDefaultsKey @"currentEntrance"

typedef enum {
    FasTScannerResultTypeSuccess,
    FasTScannerResultTypeWarning,
    FasTScannerResultTypeError,
    FasTScannerResultTypePending
} FasTScannerResultType;

typedef enum {
    FasTScannerResultViewStateHidden,
    FasTScannerResultViewStateSimple,
    FasTScannerResultViewStateDetailed
} FasTScannerResultViewState;

@interface FasTScannerResultViewController () {
    CGRect originalFrame;
    FasTScannerResultType resultType;
    FasTScannerResultViewState viewState;
    BOOL transitioningToDetailedView;
}

@property (retain, nonatomic) IBOutlet UILabel *titleLabel;
@property (retain, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (retain, nonatomic) IBOutlet UIButton *dismissButton;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

- (void)setSuccessTitle:(NSString *)title description:(NSString *)description;
- (void)setWarningTitle:(NSString *)title description:(NSString *)description;
- (void)setErrorTitle:(NSString *)title description:(NSString *)description;
- (void)setResultType:(FasTScannerResultType)type;
- (void)setTitle:(NSString *)title description:(NSString *)description;
- (void)toggleSimpleView:(BOOL)toggle;
- (void)toggleDetailedView:(BOOL)toggle;
- (void)transitionToDetailedView;
- (void)updateDetailedSize;
- (IBAction)dismissDetailedView;
- (void)runOnMainThread:(void (^)(void))block;
- (NSString *)currentEntrance;

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
    // prevent initial flashing
    self.view.layer.opacity = 0;
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
    [self runOnMainThread:^{
        [UIView animateWithDuration:duration animations:^{
            self.view.layer.transform = transform;
        } completion:NULL];
    }];

    [self toggleSimpleView:YES];
}

- (void)showForBarcodeContent:(NSString *)content {
    FasTStatisticsManager *stats = [FasTStatisticsManager sharedManager];
    
    if ([content characterAtIndex:0] == '{') {
        NSError *error = nil;
        NSDictionary *instruction = [NSJSONSerialization JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
        
        if (error) {
            [self setErrorTitle:@"Barcode ungültig" description:@"Instruction Code konnte nicht gelesen werden."];
        
        } else {
            if ([instruction[@"action"] isEqualToString:@"set_entrance"]) {
                NSString *entrance = instruction[@"entrance"];
                
                [[NSUserDefaults standardUserDefaults] setObject:entrance forKey:kCurrentEntranceDefaultsKey];
                
                [self setSuccessTitle:@"Eingang geändert" description:[NSString stringWithFormat:@"Der aktuelle Eingang wurde geändert auf „%@“.", entrance]];
            
            } else if ([instruction[@"action"] isEqualToString:@"submit_check_ins"]) {
                [self setResultType:FasTScannerResultTypePending];
                
                FasTCheckInManager *manager = [FasTCheckInManager sharedManager];
                NSInteger numCheckIns = manager.checkInsToSubmit.count;
                
                [manager submitCheckIns:^(NSError *error) {
                    NSString *description;
                    
                    if (error) {
                        description = [NSString stringWithFormat:@"Bei der Übertragung der Check-Ins ist folgender Fehler aufgetreten: %@", error];
                        [self setErrorTitle:@"Fehler bei der Übertragung" description:description];
                    
                    } else {
                        description = [NSString stringWithFormat:@"Es wurden erfolgreich %ld Check-Ins übertragen.", (long)numCheckIns];
                        [self setSuccessTitle:@"Check-Ins übertragen" description:description];
                    }
                }];
            
            } else if ([instruction[@"action"] isEqualToString:@"refresh_info"]) {
                [self setResultType:FasTScannerResultTypePending];
                
                [FasTTicketVerifier refreshInfo:^(NSError *error) {
                    if (error) {
                        NSString *description = [NSString stringWithFormat:@"Bei der Aktualisierung der Daten ist folgender Fehler aufgetreten: %@", error];
                        [self setErrorTitle:@"Fehler bei der Aktualisierung" description:description];
                    
                    } else {
                        [self setSuccessTitle:@"Daten aktualisiert" description:@"Die Daten wurden erfolgreich aktualisiert."];
                    }
                }];
            }
            
            [self transitionToDetailedView];
        }
    
    } else {
        FasTSignedInfoBinary *signedInfo;
        FasTTicket *ticket = [FasTTicketVerifier getTicketByBarcode:content signedInfo:&signedInfo];
        if (!ticket) {
            [self setErrorTitle:@"Ticket ungültig" description:@"Barcode ungültig."];
            [stats increaseDeniedScans];

        } else {
            if (![ticket isValidForDate:[FasTTicketVerifier currentDate]]) {
                [self setErrorTitle:@"Ticket ungültig" description:@"Ticket gilt für einen anderen Termin."];
                [stats increaseDeniedScans];

            } else if (ticket.cancelled) {
                [self setErrorTitle:@"Ticket ungültig" description:@"Ticket wurde storniert."];
                [stats increaseDeniedScans];

            } else if (![ticket isValidAtEntrance:[self currentEntrance]]) {
                [self setErrorTitle:@"Falscher Eingang" description:[NSString stringWithFormat:@"Der Sitzplatz dieses Tickets ist nicht über diesen Eingang erreichbar.\nDieses Ticket wird nur am Eingang „%@“ akzeptiert.", ticket.entrance]];
                [stats increaseDeniedScans];

            } else {
                if (!ticket.checkIn) {
                    [[FasTCheckInManager sharedManager] checkInTicket:ticket withMedium:signedInfo.medium];
                    [stats addCheckIn:ticket.checkIn];

                    [self setSuccessTitle:@"Ticket gültig" description:[NSString stringWithFormat:@"%@ – %@ – OK", ticket.number, ticket.type]];

                } else {
                    [self setWarningTitle:@"Ticket bereits gescannt" description:@"Dieses Ticket ist zwar gültig, wurde jedoch bereits vor Kurzem von diesem Gerät gescannt."];

                    [stats addDuplicateCheckIn:ticket.checkIn];
                }
            }
        }
    }

    [self cancelFadeOut];
}

- (void)fadeOutWithCompletion {
    if (transitioningToDetailedView || viewState != FasTScannerResultViewStateSimple) return;

    [self runOnMainThread:^{
        [UIView animateWithDuration:1.0 animations:^{
            self.view.layer.opacity = 0;

        } completion:^(BOOL finished) {
            if (!finished) return;

            [self toggleSimpleView:NO];
        }];
    }];
}

- (void)cancelFadeOut {
    [self runOnMainThread:^{
        [self.view.layer removeAllAnimations];
    }];
}

- (void)setSuccessTitle:(NSString *)title description:(NSString *)description {
    [self setResultType:FasTScannerResultTypeSuccess];
    [self setTitle:title description:description];
}

- (void)setWarningTitle:(NSString *)title description:(NSString *)description {
    [self setResultType:FasTScannerResultTypeWarning];
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
            
        case FasTScannerResultTypePending:
            color = [UIColor systemBlueColor];
            break;

        default:
            color = [UIColor systemRedColor];
            [FasTAudioFeedbackManager indicateError];
    }

    [self runOnMainThread:^{
        self.view.backgroundColor = color;
    }];

    if (type != FasTScannerResultTypeSuccess || resultType == FasTScannerResultTypePending) {
        [self transitionToDetailedView];
    }
    
    resultType = type;
}

- (void)setTitle:(NSString *)title description:(NSString *)description {
    [self runOnMainThread:^{
        _titleLabel.text = title;
        _descriptionLabel.text = description;
    }];
}

- (void)toggleSimpleView:(BOOL)toggle {
    viewState = toggle ? FasTScannerResultViewStateSimple : FasTScannerResultViewStateHidden;

    [self runOnMainThread:^{
        self.view.layer.opacity = toggle ? 0.9 : 0;
        self.view.userInteractionEnabled = NO;
        _titleLabel.layer.opacity = 0;
        _descriptionLabel.layer.opacity = 0;
        _dismissButton.layer.opacity = 0;
        [_activityIndicator stopAnimating];
    }];
}

- (void)toggleDetailedView:(BOOL)toggle {
    viewState = toggle ? FasTScannerResultViewStateDetailed : FasTScannerResultViewStateHidden;

    [self runOnMainThread:^{
        if (toggle) {
            [UIView animateWithDuration:0.7 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                CGFloat y = (self.view.superview.frame.size.height - originalFrame.size.width) / 2;

                CATransform3D transform = CATransform3DIdentity;
                transform = CATransform3DScale(transform, 1, 1, 1);
                transform = CATransform3DTranslate(transform, kFrameMargin, y, 1);
                self.view.layer.transform = transform;
            } completion:^(BOOL finished) {
                transitioningToDetailedView = NO;
            }];
        }

        [UIView animateWithDuration:toggle ? 0.3 : 0.2 animations:^{
            self.view.layer.opacity = toggle ? 1 : 0;
            self.view.layer.cornerRadius = toggle ? 20 : 0;
            
            BOOL inDetailedView = viewState == FasTScannerResultViewStateDetailed;
            BOOL isPending = resultType == FasTScannerResultTypePending;
            BOOL showLabelsAndButtons = inDetailedView && !isPending;
            
            _titleLabel.layer.opacity = showLabelsAndButtons ? 1 : 0;
            _descriptionLabel.layer.opacity = showLabelsAndButtons ? 1 : 0;
            _dismissButton.layer.opacity = showLabelsAndButtons ? 1 : 0;
            
            if (inDetailedView && isPending) {
                [_activityIndicator startAnimating];
            } else {
                [_activityIndicator stopAnimating];
            }
        } completion:NULL];

        self.view.userInteractionEnabled = toggle;
    }];
}

- (void)transitionToDetailedView {
    if (viewState == FasTScannerResultViewStateDetailed) {
        [self toggleDetailedView:YES];
        return;
    }
    
    transitioningToDetailedView = YES;
    [self.delegate scannerResultChangedModalViewState:YES];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self toggleDetailedView:YES];
    });
}

- (IBAction)dismissDetailedView {
    [self toggleDetailedView:NO];
    [self.delegate scannerResultChangedModalViewState:NO];
}

- (void)updateDetailedSize {
    CGSize parentSize = self.view.superview.frame.size;
    CGFloat width = parentSize.width - kFrameMargin * 2;
    self.view.frame = CGRectMake(0, 0, width, width);
    originalFrame = self.view.frame;
}

- (void)runOnMainThread:(void (^)(void))block {
    dispatch_async(dispatch_get_main_queue(), block);
}

- (NSString *)currentEntrance {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kCurrentEntranceDefaultsKey];
}

- (void)dealloc {
    [_titleLabel release];
    [_dismissButton release];
    [_descriptionLabel release];
    [_activityIndicator release];
    [super dealloc];
}

@end
