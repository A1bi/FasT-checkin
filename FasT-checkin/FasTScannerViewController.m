//
//  FasTScannerViewController.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 11.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import "FasTScannerViewController.h"
#import "FasTTicketVerifier.h"
#import "FasTTicket.h"
#import "FasTSignedInfoBinary.h"
#import "FasTScannerBarcodeLayer.h"
#import "FasTCheckIn.h"
#import "FasTApi.h"
#import "FasTCheckInManager.h"
#import "FasTStatisticsManager.h"

#import <AudioToolbox/AudioToolbox.h>

#define kMinutesBeforeDateAllowedForCheckIn 90
#define kMinutesAfterDateAllowedForCheckIn 45

void AudioServicesStopSystemSound(SystemSoundID soundId);
void AudioServicesPlaySystemSoundWithVibration(SystemSoundID soundId, id arg, NSDictionary *vibrationPattern);

@interface FasTScannerViewController ()
{
    AVCaptureSession *session;
    AVCaptureDevice *captureDevice;
    AVCaptureVideoPreviewLayer *preview;
    AVCaptureMetadataOutput *metadataOutput;
    NSDictionary *successVibration, *warningVibration, *failVibration;
    CALayer *targetLayer, *infoLayer;
    CATextLayer *infoTextLayer;
    FasTScannerBarcodeLayer *barcodeLayer;
    NSNumberFormatter *mediumNumberFormatter;
    NSString *lastBarcodeContent;
    UITouch *scanningTouch;
    IBOutlet UILongPressGestureRecognizer *longPressRecognizer;
    NSMutableDictionary *recentScanTimes;
}

- (void)initCaptureSession;
- (void)initCapturePreview;
- (void)initBarcodeDetection;
- (void)initLayers;
- (void)configureCaptureDeviceForFocusPoint:(CGPoint)focusPoint;
- (void)configureCaptureDeviceForAutoFocus;
- (void)configureCaptureDevice:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode focusPoint:(CGPoint)focusPoint;
- (void)stopScanning;
- (void)vibrateWithPattern:(NSDictionary *)pattern;
- (void)setInfoLayerText:(NSString *)text withBackgroundColor:(UIColor *)color;
- (void)clearRecentScanTimes;
- (IBAction)longDoublePressRecognized;
- (NSDate *)currentDate;

@end

@implementation FasTScannerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:@"statistics"]) {
        [defaults removeObjectForKey:@"checkInsToSubmit"];
    }
    
    [self initCaptureSession];
    [self initCapturePreview];
    [self initBarcodeDetection];
    [self initLayers];
    
    [successVibration release];
    successVibration = [@{ @"Intensity": @0.5, @"VibePattern": @[ @YES, @100 ] } retain];
    [warningVibration release];
    warningVibration = [@{ @"Intensity": @0.5, @"VibePattern": @[ @YES, @50, @NO, @50, @YES, @50, @NO, @50, @YES, @50 ] } retain];
    [failVibration release];
    failVibration = [@{ @"Intensity": @1.0, @"VibePattern": @[ @YES, @500 ] } retain];
    
    mediumNumberFormatter = [[NSNumberFormatter alloc] init];
    mediumNumberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    [recentScanTimes release];
    recentScanTimes = [[NSMutableDictionary alloc] init];
    
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(clearRecentScanTimes) userInfo:nil repeats:YES];
    
    [FasTTicketVerifier init];
}

- (void)dealloc {
    [session release];
    [captureDevice release];
    [metadataOutput release];
    [successVibration release];
    [warningVibration release];
    [failVibration release];
    [barcodeLayer release];
    [mediumNumberFormatter release];
    [lastBarcodeContent release];
    [infoLayer release];
    [infoTextLayer release];
    [longPressRecognizer release];
    [recentScanTimes release];
    [super dealloc];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [session startRunning];
    [self stopScanning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self stopScanning];
    [session stopRunning];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)initCaptureSession {
    session = [[AVCaptureSession alloc] init];

    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithDeviceType: AVCaptureDeviceTypeBuiltInWideAngleCamera
                                                                 mediaType: AVMediaTypeVideo
                                                                  position: AVCaptureDevicePositionBack];

    if (!device) {
        NSLog(@"no capture devices found");
        return;
    }
    
    NSError *error;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (error) {
        NSLog(@"error setting up capture device input: %@", error);
        return;
    }

    [session addInput:input];
}

