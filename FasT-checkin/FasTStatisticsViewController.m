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
#import "FasTStatisticsCheckInViewController.h"
#import "FasTTicketVerifier.h"

@interface FasTStatisticsViewController ()

@property (retain, nonatomic) IBOutlet UILabel *scanAttemptsLabel;
@property (retain, nonatomic) IBOutlet UILabel *successfulScansLabel;
@property (retain, nonatomic) IBOutlet UILabel *deniedScansLabel;
@property (retain, nonatomic) IBOutlet UILabel *submittedScansLabel;
@property (retain, nonatomic) IBOutlet UILabel *crashsLabel;
@property (retain, nonatomic) IBOutlet UILabel *duplicateScansLabel;
@property (retain, nonatomic) IBOutlet UILabel *checkInsToSubmitLabel;
@property (retain, nonatomic) IBOutlet UILabel *lastSubmissionDateLabel;
@property (retain, nonatomic) IBOutlet UILabel *lastInfoRefreshLabel;

- (IBAction)dismiss:(id)sender;
- (void)refresh;

@end

@implementation FasTStatisticsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self refresh];
}

- (IBAction)dismiss:(id)sender {
    [self.parentViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)refresh {
    FasTStatisticsManager *stats = [FasTStatisticsManager sharedManager];
    FasTCheckInManager *checkIn = [FasTCheckInManager sharedManager];
    _scanAttemptsLabel.text = [NSString stringWithFormat:@"%ld", (long)stats.scanAttempts];
    _successfulScansLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)stats.checkIns.count];
    _duplicateScansLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)stats.duplicateCheckIns.count];
    _submittedScansLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)stats.submittedCheckIns.count];
    _checkInsToSubmitLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)checkIn.checkInsToSubmit.count];
    _deniedScansLabel.text = [NSString stringWithFormat:@"%lu", (long)stats.deniedScans];
    _crashsLabel.text = [NSString stringWithFormat:@"%lu", (long)stats.crashs];
    _lastSubmissionDateLabel.text = checkIn.lastSubmissionDate.description;
    _lastInfoRefreshLabel.text = [FasTTicketVerifier lastRefresh].description;
}

- (void)dealloc {
    [_scanAttemptsLabel release];
    [_successfulScansLabel release];
    [_deniedScansLabel release];
    [_submittedScansLabel release];
    [_crashsLabel release];
    [_duplicateScansLabel release];
    [_checkInsToSubmitLabel release];
    [_lastSubmissionDateLabel release];
    [_lastInfoRefreshLabel release];
    [super dealloc];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    FasTStatisticsManager *stats = [FasTStatisticsManager sharedManager];
    FasTStatisticsCheckInViewController *vc = segue.destinationViewController;
    if ([segue.identifier isEqualToString:@"CheckInsSegue"]) {
        vc.checkIns = stats.checkIns;
        vc.navigationItem.title = @"Erfolgreiche Check-Ins";
    } else if ([segue.identifier isEqualToString:@"DuplicateCheckInsSegue"]) {
        vc.checkIns = stats.duplicateCheckIns;
        vc.navigationItem.title = @"Duplikat-Check-Ins";
    } else if ([segue.identifier isEqualToString:@"SubmittedCheckInsSegue"]) {
        vc.checkIns = stats.submittedCheckIns;
        vc.navigationItem.title = @"Übertragene Check-Ins";
    } else if ([segue.identifier isEqualToString:@"CheckInsToSubmitSegue"]) {
        vc.checkIns = [FasTCheckInManager sharedManager].checkInsToSubmit;
        vc.navigationItem.title = @"Noch nicht übertragene Check-Ins";
    }
}

- (IBAction)submitCheckIns:(id)sender {
    [[FasTCheckInManager sharedManager] submitCheckIns:^{
        [self refresh];
    }];
}

- (IBAction)resetCheckIns:(id)sender {
    [FasTTicketVerifier clearTickets];
}

- (IBAction)refreshInfo:(id)sender {
    [FasTTicketVerifier refreshInfo:^{
        [self refresh];
    }];
}

@end
