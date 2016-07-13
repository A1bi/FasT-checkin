//
//  FasTScannerViewController.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 11.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import "FasTScannerViewController.h"
#import "FasTMessageVerifier.h"

@interface FasTScannerViewController ()
{
    AVCaptureSession *session;
    AVCaptureDevice *captureDevice;
}

- (void)initCaptureSession;
- (void)initCapturePreview;
- (void)initBarcodeDetection;
- (void)configureCaptureDevice;

@end

@implementation FasTScannerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initCaptureSession];
    [self initCapturePreview];
    [self initBarcodeDetection];
    
    [FasTMessageVerifier fetchKeys];
    [FasTMessageVerifier verify:@"eyJrIjo5LCJkIjp7InRpIjoyMSwibm8iOiI0NTk4MzA0LTQiLCJkYSI6NCwidHkiOjIsInNlIjo3MX19--6b58251ebbe87752fed25ff71c9e8151f83506c5"];
}

- (void)dealloc {
    [session release];
    [super dealloc];
}

- (void)viewDidAppear:(BOOL)animated {
    [session startRunning];
    [self configureCaptureDevice];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [session stopRunning];
    [captureDevice unlockForConfiguration];
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
    AVCaptureVideoPreviewLayer *preview = [AVCaptureVideoPreviewLayer layerWithSession:session];
    
    preview.bounds = self.view.bounds;
    preview.position = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    [self.view.layer addSublayer:preview];
}

- (void)initBarcodeDetection {
    AVCaptureMetadataOutput *output = [[[AVCaptureMetadataOutput alloc] init] autorelease];
    // add output first so qr code will be available as metadata object type
    [session addOutput:output];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
}

- (void)configureCaptureDevice {
    NSError *error;
    if ([captureDevice lockForConfiguration:&error]) {
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            captureDevice.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        }
        if (captureDevice.isSmoothAutoFocusEnabled) {
            captureDevice.smoothAutoFocusEnabled = NO;
        }
        if ([captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            captureDevice.exposureMode = AVCaptureExposureModeContinuousAutoExposure;
        }
        
    } else {
        NSLog(@"error locking capture device configuration: %@", error);
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    for (AVMetadataMachineReadableCodeObject *object in metadataObjects) {
        NSString *barcodeContent = object.stringValue;
        NSLog(@"%@", barcodeContent);
    }
}

@end
