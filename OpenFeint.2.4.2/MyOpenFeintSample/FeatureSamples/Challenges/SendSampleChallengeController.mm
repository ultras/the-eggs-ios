#import "SendSampleChallengeController.h"

#import "OFChallengeDefinition.h"
#import "OFChallengeDefinitionService.h"
#import "OFChallengeService.h"
#import "OFPaginatedSeries.h"
#import "OFViewHelper.h"
#import "OFDefaultTextField.h"

#import "OpenFeint.h"
#import "OpenFeint+UserOptions.h"

#import "SampleChallengeData.h"

@implementation SendSampleChallengeController

- (void)_sendChallenge
{
    [challengeText resignFirstResponder];
    
	SampleChallengeData data;
	data.slider_one = value1.value;
	data.slider_two = value2.value;
	data.some_switch = value3.on;
	data.segment_value = value4.selectedSegmentIndex;
	
	NSData* challengeData = [NSData dataWithBytes:(void const*)&data length:sizeof(SampleChallengeData)];

	[OFChallengeService 
		displaySendChallengeModal:selectedChallenge.resourceId 
		challengeText:challengeText.text
		challengeData:challengeData];
}

- (void)_reloadAllData
{
	[challengeDefinitions removeAllObjects];
	
	OFDelegate success(self, @selector(loadedChallenges:));
	OFDelegate failure(self, @selector(failedLoadingChallenges));
	[OFChallengeDefinitionService getIndexOnSuccess:success onFailure:failure];
}

- (void)loadedChallenges:(OFPaginatedSeries*)loadedChallenges
{
	[challengeDefinitions addObjectsFromArray:loadedChallenges.objects];
	
	[challengePicker reloadAllComponents];
	if ([challengeDefinitions count] > 0)
	{
		selectedChallenge = [(OFChallengeDefinition*)[challengeDefinitions objectAtIndex:0] retain];
	}
}

- (void)failedLoadingChallenges
{
	[[[[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed downloading challenge definitions" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] autorelease] show];
	OFSafeRelease(selectedChallenge);
	[challengeDefinitions removeAllObjects];
}

- (void)awakeFromNib
{
	challengeDefinitions = [[NSMutableArray arrayWithCapacity:10] retain];
	
	challengeText.manageScrollViewOnFocus = YES;
	challengeText.closeKeyboardOnReturn = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	UIScrollView* scrollView = OFViewHelper::findFirstScrollView(self.view);
	scrollView.contentSize = OFViewHelper::sizeThatFitsTight(scrollView);

	[self _reloadAllData];
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
	OFSafeRelease(challengePicker);

	OFSafeRelease(challengeText);

	OFSafeRelease(value1);
	OFSafeRelease(value2);
	OFSafeRelease(value3);
	OFSafeRelease(value4);

	OFSafeRelease(challengeDefinitions);
	OFSafeRelease(selectedChallenge);
	[super dealloc];
}

- (IBAction)sendChallenge
{
	if (!selectedChallenge)
		return;
	
	if ([challengeText.text length] == 0)
	{
		[[[[UIAlertView alloc] initWithTitle:@"Problem" message:@"Challenge text must not be (null)" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] autorelease] show];
		return;
	}
	
	if ([OpenFeint hasUserApprovedFeint])
	{
		[self _sendChallenge];
	}
	else
	{
		OFDelegate nilDelegate;
		OFDelegate sendChallengeDelegate(self, @selector(_sendChallenge));
		[OpenFeint presentUserFeintApprovalModal:sendChallengeDelegate deniedDelegate:nilDelegate];
	}
}

- (bool)canReceiveCallbacksNow
{
	return YES;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return challengeDefinitions ? 1 : 0;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return [challengeDefinitions count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	if ((NSInteger)[challengeDefinitions count] <= row)
		return @"";
		
	OFChallengeDefinition* challenge = (OFChallengeDefinition*)[challengeDefinitions objectAtIndex:row];
	return challenge.title;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	if ((NSInteger)[challengeDefinitions count] <= row && row >= 0)
	{
		OFSafeRelease(selectedChallenge);
	}
	else if (challengeDefinitions)
	{
		selectedChallenge = [(OFChallengeDefinition*)[challengeDefinitions objectAtIndex:row] retain];
	}
}

@end