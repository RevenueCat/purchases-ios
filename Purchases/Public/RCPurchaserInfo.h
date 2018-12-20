//
//  RCPurchaserInfo.h
//  Purchases
//
//  Created by Jacob Eiting on 9/30/17.
//  Copyright © 2018 RevenueCat, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

/**
 A container for the most recent purchaser info returned from `RCPurchases`. These objects are non-mutable and do not update automatically.
 */
NS_SWIFT_NAME(PurchaserInfo)
@interface RCPurchaserInfo : NSObject

/// All active *entitlements*.
@property (readonly) NSSet<NSString *> *activeEntitlements;

/// All *subscription* product identifiers with expiration dates in the future.
@property (readonly) NSSet<NSString *> *activeSubscriptions;

/// All product identifiers purchases by the user regardless of expriration.
@property (readonly) NSSet<NSString *> *allPurchasedProductIdentifiers;

/// Returns the latest expiration date of all products, nil if there are none
@property (readonly) NSDate * _Nullable latestExpirationDate;

/// Returns all the non-consumable purchases a user has made.
@property (readonly) NSSet<NSString *> *nonConsumablePurchases;

/**
 Returns the version number for the version of the application when the user bought the app.
 Use this for grandfathering users when migrating to subscriptions.
 
 @note This can be nil, see -[RCPurchases refreshOriginalApplicationVersion:]
 */
@property (readonly) NSString * _Nullable originalApplicationVersion;

/**
 Get the expiration date for a given product identifier. You should use Entitlements though!
 
 @param productIdentifier Product identifier for product
 
 @return The expiration date for `productIdentifier`, `nil` if product never purchased
 */
- (NSDate * _Nullable)expirationDateForProductIdentifier:(NSString *)productIdentifier;

/**
 Get the purchase date for a given product identifier. You should use Entitlements though!
 
 @param productIdentifier Product identifier for subscription product
 
 @return The purchase date for `productIdentifier`, `nil` if product never purchased
 */
- (NSDate * _Nullable)purchaseDateForProductIdentifier:(NSString *)productIdentifier;

/** Get the expiration date for a given entitlement.
 
 @param entitlementId The id of the entitlement.
 
 @return The expiration date for the passed in `entitlement`, can be `nil`
 */
- (NSDate * _Nullable)expirationDateForEntitlement:(NSString *)entitlementId;

/**
 Get the purchase date for a given entitlement identifier.
 
 @param entitlementId Entitlement identifier for entitlement
 
 @return The purchase date for `entitlementId`, `nil` if product never purchased
 */
- (NSDate * _Nullable)purchaseDateForEntitlement:(NSString *)entitlementId;

/**
 Returns the fetch date of this Purchaser info.
 @note Can be nil if was cached before we added this
 */
@property (readonly) NSDate * _Nullable requestDate;

@end

NS_ASSUME_NONNULL_END
