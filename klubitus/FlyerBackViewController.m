//
//  FlyerBackViewController.m
//  klubitus
//
//  Created by Antti Qvickström on 8/26/12.
//  Copyright (c) 2012 Antti Qvickström. All rights reserved.
//

#import "FlyerBackViewController.h"
#import "DictionaryHelper.h"
#import "UIImageView+AFNetworking.h"

@interface FlyerBackViewController ()
- (void)configureView;
@end

@implementation FlyerBackViewController

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
 Setup view.
 */
- (void)configureView {
	if (self.detailItem) {
		NSDictionary *event = self.detailItem;
		NSString *flyer     = [event stringForKey:@"flyer_back"];
		NSURL *flyerURL     = [NSURL URLWithString:flyer];
		if (flyerURL != nil) {
			[flyerImage setImageWithURL:flyerURL];
		}
	}
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// Do any additional setup after loading the view.
	[self configureView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


/**
 Close flyers.
 */
- (IBAction)closeFlyer:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
//	[self.presentingViewController dismissModalViewControllerAnimated:YES];
}

@end
