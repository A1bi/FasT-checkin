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
    NSString *lastBarcodeContent;
    UITouch *scanningTouch;
    NSMutableDictionary *recentScanTimes;
    FasTScannerResultViewController *barcodeResultController;
    BOOL scanningBlocked;
}

@property (nonatomic) IBOutlet UILongPressGestureRecognizer *longPressRecognizer;
@property (weak, nonatomic) IBOutlet UIImageView *scanArea;

- (void)initCaptureSession;
- (void)initCapturePreview;
- (void)initBarcodeDetection;
- (void)initLayers;
- (void)stopScanning;
- (void)captureSessionDidStart;
- (void)clearRecentScanTimes;
- (void)setScanningBlocked:(BOOL)blocked;
- (IBAction)longDoublePressRecognized;
- (IBAction)dismissPopover:(UIStoryboardSegue *)unwindSegue;

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
    
    recentScanTimes = [[NSMutableDictionary alloc] init];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(clearRecentScanTimes) userInfo:nil repeats:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self stopScanning];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self->session startRunning];
    });
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(captureSessionDidStart)
                                                 name:AVCaptureSessionDidStartRunningNotification object:nil];

    [session addInput:input];
}

- (void)initCapturePreview {
    preview = [AVCaptureVideoPreviewLayer layerWithSession:session];
    preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    preview.frame = self.view.bounds;
    
    [self.view.layer insertSublayer:preview below:_scanArea.layer];
    
    self.view.multipleTouchEnabled = YES;
}

- (void)initBarcodeDetection {
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
    _longPressRecognizer.enabled = NO;
    
    if (lastBarcodeContent) {
        recentScanTimes[lastBarcodeContent] = [NSDate date];
    }
    
    lastBarcodeContent = nil;

    [barcodeResultController fadeOutWithCompletion];
}

- (void)captureSessionDidStart
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        self->metadataOutput.rectOfInterest = [self->preview metadataOutputRectOfInterestForRect:self->_scanArea.frame];
    });
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (scanningBlocked || scanningTouch) return;

    scanningTouch = touches.anyObject;
    _longPressRecognizer.enabled = YES;

    [metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];

    [[FasTStatisticsManager sharedManager] increaseScanAttempts];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if ([touches containsObject:scanningTouch]) {
        [self stopScanning];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self stopScanning];
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

    [barcodeResultController presentInCorners:transformedObject.corners];

    NSString *barcodeContent = targetBarcode.stringValue;
    if (lastBarcodeContent) return;

    lastBarcodeContent = barcodeContent;
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
    if (_longPressRecognizer.state == UIGestureRecognizerStateBegan) {
        [self performSegueWithIdentifier:@"InfoSegue" sender:nil];
    }
}

- (void)dismissPopover:(UIStoryboardSegue *)unwindSegue {
    [self setScanningBlocked:NO];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    segue.destinationViewController.presentationController.delegate = self;
}

- (void)setScanningBlocked:(BOOL)blocked {
    if (blocked) [self stopScanning];
    scanningBlocked = blocked;
}

#pragma mark presentation controller delegate

- (void)presentationController:(UIPresentationController *)presentationController willPresentWithAdaptiveStyle:(UIModalPresentationStyle)style transitionCoordinator:(id<UIViewControllerTransitionCoordinator>)transitionCoordinator {
    [self setScanningBlocked:YES];
}

- (void)presentationControllerWillDismiss:(UIPresentationController *)presentationController {
    [self setScanningBlocked:NO];
}

#pragma mark scanner result delegate

- (void)scannerResultChangedModalViewState:(BOOL)modal {
    [self setScanningBlocked:modal];
}

@end
