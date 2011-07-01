//
//  CloudStorageDemoController.m
//  OpenFeint
//
//  Created by Joe on 11/13/09.
//  Copyright 2009 Aurora Feint, Inc.  All rights reserved.
//

#import "CloudStorageDemoController.h"
#import "OFCloudStorageService.h"
#import "OpenFeint.h"


@implementation CloudStorageDemoController

@synthesize statusTextBox;
@synthesize blobNameTextBox;
@synthesize blobPayloadTextBox;


- (void)blobSend_SuccessDelegate{
	blobNameTextBox.text = @"";
	blobPayloadTextBox.text = @"";

	statusTextBox.text = @"sent";
}


- (void)blobSend_FailureDelegate{
	statusTextBox.text = @"failed to send";
}


- (void)blobFetch_SuccessDelegate:(NSData*)blob{
	NSString		*receivedString = nil;
	NSUInteger		 blobLen	= [blob length];
	//const void	*blobBytes	= [blob bytes]; // Can enable this for peaking in debugger.
	
	if (blobLen <= 0){
		receivedString = @"";
	}else{
		receivedString = [[NSString alloc] initWithData: blob encoding: NSUTF8StringEncoding];
		[receivedString autorelease];
	}
		
	blobPayloadTextBox.text = receivedString;
	statusTextBox.text = @"fetched";
}


- (void)blobFetch_FailureDelegate{
	statusTextBox.text = @"failed to fetch";
}


- (IBAction)onBtnBlobSend:(id)sender{
	NSData		*payloadData = [blobPayloadTextBox.text dataUsingEncoding: NSUTF8StringEncoding];
	OFDelegate	 successDelegate(self, @selector(blobSend_SuccessDelegate));
	OFDelegate	 failureDelegate(self, @selector(blobSend_FailureDelegate));
	
	statusTextBox.text = @"sending";
	
	[OFCloudStorageService uploadBlob: payloadData
		withKey: blobNameTextBox.text
		onSuccess: successDelegate
		onFailure: failureDelegate
	];
}


- (IBAction)onBtnBlobFetch:(id)sender{
	OFDelegate successDelegate(self, @selector(blobFetch_SuccessDelegate:));
	OFDelegate failureDelegate(self, @selector(blobFetch_FailureDelegate));
	
	statusTextBox.text = @"fetching";

	[OFCloudStorageService downloadBlobWithKey: blobNameTextBox.text
		onSuccess: successDelegate
		onFailure: failureDelegate
	];
}


- (void)btnClear_SuccessDelegate{
	blobNameTextBox.text = @"";
	blobPayloadTextBox.text = @"";
	statusTextBox.text = @"";
}


- (void)btnClear_FailureDelegate{
	statusTextBox.text = @"failed to clear";
}


- (IBAction)onBtnClear:(id)sender{
	OFDelegate successDelegate(self, @selector(btnClear_SuccessDelegate));
	OFDelegate failureDelegate(self, @selector(btnClear_FailureDelegate));
	
	statusTextBox.text = @"clearing";
	
	successDelegate.invoke();
	
	// Can enable the following to test [OpenFeint presentUserFeintApprovalModal ...].
	// if (! [OpenFeint isOnline]){
	//	[OpenFeint presentUserFeintApprovalModal:successDelegate deniedDelegate:failureDelegate];
	// }
}


- (IBAction) onTextFieldDoneEditing:(id) sender{
	statusTextBox.text = @"";
	[sender resignFirstResponder];
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


- (void)viewDidLoad {
	statusTextBox.text = @"Ready for command.";
	[super viewDidLoad];
}


- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


///////////////////////////////////////////////////////////////////
// init & dealloc
///////////////////////////////////////////////////////////////////

- (id) init{
	if (![super init]){
		return nil;
	}
	
	return self;
}


- (void)dealloc {
	[statusTextBox release];
	[blobNameTextBox release];
	[blobPayloadTextBox release];
    [super dealloc];
}

///////////////////////////////////////////////////////////////////
// OFCallbackable protocol requirements (stubbed until needed).
///////////////////////////////////////////////////////////////////

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

@end
