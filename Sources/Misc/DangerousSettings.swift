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

        #if DEBUG
        let forceServerErrors: Bool
        let forceSignatureFailures: Bool
        let disableHeaderSignatureVerification: Bool
        let testReceiptIdentifier: String?

        init(
            enableReceiptFetchRetry: Bool = false,
            forceServerErrors: Bool = false,
            forceSignatureFailures: Bool = false,
            disableHeaderSignatureVerification: Bool = false,
            testReceiptIdentifier: String? = nil
        ) {
            self.enableReceiptFetchRetry = enableReceiptFetchRetry
            self.forceServerErrors = forceServerErrors
            self.forceSignatureFailures = forceSignatureFailures
            self.disableHeaderSignatureVerification = disableHeaderSignatureVerification
            self.testReceiptIdentifier = testReceiptIdentifier
        }
        #else
        init(
            enableReceiptFetchRetry: Bool = false
        ) {
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
     * if `true`, the SDK will return a set of mock products instead of the
     * products obtained from StoreKit. This is useful for testing or preview purposes. 
     */
    @_spi(Internal) public let uiPreviewMode: Bool

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
     */
    @objc public convenience init(autoSyncPurchases: Bool = true) {
        self.init(autoSyncPurchases: autoSyncPurchases,
                  customEntitlementComputation: false)

    }

    /// - Note: this is `internal` only so the only `public` way to enable `customEntitlementComputation`
    /// is through ``Purchases/configureInCustomEntitlementsComputationMode(apiKey:appUserID:)``.
    @objc internal convenience init(autoSyncPurchases: Bool = true,
                                    customEntitlementComputation: Bool) {
        self.init(autoSyncPurchases: autoSyncPurchases,
                  customEntitlementComputation: customEntitlementComputation,
                  internalSettings: Internal.default)

    }

    /**
     * Used to initialize the SDK in UI preview mode.
     *
     * - Parameter uiPreviewMode: if `true`, the SDK will return a set of mock products instead of the
     * products obtained from StoreKit. This is useful for testing or preview purposes. 
     */
    @_spi(Internal) public convenience init(uiPreviewMode: Bool) {
        self.init(autoSyncPurchases: false, internalSettings: Internal.default, uiPreviewMode: uiPreviewMode)
    }

    /// Designated initializer
    internal init(autoSyncPurchases: Bool,
                  customEntitlementComputation: Bool = false,
                  internalSettings: InternalDangerousSettingsType,
                  uiPreviewMode: Bool = false) {
        self.autoSyncPurchases = autoSyncPurchases
        self.internalSettings = internalSettings
        self.customEntitlementComputation = customEntitlementComputation
        self.uiPreviewMode = uiPreviewMode
    }

}

extension DangerousSettings: Sendable {}

/// Dangerous settings not exposed outside of the SDK.
internal protocol InternalDangerousSettingsType: Sendable {

    /// Whether `ReceiptFetcher` can retry fetching receipts.
    var enableReceiptFetchRetry: Bool { get }

    #if DEBUG
    /// Whether `HTTPClient` will fake server errors
    var forceServerErrors: Bool { get }

    /// Whether `HTTPClient` will fake invalid signatures.
    var forceSignatureFailures: Bool { get }

    /// Used to verify that the backend signs correctly without this part of the signature.
    var disableHeaderSignatureVerification: Bool { get }

    /// Allows defining the receipt identifier for `PostReceiptDataOperation`.
    /// This allows the backend to disambiguate between receipts created across separate test invocations.
    var testReceiptIdentifier: String? { get }

    #endif

}
