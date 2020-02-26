//
// Created by Andrés Boedo on 2/24/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import "NSError+RCExtensions.h"
#import "RCPurchasesErrors.h"

NS_ASSUME_NONNULL_BEGIN


@implementation NSError (RCExtensions)

- (BOOL)didBackendReceiveRequestCorrectly {
    BOOL isNetworkError = self.code == RCNetworkError;
    BOOL didBackendReceiveRequest = (
        !isNetworkError
        && self.userInfo[RCFinishableKey] != nil
        && ((NSNumber *) self.userInfo[RCFinishableKey]).boolValue
    );
    if (didBackendReceiveRequest) {
        return YES;
    } else if (self.userInfo[NSUnderlyingErrorKey]) {
        NSError *underlyingError = (NSError *) self.userInfo[NSUnderlyingErrorKey];
        if (underlyingError) {
            return underlyingError.didBackendReceiveRequestCorrectly;
        }
    }

    return NO;
}

@end


NS_ASSUME_NONNULL_END
