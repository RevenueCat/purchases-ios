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
@interface RCPurchaserInfo : NSObject

/// All active *entitlements*.
@property (readonly) NSSet<NSString *> *activeEntitlements;

/** Get the expiration date for a given entitlement.

 @param entitlementId The id of the entitlement.

 @return The expiration date for the passed in `entitlement`, can be `nil`
 */
- (NSDate * _Nullable)expirationDateForEntitlement:(NSString *)entitlementId;

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
 Get the expiration date for a given product identifier.

 @param productIdentifier Product identifier for subscription product

 @return The expiration date for `productIdentifier`, `nil` if product never purchased
 */
- (NSDate * _Nullable)expirationDateForProductIdentifier:(NSString *)productIdentifier;

@end

NS_ASSUME_NONNULL_END
