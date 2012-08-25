//
//  FlyerViewController.m
//  klubitus
//
//  Created by Antti Qvickström on 8/25/12.
//  Copyright (c) 2012 Antti Qvickström. All rights reserved.
//

#import "FlyerViewController.h"
#import "DictionaryHelper.h"
#import "UIImageView+AFNetworking.h"


@interface FlyerViewController ()
- (void)configureView;
@end

@implementation FlyerViewController 


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
		NSString *flyer     = [event stringForKey:@"flyer_front"];
		NSURL *flyerURL     = [NSURL URLWithString:flyer];
		if (flyerURL != nil) {
			[flyerImage setImageWithURL:flyerURL];
		}
		
		NSString *flyerBack = [event stringForKey:@"flyer_back"];
		NSURL *flyerBackURL = [NSURL URLWithString:flyerBack];
		if (flyerBackURL != nil) {
			flipButton.enabled = YES;
			
			// Preload back
			UIImageView *preload = [UIImageView new];
			[preload setImageWithURL:flyerBackURL];
			
		} else {
			flipButton.enabled = NO;
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

/**
 Initialize view.
 */
- (void)viewDidLoad {
	[super viewDidLoad];
	
	[self configureView];
	// Do any additional setup after loading the view.
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
 Prepare segue.
 */
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([[segue identifier] isEqualToString:@"showFlyerBack"]) {
		[[segue destinationViewController] setDetailItem:self.detailItem];
	}
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
 Flip flyer after swipe.
 */
- (IBAction)flipFlyer:(id)sender {
	if (flipButton.enabled) {
		[self performSegueWithIdentifier:@"showFlyerBack" sender:sender];
	}
}


/**
 Close flyers.
 */
- (IBAction)closeFlyer:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

@end
