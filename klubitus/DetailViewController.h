//
//  DetailViewController.h
//  klubitus
//
//  Created by Antti Qvickström on 8/19/12.
//  Copyright (c) 2012 Antti Qvickström. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController {
	IBOutlet UIImageView  *flyerImage;
	IBOutlet UILabel       *nameLabel;
	IBOutlet UILabel   *locationLabel;
	IBOutlet UILabel       *dateLabel;
	IBOutlet UILabel       *timeLabel;
	IBOutlet UILabel        *ageLabel;
	IBOutlet UILabel      *musicLabel;
	IBOutlet UILabel      *priceLabel;
	IBOutlet UITextView       *djText;
	
	IBOutlet UIView    *separatorView;
	IBOutlet UIView   *separator2View;
}

@property (strong, nonatomic) id detailItem;

@end
