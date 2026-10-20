#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef void (^POInstalledAppSearchSelection)(NSString *bundleIdentifier);

@interface POInstalledAppSearchController : UIViewController
- (instancetype)initWithSelection:(POInstalledAppSearchSelection)selection;
- (void)focusSearch;
@end
NS_ASSUME_NONNULL_END
