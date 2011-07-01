#pragma once

#import <UIKit/UIKit.h>
#import "OFCallbackable.h"

@class OFChallengeDefinition;
@class OFDefaultTextField;

@interface SendSampleChallengeController : UIViewController<OFCallbackable, UIPickerViewDataSource, UIPickerViewDelegate>
{
	IBOutlet UIPickerView* challengePicker;
	
	IBOutlet OFDefaultTextField* challengeText;

	IBOutlet UISlider* value1;
	IBOutlet UISlider* value2;
	IBOutlet UISwitch* value3;
	IBOutlet UISegmentedControl* value4;
	
	NSMutableArray* challengeDefinitions;
	OFChallengeDefinition* selectedChallenge;
}

- (IBAction)sendChallenge;

- (bool)canReceiveCallbacksNow;

@end
