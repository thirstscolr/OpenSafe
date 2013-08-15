//
//  Utilities.h
//  OpenSafe
//
//  Created by tom on 4/5/13.
//
//

#import <Foundation/Foundation.h>

//#define NSLog(...)

#define kOSMasterPasswordTestStringId @"kOSMasterPasswordTestStringId"
#define kOSMasterPasswordTestStrId @"kOSMasterPasswordTestStrId"
#define kOSMasterPasswordSalt @"kOSMasterPasswordSalt"
#define kOSMasterPasswordValidNotification @"OSMasterPasswordValidNotification"

@interface Utilities : NSObject

+ (NSString *)base64Encode:(NSData *)data;
+ (NSData *)base64Decode:(NSString *)string;

@end
