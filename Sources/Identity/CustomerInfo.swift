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

// swiftlint:disable file_length
import Foundation

/**
 An identifier used to identify a product.
 */
public typealias ProductIdentifier = String

/**
 A container for the most recent customer info returned from `Purchases`.
 These objects are non-mutable and do not update automatically.
 */
@objc(RCCustomerInfo) public final class CustomerInfo: NSObject {

    /// ``EntitlementInfos`` attached to this customer info.
    @objc public let entitlements: EntitlementInfos

    /// All *subscription* product identifiers with expiration dates in the future.
    @objc public var activeSubscriptions: Set<ProductIdentifier> {
        self.activeKeys(dates: self.expirationDatesByProductId)
    }

    /// All product identifiers purchases by the user regardless of expiration.
    @objc public let allPurchasedProductIdentifiers: Set<ProductIdentifier>

    /// Returns the latest expiration date of all products, nil if there are none.
    @objc public var latestExpirationDate: Date? {
        let mostRecentDate = self.expirationDatesByProductId
            .values
            .compactMap { $0 }
            .max { $0.timeIntervalSinceReferenceDate < $1.timeIntervalSinceReferenceDate }

        return mostRecentDate
    }

    /**
     * Returns all the non-subscription purchases a user has made.
     * The purchases are ordered by purchase date in ascending order.
     * 
     * This includes:
     * - Consumables
     * - Non-consumables
     * - Non-renewing subscriptions
     */
    @objc public let nonSubscriptions: [NonSubscriptionTransaction]

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
     * - Note: This can be `nil`, see ``Purchases/restorePurchases(completion:)``
     */
    @objc public let originalPurchaseDate: Date?

    /**
     * The build number (in iOS) or the marketing version (in macOS) for the version of the application when the user
     * bought the app. This corresponds to the value of CFBundleVersion (in iOS) or CFBundleShortVersionString
     * (in macOS) in the Info.plist file when the purchase was originally made. Use this for grandfathering users
     * when migrating to subscriptions.
     *
     * - Note: This can be nil, see -`Purchases.restorePurchases(completion:)`
     */
    @objc public let originalApplicationVersion: String?

    /// Dictionary of all subscription product identifiers and their subscription info
    @objc public let subscriptionsByProductIdentifier: [ProductIdentifier: SubscriptionInfo]

    /// Get the expiration date for a given product identifier. You should use Entitlements though!
    /// - Parameter productIdentifier: Product identifier for product
    /// - Returns:  The expiration date for `productIdentifier`, `nil` if product never purchased
    @objc public func expirationDate(forProductIdentifier productIdentifier: ProductIdentifier) -> Date? {
        return expirationDatesByProductId[productIdentifier] ?? nil
    }

    /// Get the latest purchase or renewal date for a given product identifier. You should use Entitlements though!
    /// - Parameter productIdentifier: Product identifier for subscription product
    /// - Returns: The purchase date for `productIdentifier`, `nil` if product never purchased
    @objc public func purchaseDate(forProductIdentifier productIdentifier: ProductIdentifier) -> Date? {
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

        return (self.data.response == other.data.response &&
                self.data.entitlementVerification == other.data.entitlementVerification)
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.data.response)

