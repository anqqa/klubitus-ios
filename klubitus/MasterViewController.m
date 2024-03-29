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
#import "GAI.h"

@interface MasterViewController ()
	
@property (strong, nonatomic) NSArray *sectionKeys;
@property (strong, nonatomic) NSMutableDictionary *sections;
@property (strong, nonatomic) NSDateFormatter *dayDateFormatter;
@property (strong, nonatomic) NSDate *firstDay;
@property (strong, nonatomic) NSDate *lastDay;
@property NSInteger *pageUp;
@property NSInteger *pageDown;

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
	
	// Analytics
	self.pageDown = self.pageUp = 0;
	[[[GAI sharedInstance] defaultTracker] trackView:@"Event list"];
	
	// Background image
//	self.tableView.backgroundColor = [UIColor colorWithWhite:0.12 alpha:1];
	self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
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
	__block MasterViewController *blocksafeSelf = self;
	[self.tableView addInfiniteScrollingWithActionHandler:^{
		[blocksafeSelf fetchEventsWithOrder:@"asc"];
	}];
	[self.tableView addPullToRefreshWithActionHandler:^{
		[blocksafeSelf fetchEventsWithOrder:@"desc"];
	}];
    self.tableView.pullToRefreshView.activityIndicatorViewStyle     = UIActivityIndicatorViewStyleWhite;
	self.tableView.infiniteScrollingView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
	[self.tableView triggerInfiniteScrolling];
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
		if ([inputOrder isEqualToString:@"desc"]) {
			NSIndexPath *tempPath = [NSIndexPath indexPathForRow:0 inSection:newSections];

			[self.tableView.pullToRefreshView stopAnimating];
			[self.tableView reloadData];
			[self.tableView scrollToRowAtIndexPath:tempPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
			
			self.pageUp += 1;
			[[[GAI sharedInstance] defaultTracker] trackEventWithCategory:@"uiAction" withAction:@"scroll" withLabel:@"up" withValue:[NSNumber numberWithInteger:(NSInteger)self.pageUp]];
        } else {
			[self.tableView reloadData];
			[self.tableView.infiniteScrollingView stopAnimating];
			
			self.pageDown += 1;
			[[[GAI sharedInstance] defaultTracker] trackEventWithCategory:@"uiAction" withAction:@"scroll" withLabel:@"down" withValue:[NSNumber numberWithInteger:(NSInteger)self.pageDown]];
        }
		
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
	UILabel         *musicLabel = (UILabel *)[cell viewWithTag:102];
	UIImageView *flyerImageView = (UIImageView *)[cell viewWithTag:103];
	
	// Get section
	NSDate         *day = [self.sectionKeys objectAtIndex:indexPath.section];
	NSArray     *events = [self.sections objectForKey:day];
	NSDictionary *event = [events objectAtIndex:indexPath.row];

	// Get needed info
	NSString      *name = [event stringForKey:@"name"];
	NSString     *venue = [event stringForKey:@"venue"];
	NSString      *city = [event stringForKey:@"city"];
	NSString     *music = [event stringForKey:@"music"];
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

	// Music
	musicLabel.text = music;

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


/**
 Allow rotation.
 */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
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


#pragma mark - Segues

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