- (void)initCapturePreview {
    [preview release];
    preview = [[AVCaptureVideoPreviewLayer layerWithSession:session] retain];
    preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    preview.frame = self.view.bounds;
    
    [self.view.layer addSublayer:preview];
    
    targetLayer = [CALayer layer];
    targetLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:targetLayer];
    
    self.view.multipleTouchEnabled = YES;
}

- (void)initBarcodeDetection {
    [metadataOutput release];
    metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    // add output first so qr code will be available as metadata object type
    [session addOutput:metadataOutput];
    if ([[metadataOutput availableMetadataObjectTypes] containsObject:AVMetadataObjectTypeQRCode]) {
        metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    }
}

- (void)initLayers
{
    [barcodeLayer removeFromSuperlayer];
    [barcodeLayer release];
    barcodeLayer = [[FasTScannerBarcodeLayer layer] retain];
    [targetLayer addSublayer:barcodeLayer];
    
    [infoLayer removeFromSuperlayer];
    [infoLayer release];
    infoLayer = [[CALayer layer] retain];
    infoLayer.backgroundColor = [UIColor blueColor].CGColor;
    infoLayer.opacity = 0.75;
    infoLayer.frame = CGRectMake(0, 0, self.view.frame.size.width, 65);
    infoLayer.hidden = YES;
    [targetLayer addSublayer:infoLayer];
    
    [infoTextLayer removeFromSuperlayer];
    [infoTextLayer release];
    infoTextLayer = [[CATextLayer layer] retain];
    infoTextLayer.fontSize = 28;
    infoTextLayer.alignmentMode = kCAAlignmentCenter;
    infoTextLayer.frame = CGRectMake(10, 20, infoLayer.frame.size.width - 20, 40);
    infoTextLayer.contentsScale = [[UIScreen mainScreen] scale];
    infoTextLayer.hidden = YES;
    [targetLayer addSublayer:infoTextLayer];
}

- (void)configureCaptureDeviceForFocusPoint:(CGPoint)focusPoint {
    [self configureCaptureDevice:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose focusPoint:focusPoint];
}

- (void)configureCaptureDeviceForAutoFocus {
    [self configureCaptureDevice:AVCaptureFocusModeContinuousAutoFocus exposureMode:AVCaptureExposureModeContinuousAutoExposure focusPoint:CGPointZero];
}

- (void)configureCaptureDevice:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode focusPoint:(CGPoint)focusPoint {
    if (captureDevice) {
        NSError *error;
        if ([captureDevice lockForConfiguration:&error]) {
            if ([captureDevice isFocusModeSupported:focusMode]) {
                captureDevice.focusMode = focusMode;
            }
            if (focusMode == AVCaptureFocusModeAutoFocus && [captureDevice isFocusPointOfInterestSupported]) {
                captureDevice.focusPointOfInterest = focusPoint;
            }
            if ([captureDevice isExposureModeSupported:exposureMode]) {
                captureDevice.exposureMode = exposureMode;
            }
            [captureDevice unlockForConfiguration];
            
        } else {
            NSLog(@"error locking capture device configuration: %@", error);
        }
    }
}