        return hasher.finalize()
    }

    public override var description: String {
        let activeSubsDescription = self.activeSubscriptions.reduce(into: [String: String]()) { dict, subId in
            dict[subId] = "expiresDate: \(String(describing: self.expirationDate(forProductIdentifier: subId)))"
        }

        let activeEntitlementsDescription = self.entitlements.active.mapValues { $0.description }

        let allEntitlementsDescription = self.entitlements.all.mapValues { $0.description }

        let verificationResult = self.entitlements.verification.debugDescription

        let subscriptionsDescription = self.subscriptionsByProductIdentifier.mapValues { $0.description }

        return """
            <\(String(describing: CustomerInfo.self)):
            originalApplicationVersion=\(self.originalApplicationVersion ?? ""),
            latestExpirationDate=\(String(describing: self.latestExpirationDate)),
            activeEntitlements=\(activeEntitlementsDescription),
            activeSubscriptions=\(activeSubsDescription),
            nonSubscriptions=\(self.nonSubscriptions),
            subscriptions=\(subscriptionsDescription),
            requestDate=\(String(describing: self.requestDate)),
            firstSeen=\(String(describing: self.firstSeen)),
            originalAppUserId=\(self.originalAppUserId),
            entitlements=\(allEntitlementsDescription)
            verification=\(verificationResult)
            >
            """
    }

    /// Represents the original source of the ``CustomerInfo`` object.
    internal var originalSource: OriginalSource {
        return self.data.originalSource
    }

    /// Whether the `CustomerInfo` instance was loaded from the device cache.
    internal var isLoadedFromCache: Bool {
        return self.data.loadedFromCache
    }

    // MARK: -

    private let data: Contents

    /// Initializes a `CustomerInfo` with the underlying data in the current schema version
    convenience init(response: CustomerInfoResponse,
                     entitlementVerification: VerificationResult,
                     sandboxEnvironmentDetector: SandboxEnvironmentDetector,
                     httpResponseOriginalSource: HTTPResponseOriginalSource?) {
        let originalSource = OriginalSource(entitlementVerification: entitlementVerification,
                                            httpResponseOriginalSource: httpResponseOriginalSource)
        self.init(data: .init(response: response,
                              entitlementVerification: entitlementVerification,
                              schemaVersion: Self.currentSchemaVersion,
                              originalSource: originalSource ?? .main),
                  sandboxEnvironmentDetector: sandboxEnvironmentDetector)
    }

    /// Initializes a `CustomerInfo` creating a copy.
    convenience init(customerInfo: CustomerInfo,
                     sandboxEnvironmentDetector: SandboxEnvironmentDetector) {
        self.init(data: customerInfo.data, sandboxEnvironmentDetector: sandboxEnvironmentDetector)
    }

    fileprivate init(
        data: Contents,
        sandboxEnvironmentDetector: SandboxEnvironmentDetector = BundleSandboxEnvironmentDetector.default
    ) {
        let response = data.response
        let subscriber = response.subscriber

        self.data = data
        self.entitlements = EntitlementInfos(
            entitlements: subscriber.entitlements,
            purchases: subscriber.allPurchasesByProductId,
            requestDate: response.requestDate,
            sandboxEnvironmentDetector: sandboxEnvironmentDetector,
            verification: data.entitlementVerification
        )
        self.nonSubscriptions = TransactionsFactory.nonSubscriptionTransactions(
            withSubscriptionsData: subscriber.nonSubscriptions
        )
        self.requestDate = response.requestDate
        self.firstSeen = subscriber.firstSeen
        self.originalAppUserId = subscriber.originalAppUserId
        self.originalPurchaseDate = subscriber.originalPurchaseDate
        self.originalApplicationVersion = subscriber.originalApplicationVersion
        self.managementURL = subscriber.managementUrl

        self.expirationDatesByProductId = Self.extractExpirationDates(subscriber)
        self.purchaseDatesByProductId = Self.extractPurchaseDates(subscriber)
        self.allPurchasedProductIdentifiers = Set(self.expirationDatesByProductId.keys)
            .union(self.nonSubscriptions.map { $0.productIdentifier })

        self.subscriptionsByProductIdentifier =
        Dictionary(uniqueKeysWithValues: subscriber.subscriptions.map { (key, subscriptionData) in
            (key, SubscriptionInfo(
                productIdentifier: key,
                purchaseDate: subscriptionData.purchaseDate,
                originalPurchaseDate: subscriptionData.originalPurchaseDate,
                expiresDate: subscriptionData.expiresDate,
                store: subscriptionData.store,
                isSandbox: subscriptionData.isSandbox,
                unsubscribeDetectedAt: subscriptionData.unsubscribeDetectedAt,
                billingIssuesDetectedAt: subscriptionData.billingIssuesDetectedAt,
                gracePeriodExpiresDate: subscriptionData.gracePeriodExpiresDate,
                ownershipType: subscriptionData.ownershipType,
                periodType: subscriptionData.periodType,
                refundedAt: subscriptionData.refundedAt,
                storeTransactionId: subscriptionData.storeTransactionId,
                requestDate: response.requestDate,
                price: subscriptionData.price.map { ProductPaidPrice(currency: $0.currency, amount: $0.amount) },
                managementURL: subscriptionData.managementUrl,
                displayName: subscriptionData.displayName
            ))
        })
    }

    private let expirationDatesByProductId: [String: Date?]
    private let purchaseDatesByProductId: [String: Date?]
}

// MARK: - Internal

extension CustomerInfo {

    var subscriber: CustomerInfoResponse.Subscriber {
        return self.data.response.subscriber
    }

    var schemaVersion: String? {
        return self.data.schemaVersion
    }

    var schemaVersionIsCompatible: Bool {
        guard let version = self.schemaVersion else { return false }

        return Self.compatibleSchemaVersions.contains(version)
    }

    static let currentSchemaVersion = "3"

    private static let compatibleSchemaVersions: Set<String> = [
        // Version 3 is virtually identical to 2 (only difference is `Codable` vs manual decoding).
        "2",
        CustomerInfo.currentSchemaVersion
    ]

}

extension CustomerInfo {

