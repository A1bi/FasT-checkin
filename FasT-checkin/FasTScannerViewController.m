//
//  FasTScannerViewController.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 12.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTScannerViewController.h"
#import "FasTScannerButtonView.h"
#import "FasTApi.h"
#import "MBProgressHUD.h"
#import "QuartzCore/QuartzCore.h"
#import "AVFoundation/AVAudioSession.h"
#import "AVFoundation/AVAudioPlayer.h"

@interface FasTScannerViewController ()

- (NSDictionary *)parseTicketData:(ZBarSymbolSet *)data;
- (void)checkInWithInfo:(NSDictionary *)info;
- (void)tappedButton:(FasTScannerButtonView *)button;
- (void)enableScanner:(BOOL)enabled;
- (void)showColorOverlayWithSuccess:(BOOL)success messageKey:(NSString *)messageKey;

@end

@implementation FasTScannerViewController

- (id)init
{
    self = [super init];
    if (self) {
        [self setReaderDelegate:self];
        [self enableScanner:YES];
        [self setShowsZBarControls:NO];
        
        UIView *overlay = [[UIView alloc] initWithFrame:self.view.bounds];
        [self setCameraOverlayView:overlay];
        
        NSMutableArray *btns = [NSMutableArray array];
        int x = 0;
        for (NSNumber *d in @[@(FasTScannerEntranceDirectionIn), @(FasTScannerEntranceDirectionOut)]) {
            FasTScannerButtonView *button = [[[FasTScannerButtonView alloc] initWithEntranceDirection:[d intValue]] autorelease];
            CGRect frame = button.frame;
            frame.origin.x = x;
            button.frame = frame;
            x += frame.size.width;
            [overlay addSubview:button];
            
            [button addTarget:self action:@selector(tappedButton:) forControlEvents:UIControlEventTouchUpInside];
            [btns addObject:button];
        }
        buttons = [[NSArray arrayWithArray:btns] retain];
        [[buttons lastObject] toggle];
        direction = FasTScannerEntranceDirectionIn;
        
        colorOverlay = [[UIView alloc] initWithFrame:overlay.bounds];
        [colorOverlay setHidden:YES];
        [overlay addSubview:colorOverlay];
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
        NSString *extension = @".m4a";
        NSURL *soundUrl = [[NSBundle mainBundle] URLForResource:@"success" withExtension:extension];
        successSound = [[AVAudioPlayer alloc] initWithContentsOfURL:soundUrl error:nil];
        soundUrl = [[NSBundle mainBundle] URLForResource:@"error" withExtension:extension];
        errorSound = [[AVAudioPlayer alloc] initWithContentsOfURL:soundUrl error:nil];
    }
    return self;
}

- (void)dealloc
{
    [buttons release];
    [colorOverlay release];
    [successSound release];
    [errorSound release];
    [super dealloc];
}

- (NSDictionary *)parseTicketData:(ZBarSymbolSet *)data
{
	NSString *code = nil;
	for (ZBarSymbol *result in data) {
		code = [result data];
		break;
	}
	if (!code) return nil;
    
    NSMutableDictionary *ticketInfo = [NSMutableDictionary dictionary];
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^T(\\d+)(M(\\d{1,2}))?$" options:NSRegularExpressionAllowCommentsAndWhitespace error:nil];
    [regex enumerateMatchesInString:code options:0 range:NSMakeRange(0, [code length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        ticketInfo[@"number"] = [code substringWithRange:[result rangeAtIndex:1]];
        ticketInfo[@"medium"] = [code substringWithRange:[result rangeAtIndex:3]];
    }];
    
    return ticketInfo;
}

- (void)checkInWithInfo:(NSDictionary *)info
{
    [self enableScanner:NO];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    [hud setLabelText:NSLocalizedStringByKey(@"pleaseWait")];
    [hud setMode:MBProgressHUDModeIndeterminate];
    [[FasTApi defaultApi] checkInTicketWithInfo:info in:(direction == FasTScannerEntranceDirectionIn) callback:^(NSDictionary *response) {
        [hud hide:NO];
        NSString *messageKey = nil;
        if (response) {
            if (response[@"error"]) {
                messageKey = [NSString stringWithFormat:@"checkinError_%@", response[@"error"]];
            } else if (![response[@"ok"] boolValue]) {
                messageKey = @"checkinErrorGeneral";
            }
        } else {
            messageKey = @"checkinErrorNetwork";
        }
        [self showColorOverlayWithSuccess:[response[@"ok"] boolValue] messageKey:messageKey];
    }];
}

- (void)tappedButton:(FasTScannerButtonView *)button
{
    [buttons makeObjectsPerformSelector:@selector(toggle)];
    direction = [button direction];
}

- (void)enableScanner:(BOOL)enabled
{
    [[self scanner] setSymbology:0 config:ZBAR_CFG_ENABLE to:0];
    if (enabled) {
        [[self scanner] setSymbology:ZBAR_CODE39 config:ZBAR_CFG_ENABLE to:1];
        [[self scanner] setSymbology:ZBAR_QRCODE config:ZBAR_CFG_ENABLE to:1];
    }
}

- (void)showColorOverlayWithSuccess:(BOOL)success messageKey:(NSString *)messageKey
{
    MBProgressHUD *hud = nil;
    if (messageKey) {
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:NO];
        [hud setMode:MBProgressHUDModeText];
        [hud setLabelText:NSLocalizedStringByKey(@"checkinError")];
        [hud setDetailsLabelText:NSLocalizedStringByKey(messageKey)];
        [errorSound play];
    } else {
        [successSound play];
    }
    
    UIColor *color = [UIColor performSelector:NSSelectorFromString(success ? @"greenColor" : @"redColor")];
    [colorOverlay setBackgroundColor:color];
    [colorOverlay setHidden:NO];
    
    CALayer *colorLayer = [colorOverlay layer];
    [colorLayer removeAllAnimations];
    [colorLayer setOpacity:1];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (success ? 0 : 4) * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [colorLayer setOpacity:0];
        
        CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"opacity"];
        [anim setFromValue:@(1)];
        [anim setToValue:@(0)];
        [anim setDuration:.5];
        [anim setDelegate:self];
        [colorLayer addAnimation:anim forKey:@"fadeOut"];
        
        [hud hide:YES];
        [self enableScanner:YES];
    });
}

#pragma mark reader delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    ZBarSymbolSet *results = [info objectForKey: ZBarReaderControllerResults];
    [self checkInWithInfo:[self parseTicketData:results]];
}

#pragma mark animation delegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)finished
{
    if (finished) {
        [colorOverlay setHidden:YES];
    }
}

@end
