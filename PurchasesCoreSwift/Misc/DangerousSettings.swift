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
@objc(RCDangerousSettings) public class DangerousSettings: NSObject {

    /**
     Disable or enable subscribing to the StoreKit queue. If this is disabled, RevenueCat won't observe
     the StoreKit queue, and it will not sync any purchase automatically.
     Call syncPurchases whenever a new transaction is completed so the receipt is sent to RevenueCat's backend.
     Consumables disappear from the receipt after the transaction is finished, so make sure purchases are
     synced before finishing any consumable transaction, otherwise RevenueCat won't register the purchase.
     Auto syncing of purchases is enabled by default.
     */
    @objc public let autoSyncPurchases: Bool

    @objc override public init() {
        self.autoSyncPurchases = true
    }

    @objc public init(autoSyncPurchases: Bool = true) {
        self.autoSyncPurchases = autoSyncPurchases
    }

}
