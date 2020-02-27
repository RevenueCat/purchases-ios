//
// Created by Andrés Boedo on 2/24/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import "NSError+RCExtensions.h"
#import "RCPurchasesErrors.h"
#import "RCBackend.h"

NS_ASSUME_NONNULL_BEGIN


@implementation NSError (RCExtensions)

- (BOOL)shouldMarkSyncedKeyPresent {
    BOOL isNetworkError = self.code == RCNetworkError;
    BOOL shouldMarkSynced = (
        !isNetworkError
        && self.userInfo[RCShouldMarkSyncedKey] != nil
        && ((NSNumber *) self.userInfo[RCShouldMarkSyncedKey]).boolValue
    );
    if (shouldMarkSynced) {
        return YES;
    } else if (self.userInfo[NSUnderlyingErrorKey]) {
        NSError *underlyingError = (NSError *) self.userInfo[NSUnderlyingErrorKey];
        if (underlyingError) {
            return underlyingError.shouldMarkSyncedKeyPresent;
        }
    }

    return NO;
}

@end


NS_ASSUME_NONNULL_END
