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

    /// Dangerous settings not exposed outside of the SDK.
    internal struct InternalSettings {

        /// Whether `ReceiptFetcher` can retry fetching receipts.
        let enableReceiptFetchRetry: Bool

        static let `default`: Self = .init(enableReceiptFetchRetry: false)
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

    internal let internalSettings: InternalSettings

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
    @objc public convenience init(autoSyncPurchases: Bool) {
        self.init(autoSyncPurchases: autoSyncPurchases, internalSettings: .default)
    }

    /// Designated initializer
    internal init(autoSyncPurchases: Bool, internalSettings: InternalSettings) {
        self.autoSyncPurchases = autoSyncPurchases
        self.internalSettings = internalSettings
    }

}

extension DangerousSettings: Sendable {}
