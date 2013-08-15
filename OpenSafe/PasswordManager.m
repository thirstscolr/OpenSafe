//
//  PasswordManager.m
//  OpenSafe
//
//  Created by tom on 4/3/13.
//
//

#import "PasswordManager.h"

@implementation PasswordManager

static PasswordManager *sharedInstance = nil;

// Get the shared instance and create it if necessary.
+ (PasswordManager *)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [[super allocWithZone:NULL] init];
    }
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    return self;
}

-(BOOL)generateAndStorePassword:(NSString *)identifier {
    NSString *password = [self generatePassword];
    return [self storePassword:password forIdentifier:identifier];
    return NO;
}

-(NSString *)generatePassword {
    NSString *alphabet  = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY0123456789!@#$%^&*()_-+=?";
    NSMutableString *s = [NSMutableString stringWithCapacity:32];
    for (NSUInteger i = 0U; i < 20; i++) {
        u_int32_t r = arc4random() % [alphabet length];
        unichar c = [alphabet characterAtIndex:r];
        [s appendFormat:@"%C", c];
    }
    return s;
}

-(BOOL)storePassword:(NSString *)password forIdentifier:(NSString *)identifier {
    CCCryptHelper *crypt = [CCCryptHelper sharedInstance];
    NSData *encPass = [crypt encrypt:password];
    NSString *b64EncPass = [Utilities base64Encode:encPass];
    KeychainItemWrapper *newPass = [[KeychainItemWrapper alloc] initWithIdentifier:identifier
                                                                       accessGroup:nil];
    [newPass setObject:b64EncPass forKey:(__bridge id)kSecValueData];
    return YES;
}

-(NSString *)retreivePassword:(NSString *)identifier {
    KeychainItemWrapper *pass = [[KeychainItemWrapper alloc] initWithIdentifier:identifier accessGroup:nil];
    CCCryptHelper *crypt = [CCCryptHelper sharedInstance];
    NSData *enc_pass = [Utilities base64Decode:[pass objectForKey:(__bridge id)kSecValueData]];
    NSString *password = [crypt decrypt:enc_pass];
    return password;
}

-(NSArray *)retrieveAllIdentifiers {
    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  (__bridge id)kCFBooleanTrue, (__bridge id)kSecReturnAttributes,
                                  (__bridge id)kSecMatchLimitAll, (__bridge id)kSecMatchLimit,
                                  (__bridge id)kSecClassGenericPassword, (__bridge id)kSecClass,
                                  nil];
    NSDictionary *result = nil;
    NSMutableArray *identifiers = [[NSMutableArray alloc] init];
    SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef)&result);
    for (NSDictionary *item in result) {
        NSString *svc = [item objectForKey:(__bridge id)(kSecAttrService)];
        if (!([svc isEqualToString:kOSMasterPasswordTestStringId ] || [svc isEqualToString:kOSMasterPasswordSalt])) {
            [identifiers addObject:svc];
        }
    }
    return identifiers;
}

-(BOOL)deletePassword:(NSString *)identifier {
    KeychainItemWrapper *pass = [[KeychainItemWrapper alloc] initWithIdentifier:identifier accessGroup:nil];
    if([pass deleteKeychainItem])
        return YES;
    return NO;
}


@end
