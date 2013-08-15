//
//  AppDelegate.h
//  OpenSafe
//
//  Created by tom on 4/3/13.
//
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, atomic) UIImageView *splashView;

- (void)removeDefaultSubview:(NSNotification *)notification;

@end
