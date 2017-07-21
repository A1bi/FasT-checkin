//
//  FasTInfoViewController.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 21.07.17.
//  Copyright © 2017 Albisigns. All rights reserved.
//

#import "FasTStatisticsViewController.h"
#import "FasTStatisticsManager.h"
#import "FasTCheckInManager.h"

@interface FasTStatisticsViewController ()

@property (retain, nonatomic) IBOutlet UILabel *scanAttemptsLabel;
@property (retain, nonatomic) IBOutlet UILabel *successfulScansLabel;
@property (retain, nonatomic) IBOutlet UILabel *deniedScansLabel;
@property (retain, nonatomic) IBOutlet UILabel *submittedScansLabel;
@property (retain, nonatomic) IBOutlet UILabel *crashsLabel;
@property (retain, nonatomic) IBOutlet UILabel *duplicateScansLabel;
@property (retain, nonatomic) IBOutlet UILabel *checkInsToSubmitLabel;

- (IBAction)dismiss:(id)sender;

@end

@implementation FasTStatisticsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    FasTStatisticsManager *stats = [FasTStatisticsManager sharedManager];
    _scanAttemptsLabel.text = [NSString stringWithFormat:@"%ld", (long)stats.scanAttempts];
    _successfulScansLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)stats.checkIns.count];
    _duplicateScansLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)stats.duplicateCheckIns.count];
    _submittedScansLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)stats.submittedCheckIns.count];
    _checkInsToSubmitLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)[FasTCheckInManager sharedManager].checkInsToSubmit.count];
    _deniedScansLabel.text = [NSString stringWithFormat:@"%lu", (long)stats.deniedScans];
    _crashsLabel.text = [NSString stringWithFormat:@"%lu", (long)stats.crashs];
}

- (IBAction)dismiss:(id)sender {
    [self.parentViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)dealloc {
    [_scanAttemptsLabel release];
    [_successfulScansLabel release];
    [_deniedScansLabel release];
    [_submittedScansLabel release];
    [_crashsLabel release];
    [_duplicateScansLabel release];
    [_checkInsToSubmitLabel release];
    [super dealloc];
}

@end
