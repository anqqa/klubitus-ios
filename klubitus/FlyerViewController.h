//
//  FlyerViewController.h
//  klubitus
//
//  Created by Antti Qvickström on 8/25/12.
//  Copyright (c) 2012 Antti Qvickström. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FlyerViewController : UIViewController <UIGestureRecognizerDelegate> {
	IBOutlet UIBarButtonItem      *closeButton;
	IBOutlet UIBarButtonItem       *flipButton;
	IBOutlet UIImageView           *flyerImage;
	IBOutlet UINavigationBar           *navBar;
	IBOutlet UITapGestureRecognizer *doubleTap;
	IBOutlet UITapGestureRecognizer *singleTap;
	
	CGFloat previousScale;
	CGFloat beginX;
	CGFloat beginY;
}

@property (strong, nonatomic) id detailItem;

- (IBAction)closeFlyer:(id)sender;

@end
