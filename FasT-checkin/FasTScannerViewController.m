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
#import <AudioToolbox/AudioToolbox.h>

void AudioServicesStopSystemSound(SystemSoundID soundId);
void AudioServicesPlaySystemSoundWithVibration(SystemSoundID soundId, id arg, NSDictionary *vibrationPattern);

#define kCheckInsToSubmitDefaultsKey @"checkInsToSubmit"

@interface FasTScannerViewController ()
{
    AVCaptureSession *session;
    AVCaptureDevice *captureDevice;
    AVCaptureVideoPreviewLayer *preview;
    NSDictionary *successVibration, *failVibration;
    CALayer *targetLayer;
    NSString *lastBarcode;
    NSMutableArray *checkInsToSubmit;
    FasTScannerBarcodeLayer *lastBarcodeLayer;
    NSNumberFormatter *mediumNumberFormatter;
    BOOL scanning;
}

- (void)initCaptureSession;
- (void)initCapturePreview;
- (void)initBarcodeDetection;
- (void)configureCaptureDeviceForFocusPoint:(CGPoint)focusPoint;
- (void)configureCaptureDeviceForAutoFocus;
- (void)configureCaptureDevice:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode focusPoint:(CGPoint)focusPoint;
- (void)startScanning;
- (void)stopScanning;
- (void)vibrateWithPattern:(NSDictionary *)pattern;
- (void)submitCheckIns;
- (void)scheduleCheckInSubmission;
- (void)persistCheckIns;
- (void)loadPersistedCheckIns;

@end

@implementation FasTScannerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initCaptureSession];
    [self initCapturePreview];
    [self initBarcodeDetection];
    
    [successVibration release];
    successVibration = [@{ @"Intensity": @0.5, @"VibePattern": @[ @YES, @100 ] } retain];
    [failVibration release];
    failVibration = [@{ @"Intensity": @1.0, @"VibePattern": @[ @YES, @500 ] } retain];
    
    checkInsToSubmit = [[NSMutableArray alloc] init];
    
    mediumNumberFormatter = [[NSNumberFormatter alloc] init];
    mediumNumberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    [FasTTicketVerifier init];
    
    [self loadPersistedCheckIns];
    [self submitCheckIns];
    
    NSNotificationCenter* defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [self persistCheckIns];
    }];
    [defaultCenter addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        [self loadPersistedCheckIns];
    }];
}

- (void)dealloc {
    [session release];
    [captureDevice release];
    [successVibration release];
    [failVibration release];
    [lastBarcodeLayer release];
    [lastBarcode release];
    [checkInsToSubmit release];
    [mediumNumberFormatter release];
    [super dealloc];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [session startRunning];
    [self stopScanning];
}

- (void)viewWillDisappear:(BOOL)animated
{
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

- (void)startScanning
{
    scanning = YES;
}

- (void)stopScanning
{
    scanning = NO;
    [self configureCaptureDeviceForAutoFocus];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = touches.anyObject;
    CGPoint location = [touch locationInView:self.view];
    location = [preview captureDevicePointOfInterestForPoint:location];
    
    [self configureCaptureDeviceForFocusPoint:location];
    
    [self startScanning];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self stopScanning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (!scanning) return;
    
    for (AVMetadataMachineReadableCodeObject *object in metadataObjects) {
        AVMetadataMachineReadableCodeObject *transformedObject = (AVMetadataMachineReadableCodeObject *)[preview transformedMetadataObjectForMetadataObject:object];
        
        NSString *barcodeContent = object.stringValue;
        
        if (![barcodeContent isEqualToString:lastBarcode]) {
            FasTScannerBarcodeLayer *layer = [FasTScannerBarcodeLayer layer];
            layer.fillColor = [UIColor redColor].CGColor;
            [targetLayer addSublayer:layer];
            
            [lastBarcodeLayer remove];
            [lastBarcodeLayer release];
            lastBarcodeLayer = [layer retain];
            [lastBarcode release];
            lastBarcode = [barcodeContent retain];
            
            NSDictionary *vibration = failVibration;
        
            FasTTicket *ticket = [FasTTicketVerifier getTicketByBarcode:barcodeContent];
            if (!ticket) {
                NSLog(@"barcode invalid");
                
            } else {
                if (![ticket isValidToday]) {
                    NSLog(@"ticket is not valid today");
                } else if (ticket.cancelled) {
                    NSLog(@"ticket has been cancelled");
                } else {
                    if (!ticket.checkIn) {
                        // TODO: components are already determined in ticket verifier, we should leverage this!
                        NSString *mediumString = [[barcodeContent componentsSeparatedByString:@"--"] lastObject];
                        NSNumber *medium = [mediumNumberFormatter numberFromString:mediumString];
                        FasTCheckIn *checkIn = [[[FasTCheckIn alloc] initWithTicket:ticket medium:medium] autorelease];
                        ticket.checkIn = checkIn;
                        [checkInsToSubmit addObject:ticket.checkIn];
                    }
                    
                    vibration = successVibration;
                    layer.fillColor = [UIColor greenColor].CGColor;
                    
                    NSLog(@"ticket is valid: %@", ticket.number);
                }
            }
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(vibrateWithPattern:) object:nil];
            [self performSelector:@selector(vibrateWithPattern:) withObject:vibration afterDelay:0.3];
            
        } else {
            [lastBarcodeLayer setCorners:transformedObject.corners];
            
            if (![targetLayer.sublayers containsObject:lastBarcodeLayer]) {
                [targetLayer addSublayer:lastBarcodeLayer];
            }
        }
        
        [self stopScanning];
        return;
    }
}

