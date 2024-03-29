//
//  Utilities.m
//  OpenSafe
//
//  Created by tom on 4/5/13.
//
//

#import "Utilities.h"

@implementation Utilities

+ (NSString *)base64Encode:(NSData *)data {
    const uint8_t* input = (const uint8_t*)[data bytes];
    NSInteger length = [data length];
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData* enc_data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)enc_data.mutableBytes;
    
    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
        output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:enc_data encoding:NSUTF8StringEncoding];
}

+ (NSData *)base64Decode:(NSString *)string {
    {
        if ([string length] == 0) {
            return nil;
        }
        char encodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        if (string == nil)
            [NSException raise:NSInvalidArgumentException format:nil];
        if ([string length] == 0)
            return [NSData data];
        
        static char *decodingTable = NULL;
        if (decodingTable == NULL)
        {
            decodingTable = malloc(256);
            if (decodingTable == NULL)
                return nil;
            memset(decodingTable, CHAR_MAX, 256);
            NSUInteger i;
            for (i = 0; i < 64; i++)
                decodingTable[(short)encodingTable[i]] = i;
        }
        
        const char *characters = [string cStringUsingEncoding:NSASCIIStringEncoding];
        if (characters == NULL)     //  Not an ASCII string!
            return nil;
        char *bytes = malloc((([string length] + 3) / 4) * 3);
        if (bytes == NULL)
            return nil;
        NSUInteger length = 0;
        
        NSUInteger i = 0;
        while (YES)
        {
            char buffer[4];
            short bufferLength;
            for (bufferLength = 0; bufferLength < 4; i++)
            {
                if (characters[i] == '\0')
                    break;
                if (isspace(characters[i]) || characters[i] == '=')
                    continue;
                buffer[bufferLength] = decodingTable[(short)characters[i]];
                if (buffer[bufferLength++] == CHAR_MAX)      //  Illegal character!
                {
                    free(bytes);
                    return nil;
                }
            }
            
            if (bufferLength == 0)
                break;
            if (bufferLength == 1)      //  At least two characters are needed to produce one byte!
            {
                free(bytes);
                return nil;
            }
            
            //  Decode the characters in the buffer to bytes.
            bytes[length++] = (buffer[0] << 2) | (buffer[1] >> 4);
            if (bufferLength > 2)
                bytes[length++] = (buffer[1] << 4) | (buffer[2] >> 2);
            if (bufferLength > 3)
                bytes[length++] = (buffer[2] << 6) | buffer[3];
        }
        
        realloc(bytes, length);
        return [NSData dataWithBytesNoCopy:bytes length:length];
    }
}

@end
