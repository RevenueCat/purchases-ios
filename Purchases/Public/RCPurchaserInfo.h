//
//  RCPurchaserInfo.h
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCEntitlementInfos, RCTransaction;

NS_ASSUME_NONNULL_BEGIN

/**
 A container for the most recent purchaser info returned from `RCPurchases`. These objects are non-mutable and do not update automatically.
 */
NS_SWIFT_NAME(Purchases.PurchaserInfo)
@interface RCPurchaserInfo : NSObject

/// Entitlements attached to this purchaser info
@property (nonatomic, readonly) RCEntitlementInfos *entitlements;

/// All *subscription* product identifiers with expiration dates in the future.
@property (nonatomic, readonly) NSSet<NSString *> *activeSubscriptions;

/// All product identifiers purchases by the user regardless of expiration.
@property (nonatomic, readonly) NSSet<NSString *> *allPurchasedProductIdentifiers;

/// Returns the latest expiration date of all products, nil if there are none
@property (readonly, nullable) NSDate *latestExpirationDate;

/// Returns all product IDs of the non-subscription purchases a user has made.
@property (nonatomic, readonly) NSSet<NSString *> *nonConsumablePurchases DEPRECATED_MSG_ATTRIBUTE("use nonSubscriptionTransactions");

/// Returns all the non-subscription purchases a user has made.
/// The purchases are ordered by purchase date in ascending order.
@property (nonatomic, readonly) NSArray<RCTransaction *> *nonSubscriptionTransactions;

/**
Returns the build number (in iOS) or the marketing version (in macOS) for the version of the application when the user bought the app.
This corresponds to the value of CFBundleVersion (in iOS) or CFBundleShortVersionString (in macOS) in the Info.plist file when the purchase was originally made.
Use this for grandfathering users when migrating to subscriptions.

 
 @note This can be nil, see -[RCPurchases restoreTransactionsForAppStore:]
 */
@property (nonatomic, readonly, nullable) NSString *originalApplicationVersion;

/**
Returns the purchase date for the version of the application when the user bought the app.
Use this for grandfathering users when migrating to subscriptions.

@note This can be nil, see -[RCPurchases restoreTransactionsForAppStore:]
 */
@property (nonatomic, readonly, nullable) NSDate *originalPurchaseDate;

/**
 Returns the fetch date of this Purchaser info.
 @note Can be nil if was cached before we added this
 */
@property (nonatomic, readonly, nullable) NSDate *requestDate;

/// The date this user was first seen in RevenueCat.
@property (nonatomic, readonly) NSDate *firstSeen;

/// The original App User Id recorded for this user.
@property (nonatomic, readonly) NSString *originalAppUserId;

/// URL to manage the active subscription of the user.
/// If this user has an active iOS subscription, this will point to the App Store,
/// if the user has an active Play Store subscription it will point there.
/// If there are no active subscriptions it will be null.
/// If there are multiple for different platforms, it will point to the App Store
@property (nonatomic, readonly, nullable) NSURL *managementURL;

/**
 Get the expiration date for a given product identifier. You should use Entitlements though!
 
 @param productIdentifier Product identifier for product
 
 @return The expiration date for `productIdentifier`, `nil` if product never purchased
 */
- (nullable NSDate *)expirationDateForProductIdentifier:(NSString *)productIdentifier;

/**
 Get the latest purchase or renewal date for a given product identifier. You should use Entitlements though!
 
 @param productIdentifier Product identifier for subscription product
 
 @return The purchase date for `productIdentifier`, `nil` if product never purchased
 */
- (nullable NSDate *)purchaseDateForProductIdentifier:(NSString *)productIdentifier;

/** Get the expiration date for a given entitlement.
 
 @param entitlementId The id of the entitlement.
 
 @return The expiration date for the passed in `entitlement`, can be `nil`
 */
- (nullable NSDate *)expirationDateForEntitlement:(NSString *)entitlementId;

/**
 Get the latest purchase or renewal date for a given entitlement identifier.
 
 @param entitlementId Entitlement identifier for entitlement
 
 @return The purchase date for `entitlementId`, `nil` if product never purchased
 */
- (nullable NSDate *)purchaseDateForEntitlement:(NSString *)entitlementId;

@end

NS_ASSUME_NONNULL_END
