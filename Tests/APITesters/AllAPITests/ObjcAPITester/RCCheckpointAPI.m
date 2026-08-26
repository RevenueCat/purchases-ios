//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RCCheckpointAPI.m
//
//  Created by Rick van der Linden.
//

#if ENABLE_CHECKPOINTS_OBJC

@import RevenueCat;
@import RevenueCatUI;

#import "RCCheckpointAPI.h"

@implementation RCCheckpointAPI

+ (void)checkAPI {
    RCPurchases *purchases = RCPurchases.sharedPurchases;
    RCCheckpointParams *params = [[RCCheckpointParams alloc] initWithCustomVariables:@{
        @"name": @"Rick",
        @"subscriber": @YES,
    }];
    NSDictionary * __unused customVariables = params.customVariables;

    [purchases checkpointWithIdentifier:@"test_checkpoint"
                                  params:params
                              completion:^(RCCheckpointResult * _Nullable result, NSError * _Nullable error) {
        RCCheckpointInfo *checkpoint = result.checkpoint;
        NSString * __unused identifier = checkpoint.identifier;
        NSDictionary * __unused resultCustomVariables = checkpoint.customVariables;

        if ([result isKindOfClass:RCCheckpointPaywallPresentedResult.class]) {
            RCCheckpointPaywallOutcome *outcome = ((RCCheckpointPaywallPresentedResult *)result).paywallOutcome;
            if ([outcome isKindOfClass:RCCheckpointPaywallPurchasedOutcome.class]) {
                RCCustomerInfo * __unused customerInfo =
                    ((RCCheckpointPaywallPurchasedOutcome *)outcome).customerInfo;
            } else if ([outcome isKindOfClass:RCCheckpointPaywallRestoredOutcome.class]) {
                RCCustomerInfo * __unused customerInfo =
                    ((RCCheckpointPaywallRestoredOutcome *)outcome).customerInfo;
            } else if ([outcome isKindOfClass:RCCheckpointPaywallErrorOutcome.class]) {
                NSError * __unused paywallError = ((RCCheckpointPaywallErrorOutcome *)outcome).error;
            } else if ([outcome isKindOfClass:RCCheckpointPaywallDismissedOutcome.class]) {
                RCCheckpointPaywallDismissedOutcome * __unused dismissed =
                    (RCCheckpointPaywallDismissedOutcome *)outcome;
            }
        } else if ([result isKindOfClass:RCCheckpointReceivedOfferingResult.class]) {
            RCOffering * __unused offering = ((RCCheckpointReceivedOfferingResult *)result).offering;
        } else if ([result isKindOfClass:RCCheckpointNoActionResult.class]) {
            RCCheckpointNoActionReason *reason = ((RCCheckpointNoActionResult *)result).reason;
            NSString * __unused value = reason.value;
        }
    }];

    [purchases checkpointWithIdentifier:@"test_checkpoint"
                                  params:nil
                              completion:^(RCCheckpointResult * _Nullable result, NSError * _Nullable error) {}];
}

@end

#endif
