#import "PlayAChallengeController.h"

#import "OFChallengeToUser.h"
#import "OFChallenge.h"
#import "OFChallengeDefinition.h"
#import "OFChallengeService.h"
#import "OFViewHelper.h"
#import "OFDefaultTextField.h"

#import "OpenFeint.h"

#import "SampleChallengeData.h"

@implementation PlayAChallengeController

- (void)setChallenge:(OFChallengeToUser*)_challenge
{
	OFSafeRelease(challenge);
	challenge = [_challenge retain];
	
	challengeTextLabel.text = challenge.challenge.challengeDescription;
	userMessageLabel.text = challenge.challenge.userMessage;
}

- (void)setData:(NSData*)_data
{
	OFSafeRelease(data);
	data = [_data retain];
	
	SampleChallengeData& challengeData = *(SampleChallengeData*)[data bytes];
	value1.value = challengeData.slider_one;
	value2.value = challengeData.slider_two;
	[value3 setOn:challengeData.some_switch];
	value4.selectedSegmentIndex = challengeData.segment_value;
}

- (void)awakeFromNib
{
	resultDescription.manageScrollViewOnFocus = YES;
	resultDescription.closeKeyboardOnReturn = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	UIScrollView* scrollView = OFViewHelper::findFirstScrollView(self.view);
	scrollView.contentSize = OFViewHelper::sizeThatFitsTight(scrollView);
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	const unsigned int numOrientations = 4;
	UIInterfaceOrientation myOrientations[numOrientations] = { UIInterfaceOrientationPortrait, UIInterfaceOrientationLandscapeLeft, UIInterfaceOrientationLandscapeRight, UIInterfaceOrientationPortraitUpsideDown };
	return [OpenFeint shouldAutorotateToInterfaceOrientation:interfaceOrientation withSupportedOrientations:myOrientations andCount:numOrientations];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[OpenFeint setDashboardOrientation:self.interfaceOrientation];
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (void)dealloc
{
	OFSafeRelease(challengeTextLabel);
	OFSafeRelease(userMessageLabel);
	OFSafeRelease(result);
	OFSafeRelease(resultDescription);

	OFSafeRelease(value1);
	OFSafeRelease(value2);
	OFSafeRelease(value3);
	OFSafeRelease(value4);

	[super dealloc];
}

- (void)_submittedCompletedChallenge
{
	[self dismissModalViewControllerAnimated:YES];
	
	SampleChallengeData applicationStateForThisAttemptedChallengeSession;
	[data getBytes:(void*)&applicationStateForThisAttemptedChallengeSession length:sizeof(SampleChallengeData)];
	applicationStateForThisAttemptedChallengeSession.slider_one *= 0.25f;
	applicationStateForThisAttemptedChallengeSession.slider_two *= 1.25f;
	applicationStateForThisAttemptedChallengeSession.some_switch = !applicationStateForThisAttemptedChallengeSession.some_switch;

	NSData* resultData = [NSData dataWithBytes:(void const*)&applicationStateForThisAttemptedChallengeSession length:sizeof(SampleChallengeData)];

	[OFChallengeService
		displayChallengeCompletedModal:challenge 
		resultData:resultData 
		result:challenge.result 
		resultDescription:resultDescription.text 
		reChallengeDescription:@"new challenge description based on resultData goes here"];
}

- (void)_failedSubmittingCompletedChallenge
{
	[[[[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed submitting challenge result!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] autorelease] show];
}

- (IBAction)completeChallenge
{
	if (!challenge)
		return;

	switch (result.selectedSegmentIndex)
	{
		case 0: challenge.result = kChallengeResultRecipientWon; break;
		case 1: challenge.result = kChallengeResultRecipientLost; break;
		case 2: challenge.result = kChallengeResultTie; break;
	}

	OFDelegate success(self, @selector(_submittedCompletedChallenge));	
	OFDelegate failure(self, @selector(_failedSubmittingCompletedChallenge));
	[OFChallengeService 
		submitChallengeResult:challenge.resourceId 
		result:challenge.result 
		resultDescription:resultDescription.text 
		onSuccess:success 
		onFailure:failure];
}

- (bool)canReceiveCallbacksNow
{
	return YES;
}

@end