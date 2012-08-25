//
//  FlyerBackViewController.h
//  klubitus
//
//  Created by Antti Qvickström on 8/26/12.
//  Copyright (c) 2012 Antti Qvickström. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FlyerBackViewController : UIViewController {
	IBOutlet UIBarButtonItem *closeButton;
	IBOutlet UIBarButtonItem  *flipButton;
	IBOutlet UIImageView      *flyerImage;
}

@property (strong, nonatomic) id detailItem;

- (IBAction)closeFlyer:(id)sender;

@end
