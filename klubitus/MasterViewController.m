//
//  MasterViewController.m
//  klubitus
//
//  Created by Antti Qvickström on 8/19/12.
//  Copyright (c) 2012 Antti Qvickström. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "DictionaryHelper.h"
#import "SVPullToRefresh.h"
#import "AFNetworking.h"
#import "UIImageView+AFNetworking.h"

@interface MasterViewController ()
	
@property (strong, nonatomic) NSArray *sectionKeys;
@property (strong, nonatomic) NSMutableDictionary *sections;
@property (strong, nonatomic) NSDateFormatter *dayDateFormatter;
@property (strong, nonatomic) NSDate *firstDay;
@property (strong, nonatomic) NSDate *lastDay;

- (NSDate *)timeToDate:(NSDate *)inputDate;

@end



@implementation MasterViewController

@synthesize sectionKeys;
@synthesize sections;
@synthesize dayDateFormatter;
@synthesize firstDay;
@synthesize lastDay;


- (void)awakeFromNib {
	[super awakeFromNib];
}


#pragma mark - View lifecycle

/**
 View loaded.
 */
- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.tableView.backgroundColor = [UIColor colorWithWhite:0.12 alpha:1];
	self.tableView.separatorColor  = [UIColor colorWithWhite:0.17 alpha:1];
	//self.tableView.rowHeight       = 60;
	
	// Init sections
	self.sections    = [NSMutableDictionary dictionary];
	self.sectionKeys = [NSArray array];
	
	// Create our section header date formatter
	self.dayDateFormatter = [[NSDateFormatter alloc] init];
	[self.dayDateFormatter setDateStyle:NSDateFormatterFullStyle];
	[self.dayDateFormatter setTimeStyle:NSDateFormatterNoStyle];
	
	// Start loading from today
	self.lastDay = self.firstDay = [self timeToDate:[NSDate date]];
	
	// Initialize infinite scroller and pull to refresh, with initial refresh in other direction..
	self.tableView.pullToRefreshView.activityIndicatorViewStyle     = UIActivityIndicatorViewStyleWhite;
	self.tableView.infiniteScrollingView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
	__block MasterViewController *blocksafeSelf = self;
	[self.tableView addInfiniteScrollingWithActionHandler:^{
		[blocksafeSelf fetchEventsWithOrder:@"asc"];
	}];
	[self.tableView addPullToRefreshWithActionHandler:^{
		[blocksafeSelf fetchEventsWithOrder:@"desc"];
	}];
	[self.tableView.pullToRefreshView triggerRefresh];

	//	[self fetchEventsWithOrder:@"asc"];
}


- (void)viewDidUnload {
	[super viewDidUnload];
}


#pragma mark Custom functions

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
 Load events with JSON.
 */
- (void)fetchEventsWithOrder:(NSString *)inputOrder {
	
	// Kludge to always order first request descending because we are triggering refresh onViewLoad
	if ([self.lastDay isEqualToDate:self.firstDay]) {
		inputOrder = @"asc";
	}
	
	NSDate *fromDate = ([inputOrder isEqualToString:@"asc"]) ? self.lastDay : self.firstDay;
	int from = [fromDate timeIntervalSince1970];
	NSString *APIBasePath = @"http://api.klubitus.org/v1/events/browse?field=all&limit=1w&order=%@&from=%d";
	NSString *APIPath     = [NSString stringWithFormat:APIBasePath, inputOrder, from];
	NSURL    *APIURL      = [NSURL URLWithString:APIPath];
	NSURLRequest *request = [NSURLRequest requestWithURL:APIURL];
	
	// Create load operation
	AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {

		NSArray *events = [JSON objectForKey:@"events"];
		int newSections = 0;
		
		// Order by day
		for (NSDictionary *event in events) {
			
			// Parse UNIX timestamp to NSDate with time at 00:00:00
			NSDate *day = [NSDate dateWithTimeIntervalSince1970:[[event stringForKey:@"stamp_begin"] intValue]];
			day         = [self timeToDate:day];
			
			// Keep track of edge days
			self.firstDay = (self.firstDay == nil) ? day : [self.firstDay earlierDate:day];
			self.lastDay  = (self.lastDay == nil) ? day : [self.lastDay laterDate:day];

			
			// Make sure we have the day section
			NSMutableArray *dayEvents = [self.sections objectForKey:day];
			if (dayEvents == nil) {
				dayEvents = [NSMutableArray array];
				
				[self.sections setObject:dayEvents forKey:day];
				newSections++;
			}
			
			// Add the event to the day
			[dayEvents addObject:event];
			
		}
		
		
		// Create ordered day list
		self.sectionKeys = [[self.sections allKeys] sortedArrayUsingSelector:@selector(compare:)];
		
		// Bump last day to the next day so we don't reload those, surviving daylight
		self.lastDay = [self timeToDate:[self.lastDay dateByAddingTimeInterval:(60 * 60 * 25)]];
	
		// Refresh table and jump to new section if needed
		[self.tableView reloadData];
		if ([inputOrder isEqualToString:@"desc"]) {
			NSIndexPath *tempPath = [NSIndexPath indexPathForRow:0 inSection:newSections];
			[self.tableView scrollToRowAtIndexPath:tempPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
		}

		[self.tableView.pullToRefreshView stopAnimating];
		
	} failure:nil];

	[operation start];
}


/**
 Get event cell.
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
	NSString      *name = [event stringForKey:@"name"];
	NSString     *venue = [event stringForKey:@"venue"];
	NSString      *city = [event stringForKey:@"city"];
	NSString     *flyer = [event stringForKey:@"flyer_front_icon"];
	NSString  *location = @"";
	
	// Name
	nameLabel.text = name;
	
	// Location
	if (venue != nil && city != nil) {
		location = [NSString stringWithFormat:@"%@, %@", venue, city];
	} else if (venue != nil) {
		location = venue;
	} else if (city != nil) {
		location = city;
	}
	locationLabel.text = location;

	// Flyer
	flyerImageView.image = nil;
	if (flyer != nil) {
		NSURL *flyerURL = [NSURL URLWithString:flyer];
		if (flyerURL != nil) {
			[flyerImageView setImageWithURL:flyerURL];
		}
	}
	
	return cell;
}



/**
 Get event count per day.
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSDate        *day = [self.sectionKeys objectAtIndex:section];
	NSArray *dayEvents = [self.sections objectForKey:day];
	
	return [dayEvents count];
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
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [self.sectionKeys count];
}


/**
 Get section header.
 */
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSDate *day = [self.sectionKeys objectAtIndex:section];
	
	UILabel *sectionHeader = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 20)];
	sectionHeader.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.75];
	sectionHeader.shadowOffset    = CGSizeMake(1, 1);
	sectionHeader.shadowColor     = [UIColor blackColor];
	sectionHeader.font            = [UIFont boldSystemFontOfSize:14];
	sectionHeader.textColor       = [UIColor colorWithWhite:0.74 alpha:1];
	sectionHeader.text            = [self.dayDateFormatter stringFromDate:day];
	
	return sectionHeader;
}


/**
 Get section header title.
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
