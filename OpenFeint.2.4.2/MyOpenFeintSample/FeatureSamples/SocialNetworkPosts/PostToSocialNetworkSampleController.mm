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

#import "PostToSocialNetworkSampleController.h"

#import "OFSocialNotificationService.h"
#import "OFViewHelper.h"
#import "OFDefaultTextField.h"
#import "OFPaginatedSeries.h"
#import "OFUsersCredentialService.h"
#import "OFUsersCredential.h"
#import "OFTableSectionDescription.h"

#import "OpenFeint.h"
#import "OpenFeint+UserOptions.h"

@implementation PostToSocialNetworkSampleController

- (void)_retrievedCredentials:(OFPaginatedSeries*)credentialResources
{
	NSMutableArray* credentials = [[(OFTableSectionDescription*)[[credentialResources objects] objectAtIndex:0] page] objects];

	NSString* buttonTitle = @"Post to ";
	BOOL foundOneCredential = NO;
	for (OFUsersCredential* credential in credentials)
	{
		if ([credential isTwitter] || [credential isFacebook])
		{
			if (foundOneCredential)
				buttonTitle = [buttonTitle stringByAppendingString:@" / "];

			buttonTitle = [buttonTitle stringByAppendingString:[OFUsersCredential getDisplayNameForCredentialType:[credential credentialType]]];
			foundOneCredential = YES;
		}
	}
	
	if (!foundOneCredential)
	{
		[[[[UIAlertView alloc] initWithTitle:@"Error" message:@"You must have linked your twitter or facebook accounts in order to post to a social network!" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] autorelease] show];
		postButton.enabled = NO;
	}
	else
	{
		[postButton setTitle:buttonTitle forState:UIControlStateNormal];
		[postButton setTitle:buttonTitle forState:UIControlStateHighlighted];
		[postButton setTitle:buttonTitle forState:UIControlStateDisabled];
		[postButton setTitle:buttonTitle forState:UIControlStateSelected];

		postButton.enabled = YES;
	}
	
	[loadingView removeFromSuperview];
	OFSafeRelease(loadingView);
}

- (void)_failedRetrievingCredentials
{
	[[[[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed determine which social networks you are linked with. Disabling social network posting." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] autorelease] show];
	postButton.enabled = NO;

	[loadingView removeFromSuperview];
	OFSafeRelease(loadingView);
}

- (void)awakeFromNib
{
	messageField.closeKeyboardOnReturn = YES;
	imageNameField.closeKeyboardOnReturn = YES;
	
	imageNameField.manageScrollViewOnFocus = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	UIScrollView* scrollView = OFViewHelper::findFirstScrollView(self.view);
	scrollView.contentSize = OFViewHelper::sizeThatFitsTight(scrollView);

	postButton.enabled = NO;

	CGRect frame = CGRectZero;
	frame.size = self.view.bounds.size;
	loadingView = [[UIView alloc] initWithFrame:frame];
	[loadingView setBackgroundColor:[UIColor colorWithWhite:0.f alpha:0.75f]];
	UIActivityIndicatorView* spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
	[spinner setCenter:CGPointMake(frame.size.width * 0.5f, frame.size.height * 0.5f)];
	[spinner startAnimating];	
	[loadingView addSubview:spinner];
	[self.view addSubview:loadingView];

	OFDelegate success(self, @selector(_retrievedCredentials:));
	OFDelegate failed(self, @selector(_failedRetrievingCredentials));
	[OFUsersCredentialService 
		getIndexOnSuccess:success
		onFailure:failed
		onlyIncludeLinkedCredentials:YES];
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
	OFSafeRelease(messageField);
	OFSafeRelease(imageNameField);
	OFSafeRelease(postButton);
	OFSafeRelease(loadingView);
	[super dealloc];
}

- (IBAction)post
{
	if ([messageField.text length] == 0)
		return;
	
	if ([imageNameField.text length] > 0)
		[OFSocialNotificationService sendWithText:messageField.text imageNamed:imageNameField.text];
	else
		[OFSocialNotificationService sendWithText:messageField.text];
}

- (bool)canReceiveCallbacksNow
{
	return YES;
}

@end