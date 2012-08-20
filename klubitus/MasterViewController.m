//
//  MasterViewController.m
//  klubitus
//
//  Created by Antti Qvickström on 8/19/12.
//  Copyright (c) 2012 Antti Qvickström. All rights reserved.
//

// Our API URL
#define APIURL [NSURL URLWithString:@"http://api.klubitus.org/v1/events/browse?field=all&limit=1w&order=desc"]


#import "MasterViewController.h"
#import "DetailViewController.h"


@interface MasterViewController () {
    NSMutableArray *_objects;
}
@end


@implementation MasterViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
}


/**
 Get event cell.
 
 @returns  cell
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"EventCell";
	
	// Configure cell
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}
	UILabel          *nameLabel = (UILabel *)[cell viewWithTag:100];
	UILabel      *locationLabel = (UILabel *)[cell viewWithTag:101];
	UIImageView *flyerImageView = (UIImageView *)[cell viewWithTag:102];
	
	// Get needed info
	NSDictionary *event = [events objectAtIndex:indexPath.row];
	NSString      *name = [event objectForKey:@"name"];
	NSString     *venue = [event objectForKey:@"venue"];
	NSString      *city = [event objectForKey:@"city"];
	NSString     *flyer = [event objectForKey:@"flyer_front_icon"];
	NSString  *location = @"";
	
	// Name
	nameLabel.text = name;
	
	// Location
	bool hasVenue = !!venue && ![venue isEqual:[NSNull null]];
	bool hasCity  = !!city && ![city isEqual:[NSNull null]];
	if (hasVenue && hasCity) {
		location = [NSString stringWithFormat:@"%@, %@", venue, city];
	} else if (hasVenue) {
		location = venue;
	} else if (hasCity) {
		location = city;
	}
	locationLabel.text = location;

	// Flyer
	flyerImageView.image = nil;
	if (!!flyer && ![flyer isEqual:[NSNull null]]) {
		NSURL *flyerURL = [NSURL URLWithString:flyer];
		if (flyerURL != nil) {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				NSData *data = [NSData dataWithContentsOfURL:flyerURL];
				
				dispatch_async(dispatch_get_main_queue(), ^{
					flyerImageView.image = [UIImage imageWithData:data];
				});
			});
		}
	}
	
	return cell;
}


/**
 Load events with JSON.
 */
- (void)fetchEvents {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSData  *data = [NSData dataWithContentsOfURL:APIURL];
		NSError *error;
		
		NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
		events = [response objectForKey:@"events"];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.tableView reloadData];
		});
	});
}


/**
 Get event count.
 
 @returns  count
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return events.count;
}


- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[self fetchEvents];
	/*
	// Do any additional setup after loading the view, typically from a nib.
	self.navigationItem.leftBarButtonItem = self.editButtonItem;

	UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
	self.navigationItem.rightBarButtonItem = addButton;
	*/
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)insertNewObject:(id)sender
{
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    [_objects insertObject:[NSDate date] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([[segue identifier] isEqualToString:@"showEvent"]) {
		NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
		NSDictionary    *event = [events objectAtIndex:indexPath.row];
	
		[[segue destinationViewController] setDetailItem:event];
	}
}

@end
