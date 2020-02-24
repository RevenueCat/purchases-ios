//
// Created by Andrés Boedo on 2/24/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import "NSError+RCExtensions.h"
#import "RCPurchasesErrors.h"

NS_ASSUME_NONNULL_BEGIN


@interface NSError (RCExtensions)
@end


NS_ASSUME_NONNULL_END


@implementation NSError (RCExtensions)

- (BOOL)isBackendError {
    BOOL isBackendErrorDomain = [self.domain isEqualToString:RCBackendErrorDomain];
    if (isBackendErrorDomain) {
        return YES;
    } else if (self.userInfo[NSUnderlyingErrorKey]) {
        NSError *underlyingError = (NSError *) self.userInfo[NSUnderlyingErrorKey];
        if (underlyingError) {
            return underlyingError.isBackendError;
        }
    }

    return NO;
}

@end
