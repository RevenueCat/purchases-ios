//
//  PurchaserInfo.swift
//  PurchasesCoreSwift
//
//  Created by Madeline Beyl on 7/9/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

@objc(RCPurchaserInfo) public class PurchaserInfo: NSObject {

    /// Entitlements attached to this purchaser info
    @objc public let entitlements: EntitlementInfos

    /// All *subscription* product identifiers with expiration dates in the future.
    @objc public var activeSubscriptions: Set<String> { activeKeys(dates: expirationDatesByProduct) }

    /// All product identifiers purchases by the user regardless of expiration.
    @objc public var allPurchasedProductIdentifiers: Set<String> {
        return self.nonConsumablePurchases.union(expirationDatesByProduct.keys)

    }

    /// Returns the latest expiration date of all products, nil if there are none
    @objc public var latestExpirationDate: Date? {
        let mostRecentDate = self.expirationDatesByProduct.values.filter({ $0 != nil }).max(by: {
           $0!.timeIntervalSinceReferenceDate < $1!.timeIntervalSinceReferenceDate
        })

        return mostRecentDate ?? nil
    }

    /// Returns all product IDs of the non-subscription purchases a user has made.
    @available(*, deprecated, message: "use nonSubscriptionTransactions")
    @objc public let nonConsumablePurchases: Set<String>

    /**
    Returns all the non-subscription purchases a user has made.
    The purchases are ordered by purchase date in ascending order.
     */
    @objc public let nonSubscriptionTransactions: [Transaction]

    /**
     Returns the fetch date of this Purchaser info.
     @note Can be nil if was cached before we added this
     */
    @objc public let requestDate: Date

    /// The date this user was first seen in RevenueCat.
    @objc public let firstSeen: Date

    /// The original App User Id recorded for this user.
    @objc public let originalAppUserId: String

    /** URL to manage the active subscription of the user.
     If this user has an active iOS subscription, this will point to the App Store,
     if the user has an active Play Store subscription it will point there.
     If there are no active subscriptions it will be null.
     If there are multiple for different platforms, it will point to the App Store
     */
    @objc public let managementURL: URL?

    /**
    Returns the purchase date for the version of the application when the user bought the app.
    Use this for grandfathering users when migrating to subscriptions.

    @note This can be nil, see -[RCPurchases restoreTransactionsForAppStore:]
     */
    @objc public let originalPurchaseDate: Date?

    /**
    Returns the build number (in iOS) or the marketing version (in macOS) for the version of the application when the user bought the app.
    This corresponds to the value of CFBundleVersion (in iOS) or CFBundleShortVersionString (in macOS) in the Info.plist file when the purchase was originally made.
    Use this for grandfathering users when migrating to subscriptions.

     
     @note This can be nil, see -[RCPurchases restoreTransactionsForAppStore:]
     */
    @objc public let originalApplicationVersion: String?

    // TODO after migration make this internal
    @objc public let schemaVersion: String?

    private let expirationDatesByProduct: [String: Date?]

    private let purchaseDatesByProduct: [String: Date?]

    private let originalData: [AnyHashable: Any]

    @objc public init?(data: [AnyHashable: Any]) {
        guard let subscriberObject = data["subscriber"] as? [String: Any],
              let subscriberData = SubscriberData.init(subscriberData: subscriberObject)
            else {
            return nil
        }

        self.originalData = data
        self.schemaVersion = data["schema_version"] as? String

        guard let requestDateString = data["request_date"] as? String,
              let formattedRequestDate = DateFormatter.dateFormatter.date(from: requestDateString) else {
            return nil
        }
        self.requestDate = formattedRequestDate

        self.originalPurchaseDate = subscriberData.originalPurchaseDate
        self.firstSeen = subscriberData.firstSeen
        self.originalAppUserId = subscriberData.originalAppUserId
        self.managementURL = subscriberData.managementURL
        self.originalApplicationVersion = subscriberData.originalApplicationVersion

        self.nonConsumablePurchases = Set(subscriberData.nonSubscriptions.keys)
        self.nonSubscriptionTransactions = subscriberData.nonSubscriptionTransactions

        self.entitlements = EntitlementInfos.init(entitlementsData: subscriberData.entitlements, purchasesData: subscriberData.allPurchases, dateFormatter: DateFormatter.dateFormatter, requestDate: requestDate)

        self.expirationDatesByProduct = subscriberData.expirationDatesByProduct
        self.purchaseDatesByProduct = subscriberData.purchaseDatesByProduct
    }

