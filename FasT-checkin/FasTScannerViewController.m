//
//  FasTScannerViewController.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 12.08.13.
//  Copyright (c) 2013 Albisigns. All rights reserved.
//

#import "FasTScannerViewController.h"
#import "FasTScannerButtonView.h"

@interface FasTScannerViewController ()

- (NSDictionary *)parseTicketData:(ZBarSymbolSet *)data;
- (void)tappedButton:(FasTScannerButtonView *)button;

@end

@implementation FasTScannerViewController

- (id)init
{
    self = [super init];
    if (self) {
        [self setReaderDelegate:self];
        
        // only enable code39 and qr code
		[[self scanner] setSymbology:0 config:ZBAR_CFG_ENABLE to:1];
        [[self scanner] setSymbology:ZBAR_CODE39 config:ZBAR_CFG_ENABLE to:1];
        [[self scanner] setSymbology:ZBAR_QRCODE config:ZBAR_CFG_ENABLE to:1];
        
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
    }
    return self;
}

- (void)dealloc
{
    [buttons release];
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

- (void)tappedButton:(FasTScannerButtonView *)button
{
    [buttons makeObjectsPerformSelector:@selector(toggle)];
    direction = [button direction];
}

#pragma mark reader delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    ZBarSymbolSet *results = [info objectForKey: ZBarReaderControllerResults];
    [self parseTicketData:results];
}

@end
