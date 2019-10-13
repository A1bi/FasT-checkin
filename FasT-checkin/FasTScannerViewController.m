//
//  FasTScannerViewController.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 11.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import "FasTScannerViewController.h"
#import "FasTApi.h"
#import "FasTStatisticsManager.h"

@interface FasTScannerViewController ()
{
    AVCaptureSession *session;
    AVCaptureVideoPreviewLayer *preview;
    AVCaptureMetadataOutput *metadataOutput;
    CALayer *targetLayer;
    NSString *lastBarcodeContent;
    UITouch *scanningTouch;
    IBOutlet UILongPressGestureRecognizer *longPressRecognizer;
    NSMutableDictionary *recentScanTimes;
    FasTScannerResultViewController *barcodeResultController;
    BOOL scanningBlocked;
}

- (void)initCaptureSession;
- (void)initCapturePreview;
- (void)initBarcodeDetection;
- (void)initLayers;
- (void)stopScanning;
- (void)clearRecentScanTimes;
- (IBAction)longDoublePressRecognized;

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
    
    [recentScanTimes release];
    recentScanTimes = [[NSMutableDictionary alloc] init];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(clearRecentScanTimes) userInfo:nil repeats:YES];
}

- (void)dealloc {
    [session release];
    [metadataOutput release];
    [lastBarcodeContent release];
    [longPressRecognizer release];
    [recentScanTimes release];
    [barcodeResultController release];
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
    if ([device lockForConfiguration:&error]) {
        if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        }
        if ([device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            device.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        }
        [device unlockForConfiguration];

    } else {
        NSLog(@"error locking capture device configuration: %@", error);
    }

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
    barcodeResultController = [[FasTScannerResultViewController alloc] init];
    barcodeResultController.delegate = self;
    [self.view addSubview:barcodeResultController.view];
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

    [barcodeResultController fadeOutWithCompletion];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (scanningBlocked || scanningTouch) return;

    scanningTouch = touches.anyObject;
    longPressRecognizer.enabled = YES;

    [metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];

    [[FasTStatisticsManager sharedManager] increaseScanAttempts];
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
        NSString *barcodeContent = object.stringValue;
        BOOL theSameAsBefore = [lastBarcodeContent isEqualToString:barcodeContent];
        BOOL newScanAndNewBarcode = !lastBarcodeContent && !recentScanTimes[barcodeContent];
        if (theSameAsBefore || newScanAndNewBarcode) {
            targetBarcode = object;
            break;
        }
    }
    
    if (!targetBarcode) {
        return;
    }
    
    AVMetadataMachineReadableCodeObject *transformedObject = (AVMetadataMachineReadableCodeObject *)[preview transformedMetadataObjectForMetadataObject:targetBarcode];

    dispatch_async(dispatch_get_main_queue(), ^{
        [barcodeResultController presentInCorners:transformedObject.corners];
    });

    NSString *barcodeContent = targetBarcode.stringValue;
    if (lastBarcodeContent) return;

    lastBarcodeContent = [barcodeContent retain];
    [barcodeResultController showForBarcodeContent:barcodeContent];
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

- (void)scannerResultChangedModalViewState:(BOOL)modal {
    if (modal) [self stopScanning];
    scanningBlocked = modal;
}

@end
