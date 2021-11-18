//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfo.swift
//
//  Created by Madeline Beyl on 7/9/21.
//

import Foundation

@objc(RCCustomerInfo) public class CustomerInfo: NSObject {

    /// ``EntitlementInfos`` attached to this purchaser info.
    @objc public let entitlements: EntitlementInfos

    /// All *subscription* product identifiers with expiration dates in the future.
    @objc public var activeSubscriptions: Set<String> { activeKeys(dates: expirationDatesByProductId) }

    /// All product identifiers purchases by the user regardless of expiration.
    @objc public lazy var allPurchasedProductIdentifiers: Set<String> = {
        return Set(self.expirationDatesByProductId.keys).union(self.nonSubscriptionTransactions.map { $0.productId })
    }()

    /// Returns the latest expiration date of all products, nil if there are none.
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
     * Returns all the non-subscription purchases a user has made.
     * The purchases are ordered by purchase date in ascending order.
     */
    @objc public let nonSubscriptionTransactions: [Transaction]

    /**
     * Returns the fetch date of this CustomerInfo.
     */
    @objc public let requestDate: Date

    /// The date this user was first seen in RevenueCat.
    @objc public let firstSeen: Date

    /// The original App User Id recorded for this user.
    @objc public let originalAppUserId: String

    /**
     URL to manage the active subscription of the user.
     * If this user has an active iOS subscription, this will point to the App Store.
     * If the user has an active Play Store subscription it will point there.
     * If there are no active subscriptions it will be null.
     * If there are multiple for different platforms, it will point to the App Store.
     */
    @objc public let managementURL: URL?

    /**
     * Returns the purchase date for the version of the application when the user bought the app.
     * Use this for grandfathering users when migrating to subscriptions.
     *
     * - Note: This can be `nil`, see ``Purchases/restoreTransactions(completion:)``
     */
    @objc public let originalPurchaseDate: Date?

    /**
     * The build number (in iOS) or the marketing version (in macOS) for the version of the application when the user
     * bought the app. This corresponds to the value of CFBundleVersion (in iOS) or CFBundleShortVersionString
     * (in macOS) in the Info.plist file when the purchase was originally made. Use this for grandfathering users
     * when migrating to subscriptions.
     *
     * - Note: This can be nil, see -`Purchases.restoreTransactions(completion:)`
     */
    @objc public let originalApplicationVersion: String?

