//
//  FasTStatisticsDetailsViewController.m
//  FasT-checkin
//
//  Created by Albrecht Oster on 21.07.17.
//  Copyright © 2017 Albisigns. All rights reserved.
//

#import "FasTStatisticsCheckInViewController.h"
#import "FasTCheckIn.h"

@interface FasTStatisticsCheckInViewController ()

@end

@implementation FasTStatisticsCheckInViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)setCheckIns:(NSArray *)checkIns
{
    [_checkIns release];
    NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"ticketNumberWithIdFallback" ascending:YES];
    _checkIns = [[checkIns sortedArrayUsingDescriptors:@[sorter]] retain];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _checkIns.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CheckInCell" forIndexPath:indexPath];
    FasTCheckIn *checkIn = _checkIns[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@", checkIn.ticketNumberWithIdFallback];
    cell.detailTextLabel.text = checkIn.date.description;
    
    return cell;
}

- (void)dealloc
{
    [_checkIns release];
    [super dealloc];
}

@end
