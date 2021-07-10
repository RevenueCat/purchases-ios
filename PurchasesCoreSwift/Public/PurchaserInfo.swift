//
//  PurchaserInfo.swift
//  PurchasesCoreSwift
//
//  Created by Madeline Beyl on 7/9/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

@objc public class PurchaserInfo: NSObject {
    
    // Entitlements attached to this purchaser info
    let entitlements: EntitlementInfos
    
    // All *subscription* product identifiers with expiration dates in the future.
    let activeSubscriptions: Set<String>
    
    
    // All product identifiers purchases by the user regardless of expiration.
    let allPurchasedProductIdentifiers: Set<String>
    
    // Returns the latest expiration date of all products, nil if there are none
    let latestExpirationDate: Date?

    // Returns all product IDs of the non-subscription purchases a user has made.
    // TODO add deprecation message:  DEPRECATED_MSG_ATTRIBUTE("use nonSubscriptionTransactions");
    let nonConsumablePurchases: Set<String>
    
    
    // Returns all the non-subscription purchases a user has made.
    // The purchases are ordered by purchase date in ascending order.
    let nonSubscriptionTransactions: Array<Transaction>
    
    /**
    Returns the build number (in iOS) or the marketing version (in macOS) for the version of the application when the user bought the app.
    This corresponds to the value of CFBundleVersion (in iOS) or CFBundleShortVersionString (in macOS) in the Info.plist file when the purchase was originally made.
    Use this for grandfathering users when migrating to subscriptions.

     
     @note This can be nil, see -[RCPurchases restoreTransactionsForAppStore:]
     */
    let originalApplicationVersion: String?
    
    /**
    Returns the purchase date for the version of the application when the user bought the app.
    Use this for grandfathering users when migrating to subscriptions.

    @note This can be nil, see -[RCPurchases restoreTransactionsForAppStore:]
     */
    let originalPurchaseDate: Date?
    
    /**
     Returns the fetch date of this Purchaser info.
     @note Can be nil if was cached before we added this
     */
    let requestDate: Date?
    
    ///The date this user was first seen in RevenueCat.
    let firstSeen: Date
    
    // The original App User Id recorded for this user.
    let originalAppUserId: String
    
    // URL to manage the active subscription of the user.
    // If this user has an active iOS subscription, this will point to the App Store,
    // if the user has an active Play Store subscription it will point there.
    // If there are no active subscriptions it will be null.
    // If there are multiple for different platforms, it will point to the App Store
    let managementURL: URL?

}



///**
// Get the expiration date for a given product identifier. You should use Entitlements though!
//
// @param productIdentifier Product identifier for product
//
// @return The expiration date for `productIdentifier`, `nil` if product never purchased
// */
//- (nullable NSDate *)expirationDateForProductIdentifier:(NSString *)productIdentifier;
//
///**
// Get the latest purchase or renewal date for a given product identifier. You should use Entitlements though!
//
// @param productIdentifier Product identifier for subscription product
//
// @return The purchase date for `productIdentifier`, `nil` if product never purchased
// */
//- (nullable NSDate *)purchaseDateForProductIdentifier:(NSString *)productIdentifier;
//
///** Get the expiration date for a given entitlement.
//
// @param entitlementId The id of the entitlement.
//
// @return The expiration date for the passed in `entitlement`, can be `nil`
// */
//- (nullable NSDate *)expirationDateForEntitlement:(NSString *)entitlementId;
//
///**
// Get the latest purchase or renewal date for a given entitlement identifier.
//
// @param entitlementId Entitlement identifier for entitlement
//
// @return The purchase date for `entitlementId`, `nil` if product never purchased
// */
//- (nullable NSDate *)purchaseDateForEntitlement:(NSString *)entitlementId;

