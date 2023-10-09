//
//  DangerousSetting.swift
//  PurchasesCoreSwift
//
//  Created by Cesar de la Vega on 1/25/22.
//  Copyright © 2022 Purchases. All rights reserved.
//

import Foundation

/**
 Only use a Dangerous Setting if suggested by RevenueCat support team.
 */
@objc(RCDangerousSettings) public final class DangerousSettings: NSObject {

    internal struct Internal: InternalDangerousSettingsType {

        let enableReceiptFetchRetry: Bool
        let usesStoreKit2JWS: Bool

        #if DEBUG
        let forceServerErrors: Bool
        let forceSignatureFailures: Bool
        let testReceiptIdentifier: String?

        init(
            enableReceiptFetchRetry: Bool = false,
            usesStoreKit2JWS: Bool = false,
            forceServerErrors: Bool = false,
            forceSignatureFailures: Bool = false,
            testReceiptIdentifier: String? = nil
        ) {
            self.enableReceiptFetchRetry = enableReceiptFetchRetry
            self.usesStoreKit2JWS = usesStoreKit2JWS
            self.forceServerErrors = forceServerErrors
            self.forceSignatureFailures = forceSignatureFailures
            self.testReceiptIdentifier = testReceiptIdentifier
        }
        #else
        init(enableReceiptFetchRetry: Bool = false) {
            self.enableReceiptFetchRetry = enableReceiptFetchRetry
        }
        #endif

        static let `default`: Self = .init()
    }

    /**
     * Disable or enable subscribing to the StoreKit queue. If this is disabled, RevenueCat won't observe
     * the StoreKit queue, and it will not sync any purchase automatically.
     * Call syncPurchases whenever a new transaction is completed so the receipt is sent to RevenueCat's backend.
     * Consumables disappear from the receipt after the transaction is finished, so make sure purchases are
     * synced before finishing any consumable transaction, otherwise RevenueCat won't register the purchase.
     * Auto syncing of purchases is enabled by default.
     */
    @objc public let autoSyncPurchases: Bool

    /**
     * A property meant for apps that do their own entitlements computation, separated from RevenueCat.
     * It:
     *   - disables automatic CustomerInfo cache updates
     *   - disables ``Purchases/logOut()`` and ``Purchases/logOut(completion:)``
     *   - disallows configuration of the SDK without an appUserID
     *   - disables automatic firing of the PurchasesDelegate's CustomerInfo listener when setting the delegate.
     * It will only be called when the SDK posts a receipt or after customerInfo on device changes.
     *
     * - Important: This is a dangerous setting and should only be used if you intend to do your own entitlement
     * granting, separate from RevenueCat.
     */
    @objc public let customEntitlementComputation: Bool

    internal let internalSettings: InternalDangerousSettingsType

    @objc public override convenience init() {
        self.init(autoSyncPurchases: true)
    }

    /**
     * Only use a Dangerous Setting if suggested by RevenueCat support team.
     *
     * - Parameter autoSyncPurchases: Disable or enable subscribing to the StoreKit queue.
     * If this is disabled, RevenueCat won't observe the StoreKit queue, and it will not sync any purchase
     * automatically.
     * - Parameter usesStoreKit2JWS: Disable or enable sending StoreKit 2 JWS tokens to RevenueCat
     * instead of StoreKit 1 receipts.
     */
    @objc public convenience init(autoSyncPurchases: Bool = true, usesStoreKit2JWS: Bool = false) {
        self.init(autoSyncPurchases: autoSyncPurchases,
                  customEntitlementComputation: false,
                  usesStoreKit2JWS: usesStoreKit2JWS)

    }

    /// - Note: this is `internal` only so the only `public` way to enable `customEntitlementComputation`
    /// is through ``Purchases/configureInCustomEntitlementsComputationMode(apiKey:appUserID:)``.
    @objc internal convenience init(autoSyncPurchases: Bool = true,
                                    customEntitlementComputation: Bool,
                                    usesStoreKit2JWS: Bool) {
        self.init(autoSyncPurchases: autoSyncPurchases,
                  customEntitlementComputation: customEntitlementComputation,
                  internalSettings: Internal.default)

    }

    /// Designated initializer
    internal init(autoSyncPurchases: Bool,
                  customEntitlementComputation: Bool = false,
                  internalSettings: InternalDangerousSettingsType) {
        self.autoSyncPurchases = autoSyncPurchases
        self.internalSettings = internalSettings
        self.customEntitlementComputation = customEntitlementComputation
    }

}

extension DangerousSettings: Sendable {}

/// Dangerous settings not exposed outside of the SDK.
internal protocol InternalDangerousSettingsType: Sendable {

    /// Whether `ReceiptFetcher` can retry fetching receipts.
    var enableReceiptFetchRetry: Bool { get }

    /**
     * Controls whether StoreKit 2 JWS tokens are sent to RevenueCat instead of StoreKit 1 receipts.
     * Must be used in conjunction with the `usesStoreKit2IfAvailable configuration` option.
     */
    var usesStoreKit2JWS: Bool { get }

    #if DEBUG
    /// Whether `HTTPClient` will fake server errors
    var forceServerErrors: Bool { get }

    /// Whether `HTTPClient` will fake invalid signatures.
    var forceSignatureFailures: Bool { get }

    /// Allows defining the receipt identifier for `PostReceiptDataOperation`.
    /// This allows the backend to disambiguate between receipts created across separate test invocations.
    var testReceiptIdentifier: String? { get }
    #endif

}
