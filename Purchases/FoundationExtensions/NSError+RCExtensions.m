//
// Created by Andrés Boedo on 2/24/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

@import PurchasesCoreSwift;

#import "NSError+RCExtensions.h"

NS_ASSUME_NONNULL_BEGIN


@implementation NSError (RCExtensions)

- (BOOL)rc_successfullySynced {
    if (self.code == RCNetworkError) {
        return NO;
    }

    if (self.userInfo[RCBackend.RCSuccessfullySyncedKey] == nil) {
        return NO;
    }

    NSNumber *successfullySyncedNumber = self.userInfo[RCBackend.RCSuccessfullySyncedKey];

    return successfullySyncedNumber.boolValue;
}

- (nullable NSDictionary *)rc_subscriberAttributesErrors {
    return self.userInfo[RCBackend.RCAttributeErrorsKey];
}

@end


NS_ASSUME_NONNULL_END
