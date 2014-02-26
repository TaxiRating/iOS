//
//  TAXCabsTableViewController.m
//  Taxi Rating
//
//  Created by Seth Friedman on 2/26/14.
//  Copyright (c) 2014 Nashville Public Works. All rights reserved.
//

#import "TAXCabsTableViewController.h"
#import "TAXCab.h"

@import CoreLocation;

@interface TAXCabsTableViewController () <CLLocationManagerDelegate>

@property (nonatomic, copy) NSArray *cabs;
@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation TAXCabsTableViewController

#pragma mark - Custom Setter

- (void)setCabs:(NSArray *)cabs {
    if (![_cabs isEqualToArray:cabs]) {
        _cabs = cabs;
        
        [self.tableView reloadData];
    }
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:@"8DEEFBB9-F738-4297-8040-96668BB44281"]
                                                                      identifier:@"home"];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    [self.locationManager startMonitoringForRegion:beaconRegion];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.cabs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CabCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    TAXCab *cab = self.cabs[indexPath.row];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", cab.companyName, cab.beacon.minor];
    
    return cell;
}

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

#pragma mark - Core Location Delegate

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
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
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    NSLog(@"Beacons ranged");
    
    if ([beacons count]) {
        NSMutableArray *cabs = [NSMutableArray arrayWithCapacity:[beacons count]];
        
        for (CLBeacon *beacon in beacons) {
            [cabs addObject:[TAXCab cabWithCompanyName:@"Allied"
                                             andBeacon:beacon]];
        }
        
        self.cabs = [cabs copy];
        
        [manager stopRangingBeaconsInRegion:region];
    }
}

- (void)locationManager:(CLLocationManager *)manager rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region withError:(NSError *)error {
    NSLog(@"Ranging error: %@", error);
}

@end