- (void)stopScanning
{
    [metadataOutput setMetadataObjectsDelegate:nil queue:dispatch_get_main_queue()];
    
    scanningTouch = nil;
    longPressRecognizer.enabled = NO;
    
    if (lastBarcodeContent) {
        recentScanTimes[lastBarcodeContent] = [NSDate date];
    }
    
    [lastBarcodeContent release];
    lastBarcodeContent = nil;
    
    [self configureCaptureDeviceForAutoFocus];
    
    barcodeLayer.hidden = YES;
    infoLayer.hidden = YES;
    infoTextLayer.hidden = YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (!scanningTouch) {
        scanningTouch = touches.anyObject;
        longPressRecognizer.enabled = YES;
        
        CGPoint location = [scanningTouch locationInView:self.view];
        location = [preview captureDevicePointOfInterestForPoint:location];
        
        [metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        
        [self configureCaptureDeviceForFocusPoint:location];
        
        [[FasTStatisticsManager sharedManager] increaseScanAttempts];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if ([touches containsObject:scanningTouch]) {
        [self stopScanning];
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (!scanningTouch || metadataObjects.count < 1) return;
    
    AVMetadataMachineReadableCodeObject *targetBarcode = nil;
    for (AVMetadataMachineReadableCodeObject *object in metadataObjects) {
        BOOL theSameAsBefore = lastBarcodeContent && [lastBarcodeContent isEqualToString:object.stringValue];
        BOOL newScanAndNewBarcode = !lastBarcodeContent && !recentScanTimes[object.stringValue];
        if (theSameAsBefore || newScanAndNewBarcode) {
            targetBarcode = object;
            break;
        }
    }
    
    if (!targetBarcode) {
        return;
    }
    
    AVMetadataMachineReadableCodeObject *transformedObject = (AVMetadataMachineReadableCodeObject *)[preview transformedMetadataObjectForMetadataObject:targetBarcode];
    
    NSString *barcodeContent = targetBarcode.stringValue;
    
    BOOL showLayer = !lastBarcodeContent || [barcodeContent isEqualToString:lastBarcodeContent];
    if (showLayer) {
        [barcodeLayer setCorners:transformedObject.corners];
    }
    barcodeLayer.hidden = !showLayer;
    
    if (lastBarcodeContent) return;
    lastBarcodeContent = [barcodeContent retain];
    
    UIColor *fillColor = [UIColor redColor];
    NSString *infoText = @"Ungültiger Barcode";
    NSDictionary *vibration = failVibration;
    
    FasTStatisticsManager *stats = [FasTStatisticsManager sharedManager];

    FasTSignedInfoBinary *signedInfo;
    FasTTicket *ticket = [FasTTicketVerifier getTicketByBarcode:barcodeContent signedInfo:&signedInfo];
    if (!ticket) {
        NSLog(@"barcode invalid");
        
    } else {
        if (![ticket isValidForDate:[self currentDate]]) {
            infoText = @"Gültig für einen anderen Termin";
            NSLog(@"ticket is not valid today");

        } else if (ticket.cancelled) {
            infoText = @"Ticket ist storniert";
            NSLog(@"ticket has been cancelled");
            
        } else {
            if (!ticket.checkIn) {
                [[FasTCheckInManager sharedManager] checkInTicket:ticket withMedium:signedInfo.medium];
                
                fillColor = [UIColor greenColor];
                vibration = successVibration;
                
                [stats addCheckIn:ticket.checkIn];
                
            } else {
                fillColor = [UIColor yellowColor];
                vibration = warningVibration;
                
                [stats addDuplicateCheckIn:ticket.checkIn];
            }
            
            infoText = [NSString stringWithFormat:@"%@ – %@ – OK", ticket.number, ticket.type];
            NSLog(@"ticket is valid: %@", ticket.number);
        }
    }
    
    if (fillColor == UIColor.redColor) {
        [stats increaseDeniedScans];
    }

    barcodeLayer.fillColor = fillColor.CGColor;
    barcodeLayer.hidden = NO;
    [self setInfoLayerText:infoText withBackgroundColor:fillColor];
    
    [self vibrateWithPattern:vibration];
}

- (void)vibrateWithPattern:(NSDictionary *)pattern {
    AudioServicesPlaySystemSoundWithVibration(kSystemSoundID_Vibrate, nil, pattern);
}

- (void)setInfoLayerText:(NSString *)text withBackgroundColor:(UIColor *)color
{
    float fontSize = 28;
    CGSize fontBounds = CGSizeMake(1000, 1000);
    while (fontBounds.width >= infoTextLayer.frame.size.width - 10) {
        fontSize -= 0.1f;
        UIFont *font = [UIFont systemFontOfSize:fontSize];
        fontBounds = [text sizeWithAttributes:@{NSFontAttributeName: font}];
    }
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    infoTextLayer.fontSize = fontSize;
    infoTextLayer.string = text;
    
    [CATransaction commit];
    
    infoTextLayer.hidden = NO;
    
    infoLayer.backgroundColor = color.CGColor;
    infoLayer.hidden = NO;
}

- (void)clearRecentScanTimes {
    NSArray *contents = recentScanTimes.allKeys;
    for (NSString *content in contents) {
        NSDate *time = recentScanTimes[content];
        if ([time timeIntervalSinceNow] < -2) {
            [recentScanTimes removeObjectForKey:content];
            NSLog(@"removed recent scan");
        }
    }
}

- (void)longDoublePressRecognized
{
    if (longPressRecognizer.state == UIGestureRecognizerStateBegan) {
        [self performSegueWithIdentifier:@"InfoSegue" sender:nil];
    }
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

@end
