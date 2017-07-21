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
#import "FasTScannerBarcodeLayer.h"
#import "FasTCheckIn.h"
#import "FasTApi.h"
#import "FasTCheckInManager.h"
#import "FasTStatisticsManager.h"

#import <AudioToolbox/AudioToolbox.h>

void AudioServicesStopSystemSound(SystemSoundID soundId);
void AudioServicesPlaySystemSoundWithVibration(SystemSoundID soundId, id arg, NSDictionary *vibrationPattern);

@interface FasTScannerViewController ()
{
    AVCaptureSession *session;
    AVCaptureDevice *captureDevice;
    AVCaptureVideoPreviewLayer *preview;
    NSDictionary *successVibration, *warningVibration, *failVibration;
    CALayer *targetLayer, *infoLayer;
    CATextLayer *infoTextLayer;
    FasTScannerBarcodeLayer *barcodeLayer;
    NSNumberFormatter *mediumNumberFormatter;
    NSString *lastBarcodeContent;
    UITouch *scanningTouch;
    IBOutlet UILongPressGestureRecognizer *longPressRecognizer;
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
- (IBAction)longDoublePressRecognized;

@end

@implementation FasTScannerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    
    [FasTTicketVerifier init];
}

- (void)dealloc {
    [session release];
    [captureDevice release];
    [successVibration release];
    [warningVibration release];
    [failVibration release];
    [barcodeLayer release];
    [mediumNumberFormatter release];
    [lastBarcodeContent release];
    [infoLayer release];
    [infoTextLayer release];
    [longPressRecognizer release];
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
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    if (devices.count < 1) {
        NSLog(@"no capture devices found");
        return;
    }
    captureDevice = devices[0];
    
    NSError *error;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!error) {
        [session addInput:input];
    } else {
        NSLog(@"error setting up capture device input: %@", error);
    }
}

- (void)initCapturePreview {
    preview = [AVCaptureVideoPreviewLayer layerWithSession:session];
    preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    preview.frame = self.view.bounds;
    
    [self.view.layer addSublayer:preview];
    
    targetLayer = [CALayer layer];
    targetLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:targetLayer];
    
    self.view.multipleTouchEnabled = YES;
}

- (void)initBarcodeDetection {
    AVCaptureMetadataOutput *metadataOutput = [[[AVCaptureMetadataOutput alloc] init] autorelease];
    // add output first so qr code will be available as metadata object type
    [session addOutput:metadataOutput];
    if ([[metadataOutput availableMetadataObjectTypes] containsObject:AVMetadataObjectTypeQRCode]) {
        metadataOutput.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    }
    [metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
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
    scanningTouch = nil;
    longPressRecognizer.enabled = NO;
    
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
    if (!scanningTouch) return;
    
    for (AVMetadataMachineReadableCodeObject *object in metadataObjects) {
        AVMetadataMachineReadableCodeObject *transformedObject = (AVMetadataMachineReadableCodeObject *)[preview transformedMetadataObjectForMetadataObject:object];
        
        NSString *barcodeContent = object.stringValue;
        
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
    
        FasTTicket *ticket = [FasTTicketVerifier getTicketByBarcode:barcodeContent];
        if (!ticket) {
            NSLog(@"barcode invalid");
            
        } else {
            if (![ticket isValidToday]) {
                infoText = @"Gültig für eine andere Aufführung";
                NSLog(@"ticket is not valid today");
            } else if (ticket.cancelled) {
                infoText = @"Ticket ist storniert";
                NSLog(@"ticket has been cancelled");
                
            } else {
                if (!ticket.checkIn) {
                    // TODO: components are already determined in ticket verifier, we should leverage this!
                    NSString *mediumString = [[barcodeContent componentsSeparatedByString:@"--"] lastObject];
                    NSNumber *medium = [mediumNumberFormatter numberFromString:mediumString];
                    [[FasTCheckInManager sharedManager] checkInTicket:ticket withMedium:medium];
                    
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
        
        return;
    }
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

- (void)longDoublePressRecognized
{
    if (longPressRecognizer.state == UIGestureRecognizerStateBegan) {
        [self performSegueWithIdentifier:@"InfoSegue" sender:nil];
    }
}

@end