    /// Creates a copy of this ``CustomerInfo`` modifying only the ``VerificationResult`` and the ``OriginalSource``.
    func copy(
        with entitlementVerification: VerificationResult,
        httpResponseOriginalSource: HTTPResponseOriginalSource?
    ) -> Self {
        let originalSource = OriginalSource(entitlementVerification: entitlementVerification,
                                            httpResponseOriginalSource: httpResponseOriginalSource)
        guard entitlementVerification != self.data.entitlementVerification ||
                originalSource != self.data.originalSource
        else { return self }

        var copy = self.data
        copy.entitlementVerification = entitlementVerification
        copy.originalSource = originalSource ?? .main
        return .init(data: copy)
    }

    /// Creates a copy of this ``CustomerInfo`` setting the `isLoadedFromCache` flag  to `true`.
    func loadedFromCache() -> Self {
        guard !self.isLoadedFromCache else { return self }

        var copy = self.data
        copy.loadedFromCache = true
        return .init(data: copy)
    }

}

extension CustomerInfo: RawDataContainer {

    // Docs inherited from protocol
    // swiftlint:disable missing_docs
    @objc
    public var rawData: [String: Any] {
        return self.data.response.rawData
    }

}

extension CustomerInfo: Sendable {}

/// `CustomerInfo`'s `Codable` implementation relies on `Data`
extension CustomerInfo: Codable {

    // swiftlint:disable:next missing_docs
    public convenience init(from decoder: Decoder) throws {
        do {
            self.init(data: try Contents(from: decoder))
        } catch {
            throw ErrorUtils.customerInfoError(error: error)
        }
    }

    // swiftlint:disable:next missing_docs
    public func encode(to encoder: Encoder) throws {
        try self.data.encode(to: encoder)
    }

}

extension CustomerInfo: HTTPResponseBody {

    /// Creates a copy of this ``CustomerInfo`` modifying only the `requestDate`.
    func copy(with newRequestDate: Date) -> CustomerInfo {
        Logger.verbose(Strings.customerInfo.updating_request_date(self, newRequestDate))

        var copy = self.data
        copy.response.requestDate = newRequestDate
        return .init(data: copy)
    }

}

// MARK: -

extension CustomerInfo: Identifiable {

    // swiftlint:disable:next missing_docs
    public var id: String {
        return self.originalAppUserId
    }

}

// MARK: - Private

private extension CustomerInfo {

    /// The actual contents of a ``CustomerInfo``: the response with the associated version and other metadata.
    struct Contents {

        var response: CustomerInfoResponse
        var entitlementVerification: VerificationResult
        var schemaVersion: String?
        var originalSource: CustomerInfo.OriginalSource
        var loadedFromCache: Bool = false

        init(response: CustomerInfoResponse,
             entitlementVerification: VerificationResult,
             schemaVersion: String?,
             originalSource: CustomerInfo.OriginalSource) {
            self.response = response
            self.entitlementVerification = entitlementVerification
            self.schemaVersion = schemaVersion
            self.originalSource = originalSource
        }

    }

}

/// `Codable` implementation that puts the content of`response`, `schemaVersion` and `originalSource`
/// at the same level instead of nested.
extension CustomerInfo.Contents: Codable {

    private enum CodingKeys: String, CodingKey {

        case response
        case entitlementVerification
        case schemaVersion
        case originalSource

    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try self.response.encode(to: encoder)
        try container.encode(self.entitlementVerification, forKey: .entitlementVerification)
        // Always use current schema version when encoding
        try container.encode(CustomerInfo.currentSchemaVersion, forKey: .schemaVersion)
        try container.encode(self.originalSource, forKey: .originalSource)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.response = try CustomerInfoResponse(from: decoder)
        self.entitlementVerification = try container.decodeIfPresent(
            VerificationResult.self,
            forKey: .entitlementVerification
        ) ?? .notRequested
        self.schemaVersion = try container.decodeIfPresent(String.self, forKey: .schemaVersion)
        self.originalSource = try container.decodeIfPresent(CustomerInfo.OriginalSource.self,
                                                            forKey: .originalSource) ?? .main
    }

}

extension CustomerInfo {

    /// Internal enum representing the original source of the ``CustomerInfo`` object.
    enum OriginalSource: String, Codable {
        /// Main server
        case main

        /// Load shedder server
        case loadShedder = "load_shedder"

        /// Computed on device from offline entitlements
        case offlineEntitlements = "offline_entitlements"

        init?(entitlementVerification: VerificationResult, httpResponseOriginalSource: HTTPResponseOriginalSource?) {
            if entitlementVerification == .verifiedOnDevice {
                self = .offlineEntitlements
            } else {
                switch httpResponseOriginalSource {
                case .mainServer:
                    self = .main
                case .loadShedder:
                    self = .loadShedder
                case .fallbackUrl:
                    return nil // CustomerInfo not supported from fallback URL
                case .none:
                    return nil
                }
            }
        }
    }

}
