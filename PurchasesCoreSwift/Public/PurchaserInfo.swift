//
//  PurchaserInfo.swift
//  PurchasesCoreSwift
//
//  Created by Madeline Beyl on 7/9/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

@objc public class PurchaserInfo: NSObject {
//    typealias TransactionsByProductId =  NSDictionary

    // Entitlements attached to this purchaser info
    public var entitlements: EntitlementInfos?

    // All *subscription* product identifiers with expiration dates in the future.
    // TODO implement
    public var activeSubscriptions: Set<String>?

    // All product identifiers purchases by the user regardless of expiration.
    public let allPurchasedProductIdentifiers: Set<String> = Set()

    // Returns the latest expiration date of all products, nil if there are none
    // TODO implement
    public var latestExpirationDate: Date?

    // Returns all product IDs of the non-subscription purchases a user has made.
    // TODO add deprecation message:  DEPRECATED_MSG_ATTRIBUTE("use nonSubscriptionTransactions");
    public var nonConsumablePurchases: Set<String> = Set()

    // Returns all the non-subscription purchases a user has made.
    // The purchases are ordered by purchase date in ascending order.
    public var nonSubscriptionTransactions: [Transaction] = []
    
    /**
     Returns the fetch date of this Purchaser info.
     @note Can be nil if was cached before we added this
     */
    public let requestDate: Date?

    // The date this user was first seen in RevenueCat.
    public var firstSeen: Date?

    // The original App User Id recorded for this user.
    public var originalAppUserId: String?
    
