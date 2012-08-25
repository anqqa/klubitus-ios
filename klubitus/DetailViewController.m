//
//  DetailViewController.m
//  klubitus
//
//  Created by Antti Qvickström on 8/19/12.
//  Copyright (c) 2012 Antti Qvickström. All rights reserved.
//

#import "DetailViewController.h"
#import "DictionaryHelper.h"
#import "UIImageView+AFNetworking.h"

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
		
		// Name
		NSString *name = [event stringForKey:@"name"];
		nameLabel.lineBreakMode = UILineBreakModeWordWrap;
		nameLabel.numberOfLines = 0;
		nameLabel.text          = name;

		// Flyer
		NSString *flyer = [event stringForKey:@"flyer_front_thumb"];
		if (flyer != nil) {
			NSURL *flyerURL = [NSURL URLWithString:flyer];
			if (flyerURL != nil) {
				[flyerImage setImageWithURL:flyerURL];
			}
		}
		
	}
}


/**
 View loaded.
 */
- (void)viewDidLoad {
	self.view.backgroundColor = [UIColor colorWithWhite:0.12 alpha:1];
	
	[super viewDidLoad];
	
	// Do any additional setup after loading the view, typically from a nib.
	[self configureView];
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

@end
