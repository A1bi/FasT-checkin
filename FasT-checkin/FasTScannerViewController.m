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
#import <AudioToolbox/AudioToolbox.h>

void AudioServicesStopSystemSound(SystemSoundID soundId);
void AudioServicesPlaySystemSoundWithVibration(SystemSoundID soundId, id arg, NSDictionary *vibrationPattern);

@interface FasTScannerViewController ()
{
    AVCaptureSession *session;
    AVCaptureDevice *captureDevice;
    AVCaptureVideoPreviewLayer *preview;
    NSDictionary *successVibration, *failVibration;
    CALayer *targetLayer;
    NSString *lastBarcode;
    FasTScannerBarcodeLayer *lastBarcodeLayer;
}

- (void)initCaptureSession;
- (void)initCapturePreview;
- (void)initBarcodeDetection;
- (void)configureCaptureDevice;
- (void)vibrateWithPattern:(NSDictionary *)pattern;

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
    
    [FasTTicketVerifier init];
}

- (void)dealloc {
    [session release];
    [captureDevice release];
    [successVibration release];
    [failVibration release];
    [lastBarcodeLayer release];
    [lastBarcode release];
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
    preview = [AVCaptureVideoPreviewLayer layerWithSession:session];
    preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    preview.frame = self.view.bounds;
    
    [self.view.layer addSublayer:preview];
    
    targetLayer = [CALayer layer];
    targetLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:targetLayer];
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
        AVMetadataMachineReadableCodeObject *transformedObject = (AVMetadataMachineReadableCodeObject *)[preview transformedMetadataObjectForMetadataObject:object];
        
        NSString *barcodeContent = object.stringValue;
        
        if (![barcodeContent isEqualToString:lastBarcode]) {
            FasTScannerBarcodeLayer *layer = [FasTScannerBarcodeLayer layer];
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
                layer.fillColor = [UIColor redColor].CGColor;
                
                if (ticket.checkedIn) {
                    NSLog(@"ticket already checked in");
                } else if (![ticket isValidToday]) {
                    NSLog(@"ticket is not valid today");
                } else if (ticket.cancelled) {
                    NSLog(@"ticket has been cancelled");
                } else {
//                    ticket.checkedIn = YES;
                    
                    vibration = successVibration;
                    layer.fillColor = [UIColor greenColor].CGColor;
                    
                    NSLog(@"ticket is valid: %@", ticket.number);
                }
                
                [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(vibrateWithPattern:) object:nil];
                [self performSelector:@selector(vibrateWithPattern:) withObject:vibration afterDelay:0.3];
            }
        } else {
            [lastBarcodeLayer setCorners:transformedObject.corners];
            
            if (![targetLayer.sublayers containsObject:lastBarcodeLayer]) {
                [targetLayer addSublayer:lastBarcodeLayer];
            }
        }
    }
}

- (void)vibrateWithPattern:(NSDictionary *)pattern {
    NSLog(@"vibe");
    AudioServicesPlaySystemSoundWithVibration(kSystemSoundID_Vibrate, nil, pattern);
}

@end
