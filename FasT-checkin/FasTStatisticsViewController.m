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

@import MBProgressHUD;

@interface FasTStatisticsViewController ()
{
    NSDateFormatter *dateFormatter;
}

@property (retain, nonatomic) IBOutlet UILabel *scanAttemptsLabel;
@property (retain, nonatomic) IBOutlet UILabel *successfulScansLabel;
@property (retain, nonatomic) IBOutlet UILabel *deniedScansLabel;
@property (retain, nonatomic) IBOutlet UILabel *submittedScansLabel;
@property (retain, nonatomic) IBOutlet UILabel *crashsLabel;
@property (retain, nonatomic) IBOutlet UILabel *duplicateScansLabel;
@property (retain, nonatomic) IBOutlet UILabel *checkInsToSubmitLabel;
@property (retain, nonatomic) IBOutlet UILabel *lastSubmissionDateLabel;
@property (retain, nonatomic) IBOutlet UILabel *lastInfoRefreshLabel;

- (void)refresh;
- (void)presentError:(NSError *)error;
- (NSString *)formattedDate:(NSDate *)date;

@end

@implementation FasTStatisticsViewController

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self refresh];
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
    _lastSubmissionDateLabel.text = [self formattedDate:checkIn.lastSubmissionDate];
    _lastInfoRefreshLabel.text = [self formattedDate:[FasTTicketVerifier lastRefresh]];
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

- (IBAction)showActionSheet:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *action;
    action = [UIAlertAction actionWithTitle:@"Check-Ins übertragen" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];

        [[FasTCheckInManager sharedManager] submitCheckIns:^(NSError *error) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            
            if (error) {
                [self presentError:error];
                return;
            }
            
            [self refresh];
        }];
    }];
    [alert addAction:action];
    
    action = [UIAlertAction actionWithTitle:@"Check-In-Status zurücksetzen" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [FasTTicketVerifier clearTickets];
    }];
    [alert addAction:action];
    
    action = [UIAlertAction actionWithTitle:@"abbrechen" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
    }];
    [alert addAction:action];
    
    [self presentViewController:alert animated:YES completion:NULL];
}

- (IBAction)refreshInfo:(id)sender {
    [FasTTicketVerifier refreshInfo:^(NSError *error) {
        [self.refreshControl endRefreshing];

        if (error) {
            [self presentError:error];
            return;
        }

        [self refresh];
    }];
}

- (void)presentError:(NSError *)error {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Fehler bei der Aktualisierung" message:[error localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:NULL];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:NULL];
}

- (NSString *)formattedDate:(NSDate *)date {
    if (date) {
        return [dateFormatter stringFromDate:date];
    } else {
        return @"noch nie";
    }
}

@end
