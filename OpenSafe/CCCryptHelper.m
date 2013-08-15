//
//  CCCryptWrapper.m
//  OpenSafe
//
//  Created by tom on 4/3/13.
//
//

#import "CCCryptHelper.h"

@implementation CCCryptHelper

@synthesize masterPassword;

static CCCryptHelper *sharedInstance = nil;

// Get the shared instance and create it if necessary.
+ (CCCryptHelper *)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [[super allocWithZone:NULL] init];
    }
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    masterPassword = nil;
    return self;
}

- (void)promptForMasterPassword {
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Master password"
                                                     message:@"Enter password"
                                                    delegate: self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"OK", nil];
    [alert setAlertViewStyle:UIAlertViewStyleSecureTextInput];
    [[alert textFieldAtIndex:0] setPlaceholder:@"Password"];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    // grab the master salt out of the keychain
    KeychainItemWrapper *saltKC = [[KeychainItemWrapper alloc] initWithIdentifier:kOSMasterPasswordSalt accessGroup:nil];
    NSData* salt = [Utilities base64Decode:[saltKC objectForKey:(__bridge id)kSecValueData]];
    if ([salt length] == 0) {
        salt = [self generateRandomData];
        // store it in the keychain for future PBKDF2 derivation
        [saltKC setObject:[Utilities base64Encode:salt] forKey:(__bridge id)kSecValueData];
    }
    masterPassword = [self PBKDF2DeriveKeyFromPassword:[[alertView textFieldAtIndex:0] text] withSalt:salt];

    // determine if the password was valid
    KeychainItemWrapper *mTest = [[KeychainItemWrapper alloc] initWithIdentifier:kOSMasterPasswordTestStringId accessGroup:nil];
    NSString *storedTest = [mTest objectForKey:(__bridge id)kSecValueData];
    if ([storedTest length] == 0) {
        // this is the first login attempt so we need to store both the generated data to test and encrypted value into the keychain
        KeychainItemWrapper *test = [[KeychainItemWrapper alloc] initWithIdentifier:kOSMasterPasswordTestStrId accessGroup:nil];
        NSString *testString = [[NSString alloc] initWithData:[self generateRandomData] encoding:NSUTF8StringEncoding];
        [test setObject:testString forKey:(__bridge id)kSecValueData];
        NSString *baseLine = [Utilities base64Encode:[self encrypt:testString]];
        [mTest setObject:baseLine forKey:(__bridge id)kSecValueData];
        // now reset the test string value
        storedTest = [mTest objectForKey:(__bridge id)kSecValueData];
    }
    KeychainItemWrapper *test = [[KeychainItemWrapper alloc] initWithIdentifier:kOSMasterPasswordTestStrId accessGroup:nil];
    NSString *testString = [test objectForKey:(__bridge id)kSecValueData];
    NSString *derivedStr = [Utilities base64Encode:[self encrypt:testString]];
    
    if (![storedTest isEqualToString:derivedStr]) {
        // master password is icorrect
        UIAlertView *anAlert = [[UIAlertView alloc] initWithTitle:@"Hit Home Button to Exit"
                                                          message:@"Invalid password"
                                                         delegate:nil
                                                cancelButtonTitle:nil
                                                otherButtonTitles:nil];
        [anAlert show];
    } else {
        // Let the AppDelegate know it can display the screen
        [[NSNotificationCenter defaultCenter] postNotificationName:kOSMasterPasswordValidNotification object:self];
    }
}

- (NSData *)encrypt:(NSString *)data {
    NSData *encData = [self AES128EncryptData:[data dataUsingEncoding:NSUTF8StringEncoding]
                                      withKey:masterPassword];
    return encData;
}

- (NSString *)decrypt:(NSData *)data {
    NSData *encData = [self AES128DecryptData:data
                                      withKey:masterPassword];
    return [[NSString alloc] initWithData:encData encoding:NSUTF8StringEncoding];
}

- (NSData *)generateRandomData {
    uint8_t data[32];
    int err = 0;

    err = SecRandomCopyBytes(kSecRandomDefault, 8, data);
    if(err != noErr) {
        @throw [NSException exceptionWithName:@"..." reason:@"..." userInfo:nil];
    }
    NSData* randomData = [[NSData alloc] initWithBytes:data length:8];
    return randomData;
}

- (NSData *)PBKDF2DeriveKeyFromPassword:(NSString *)password withSalt:(NSData *)salt {
    NSData* passData = [password dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData * derivedKey = [NSMutableData dataWithLength:kCCKeySizeAES256];
    int keyDerivationResult = CCKeyDerivationPBKDF(kCCPBKDF2,
                                                   passData.bytes,
                                                   passData.length,
                                                   salt.bytes,
                                                   salt.length,
                                                   kCCPRFHmacAlgSHA256,
                                                   10000,
                                                   derivedKey.mutableBytes,
                                                   32);
    if (keyDerivationResult == kCCParamError) {
        return nil;
    }
    return derivedKey;
}

- (NSData *)AES128EncryptData:(NSData *)data withKey:(NSData *)key {
    NSMutableData *encData = [NSMutableData dataWithLength:(data.length + kCCBlockSizeAES128)];
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding,
                                          key.bytes,
                                          key.length,
                                          NULL /* initialization vector (optional) */,
                                          data.bytes,
                                          data.length, /* input */
                                          encData.mutableBytes,
                                          encData.length, /* output */
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        encData.length = numBytesEncrypted;
        return encData;
    }
    
    return nil;
}

- (NSData *)AES128DecryptData:(NSData *)data withKey:(NSData *)key {
    NSMutableData *decData = [NSMutableData dataWithLength:data.length + kCCBlockSizeAES128];
    
    size_t numBytesEncrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding,
                                          key.bytes,
                                          key.length,
                                          NULL /* initialization vector (optional) */,
                                          data.bytes,
                                          data.length, /* input */
                                          decData.mutableBytes,
                                          decData.length, /* output */
                                          &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        decData.length = numBytesEncrypted;
        return decData;
    }
    
    return nil;
}

@end
