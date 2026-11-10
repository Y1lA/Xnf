#import "MFAppDelegate.h"
#import "MFEditionsViewController.h"
#import "MFTheme.h"

@implementation MFAppDelegate

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    MFEditionsViewController *editions = [[MFEditionsViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:editions];
    nav.navigationBar.tintColor = MFAccent();
    nav.navigationBar.translucent = NO;
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = MFBackground();
        appearance.shadowColor = MFSeparator();
        appearance.titleTextAttributes = @{NSForegroundColorAttributeName: MFText()};
        nav.navigationBar.standardAppearance = appearance;
        nav.navigationBar.scrollEdgeAppearance = appearance;
        nav.navigationBar.compactAppearance = appearance;
    }
    self.window.rootViewController = nav;
    self.window.tintColor = MFAccent();
    self.window.backgroundColor = MFBackground();
    [self.window makeKeyAndVisible];
    return YES;
}

@end
