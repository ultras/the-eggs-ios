////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// 
///  Copyright 2009 Aurora Feint, Inc.
/// 
///  Licensed under the Apache License, Version 2.0 (the "License");
///  you may not use this file except in compliance with the License.
///  You may obtain a copy of the License at
///  
///  	http://www.apache.org/licenses/LICENSE-2.0
///  	
///  Unless required by applicable law or agreed to in writing, software
///  distributed under the License is distributed on an "AS IS" BASIS,
///  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
///  See the License for the specific language governing permissions and
///  limitations under the License.
/// 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#import "SampleLeaderboardListController.h"
#import "OpenFeint.h"
#import "OFHighScoreService.h"
#import "OFLeaderboardService.h"
#import "OFLeaderboard.h"
#import "OFPaginatedSeries.h"
#import "OFViewHelper.h"
#import "OpenFeint+Dashboard.h"

@implementation SampleLeaderboardListController

@synthesize leaderboardPicker, highScoreTextField, displayTextTextField, customDataTextField, submitButton;

- (void)closeKeyboard
{
	[self.highScoreTextField resignFirstResponder];
	[self.displayTextTextField resignFirstResponder];
	[self.customDataTextField resignFirstResponder];
}

- (void)disableCloseKbdButton
{
	[self.navigationItem.rightBarButtonItem setEnabled:false];
}

- (void)enableCloseKbdButton
{
	[self.navigationItem.rightBarButtonItem setEnabled:true];
}

- (void)onLoadedLeaderboards:(OFPaginatedSeries*)loadedLeaderboards
{
	OFSafeRelease(leaderboards);
	leaderboards = [loadedLeaderboards.objects copy];
	[leaderboards retain];
	if ([leaderboards count] > 0)
	{
		OFLeaderboard* leaderboard = (OFLeaderboard*)[leaderboards objectAtIndex:0];
		OFSafeRelease(selectedLeaderboardId);
		selectedLeaderboardId = [leaderboard.resourceId retain];
	}
	[self.leaderboardPicker reloadAllComponents];
}

- (void)onFailedLoadingLeaderboards
{
	OFSafeRelease(selectedLeaderboardId);
	NSLog(@"Error downloading leaderboards");
}

- (void)awakeFromNib
{
	self.highScoreTextField.manageScrollViewOnFocus = NO;
	self.highScoreTextField.closeKeyboardOnReturn = YES;
	
	self.displayTextTextField.manageScrollViewOnFocus = NO;
	self.displayTextTextField.closeKeyboardOnReturn = YES;

	self.customDataTextField.manageScrollViewOnFocus = NO;
	self.customDataTextField.closeKeyboardOnReturn = YES;
	
	self.leaderboardPicker.delegate = self;
	self.leaderboardPicker.dataSource = self;
	
	[self disableCloseKbdButton];
	
	OFSafeRelease(selectedLeaderboardId);

	OFDelegate success(self, @selector(onLoadedLeaderboards:));
	OFDelegate failure(self, @selector(onFailedLoadingLeaderboards));
	[OFLeaderboardService getIndexOnSuccess:success onFailure:failure];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	UIScrollView* scrollView = OFViewHelper::findFirstScrollView(self.view);
	scrollView.contentSize = OFViewHelper::sizeThatFitsTight(scrollView);
}

- (void)_highScoreSet
{
	OFLog(@"High score has been set");
}

- (void)_highScoreFailedSetting
{
	OFLog(@"High score has NOT been set");
}

- (void)_setHighScoreOnThread:(NSDictionary*)params
{
	if (!selectedLeaderboardId)
	{
		return;
	}
	
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	
	OFDelegate success = OFDelegate(self, @selector(_highScoreSet));	
	OFDelegate failure = OFDelegate(self, @selector(_highScoreFailedSetting));
	
	NSNumber* score = [params objectForKey:@"score"];
	NSString* displayText = [params objectForKey:@"displayText"];
	displayText = [displayText isEqualToString:@""] ? nil : displayText;
	NSString* customData = [params objectForKey:@"customData"];
	customData = [customData isEqualToString:@""] ? nil : customData;
	
	[OFHighScoreService setHighScore:[score longLongValue] withDisplayText:displayText withCustomData:customData forLeaderboard:selectedLeaderboardId silently:NO onSuccess:success onFailure:failure];
	
	[pool release];
}

- (IBAction)setHighScore
{
	if (selectedLeaderboardId)
	{
		NSNumber* num = [NSNumber numberWithLongLong:[self.highScoreTextField.text longLongValue]];
		NSString* displayText = self.displayTextTextField.text;	
		NSString* customData = self.customDataTextField.text;
		NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:num, @"score", displayText, @"displayText", customData, @"customData", nil];
		// High scores do not need to be set on a separate thread. It is done here for testing purposes.
		[NSThread detachNewThreadSelector:@selector(_setHighScoreOnThread:) toTarget:self withObject:dictionary];
	}
	[self closeKeyboard];
}

- (IBAction)openLeaderboard
{
	if (selectedLeaderboardId)
	{
		[self closeKeyboard];
		[OpenFeint launchDashboardWithHighscorePage:selectedLeaderboardId];
	}
}

- (bool)canReceiveCallbacksNow
{
	return YES;
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
	self.leaderboardPicker = nil;
	self.highScoreTextField = nil;
	self.displayTextTextField = nil;
	self.customDataTextField = nil;
	self.submitButton = nil;
	OFSafeRelease(leaderboards);
	[super dealloc];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	if (leaderboards)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	if (leaderboards)
	{
		return [leaderboards count];
	}
	else
	{
		return 0;
	}
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	if (leaderboards)
	{
		OFLeaderboard* curLeaderboard = (OFLeaderboard*)[leaderboards objectAtIndex:row];
		return curLeaderboard.name;
	}
	else
	{
		return @"";
	}
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	NSInteger numLeaderboards = (NSInteger)[leaderboards count];
	if (leaderboards && numLeaderboards > row && row >= 0)
	{
		OFLeaderboard* leaderboard = (OFLeaderboard*)[leaderboards objectAtIndex:row];
		selectedLeaderboardId = [leaderboard.resourceId retain];
	}
	else
	{
		OFSafeRelease(selectedLeaderboardId);
	}
	[self closeKeyboard];
}

@end
