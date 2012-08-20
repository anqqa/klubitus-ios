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


@interface MasterViewController ()
	
@property (strong, nonatomic) NSArray *sectionKeys;
@property (strong, nonatomic) NSMutableDictionary *sections;
@property (strong, nonatomic) NSDateFormatter *dayDateFormatter;

- (NSDate *)timeToDate:(NSDate *)inputDate;

@end



@implementation MasterViewController

@synthesize sectionKeys;
@synthesize sections;
@synthesize dayDateFormatter;


- (void)awakeFromNib {
	[super awakeFromNib];
}


#pragma mark - View lifecycle

/**
 View loaded.
 */
- (void)viewDidLoad {
	[super viewDidLoad];
	
	// Create our section header date formatter
	self.dayDateFormatter = [[NSDateFormatter alloc] init];
	[self.dayDateFormatter setDateStyle:NSDateFormatterLongStyle];
	[self.dayDateFormatter setTimeStyle:NSDateFormatterNoStyle];
	
	[self fetchEvents];
}


- (void)viewDidUnload {
	[super viewDidUnload];
}


/**
 Convert a date with time to date at 00:00:00
 */
- (NSDate *)timeToDate:(NSDate *)inputDate {
	NSCalendar *calendar = [NSCalendar currentCalendar];
	[calendar setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
	
	NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:inputDate];
	[components setHour:0];
	[components setMinute:0];
	[components setSecond:0];
	
	NSDate *outputDate = [calendar dateFromComponents:components];
	
	return outputDate;
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
	
	// Get section
	NSDate         *day = [self.sectionKeys objectAtIndex:indexPath.section];
	NSArray     *events = [self.sections objectForKey:day];
	NSDictionary *event = [events objectAtIndex:indexPath.row];

	// Get needed info
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
		
		// Load data
		NSData  *data = [NSData dataWithContentsOfURL:APIURL];
		NSError *error;
		
		// Parse JSON
		NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
		NSArray        *events = [response objectForKey:@"events"];
		
		// Order by day
		NSMutableArray          *keys = [[NSMutableArray alloc] init];
		NSMutableDictionary *contents = [[NSMutableDictionary alloc] init];
		for (NSDictionary *event in events) {
			NSLog(@"Parsing event.. %@", [event objectForKey:@"name"]);
			
			// Parse UNIX timestamp to date with 00:00:00
			NSDate *day = [NSDate dateWithTimeIntervalSince1970:[[event objectForKey:@"stamp_begin"] intValue]];
			day         = [self timeToDate:day];

			// Make sure we have the day section
			NSMutableArray *dayEvents = [contents objectForKey:day];
			if (dayEvents == nil) {
				NSLog(@"Creating new section for %@", day);
				dayEvents = [[NSMutableArray alloc] init];
				[contents setObject:dayEvents forKey:day];
				NSLog(@"Sections: %d", contents.count);
			}
			
			// Add the event to the day
			[dayEvents addObject:event];
			NSLog(@"Sections: %d", contents.count);
			
		}
		
		// Create ordered day list
		NSArray *unsortedDays = [contents allKeys];
		[self setSectionKeys:[unsortedDays sortedArrayUsingSelector:@selector(compare:)]];
		[self setSections:contents];
		
		NSLog(@"Sections: %d, Events: %d", self.sections.count, self.sectionKeys.count);
		
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
	NSDate        *day = [self.sectionKeys objectAtIndex:section];
	NSArray *dayEvents = [self.sections objectForKey:day];
	
	return dayEvents.count;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}
/*
- (void)insertNewObject:(id)sender
{
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    [_objects insertObject:[NSDate date] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}
*/

#pragma mark - Table View

/**
 Get number of days.
 
 @returns  integer
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [self.sectionKeys count];
}


/**
 Get section header.
 */
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSDate *day = [self.sectionKeys objectAtIndex:section];
	
	return [self.dayDateFormatter stringFromDate:day];
}


/*
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}
*/
/*
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}
*/

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
		NSDate            *day = [self.sectionKeys objectAtIndex:indexPath.section];
		NSArray        *events = [self.sections objectForKey:day];
		NSDictionary    *event = [events objectAtIndex:indexPath.row];
	
		[[segue destinationViewController] setDetailItem:event];
	}
}

@end
