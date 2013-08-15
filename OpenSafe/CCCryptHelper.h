//
//  CCCryptWrapper.h
//  OpenSafe
//
//  Created by tom on 4/3/13.
//
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonKeyDerivation.h>
#import "KeychainItemWrapper.h"
#import "Utilities.h"

@interface CCCryptHelper : NSObject

@property (atomic, strong) NSData *masterPassword;

+(id)sharedInstance;

-(void)promptForMasterPassword;
-(NSData *)encrypt:(NSString *)data;
-(NSString *)decrypt:(NSData *)data;
-(NSData *)generateSalt;
-(NSData *)PBKDF2DeriveKeyFromPassword:(NSString *)password;
-(NSData *)AES128EncryptData:(NSData *)data withKey:(NSData *)key;
-(NSData *)AES128DecryptData:(NSData *)data withKey:(NSData *)key;

@end
