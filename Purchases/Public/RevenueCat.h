//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RevenueCat.h
//
//  Created by Andrés Boedo on 8/18/20.
//

#import <Foundation/Foundation.h>

//! Project version number for Purchases.
FOUNDATION_EXPORT double RevenueCatVersionNumber;

//! Project version string for Purchases.
FOUNDATION_EXPORT const unsigned char RevenueCatVersionString[];

@class RCPurchaserInfo, RCIntroEligibility, RCOfferings;
@class SKPaymentTransaction, SKProduct, SKPaymentDiscount;

NS_ASSUME_NONNULL_BEGIN
/**
 Completion block for `-[RCPurchases purchaseProduct:withCompletion:]`
 */
typedef void (^RCPurchaseCompletedBlock)(SKPaymentTransaction * _Nullable,
                                         RCPurchaserInfo * _Nullable,
                                         NSError * _Nullable,
                                         BOOL userCancelled)
NS_SWIFT_UNAVAILABLE("Use PurchaseCompletedBlock instead.");

/**
 Deferred block for `purchases:shouldPurchasePromoProduct:defermentBlock:`
 */
typedef void (^RCDeferredPromotionalPurchaseBlock)(RCPurchaseCompletedBlock)
NS_SWIFT_UNAVAILABLE("Use DeferredPromotionalPurchaseBlock instead.");

NS_ASSUME_NONNULL_END
