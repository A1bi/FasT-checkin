//
//  FasTScannerViewController.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 11.07.16.
//  Copyright © 2016 Albisigns. All rights reserved.
//

#import "FasTScannerViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface FasTScannerViewController ()
{
    AVCaptureSession *session;
}

- (void)initCaptureSession;
- (void)initCapturePreview;

@end

@implementation FasTScannerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initCaptureSession];
    [self initCapturePreview];
}

- (void)dealloc {
    [session release];
    [super dealloc];
}

- (void)viewDidAppear:(BOOL)animated {
    [session startRunning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [session stopRunning];
}

- (void)initCaptureSession {
    session = [[AVCaptureSession alloc] init];
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:devices[0] error:NULL];
    
    [session addInput:input];
}

- (void)initCapturePreview {
    AVCaptureVideoPreviewLayer *preview = [AVCaptureVideoPreviewLayer layerWithSession:session];
    
    preview.bounds = self.view.bounds;
    preview.position = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    [self.view.layer addSublayer:preview];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
