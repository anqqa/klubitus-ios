//
//  DetailViewController.m
//  klubitus
//
//  Created by Antti Qvickström on 8/19/12.
//  Copyright (c) 2012 Antti Qvickström. All rights reserved.
//

#import "DetailViewController.h"
#import "DictionaryHelper.h"
#import "SVModalWebViewController.h"
#import "UIImageView+AFNetworking.h"
#import "GAI.h"

@interface DetailViewController ()
- (void)configureView;
@end

@implementation DetailViewController


#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
}


/**
 Setup event detail view.
 */
- (void)configureView {
	if (self.detailItem) {
		NSDictionary *event = self.detailItem;
		
		// Flyer
		NSString *flyer = [event stringForKey:@"flyer_front_thumb"];
		flyerButton.enabled = NO;
		if (flyer != nil) {
			NSURL *flyerURL = [NSURL URLWithString:flyer];
			if (flyerURL != nil) {
				flyerButton.enabled = YES;
				[flyerImage setImageWithURL:flyerURL];
			}
		}
		
		// Name
		NSString *name = [event stringForKey:@"name"];
		nameLabel.lineBreakMode = UILineBreakModeWordWrap;
		nameLabel.numberOfLines = 0;
		nameLabel.text          = name;

		// Location
		NSString *venue    = [event stringForKey:@"venue"];
		NSString  *city    = [event stringForKey:@"city"];
		NSString *location = @"";
		if (venue != nil && city != nil) {
			location = [NSString stringWithFormat:@"%@, %@", venue, city];
		} else if (venue != nil) {
			location = venue;
		} else if (city != nil) {
			location = city;
		}
		locationLabel.text = location;

		// Date
		NSString *formatString            = [NSDateFormatter dateFormatFromTemplate:@"EdMMMy" options:0 locale:[NSLocale currentLocale]];
		NSDateFormatter *dayDateFormatter = [[NSDateFormatter alloc] init];
		[dayDateFormatter setDateFormat:formatString];
		//[dayDateFormatter setTimeStyle:NSDateFormatterNoStyle];
		NSDate *fromDate = [NSDate dateWithTimeIntervalSince1970:[[event stringForKey:@"stamp_begin"] intValue]];
		NSDateFormatter *timeDateFormatter = [[NSDateFormatter alloc] init];
		[timeDateFormatter setDateStyle:NSDateFormatterNoStyle];
		[timeDateFormatter setTimeStyle:NSDateFormatterShortStyle];
		NSDate *toDate = [NSDate dateWithTimeIntervalSince1970:[[event stringForKey:@"stamp_end"] intValue]];
		dateLabel.text = [dayDateFormatter stringFromDate:fromDate];
		timeLabel.text = [NSString stringWithFormat:@"%@ - %@", [timeDateFormatter stringFromDate:fromDate], [timeDateFormatter stringFromDate:toDate]];
		
		// Price
		NSString *price = [event stringForKey:@"price"];
		if (price == nil || [price floatValue] < 0) {
			priceLabel.text = @"";
		} else if ([price floatValue] == 0) {
			priceLabel.text = NSLocalizedString(@"Free entry",);
		} else {
			priceLabel.text = [NSString stringWithFormat:@"%g€", [price floatValue]];
		}
		
		// Age
		NSString *age = [event stringForKey:@"age"];
		if (age == nil || [age intValue] < 0) {
			ageLabel.text = @"";
		} else if ([age intValue] == 0) {
			ageLabel.text = NSLocalizedString(@"No age limit",);
		} else {
			ageLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Age limit %d",), [age intValue]];
		}
		
		// Music
		musicLabel.text = [event stringForKey:@"music"];
		
		// DJ
		NSString *dj   = [event stringForKey:@"dj"];
		NSString *info = [event stringForKey:@"info"];
		NSString *text = @"";
		if (dj != nil && info != nil) {
			text = [NSString stringWithFormat:@"%@\n\n%@", dj, info];
		} else if (dj != nil) {
			text = dj;
		} else if (info != nil) {
			text = info;
		}

		// Remove BBCode
		NSScanner *tagScanner;
		NSString *tag = nil;
		tagScanner = [NSScanner scannerWithString:text];
		while ([tagScanner isAtEnd] == NO) {
			[tagScanner scanUpToString:@"[" intoString:NULL];
			[tagScanner scanUpToString:@"]" intoString:&tag];
			text = [text stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@]", tag] withString:@""];
		}

		djText.text = text;

	}
}


/**
 View loaded.
 */
- (void)viewDidLoad {
	[super viewDidLoad];

//	self.view.backgroundColor     = [UIColor colorWithWhite:0.12 alpha:1];
	self.view.backgroundColor     = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.png"]];
	separatorView.backgroundColor = separator2View.backgroundColor = [UIColor colorWithWhite:0.17 alpha:1];
		
	// Do any additional setup after loading the view, typically from a nib.
	[self configureView];
	
	[[[GAI sharedInstance] defaultTracker] trackView:@"Event details"];
}

- (void)viewDidUnload
{
	flyerButton = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


/**
 Prepare segue.
 */
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([[segue identifier] isEqualToString:@"showFlyer"]) {
		[[segue destinationViewController] setDetailItem:self.detailItem];
	}
}


/**
 Show browser.
 */
- (IBAction)openBrowser:(id)sender {
	NSDictionary *event = self.detailItem;
	NSString *url       = [event stringForKey:@"url"];
	
	SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:url];
	webViewController.barsTintColor = [UIColor blackColor];
	webViewController.availableActions = SVWebViewControllerAvailableActionsOpenInSafari | SVWebViewControllerAvailableActionsCopyLink;
	
	[self presentModalViewController:webViewController animated:YES];
	
	[[[GAI sharedInstance] defaultTracker] trackView:@"Browser"];
}

@end
