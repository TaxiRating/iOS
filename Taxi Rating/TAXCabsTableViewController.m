//
//  TAXCabsTableViewController.m
//  Taxi Rating
//
//  Created by Seth Friedman on 2/26/14.
//  Copyright (c) 2014 Nashville Public Works. All rights reserved.
//

#import "TAXCabsTableViewController.h"
#import "TAXDriver.h"
#import "TAXDriverViewController.h"
#import "TAXLocationManagerDelegate.h"
#import "TAXCabTableViewCell.h"
#import "TAXRatingView.h"
#import "TAXClient.h"

@interface TAXCabsTableViewController ()

@property (nonatomic, copy, readwrite) NSArray *drivers;

@property (strong, nonatomic, readwrite) CLLocationManager *locationManager;
@property (strong, nonatomic) CLBeaconRegion *beaconRegion;

@property (strong, nonatomic, readwrite) TAXLocationManagerDelegate *locationManagerDelegate;

@end

@implementation TAXCabsTableViewController

#pragma mark - Custom Getter

- (CLBeaconRegion *)beaconRegion {
    if (!_beaconRegion) {
        _beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:@"8DEEFBB9-F738-4297-8040-96668BB44281"]
                                                           identifier:@"cabs"];
    }
    
    return _beaconRegion;
}

- (TAXLocationManagerDelegate *)locationManagerDelegate {
    if (!_locationManagerDelegate) {
        TAXCabsTableViewController * __weak weakSelf = self;
        
        _locationManagerDelegate = [TAXLocationManagerDelegate locationManagerDelegateWithDidRangeBeaconsBlock:^(NSArray *beacons) {
            TAXCabsTableViewController *strongSelf = weakSelf;
            
            [strongSelf.refreshControl endRefreshing];
            
            [[TAXClient sharedClient] fetchDriversWithBeacons:beacons
                                          withCompletionBlock:^(BOOL success, NSArray *drivers) {
                                              if (success) {
                                                  strongSelf.drivers = drivers;
                                              } else {
                                                  [[[UIAlertView alloc] initWithTitle:@"Failure"
                                                                             message:@"Failed to connect to the server."
                                                                            delegate:nil
                                                                   cancelButtonTitle:@"OK"
                                                                    otherButtonTitles:nil] show];
                                              }
                                          }];
        } andRangingBeaconsDidFailBlock:^{
            TAXCabsTableViewController *strongSelf = weakSelf;
            
            [strongSelf.refreshControl endRefreshing];
        }];
    }
    
    return _locationManagerDelegate;
}

#pragma mark - Custom Setter

- (void)setDrivers:(NSArray *)drivers {
    if (![_drivers isEqualToArray:drivers]) {
        _drivers = drivers;
        
        [self.tableView reloadData];
    }
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self.locationManagerDelegate;
    
    [self refresh];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70.0;
}

#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.drivers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CabCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if ([cell isKindOfClass:[TAXCabTableViewCell class]]) {
        TAXCabTableViewCell *cabCell = (TAXCabTableViewCell *)cell;
        
        TAXDriver *driver = self.drivers[indexPath.row];
        
        cabCell.ratingView.rating = TAXRatingHighRating;
        cabCell.ratingLabel.text = [NSString stringWithFormat:@"%.1f", driver.averageRating];
        cabCell.cabNumberLabel.text = [NSString stringWithFormat:@"%@ #%lu", driver.companyName, (unsigned long)driver.permitNumber];
        cabCell.driverLabel.text = [NSString stringWithFormat:@"%@ %@", driver.firstName, driver.lastName];
        
        /*UIImage *bannerImage;
        
        if ([cab.companyName isEqualToString:@"Music City Taxi Cab"]) {
            bannerImage = [UIImage imageNamed:@"musiccitytaxi.gif"];
        } else if ([cab.companyName isEqualToString:@"Allied Cab"]) {
            bannerImage = [UIImage imageNamed:@"allied.jpg"];
        } else { // Nashville Checker Cab
            bannerImage = [UIImage imageNamed:@"checkercab.jpg"];
        }
        
        cabCell.bannerImageView.image = bannerImage;*/
        
        
    }
    
    return cell;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"PushDriver"]) {
        if ([segue.destinationViewController isKindOfClass:[TAXDriverViewController class]]) {
            TAXDriverViewController *driverViewController = segue.destinationViewController;
            
            if ([sender isKindOfClass:[UITableViewCell class]]) {
                UITableViewCell *cell = sender;
                NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:cell];
                
                TAXDriver *driver = self.drivers[cellIndexPath.row];
                driverViewController.driver = driver;
            }
        }
    }
}

#pragma mark - IB Action

- (IBAction)userDidRefresh:(UIRefreshControl *)sender {
    [self refresh];
}

#pragma mark - Core Location Delegate

/*- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        NSLog(@"Region entered");
        
        [manager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        NSLog(@"Region exited");
    }
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    NSLog(@"Monitoring Error: %@", error);
}*/

#pragma mark - Helper Method

- (void)refresh {
    // If Location Services have been disabled, warn the user. Otherwise, start searching for beacons.
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        NSString *appName = [[NSBundle mainBundle] infoDictionary][(NSString *)kCFBundleNameKey];
        
        [[[UIAlertView alloc] initWithTitle:@"Location Services Disabled"
                                    message:[NSString stringWithFormat:@"It looks like you have disabled Location Services for %@. Please go to Settings > Privacy > Location Services and turn these back on, or the app will not be able to locate nearby cabs for you.", appName]
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    } else {
        [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
    }
}

@end
