//
//  PurchasesCoreSwift.h
//  PurchasesCoreSwift
//
//  Created by Andrés Boedo on 8/18/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for PurchasesCoreSwift.
FOUNDATION_EXPORT double PurchasesCoreSwiftVersionNumber;

//! Project version string for PurchasesCoreSwift.
FOUNDATION_EXPORT const unsigned char PurchasesCoreSwiftVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <PurchasesCoreSwift/PublicHeader.h>

@class RCPurchaserInfo, RCIntroEligibility, RCOfferings;
@class SKPaymentTransaction, SKProduct, SKPaymentDiscount;

NS_ASSUME_NONNULL_BEGIN
/**
 Completion block for calls that send back a `PurchaserInfo`
 */
typedef void (^RCReceivePurchaserInfoBlock)(RCPurchaserInfo * _Nullable, NSError * _Nullable);

/**
 Completion block for `-[RCPurchases checkTrialOrIntroductoryPriceEligibility:completionBlock:]`
 */
typedef void (^RCReceiveIntroEligibilityBlock)(NSDictionary<NSString *, RCIntroEligibility *> *);

/**
 Completion block for `-[RCPurchases offeringsWithCompletionBlock:]`
 */
typedef void (^RCReceiveOfferingsBlock)(RCOfferings * _Nullable, NSError * _Nullable);

/**
 Completion block for `-[RCPurchases productsWithIdentifiers:completionBlock:]`
 */
typedef void (^RCReceiveProductsBlock)(NSArray<SKProduct *> *);

/**
 Completion block for `-[RCPurchases purchaseProduct:withCompletionBlock:]`
 */
typedef void (^RCPurchaseCompletedBlock)(SKPaymentTransaction * _Nullable,
                                         RCPurchaserInfo * _Nullable,
                                         NSError * _Nullable,
                                         BOOL userCancelled);

/**
 Deferred block for `purchases:shouldPurchasePromoProduct:defermentBlock:`
 */
typedef void (^RCDeferredPromotionalPurchaseBlock)(RCPurchaseCompletedBlock);

/**
 * Deferred block for `-[RCPurchases paymentDiscountForProductDiscount:product:completion:]`
 */
API_AVAILABLE(ios(12.2), macos(10.14.4), watchos(6.2), macCatalyst(13.0), tvos(12.2))
typedef void (^RCPaymentDiscountBlock)(SKPaymentDiscount * _Nullable, NSError * _Nullable);

NS_ASSUME_NONNULL_END
