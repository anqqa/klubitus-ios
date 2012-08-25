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
 Scale flyer after pinch.
 */
- (IBAction)scaleFlyer:(UIPinchGestureRecognizer *)sender {
	if ([sender state] == UIGestureRecognizerStateEnded) {
		previousScale = 1.0;
		
		return;
	}
	
	CGFloat newScale = 1.0 - (previousScale - [sender scale]);
	
	CGAffineTransform currentTransform = flyerImage.transform;
	CGAffineTransform newTransform     = CGAffineTransformScale(currentTransform, newScale, newScale);
	
	flyerImage.transform = newTransform;
	
	previousScale = [sender scale];
}


/**
 Move scaled flyer.
 */
- (IBAction)panFlyer:(UIPanGestureRecognizer *)sender {
	CGPoint newCenter = [sender translationInView:self.view];
	
	if ([sender state] == UIGestureRecognizerStateBegan) {
		beginX = flyerImage.center.x;
		beginY = flyerImage.center.y;
	}
	
	newCenter = CGPointMake(beginX + newCenter.x, beginY + newCenter.y);
	
	[flyerImage setCenter:newCenter];
}


/**
 Reset scaled flyer.
 */
- (IBAction)resetFlyer:(UITapGestureRecognizer *)sender {
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.3];
	
	navBar.hidden = !navBar.hidden;
	
	flyerImage.transform = CGAffineTransformIdentity;
	[flyerImage setCenter:CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2)];
	
	[UIView commitAnimations];
}


/**
 Close flyers.
 */
- (IBAction)closeFlyer:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
//	[self.presentingViewController dismissModalViewControllerAnimated:YES];
}

@end
