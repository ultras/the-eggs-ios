#import <UIKit/UIKit.h>
#import "OFCallbackable.h"

@interface SampleRootController : UIViewController<OFCallbackable>

- (IBAction) onLaunchDashboard;

- (IBAction) onExploreChallenges;
- (IBAction) onExploreLeaderboards;
- (IBAction) onExploreAchivements;
- (IBAction) onExploreSocialNetworkPosts;
- (IBAction) onExploreCloudStorage;
@end