- (void)vibrateWithPattern:(NSDictionary *)pattern {
    NSLog(@"vibe");
    AudioServicesPlaySystemSoundWithVibration(kSystemSoundID_Vibrate, nil, pattern);
}

- (void)submitCheckIns {
    NSMutableArray *checkIns = [NSMutableArray array];
    for (FasTCheckIn *checkIn in checkInsToSubmit) {
        NSDictionary *info = @{ @"ticket_id": checkIn.ticketId, @"date": @(checkIn.date.timeIntervalSince1970), @"medium": checkIn.medium };
        [checkIns addObject:info];
    }
    
    if (checkIns.count < 1) {
        [self scheduleCheckInSubmission];
        return;
    }
    
    NSArray *_checkInsToSubmit = [checkInsToSubmit copy];
    [FasTApi post:nil parameters:@{ @"check_ins": checkIns } success:^(NSURLSessionDataTask *task, id response) {
        if (((NSNumber *)response[@"ok"]).boolValue) {
            [checkInsToSubmit removeObjectsInArray:_checkInsToSubmit];
        }
        [self scheduleCheckInSubmission];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        [self scheduleCheckInSubmission];
    }];
}

- (void)scheduleCheckInSubmission {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scheduleCheckInSubmission) object:nil];
    [self performSelector:@selector(submitCheckIns) withObject:nil afterDelay:60];
}

// if internet connection is not available save check ins for later submission
- (void)persistCheckIns {
    if (checkInsToSubmit.count < 1) {
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *checkInsToPersist = [[defaults objectForKey:kCheckInsToSubmitDefaultsKey] mutableCopy];
    if (!checkInsToPersist) {
        checkInsToPersist = [NSMutableArray array];
    }
    
    for (FasTCheckIn *checkIn in checkInsToSubmit) {
        NSDictionary *info = @{ @"ticketId": checkIn.ticketId, @"date": checkIn.date, @"medium": checkIn.medium };
        [checkInsToPersist addObject:info];
    }
    [checkInsToSubmit removeAllObjects];
    
    [defaults setObject:checkInsToPersist forKey:kCheckInsToSubmitDefaultsKey];
    [defaults synchronize];
}

- (void)loadPersistedCheckIns {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // are there check ins from older sessions yet to submit ?
    NSArray *checkInsLeftOver = [defaults objectForKey:kCheckInsToSubmitDefaultsKey];
    for (NSDictionary *checkInInfo in checkInsLeftOver) {
        FasTCheckIn *checkIn = [[[FasTCheckIn alloc] initWithTicketId:checkInInfo[@"ticketId"] medium:checkInInfo[@"medium"] date:checkInInfo[@"date"]] autorelease];
        [checkInsToSubmit addObject:checkIn];
    }
    [defaults removeObjectForKey:kCheckInsToSubmitDefaultsKey];
}

@end
