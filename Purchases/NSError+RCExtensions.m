//
// Created by Andrés Boedo on 2/24/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import "NSError+RCExtensions.h"
#import "RCPurchasesErrors.h"
#import "RCBackend.h"

NS_ASSUME_NONNULL_BEGIN


@implementation NSError (RCExtensions)

- (BOOL)successfullySynced {
    BOOL isNetworkError = self.code == RCNetworkError;
    BOOL successfullySynced = (
        !isNetworkError
        && self.userInfo[RCSuccessfullySyncedKey] != nil
        && ((NSNumber *) self.userInfo[RCSuccessfullySyncedKey]).boolValue
    );
    if (successfullySynced) {
        return YES;
    } else if (self.userInfo[NSUnderlyingErrorKey]) {
        NSError *underlyingError = (NSError *) self.userInfo[NSUnderlyingErrorKey];
        if (underlyingError) {
            return underlyingError.successfullySynced;
        }
    }

    return NO;
}

@end


NS_ASSUME_NONNULL_END
