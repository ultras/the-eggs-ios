#pragma once

#import <UIKit/UIKit.h>
#import "OFCallbackable.h"

@class OFChallengeToUser;
@class OFDefaultTextField;

@interface PlayAChallengeController : UIViewController<OFCallbackable>
{
	IBOutlet UILabel* challengeTextLabel;
	IBOutlet UILabel* userMessageLabel;
	IBOutlet UISegmentedControl* result;
	IBOutlet OFDefaultTextField* resultDescription;

	IBOutlet UISlider* value1;
	IBOutlet UISlider* value2;
	IBOutlet UISwitch* value3;
	IBOutlet UISegmentedControl* value4;
	
	OFChallengeToUser* challenge;
	NSData* data;
}

- (void)setChallenge:(OFChallengeToUser*)_challenge;
- (void)setData:(NSData*)_data;

- (IBAction)completeChallenge;

- (bool)canReceiveCallbacksNow;

@end