    // TODO is this equivalent to dispatch_once_t
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.init(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    // URL to manage the active subscription of the user.
    // If this user has an active iOS subscription, this will point to the App Store,
    // if the user has an active Play Store subscription it will point there.
    // If there are no active subscriptions it will be null.
    // If there are multiple for different platforms, it will point to the App Store
    public var managementURL: URL?

    private let originalData: NSDictionary

    // from rcpurchaserinfo+protected
    // public in android
    var expirationDatesByProduct: [String: Date]?
    //public in android
    var purchaseDatesByProduct: [String: Date]?
    private let schemaVersion: String?
    
    /**
    Returns the purchase date for the version of the application when the user bought the app.
    Use this for grandfathering users when migrating to subscriptions.

    @note This can be nil, see -[RCPurchases restoreTransactionsForAppStore:]
     */
    public var originalPurchaseDate: Date?
    
    /**
    Returns the build number (in iOS) or the marketing version (in macOS) for the version of the application when the user bought the app.
    This corresponds to the value of CFBundleVersion (in iOS) or CFBundleShortVersionString (in macOS) in the Info.plist file when the purchase was originally made.
    Use this for grandfathering users when migrating to subscriptions.

     
     @note This can be nil, see -[RCPurchases restoreTransactionsForAppStore:]
     */
    public var originalApplicationVersion: String?
    
    
    @objc public init?(data: NSDictionary) {
        if let subscriberObject = data["subscriber"] as? [String: Any] {
            if let subscriberData = SubscriberData.init(subscriberData: subscriberObject) {
                self.originalData = data
                self.schemaVersion = data["schema_version"] as? String

                guard let requestDateString = data["request_date"] as? String else {
                    return nil
                }
                self.requestDate = PurchaserInfo.dateFormatter.date(from: requestDateString)

                self.originalPurchaseDate = subscriberData.originalPurchaseDate
                self.firstSeen = subscriberData.firstSeen
                self.originalAppUserId = subscriberData.originalAppUserId
                self.managementURL = subscriberData.managementURL

                let nonSubscriptionProductIds = subscriberData.nonSubscriptions.keys
                self.nonConsumablePurchases = Set(nonSubscriptionProductIds)

                self.entitlements = EntitlementInfos.init(entitlementsData: subscriberData.entitlements, purchasesData: subscriberData.allPurchases, dateFormatter: PurchaserInfo.dateFormatter, requestDate: requestDate)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    class func parseURL(url: Any) -> URL? {
        if let urlString = url as? String {
            return URL.init(fileURLWithPath: urlString)
        }
        return nil
    }

    class func parseDate(date: Any, withDateFormatter: DateFormatter) -> Date? {
        if let dateString = date as? String {
            return PurchaserInfo.dateFormatter.date(from: dateString)
        }
        return nil
    }

    class func parseExpirationDate(expirationDates: [String: Any]) -> NSDictionary {
        return parseDatesIn(dates: expirationDates, label: "expires_date")
    }

    class func parsePurchaseDate(purchaseDates: [String: Any]) -> NSDictionary {
        return parseDatesIn(dates: purchaseDates, label: "purchase_date")
    }

    class func parseDatesIn(dates: [String: Any], label: String) -> NSDictionary {
        let parsedDates = NSMutableDictionary()

        for (identifier, _) in dates {
            let date = (dates[identifier] as? NSDictionary ?? NSDictionary())[label]

            if let dateString = date as? String {
                let date = PurchaserInfo.dateFormatter.date(from: dateString)
                if date != nil {
                    parsedDates[identifier] = date
                }
            } else {
                parsedDates[identifier] = nil
            }
        }
        return parsedDates
    }
    
    class func currentSchemaVersion() -> String {
        return "2"
    }

    private struct SubscriberData {
        let originalAppUserId: String
        let managementURL: URL?
        let originalApplicationVersion: String?
        let originalPurchaseDate: Date?
        let firstSeen: Date
        let subscriptions: [String: Any]
        let nonSubscriptions: [String: [[String: Any]]]
        let entitlements: [String: Any]
        let nonConsumablePurchases: Set<String>
        let nonSubscriptionLatestTransactions: NSDictionary
        let nonSubscriptionTransactions: [Transaction]
        let allPurchases: [String: Any]
        let expirationDatesByProduct: NSDictionary
        let purchaseDatesByProduct: NSDictionary

        init?(subscriberData: [String: Any]) {
            guard let subscriptionsDictionary = subscriberData["subscriptions"] as? [String: Any] else {
                return nil
            }
            self.subscriptions = subscriptionsDictionary

            guard let originalApplicationVersionString = subscriberData["original_application_version"] as? String else {
                return nil
            }
            self.originalApplicationVersion = originalApplicationVersionString

            if let originalPurchaseDateString = subscriberData["original_purchase_date"] as? String {
                self.originalPurchaseDate = PurchaserInfo.parseDate(date: originalPurchaseDateString, withDateFormatter: PurchaserInfo.dateFormatter)
            } else {
                self.originalPurchaseDate = nil
            }

            guard let firstSeenDateString = subscriberData["first_seen"] as? String else {
                return nil
            }

            self.firstSeen = PurchaserInfo.parseDate(date: firstSeenDateString, withDateFormatter: PurchaserInfo.dateFormatter)!

            guard let originalAppUserIdString = subscriberData["original_app_user_id"] as? String else {
                return nil
            }
            self.originalAppUserId = originalAppUserIdString

            if let managementUrlString = subscriberData["management_url"] as? String {
                self.managementURL = parseURL(url: managementUrlString)
            } else {
                self.managementURL = nil
            }

            self.nonSubscriptions = subscriberData["non_subscriptions"] as? [String: [[String: Any]]] ?? [String: [[String: Any]]]()
            self.entitlements = subscriberData["entitlements"] as? [String: Any] ?? [String: Any]()

            self.nonConsumablePurchases = Set(nonSubscriptions.keys)

            self.nonSubscriptionTransactions = TransactionsFactory().nonSubscriptionTransactions(withSubscriptionsData: nonSubscriptions, dateFormatter: PurchaserInfo.dateFormatter)

            // nonSubscriptionLatestTransactions
            let productIdToLatestTransaction = NSMutableDictionary()
            for productId in nonSubscriptions.keys {
                let purchasesArray = nonSubscriptions[productId] ?? [[String: Any]]()
                if let latestTransaction = purchasesArray.last {
                    productIdToLatestTransaction[productId] = latestTransaction
                }
            }
            self.nonSubscriptionLatestTransactions = productIdToLatestTransaction

            // all purchases
            guard let nonSubsLatest = nonSubscriptionLatestTransactions as? [String: Any] else {
                return nil
            }
            self.allPurchases = nonSubsLatest.merging(subscriptions) { (current, _) in current }

            self.expirationDatesByProduct = PurchaserInfo.parseExpirationDate(expirationDates: subscriptions)
            self.purchaseDatesByProduct = PurchaserInfo.parsePurchaseDate(purchaseDates: allPurchases)
        }
    }

}

/// **
// Get the expiration date for a given product identifier. You should use Entitlements though!
//
// @param productIdentifier Product identifier for product
//
// @return The expiration date for `productIdentifier`, `nil` if product never purchased
// */
// - (nullable NSDate *)expirationDateForProductIdentifier:(NSString *)productIdentifier;
//
/// **
// Get the latest purchase or renewal date for a given product identifier. You should use Entitlements though!
//
// @param productIdentifier Product identifier for subscription product
//
// @return The purchase date for `productIdentifier`, `nil` if product never purchased
// */
// - (nullable NSDate *)purchaseDateForProductIdentifier:(NSString *)productIdentifier;
//
/// ** Get the expiration date for a given entitlement.
//
// @param entitlementId The id of the entitlement.
//
// @return The expiration date for the passed in `entitlement`, can be `nil`
// */
// - (nullable NSDate *)expirationDateForEntitlement:(NSString *)entitlementId;
//
/// **
// Get the latest purchase or renewal date for a given entitlement identifier.
//
// @param entitlementId Entitlement identifier for entitlement
//
// @return The purchase date for `entitlementId`, `nil` if product never purchased
// */
// - (nullable NSDate *)purchaseDateForEntitlement:(NSString *)entitlementId;
