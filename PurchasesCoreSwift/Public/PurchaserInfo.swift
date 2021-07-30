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
    @objc public var activeSubscriptions: Set<String> { activeKeys(dates: expirationDatesByProductId) }

    /// All product identifiers purchases by the user regardless of expiration.
    @objc public lazy var allPurchasedProductIdentifiers: Set<String> = {
        return Set(self.expirationDatesByProductId.keys).union(self.nonSubscriptionTransactions.map { $0.productId })
    }()

    /// Returns the latest expiration date of all products, nil if there are none
    @objc public var latestExpirationDate: Date? {
        let mostRecentDate = self.expirationDatesByProductId
            .values
            .compactMap { $0 }
            .max { $0.timeIntervalSinceReferenceDate < $1.timeIntervalSinceReferenceDate }

        return mostRecentDate
    }

    /// Returns all product IDs of the non-subscription purchases a user has made.
    @available(*, deprecated, message: "use nonSubscriptionTransactions")
    @objc public var nonConsumablePurchases: Set<String> { Set(self.nonSubscriptionTransactions.map { $0.productId }) }

    /**
    Returns all the non-subscription purchases a user has made.
    The purchases are ordered by purchase date in ascending order.
     */
    @objc public let nonSubscriptionTransactions: [Transaction]

    /**
     Returns the fetch date of this Purchaser info.
     Note: Can be `nil` if was cached before we added this
     */
    @objc public let requestDate: Date

    /// The date this user was first seen in RevenueCat.
    @objc public let firstSeen: Date

    /// The original App User Id recorded for this user.
    @objc public let originalAppUserId: String

    /**
     URL to manage the active subscription of the user.
     If this user has an active iOS subscription, this will point to the App Store,
     if the user has an active Play Store subscription it will point there.
     If there are no active subscriptions it will be null.
     If there are multiple for different platforms, it will point to the App Store
     */
    @objc public let managementURL: URL?

    /**
    Returns the purchase date for the version of the application when the user bought the app.
    Use this for grandfathering users when migrating to subscriptions.

    Note: This can be `nil`, see `Purchases.restoreTransactions(completionBlock:)`
     */
    @objc public let originalPurchaseDate: Date?

    /**
    Returns the build number (in iOS) or the marketing version (in macOS) for the version of the application when the user bought the app.
    This corresponds to the value of CFBundleVersion (in iOS) or CFBundleShortVersionString (in macOS) in the Info.plist file when the purchase was originally made.
    Use this for grandfathering users when migrating to subscriptions.

     
     Note: This can be nil, see -`Purchases.restoreTransactions(completionBlock:)`
     */
    @objc public let originalApplicationVersion: String?

    // TODO after migration make this internal
    @objc public let schemaVersion: String?

    private let allPurchases: [String: [String: Any]]

    private let subscriptionTransactionsByProductId: [String: [String: Any]]

    private lazy var expirationDatesByProductId: [String: Date?] = {
        return parseExpirationDates(transactionsByProductId: subscriptionTransactionsByProductId)
    }()

    private lazy var purchaseDatesByProductId: [String: Date?] = {
        return parseExpirationDates(transactionsByProductId: allPurchases)
    }()

    private let originalData: [String: Any]

    private let dateFormatter: DateFormatter

    @objc public convenience init?(data: [String: Any]) {
        self.init(data: data, dateFormatter: .iso8601SecondsDateFormatter)
    }

    /// Get the expiration date for a given product identifier. You should use Entitlements though!
    /// - Parameter productIdentifier: Product identifier for product
    /// - Returns:  The expiration date for `productIdentifier`, `nil` if product never purchased
    @objc public func expirationDate(forProductIdentifier productIdentifier: String) -> Date? {
        return expirationDatesByProductId[productIdentifier] ?? nil
    }

    /// Get the latest purchase or renewal date for a given product identifier. You should use Entitlements though!
    /// - Parameter productIdentifier: Product identifier for subscription product
    /// - Returns: The purchase date for `productIdentifier`, `nil` if product never purchased
    @objc public func purchaseDate(forProductIdentifier productIdentifier: String) -> Date? {
        return purchaseDatesByProductId[productIdentifier] ?? nil
    }

    /// Get the expiration date for a given entitlement.
    /// - Parameter entitlementIdentifier: The ID of the entitlement
    /// - Returns: The expiration date for the passed in `entitltmentIdentifier`, or `nil`
    @objc public func expirationDate(forEntitlement entitlementIdentifier: String) -> Date? {
        return entitlements[entitlementIdentifier]?.expirationDate
    }

    /// Get the latest purchase or renewal date for a given entitlement identifier.
    /// - Parameter entitlementIdentifier: Entitlement identifier for entitlement
    /// - Returns: The purchase date for `entitlementIdentifier`, `nil` if product never purchased
    @objc public func purchaseDate(forEntitlement entitlementIdentifier: String) -> Date? {
        return entitlements[entitlementIdentifier]?.latestPurchaseDate
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? PurchaserInfo else {
            return false
        }

        var selfJson = self.jsonObject()
        selfJson.removeValue(forKey: "request_date")
        var otherJson = other.jsonObject()
        otherJson.removeValue(forKey: "request_date")

        return NSDictionary(dictionary: selfJson).isEqual(NSDictionary(dictionary: otherJson))
    }

    public override var description: String {
        let activeSubsDescription = self.activeSubscriptions.reduce(into: [String: String]()) { dict, subId in
            dict[subId] = "expiresDate: \(String(describing: self.expirationDate(forProductIdentifier: subId)))"
        }

        let activeEntitlementsDescription = self.entitlements.active.mapValues { $0.description }

        let allEntitlementsDescription = self.entitlements.all.mapValues { $0.description }

        return """
            <\(String(describing: PurchaserInfo.self)):
            originalApplicationVersion=\(self.originalApplicationVersion ?? ""),
            latestExpirationDate=\(String(describing: self.latestExpirationDate)),
            activeEntitlements=\(activeEntitlementsDescription),
            activeSubscriptions=\(activeSubsDescription),
            nonSubscriptionTransactions=\(self.nonSubscriptionTransactions),
            requestDate=\(String(describing: self.requestDate)),
            firstSeen=\(String(describing: self.firstSeen)),
            originalAppUserId=\(self.originalAppUserId),
            entitlements=\(allEntitlementsDescription)
            >
            """
    }

    // TODO make internal after swift migration
    @objc public init?(data: [String: Any]) {
    init?(data: [String: Any], dateFormatter: ISO3601DateFormatter = ISO3601DateFormatter.shared) {
    init?(data: [String: Any], dateFormatter: DateFormatter) {
        guard let subscriberObject = data["subscriber"] as? [String: Any],
              let subscriberData = SubscriberData(subscriberData: subscriberObject, dateFormatter: dateFormatter)
            else {
            return nil
        }

        self.dateFormatter = dateFormatter
        self.originalData = data
        self.schemaVersion = data["schema_version"] as? String

        guard let requestDateString = data["request_date"] as? String,
              let formattedRequestDate = dateFormatter.date(fromString: requestDateString) else {
            return nil
        }
        self.requestDate = formattedRequestDate

        self.originalPurchaseDate = subscriberData.originalPurchaseDate
        self.firstSeen = subscriberData.firstSeen
        self.originalAppUserId = subscriberData.originalAppUserId
        self.managementURL = subscriberData.managementURL
        self.originalApplicationVersion = subscriberData.originalApplicationVersion

        self.nonSubscriptionTransactions = subscriberData.nonSubscriptionTransactions

        self.entitlements = EntitlementInfos(entitlementsData: subscriberData.entitlementsData,
                                             purchasesData: subscriberData.allTransactionsByProductId,
                                             dateFormatter: Self.dateFormatter,
                                             requestDate: requestDate)

        self.subscriptionTransactionsByProductId = subscriberData.subscriptionTransactionsByProductId
        self.allPurchases = subscriberData.allPurchases
    }

    // TODO after migration make this internal
    @objc public static let currentSchemaVersion = "2"

    // TODO after migration make this internal and remove objc rename
    @objc(JSONObject) public func jsonObject() -> [String: Any] {
        return originalData.merging(
            ["schema_version": PurchaserInfo.currentSchemaVersion],
            uniquingKeysWith: { (current, _) in current })
    }

    private struct SubscriberData {
        let subscriptionTransactionsByProductId: [String: [String: Any]]
        let originalAppUserId: String
        let managementURL: URL?
        let originalApplicationVersion: String?
        let originalPurchaseDate: Date?
        let firstSeen: Date
        let nonSubscriptionsByProductId: [String: [[String: Any]]]
        let entitlementsData: [String: Any]
        let nonSubscriptionTransactions: [Transaction]
        let allPurchases: [String: [String: Any]]

        init?(subscriberData: [String: Any], dateFormatter: DateFormatter) {
            self.subscriptionTransactionsByProductId =
                subscriberData["subscriptions"] as? [String: [String: Any]] ?? [String: [String: Any]]()

            // Metadata
            self.originalApplicationVersion = subscriberData["original_application_version"] as? String

            self.originalPurchaseDate =
                dateFormatter.date(fromString: subscriberData["original_purchase_date"] as? String ?? "")

            guard let firstSeenDateString = subscriberData["first_seen"] as? String,
                  let firstSeenDate = dateFormatter.date(fromString: firstSeenDateString) else {
                return nil
            }
            self.firstSeen = firstSeenDate

            guard let originalAppUserIdString = subscriberData["original_app_user_id"] as? String else {
                return nil
            }
            self.originalAppUserId = originalAppUserIdString

            self.managementURL = URL(string: subscriberData["management_url"] as? String ?? "")

            // Purchases and entitlements
            self.nonSubscriptionsByProductId =
                subscriberData["non_subscriptions"] as? [String: [[String: Any]]] ?? [:]
            self.entitlementsData = subscriberData["entitlements"] as? [String: Any] ?? [:]
            self.nonSubscriptionTransactions = TransactionsFactory().nonSubscriptionTransactions(
                withSubscriptionsData: nonSubscriptionsByProductId,
                dateFormatter: dateFormatter)

            let latestNonSubscriptionTransactionsByProductId =
                [String: [String: Any]](uniqueKeysWithValues: nonSubscriptionsByProductId.map { productId, transactionsArray in
                    (productId, transactionsArray.last ?? [:])
            })

            self.allTransactionsByProductId = latestNonSubscriptionTransactionsByProductId
                .merging(subscriptionTransactionsByProductId) { (current, _) in current }
        }
    }

}

private extension PurchaserInfo {

    func activeKeys(dates: [String: Date?]) -> Set<String> {
        return Set(dates.keys.filter {
            guard let nonNullDate = dates[$0] as? Date else { return true }
            return isAfterReferenceDate(date: nonNullDate)
        })
    }

    func isAfterReferenceDate(date: Date) -> Bool { date.timeIntervalSince(self.requestDate) > 0 }

    func parseExpirationDates(transactionsByProductId: [String: [String: Any]]) -> [String: Date?] {
        return parseDatesIn(transactionsByProductId: transactionsByProductId, dateLabel: "expires_date")
    }

    func parsePurchaseDates(transactionsByProductId: [String: [String: Any]]) -> [String: Date?] {
        return parseDatesIn(transactionsByProductId: transactionsByProductId, dateLabel: "purchase_date")
    }

    class func parseDatesIn(transactionsByProductId: [String: [String: Any]], dateLabel: String) -> [String: Date?] {
        // mapValues will the key-value pair in the dictionary for nil values, as desired
        return transactionsByProductId.mapValues { maybeTransaction in
            if let transactionFieldsByKey = maybeTransaction as? [String: String],
               let dateString = transactionFieldsByKey[dateLabel] {
                return dateFormatter.date(fromString: dateString)
            }
            return nil
        }
    }

}
