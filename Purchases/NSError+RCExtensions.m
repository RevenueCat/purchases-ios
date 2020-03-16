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
    if (self.code == RCNetworkError) {
        return NO;
    }

    if (self.userInfo[RCSuccessfullySyncedKey] == nil) {
        return NO;
    }

    NSNumber *successfullySyncedNumber = self.userInfo[RCSuccessfullySyncedKey];

    return successfullySyncedNumber.boolValue;
}

- (nullable NSDictionary *)subscriberAttributesErrors {
    return self.userInfo[RCAttributeErrorsKey];
}

@end


NS_ASSUME_NONNULL_END
