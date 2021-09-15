//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RCBackendErrorCodeAPI.m
//
//  Created by Madeline Beyl on 9/7/21.

#import "RCBackendErrorCodeAPI.h"
@import RevenueCat;

@implementation RCBackendErrorCodeAPI

+ (void)checkEnums {
    RCBackendErrorCode errCode = RCBackendStoreProblem;
    switch(errCode){
        case RCBackendInvalidPlatform:
        case RCBackendStoreProblem:
        case RCBackendCannotTransferPurchase:
        case RCBackendInvalidReceiptToken:
        case RCBackendInvalidAppStoreSharedSecret:
        case RCBackendInvalidPaymentModeOrIntroPriceNotProvided:
        case RCBackendProductIdForGoogleReceiptNotProvided:
        case RCBackendInvalidPlayStoreCredentials:
        case RCBackendInternalServerError:
        case RCBackendEmptyAppUserId:
        case RCBackendInvalidAuthToken:
        case RCBackendInvalidAPIKey:
        case RCBackendBadRequest:
        case RCBackendPlayStoreQuotaExceeded:
        case RCBackendPlayStoreInvalidPackageName:
        case RCBackendPlayStoreGenericError:
        case RCBackendUserIneligibleForPromoOffer:
        case RCBackendInvalidAppleSubscriptionKey:
        case RCBackendInvalidSubscriberAttributes:
        case RCBackendInvalidSubscriberAttributesBody:
            NSLog(@"%ld", (long)errCode);
            break;
    }
}

@end