    // TODO after migration make this internal
    @objc public class func currentSchemaVersion() -> String {
        return "2"
    }

    /**
     Get the expiration date for a given product identifier. You should use Entitlements though!
    
     @param forProductIdentifier Product identifier for product
    
     @return The expiration date for `productIdentifier`, `nil` if product never purchased
     */
    @objc public func expirationDate(forProductIdentifier: String) -> Date? {
        return expirationDatesByProduct[forProductIdentifier] ?? nil
    }

     /**
     Get the latest purchase or renewal date for a given product identifier. You should use Entitlements though!
    
     @param forProductIdentifier Product identifier for subscription product
    
     @return The purchase date for `productIdentifier`, `nil` if product never purchased
     */
    @objc public func purchaseDate(forProductIdentifier: String) -> Date? {
        return purchaseDatesByProduct[forProductIdentifier] ?? nil
    }

    /**
     Get the expiration date for a given entitlement.
    
     @param forEntitlement The id of the entitlement.
    
     @return The expiration date for the passed in `entitlement`, can be `nil`
     */
    @objc public func expirationDate(forEntitlement: String) -> Date? {
        return entitlements[forEntitlement]?.expirationDate
    }

    /**
     Get the latest purchase or renewal date for a given entitlement identifier.
    
     @param forEntitlement Entitlement identifier for entitlement
    
     @return The purchase date for `entitlement`, `nil` if product never purchased
     */
    @objc public func purchaseDate(forEntitlement: String) -> Date? {
        return entitlements[forEntitlement]?.latestPurchaseDate
    }

    // TODO after migration make this internal and remove objc rename
    @objc(JSONObject) public func jsonObject() -> [AnyHashable: Any] {
        var dictionary = self.originalData
        dictionary["schema_version"] = PurchaserInfo.currentSchemaVersion()
        return dictionary
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? PurchaserInfo else {
            return false
        }

        var selfJson = self.jsonObject()
        selfJson.removeValue(forKey: "request_date")
        var otherJson = other.jsonObject()
        otherJson.removeValue(forKey: "request_date")

        return NSDictionary(dictionary: selfJson).isEqual(to: otherJson)
    }

    public override var description: String {
        let activeSubsDescription = self.activeSubscriptions.reduce(into: [String: String]()) { dict, subId in
            dict[subId] = "expiresDate: \(String(describing: self.expirationDate(forProductIdentifier: subId)))"
        }

        let activeEntitlementsDescription = self.entitlements.active.mapValues { $0.description }

        let allEntitlementsDescription = self.entitlements.all.mapValues { $0.description }

        var description = "<\(NSStringFromClass(type(of: self))): "
        description += "originalApplicationVersion=\(String(describing: self.originalApplicationVersion)),\n"
        description += "latestExpirationDate=\(String(describing: self.latestExpirationDate)),\n"
        description += "activeEntitlements=\(activeEntitlementsDescription),\n"
        description += "activeSubscriptions=\(activeSubsDescription),\n"
        description += "nonSubscriptionTransactions=\(self.nonSubscriptionTransactions),\n"
        description += "requestDate=\(String(describing: self.requestDate)),\n"
        description += "firstSeen=\(String(describing: self.firstSeen)),\n"
        description += "originalAppUserId=\(self.originalAppUserId),\n"
        description += "entitlements=\(allEntitlementsDescription),\n"
        description += ">"

        return description
    }

    private struct SubscriberData {

