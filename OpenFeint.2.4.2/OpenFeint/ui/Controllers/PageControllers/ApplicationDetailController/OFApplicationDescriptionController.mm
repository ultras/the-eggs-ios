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

#import "OFDependencies.h"
#import "OFApplicationDescriptionController.h"
#import "OFTableSectionDescription.h"
#import "OFTableSectionCellDescription.h"
#import "OFService.h"
#import "OFControllerLoader.h"
#import "OFApplicationDescriptionService.h"
#import "OpenFeintSettings.h"
#import "OpenFeint+Private.h"
#import "OFActionRequestType.h"
#import "OFProvider.h"
#import "MPOAuthAPIRequestLoader.h"
#import "MPURLRequestParameter.h"
#import "NSObject+WeakLinking.h"
#import "OpenFeint+UserOptions.h"

@implementation OFApplicationDescriptionController

@synthesize resourceId, appBannerPlacement;

+ (id)applicationDescriptionForId:(NSString*)resourceId appBannerPlacement:(NSString*)usersDisplayContext
{
	OFApplicationDescriptionController* me = (OFApplicationDescriptionController*)OFControllerLoader::load(@"ApplicationDescription");
	me.resourceId = resourceId;
	me.appBannerPlacement = usersDisplayContext;
	return me;
}

- (void)loadWebContent
{
	mWebView.delegate = self;
	
	NSMutableArray* params = [NSMutableArray array];

	bool landscape = [OpenFeint isInLandscapeMode];	
	MPURLRequestParameter* landscapeParam = [[[MPURLRequestParameter alloc] initWithName:@"landscape" andValue:[NSString stringWithFormat:@"%u", landscape]] autorelease];
	unsigned int dashboardOrientation = [OpenFeint getDashboardOrientation];
	[params addObject:landscapeParam];	
	
	MPURLRequestParameter* orientationParam = [[[MPURLRequestParameter alloc] initWithName:@"orientation" andValue:[NSString stringWithFormat:@"%u", dashboardOrientation]] autorelease];
	[params addObject:orientationParam];

	if(self.appBannerPlacement)
	{
		MPURLRequestParameter* appBannerPlacementParam = [[[MPURLRequestParameter alloc] initWithName:@"app_banner_placement" andValue:self.appBannerPlacement] autorelease];
		[params addObject:appBannerPlacementParam];
	}

	NSString* action = [NSString stringWithFormat:@"client_applications/%@/application_descriptions.iphone", self.resourceId];
	NSURLRequest* request = 
	[[[OpenFeint provider] 
	  getRequestForAction:action
	  withParameters:params
	  withHttpMethod:@"GET"
	  withSuccess:OFDelegate()
	  withFailure:OFDelegate()
	  withRequestType:OFActionRequestForeground
	  withNotice:[OFNotificationData foreGroundDataWithText:@"Downloaded Application Description"]
	  requiringAuthentication:true] getConfiguredRequest];
	
	[mWebView loadRequest:request];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.view bringSubviewToFront:mLoadingView];
	self.title = @"Info";
	[self loadWebContent];
}

- (void)viewWillDisappear:(BOOL)animated
{
	mWebView.delegate = nil;
	[mWebView stopLoading];
	[super viewWillDisappear:animated];
}

- (void)loadView
{	
	UIView* contentView = [[UIView alloc] initWithFrame:CGRectZero];
	contentView.backgroundColor = [UIColor clearColor];
	
	self.view = contentView;
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.view.autoresizesSubviews = YES;
	
	[contentView release];

	mWebView = [[UIWebView alloc] initWithFrame:CGRectZero];
	mWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	mWebView.autoresizesSubviews = YES;	
	mWebView.backgroundColor = [UIColor clearColor];
	mWebView.scalesPageToFit = YES;
	mWebView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

	[mWebView trySet:@"dataDetectorTypes" with:OF_OS_3_ENUM_ARG(UIDataDetectorTypeNone) elseSet:@"detectsPhoneNumbers" with:NO];
	
	[self.view addSubview:mWebView];

	CGRect fullscreen = [[UIScreen mainScreen] bounds];
	CGPoint indicatorCenter = CGPointZero;
	if ([OpenFeint isInLandscapeMode])
	{
		indicatorCenter = CGPointMake(fullscreen.size.height * 0.5f, fullscreen.size.width * 0.5f);
	}
	else
	{
		indicatorCenter = CGPointMake(fullscreen.size.width * 0.5f, fullscreen.size.height * 0.5f);
	}
	float const kLoadingViewSize = 40.0f;
	mLoadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	mLoadingView.frame = CGRectMake(indicatorCenter.x - (kLoadingViewSize * 0.5f), indicatorCenter.y - (kLoadingViewSize * 0.5f), kLoadingViewSize, kLoadingViewSize);
	mLoadingView.hidesWhenStopped = YES;
	[mLoadingView stopAnimating];
	[self.view addSubview:mLoadingView];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	[mLoadingView startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	[mLoadingView stopAnimating];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType 
{
	NSURL* url = [request URL];
	
	// send app-store links to app store
	if ([[url host] isEqualToString:@"phobos.apple.com"])
	{
		[[UIApplication sharedApplication] openURL:url];
		return NO;
	}
	else if([[url host] isEqualToString:@"oauth_redirect.openfeint.com"])
	{
		NSString* action = [url path];
		NSURLRequest* request = 
			[[[OpenFeint provider] 
				getRequestForAction:action
				withParameters:nil
				withHttpMethod:@"GET"
				withSuccess:OFDelegate()
				withFailure:OFDelegate()
				withRequestType:OFActionRequestForeground
				withNotice:[OFNotificationData foreGroundDataWithText:@"Downloaded"]
				requiringAuthentication:true] getConfiguredRequest];
		
		[mWebView loadRequest:request];		
		return NO;
	}
	
	return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	[mLoadingView stopAnimating];
	
	NSString* centeredErrorMessage = 
	@"<html>"
	@"	<head>"
	@"		<meta http-equiv=\"Content-Type\" content=\"text/html; charset=iso-8859-1\">"
	@"		<meta name=\"viewport\" content=\"width=device-width, user-scalable=no\" />"
	@"	</head>"
	@"	<body bgcolor=\"#000000\" style=\"width:320px;height:480px;margin:0px;padding:0px; color: white; font-family: Helvetica\">"
	@"		<table width=\"320\" height=\"480\">"
	@"			<tr valign=\"middle\">"
	@"				<td align=\"center\">%@</td>"
	@"			</tr>"
	@"		</table>"
	@"	</body>"
	@"</html>";
							
	
    NSString* errorString = nil;
	
	if(error.code == NSURLErrorNotConnectedToInternet && error.domain == NSURLErrorDomain)
	{
		errorString = @"You must be connected to the Internet.<br /><br /><i style=\"color: gray\">Try again once you're online.</i>";
	}
	else
	{
		errorString = [NSString stringWithFormat:@"Oops! An Error Occurred. Press the Back button to return to the previous screen.<br /><br /><i style=\"color: gray\">%@</i>", error.localizedDescription];
	}										

	[mWebView loadHTMLString:[NSString stringWithFormat:centeredErrorMessage, errorString] baseURL:nil];
}

- (void)dealloc
{	
	self.appBannerPlacement = nil;
	self.resourceId = nil;
	
	OFSafeRelease(mWebView);
	OFSafeRelease(mLoadingView);
	[super dealloc];
}

@end