    /**
     * The underlying data for this `CustomerInfo`.
     *
     * - Note: the content and format of this data isn’t documented and is subject to change.
     *         it's only meant for debugging purposes or for getting access to future data
     *         without updating the SDK.
     */
    @objc public let rawData: [String: Any]

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
    /// - Returns: The expiration date for the passed in `entitlementIdentifier`, or `nil`
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
        guard let other = object as? CustomerInfo else {
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
            <\(String(describing: CustomerInfo.self)):
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

    let schemaVersion: String?

    convenience init(data: [String: Any]) throws {
        try self.init(data: data,
                      dateFormatter: .iso8601SecondsDateFormatter,
                      transactionsFactory: TransactionsFactory())
    }

    init(data: [String: Any], dateFormatter: DateFormatter, transactionsFactory: TransactionsFactory) throws {
        guard let subscriberObject = data["subscriber"] as? [String: Any] else {
            Logger.error(Strings.customerInfo.missing_json_object_instantiation_error(maybeJsonData: data))
            throw CustomerInfoError.missingJsonObject
        }

        let subscriberData: SubscriberData
        do {
            try subscriberData = SubscriberData(subscriberData: subscriberObject,
                                                dateFormatter: dateFormatter,
                                                transactionsFactory: transactionsFactory)
        } catch let subscriberDataError {
            throw CustomerInfo.createSubscriberDataError(subscriberDataError, subscriberDictionary: subscriberObject)
        }

        guard let requestDateString = data["request_date"] as? String else {
            Logger.error(Strings.customerInfo.cant_parse_request_date_from_json(maybeDate: data["request_date"]))
            throw CustomerInfoError.requestDateFromJson
        }

        guard let formattedRequestDate = dateFormatter.date(from: requestDateString) else {
            Logger.error(Strings.customerInfo.cant_parse_request_date_from_string(string: requestDateString))
            throw CustomerInfoError.requestDateFromString
        }

        self.dateFormatter = dateFormatter
        self.rawData = data
        self.schemaVersion = data["schema_version"] as? String
        self.requestDate = formattedRequestDate
        self.originalPurchaseDate = subscriberData.originalPurchaseDate
        self.firstSeen = subscriberData.firstSeen
        self.originalAppUserId = subscriberData.originalAppUserId
        self.managementURL = subscriberData.managementURL
        self.originalApplicationVersion = subscriberData.originalApplicationVersion
        self.nonSubscriptionTransactions = subscriberData.nonSubscriptionTransactions
        self.entitlements = EntitlementInfos(entitlementsData: subscriberData.entitlementsData,
                                             purchasesData: subscriberData.allTransactionsByProductId,
                                             requestDate: requestDate,
                                             dateFormatter: dateFormatter)

        self.subscriptionTransactionsByProductId = subscriberData.subscriptionTransactionsByProductId
        self.allPurchases = subscriberData.allPurchases
    }

    static let currentSchemaVersion = "2"

    func jsonObject() -> [String: Any] {
        return rawData.merging(
            ["schema_version": CustomerInfo.currentSchemaVersion],
            strategy: .keepOriginalValue
        )
    }

    private let allPurchases: [String: [String: Any]]
    private let subscriptionTransactionsByProductId: [String: [String: Any]]
    private let dateFormatter: DateFormatter

    private lazy var expirationDatesByProductId: [String: Date?] = {
        return parseExpirationDates(transactionsByProductId: subscriptionTransactionsByProductId)
    }()
    private lazy var purchaseDatesByProductId: [String: Date?] = {
        return parsePurchaseDates(transactionsByProductId: allPurchases)
    }()

    fileprivate struct SubscriberData {

        // swiftlint:disable:next nesting
        enum SubscriberDataError: Int, DescribableError {

            case originalAppUserIdMissing = 0
            case firstSeenMissing
            case firstSeenFormat

            var description: String {
                switch self {
                case .originalAppUserIdMissing:
                    return "Missing property \"original_app_user_id\" from json."
                case .firstSeenMissing:
                    return "Missing propery \"first_seen\" from json."
                case .firstSeenFormat:
                    return "Unable to parse \"first_seen\" due to formatting issues."
                }
            }

        }

        let subscriptionTransactionsByProductId: [String: [String: Any]]
        let originalAppUserId: String
        let managementURL: URL?
        let originalApplicationVersion: String?
        let originalPurchaseDate: Date?
        let firstSeen: Date
        let nonSubscriptionsByProductId: [String: [[String: Any]]]
        let entitlementsData: [String: Any]
        let nonSubscriptionTransactions: [Transaction]
        let allTransactionsByProductId: [String: [String: Any]]
        let allPurchases: [String: [String: Any]]

        init(subscriberData: [String: Any],
             dateFormatter: DateFormatter,
             transactionsFactory: TransactionsFactory) throws {
            let maybeSubscriptions = subscriberData["subscriptions"] as? [String: [String: Any]] ?? [:]
            self.subscriptionTransactionsByProductId = maybeSubscriptions

            // Metadata
            self.originalApplicationVersion = subscriberData["original_application_version"] as? String

            self.originalPurchaseDate =
            dateFormatter.date(fromString: subscriberData["original_purchase_date"] as? String ?? "")

            guard let firstSeenDateString = subscriberData["first_seen"] as? String else {
                throw SubscriberDataError.firstSeenMissing
            }

            guard let firstSeenDate = dateFormatter.date(fromString: firstSeenDateString) else {
                throw SubscriberDataError.firstSeenFormat
            }

            self.firstSeen = firstSeenDate

            guard let originalAppUserIdString = subscriberData["original_app_user_id"] as? String else {
                throw SubscriberDataError.originalAppUserIdMissing
            }
            self.originalAppUserId = originalAppUserIdString

            self.managementURL = URL(string: subscriberData["management_url"] as? String ?? "")

            // Purchases and entitlements
            self.nonSubscriptionsByProductId =
                subscriberData["non_subscriptions"] as? [String: [[String: Any]]] ?? [:]
            self.entitlementsData = subscriberData["entitlements"] as? [String: Any] ?? [:]
            self.nonSubscriptionTransactions = transactionsFactory.nonSubscriptionTransactions(
                withSubscriptionsData: nonSubscriptionsByProductId,
                dateFormatter: dateFormatter)

            let latestNonSubscriptionTransactionsByProductId = [String: [String: Any]](
                uniqueKeysWithValues: nonSubscriptionsByProductId.map { productId, transactionsArray in
                    (productId, transactionsArray.last ?? [:])
                })

            self.allTransactionsByProductId = latestNonSubscriptionTransactionsByProductId
                .merging(subscriptionTransactionsByProductId, strategy: .keepOriginalValue)

            self.allPurchases = latestNonSubscriptionTransactionsByProductId
                .merging(subscriptionTransactionsByProductId) { (current, _) in current }
        }
    }

}

extension CustomerInfo: RawDataContainer {}

enum CustomerInfoError: Int, DescribableError {

    case missingJsonObject = 0
    case cantInstantiateJsonObject
    case requestDateFromJson
    case requestDateFromString

    var description: String {
        switch self {
        case .missingJsonObject:
            return "Unable to read property \"subscriber\" from json."
        case .cantInstantiateJsonObject:
            return "json appears to be in an unexpected format."
        case .requestDateFromJson:
            return "Unable to read property \"request_date\" from json."
        case .requestDateFromString:
            return "Unable to parse a date from json propery \"request_date\"."
        }
    }

}

private extension CustomerInfo {

    static func createSubscriberDataError(_ error: Error, subscriberDictionary: [String: Any]) -> Error {
        Logger.error(Strings.customerInfo.cant_instantiate_from_json_object(maybeJsonObject: subscriberDictionary))

        guard let subscriberDataError = error as? SubscriberData.SubscriberDataError else {
            return CustomerInfoError.cantInstantiateJsonObject.addingUnderlyingError(error)
        }

        let extraContext: String?
        switch subscriberDataError {
        case .originalAppUserIdMissing:
            let originalAppUserId = subscriberDictionary["original_app_user_id"] as? String ?? "missing"
            extraContext = "original_app_user_id is: \(originalAppUserId)"
        case .firstSeenMissing, .firstSeenFormat:
            let firstSeen = subscriberDictionary["first_seen"] as? String ?? "missing"
            extraContext = "first_seen is: \(firstSeen)"
        }
        return CustomerInfoError.cantInstantiateJsonObject.addingUnderlyingError(subscriberDataError,
                                                                                 extraContext: extraContext)
    }

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

    func parseDatesIn(transactionsByProductId: [String: [String: Any]], dateLabel: String) -> [String: Date?] {
        // mapValues will keep the key-value pair in the dictionary for nil values, as desired
        return transactionsByProductId.mapValues { transaction in
            if let dateString = transaction[dateLabel] as? String {
                return dateFormatter.date(fromString: dateString)
            }
            return nil
        }
    }

}
