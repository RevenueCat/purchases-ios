//
// Created by Andrés Boedo on 3/4/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import "NSData+RCExtensions.h"

NS_ASSUME_NONNULL_BEGIN


@interface NSData (RCExtensions)
@end


NS_ASSUME_NONNULL_END


@implementation NSData (RCExtensions)

- (NSString *)dataAsString {
    NSMutableString *deviceTokenString = [NSMutableString string];
    [self enumerateByteRangesUsingBlock:^(const void *bytes,
                                          NSRange byteRange,
                                          BOOL *stop) {

        for (NSUInteger i = 0; i < byteRange.length; ++i) {
            [deviceTokenString appendFormat:@"%02x", ((uint8_t *) bytes)[i]];
        }
    }];
    return deviceTokenString;
}


@end