        let originalAppUserId: String
        let managementURL: URL?
        let originalApplicationVersion: String?
        let originalPurchaseDate: Date?
        let firstSeen: Date
        let nonSubscriptions: [String: [[String: Any]]]
        let entitlements: [String: Any]
        let nonSubscriptionTransactions: [Transaction]
        let allPurchases: [String: Any]
        let expirationDatesByProduct: [String: Date?]
        let purchaseDatesByProduct: [String: Date?]

        init?(subscriberData: [String: Any]) {
            let subscriptions = subscriberData["subscriptions"] as? [String: [String: Any]] ?? [String: [String: Any]]()

            // Metadata
            self.originalApplicationVersion = subscriberData["original_application_version"] as? String ?? nil

            if let originalPurchaseDateString = subscriberData["original_purchase_date"] as? String {
                self.originalPurchaseDate = PurchaserInfo.parseDate(date: originalPurchaseDateString, withDateFormatter: DateFormatter.dateFormatter)
            } else {
                self.originalPurchaseDate = nil
            }

            guard let firstSeenDateString = subscriberData["first_seen"] as? String,
                  let firstSeenDate = PurchaserInfo.parseDate(date: firstSeenDateString, withDateFormatter: DateFormatter.dateFormatter) else {
                return nil
            }
            self.firstSeen = firstSeenDate

            guard let originalAppUserIdString = subscriberData["original_app_user_id"] as? String else {
                return nil
            }
            self.originalAppUserId = originalAppUserIdString

            if let managementUrlString = subscriberData["management_url"] as? String {
                self.managementURL = parseURL(url: managementUrlString)
            } else {
                self.managementURL = nil
            }

            // Purchases and entitlements
            self.nonSubscriptions = subscriberData["non_subscriptions"] as? [String: [[String: Any]]] ?? [String: [[String: Any]]]()
            self.entitlements = subscriberData["entitlements"] as? [String: Any] ?? [String: Any]()
            self.nonSubscriptionTransactions = TransactionsFactory().nonSubscriptionTransactions(withSubscriptionsData: nonSubscriptions, dateFormatter: DateFormatter.dateFormatter)

            let latestNonSubscriptionTransactionsByProductId = [String: Any](uniqueKeysWithValues: nonSubscriptions.map { productId, transactionsArray in
                (productId, transactionsArray.last)
            })

            self.allPurchases = latestNonSubscriptionTransactionsByProductId.merging(subscriptions) { (current, _) in current }

            self.expirationDatesByProduct = PurchaserInfo.parseExpirationDate(expirationDates: subscriptions)
            self.purchaseDatesByProduct = PurchaserInfo.parsePurchaseDate(purchaseDates: allPurchases)
        }
    }

}

private extension PurchaserInfo {

    func activeKeys(dates: [String: Date?]) -> Set<String> {
        return Set<String>(dates.keys.filter({
            if let nonNullDate = dates[$0] as? Date {
                return isAfterReferenceDate(date: nonNullDate)
            }
            return true
        }))
    }

    func isAfterReferenceDate(date: Date) -> Bool {
        return date.timeIntervalSince(self.requestDate) > 0
    }

    class func parseURL(url: Any) -> URL? {
        if let urlString = url as? String {
            return URL.init(string: urlString)
        }
        return nil
    }

    class func parseDate(date: Any, withDateFormatter: DateFormatter) -> Date? {
        if let dateString = date as? String {
            return DateFormatter.dateFormatter.date(from: dateString)
        }
        return nil
    }

    class func parseExpirationDate(expirationDates: [String: Any]) -> [String: Date?] {
        return parseDatesIn(dates: expirationDates, label: "expires_date")
    }

    class func parsePurchaseDate(purchaseDates: [String: Any]) -> [String: Date?] {
        return parseDatesIn(dates: purchaseDates, label: "purchase_date")
    }

    class func parseDatesIn(dates: [String: Any], label: String) -> [String: Date?] {
        return dates.mapValues {
            if let dateString = ($0 as? [String: String] ?? [String: String]())[label] {
                return DateFormatter.dateFormatter.date(from: dateString)
            } else {
                return nil
            }
        }
    }

}

private extension DateFormatter {

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.init(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

}
