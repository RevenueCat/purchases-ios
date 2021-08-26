//
//  Purchases.h
//  Purchases
//
//  Created by Andrés Boedo on 8/18/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for Purchases.
FOUNDATION_EXPORT double PurchasesVersionNumber;

//! Project version string for Purchases.
FOUNDATION_EXPORT const unsigned char PurchasesVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Purchases/PublicHeader.h>

@class RCPurchaserInfo, RCIntroEligibility, RCOfferings;
@class SKPaymentTransaction, SKProduct, SKPaymentDiscount;

NS_ASSUME_NONNULL_BEGIN
/**
 Completion block for calls that send back a `PurchaserInfo`
 */
typedef void (^RCReceivePurchaserInfoBlock)(RCPurchaserInfo * _Nullable, NSError * _Nullable)
NS_SWIFT_UNAVAILABLE("Use ReceivePurchaserInfoBlock instead.");


/**
 Completion block for `-[RCPurchases checkTrialOrIntroductoryPriceEligibility:completionBlock:]`
 */
typedef void (^RCReceiveIntroEligibilityBlock)(NSDictionary<NSString *, RCIntroEligibility *> *)
NS_SWIFT_UNAVAILABLE("Use ReceiveIntroEligibilityBlock instead.");

/**
 Completion block for `-[RCPurchases offeringsWithCompletionBlock:]`
 */
typedef void (^RCReceiveOfferingsBlock)(RCOfferings * _Nullable, NSError * _Nullable)
NS_SWIFT_UNAVAILABLE("Use ReceiveOfferingsBlock instead.");

/**
 Completion block for `-[RCPurchases productsWithIdentifiers:completionBlock:]`
 */
typedef void (^RCReceiveProductsBlock)(NSArray<SKProduct *> *)
NS_SWIFT_UNAVAILABLE("Use ReceiveProductsBlock instead.");

/**
 Completion block for `-[RCPurchases purchaseProduct:withCompletionBlock:]`
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

/**
 * Deferred block for `-[RCPurchases paymentDiscountForProductDiscount:product:completion:]`
 */
API_AVAILABLE(ios(12.2), macos(10.14.4), watchos(6.2), macCatalyst(13.0), tvos(12.2))
typedef void (^RCPaymentDiscountBlock)(SKPaymentDiscount * _Nullable, NSError * _Nullable)
NS_SWIFT_UNAVAILABLE("Use PaymentDiscountBlock instead.");

NS_ASSUME_NONNULL_END
