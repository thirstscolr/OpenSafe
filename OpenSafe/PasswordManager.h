//
//  PasswordManager.h
//  OpenSafe
//
//  Created by tom on 4/3/13.
//
//

#import <Foundation/Foundation.h>
#import "CCCryptHelper.h"
#import "KeychainItemWrapper.h"
#import "Utilities.h"

@interface PasswordManager : NSObject

+(id)sharedInstance;

-(void)promptForMasterPassword;

-(BOOL)generateAndStorePassword:(NSString *)identifier;
-(BOOL)storePassword:(NSString *)password forIdentifier:(NSString *)identifier;
-(NSString *)generatePassword;

-(NSString *)retreivePassword:(NSString *)identifier;
-(BOOL)deletePassword:(NSString *)identifier;

-(NSArray *)retrieveAllIdentifiers;

@end
