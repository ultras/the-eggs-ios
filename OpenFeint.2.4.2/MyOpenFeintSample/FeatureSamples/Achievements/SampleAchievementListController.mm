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

#import "SampleAchievementListController.h"

#import "OFAchievement.h"
#import "OFAchievementService.h"
#import "OFPaginatedSeries.h"
#import "OFPaginatedSeriesHeader.h"
#import "OFImageView.h"
#import "OFViewHelper.h"

#import "OpenFeint.h"
#import "OpenFeint+UserOptions.h"

@implementation SampleAchievementListController

- (void)_updateUIWithAchievement:(OFAchievement*)achievement
{
	iconView.imageUrl = achievement.iconUrl;
	titleLabel.text = achievement.title;
	descriptionLabel.text = achievement.description;
	[isUnlocked setOn:achievement.isUnlocked animated:YES];
}

- (void)_reloadAllData
{
	[achievements removeAllObjects];
	
	[loadingView removeFromSuperview];
	OFSafeRelease(loadingView);
	CGRect frame = CGRectZero;
	frame.size = self.view.bounds.size;
	loadingView = [[UIView alloc] initWithFrame:frame];
	[loadingView setBackgroundColor:[UIColor colorWithWhite:0.f alpha:0.75f]];
	UIActivityIndicatorView* spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
	[spinner setCenter:CGPointMake(frame.size.width * 0.5f, frame.size.height * 0.5f)];
	[spinner startAnimating];	
	[loadingView addSubview:spinner];
	[self.view addSubview:loadingView];

	OFDelegate success(self, @selector(loadedAchievements:));
	OFDelegate failure(self, @selector(failedLoadingAchievements));
	[OFAchievementService 
		getAchievementsForApplication:[OpenFeint clientApplicationId] 
		comparedToUser:[OpenFeint lastLoggedInUserId] 
		page:1 
		silently:YES
		onSuccess:success 
		onFailure:failure];
}

- (void)loadedAchievements:(OFPaginatedSeries*)loadedAchievements
{
	[achievements addObjectsFromArray:loadedAchievements.objects];
	
	if (loadedAchievements.header.currentPage != loadedAchievements.header.totalPages)
	{
		OFDelegate success(self, @selector(loadedAchievements:));
		OFDelegate failure(self, @selector(failedLoadingAchievements));
		[OFAchievementService 
			getAchievementsForApplication:[OpenFeint clientApplicationId] 
			comparedToUser:nil
			page:(loadedAchievements.header.currentPage + 1)
			silently:YES
			onSuccess:success 
			onFailure:failure];
	}
	else
	{
		[achievementPicker reloadAllComponents];
		if ([achievements count] > 0)
		{
			selectedAchievement = [[achievements objectAtIndex:0] retain];
			[self _updateUIWithAchievement:selectedAchievement];
			[achievementPicker selectRow:0 inComponent:0 animated:YES];
		}
		[loadingView removeFromSuperview];
		OFSafeRelease(loadingView);
	}
}

- (void)failedLoadingAchievements
{
	[[[[UIAlertView alloc] initWithTitle:@"Failed downloading achievements" message:@"The achievement list will be incomplete" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] autorelease] show];
	[achievementPicker reloadAllComponents];
	if ([achievements count] > 0)
	{
		[self _updateUIWithAchievement:[achievements objectAtIndex:0]];
		[achievementPicker selectRow:0 inComponent:0 animated:YES];
	}
	[loadingView removeFromSuperview];
	OFSafeRelease(loadingView);
}

- (void)awakeFromNib
{
	achievements = [[NSMutableArray arrayWithCapacity:25] retain];
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
	OFSafeRelease(achievementPicker);
	OFSafeRelease(achievements);
	OFSafeRelease(selectedAchievement);
	OFSafeRelease(titleLabel);
	OFSafeRelease(descriptionLabel);
	OFSafeRelease(isUnlocked);
	OFSafeRelease(loadingView);
	OFSafeRelease(contentView);
	[super dealloc];
}

- (IBAction)unlockSelected
{
	if (selectedAchievement)
	{
		OFDelegate reloadDelegate(self, @selector(_reloadAllData));
		[OFAchievementService unlockAchievement:selectedAchievement.resourceId onSuccess:reloadDelegate onFailure:OFDelegate()];
	}
}

- (IBAction)queueUnlock
{
	if (selectedAchievement)
	{
		[OFAchievementService queueUnlockedAchievement:selectedAchievement.resourceId];
		//[[[[UIAlertView alloc] initWithTitle:@"Not Implemented" message:@"I haven't written this yet" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] autorelease] show];
	}
}

- (IBAction)submitQueued
{
	if (selectedAchievement)
	{
		OFDelegate reloadDelegate(self, @selector(_reloadAllData));
		[OFAchievementService submitQueuedUnlockedAchievements:reloadDelegate onFailure:OFDelegate()];
	}
}

- (bool)canReceiveCallbacksNow
{
	return YES;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return achievements ? 1 : 0;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return [achievements count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	if ((NSInteger)[achievements count] <= row)
		return @"";
		
	OFAchievement* achievement = (OFAchievement*)[achievements objectAtIndex:row];
	return achievement.title;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	if (row == -1)
	{
		return;
	}
	if ((NSInteger)[achievements count] <= row)
	{
		OFSafeRelease(selectedAchievement);
	}
	else
	{
		selectedAchievement = [(OFAchievement*)[achievements objectAtIndex:row] retain];
		[self _updateUIWithAchievement:selectedAchievement];
	}
}

@end