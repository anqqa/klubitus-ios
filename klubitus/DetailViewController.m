//
//  DetailViewController.m
//  klubitus
//
//  Created by Antti Qvickström on 8/19/12.
//  Copyright (c) 2012 Antti Qvickström. All rights reserved.
//

#import "DetailViewController.h"

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
		NSString *name = [event objectForKey:@"name"];
		nameLabel.lineBreakMode = UILineBreakModeWordWrap;
		nameLabel.numberOfLines = 0;
		nameLabel.text          = name;

		// Flyer
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			NSString *flyerUrl = [event objectForKey:@"flyer_front_thumb"];
			NSData       *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:flyerUrl]];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				flyerImage.image = [UIImage imageWithData:data];
			});
		});
		
	}
}


- (void)viewDidLoad
{
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
