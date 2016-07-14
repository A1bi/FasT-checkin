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
#import <AudioToolbox/AudioToolbox.h>

void AudioServicesStopSystemSound(SystemSoundID soundId);
void AudioServicesPlaySystemSoundWithVibration(SystemSoundID soundId, id arg, NSDictionary *vibrationPattern);

@interface FasTScannerViewController ()
{
    AVCaptureSession *session;
    AVCaptureDevice *captureDevice;
    NSDictionary *successVibration, *failVibration;
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
    
    [successVibration release];
    successVibration = [@{ @"Intensity": @0.5, @"VibePattern": @[ @YES, @100 ] } retain];
    [failVibration release];
    failVibration = [@{ @"Intensity": @1.0, @"VibePattern": @[ @YES, @100, @NO, @100, @YES, @100, @NO, @100, @YES, @100 ] } retain];
    
    [FasTTicketVerifier init];
}

- (void)dealloc {
    [session release];
    [captureDevice release];
    [successVibration release];
    [failVibration release];
    [super dealloc];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [session startRunning];
    [self configureCaptureDevice];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
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
    if ([[output availableMetadataObjectTypes] containsObject:AVMetadataObjectTypeQRCode]) {
        output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    }
}

- (void)configureCaptureDevice {
    if (captureDevice) {
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
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    for (AVMetadataMachineReadableCodeObject *object in metadataObjects) {
        NSString *barcodeContent = object.stringValue;
        
        NSDictionary *vibration = nil;
        
        FasTTicket *ticket = [FasTTicketVerifier getTicketByBarcode:barcodeContent];
        if (!ticket) {
            NSLog(@"barcode invalid");
        } else if (ticket.checkedIn) {
            NSLog(@"ticket already checked in");
        } else if (![ticket isValidToday]) {
            NSLog(@"ticket is not valid today");
        } else if (ticket.cancelled) {
            NSLog(@"ticket has been cancelled");
        } else {
            ticket.checkedIn = YES;
            
            vibration = successVibration;
            
            NSLog(@"ticket is valid: %@", ticket.number);
        }
        
        AudioServicesPlaySystemSoundWithVibration(kSystemSoundID_Vibrate, nil, vibration);
    }
}

@end
