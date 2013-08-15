//
//  AppDelegate.m
//  OpenSafe
//
//  Created by tom on 4/3/13.
//
//

#import "AppDelegate.h"
#import "CCCryptHelper.h"

@implementation AppDelegate

@synthesize splashView;
@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //Clear keychain on first run in case of reinstallation
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"HazRun"]) {
        NSArray *secItemClasses = @[(__bridge id)kSecClassGenericPassword,
                                    (__bridge id)kSecClassInternetPassword,
                                    (__bridge id)kSecClassCertificate,
                                    (__bridge id)kSecClassKey,
                                    (__bridge id)kSecClassIdentity];
        for (id secItemClass in secItemClasses) {
            NSDictionary *spec = @{(__bridge id)kSecClass:secItemClass};
            SecItemDelete((__bridge CFDictionaryRef)spec);
        }
        [[NSUserDefaults standardUserDefaults] setValue:@"TRUE" forKey:@"HazRun"];
    }
    
    return YES;
}

- (void)removeSplash:(NSNotification *)notification {
    // iterates through subviews and finds the Splash screen (by tag number) and removes it from the stack to allow app interaction.
    // this is a callback for the OSValidMasterPasswordNotification NSNotification.
    for (UIView *subview in window.subviews) {
        subview.userInteractionEnabled = TRUE;
        if (subview.tag == 24) {
            [subview removeFromSuperview];
        }
    }
}

- (void)dismissAlertViews:(NSArray *)subviews {
    // iterate through subviews and remove any UIAlertViews that are found. If the user enters an incorrect password they have to background and relaunch the application to try again due to a prevantative UIAlertView. We need to make sure we remove it so when the app is relaunched it doesn't prevent usability if the correct password was entered.
    Class AVClass = [UIAlertView class];
    for (UIView * subview in subviews){
        if ([subview isKindOfClass:AVClass]){
            [(UIAlertView *)subview dismissWithClickedButtonIndex:[(UIAlertView *)subview cancelButtonIndex] animated:NO];
        } else {
            [self dismissAlertViews:subview.subviews];
        }
    }
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // dismiss alert views in case the user entered an incorrect password
    [self dismissAlertViews:application.windows];
    // push a blank splash screen onto the view stack to hide sensitive info from unauthd view
    splashView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, 320, 480)];
    splashView.image = [UIImage imageNamed:@"Default.png"];
    splashView.tag = 24;
    // some defense in depth. even though users should never interact with the splash screen make sure screen touches arent passed to the underlying views
    for (UIView *subview in window.subviews) {
        subview.userInteractionEnabled = FALSE;
        if (subview.tag == 24) {
            return;
        }
    }
    [window addSubview:splashView];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // dismiss alert views in case the user entered an incorrect password
    [self dismissAlertViews:application.windows];
    // push a blank splash screen onto the view stack to hide sensitive info from unauthd view
    splashView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0, 320, 480)];
    splashView.image = [UIImage imageNamed:@"Default.png"];
    splashView.tag = 24;
    [window addSubview:splashView];
    
    // register successful authentication callbacks.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(removeSplash:)
                                                 name:kOSMasterPasswordValidNotification
                                               object:nil];
    // authenticate the user
    CCCryptHelper *crypt = [CCCryptHelper sharedInstance];
    [crypt promptForMasterPassword];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

@end
