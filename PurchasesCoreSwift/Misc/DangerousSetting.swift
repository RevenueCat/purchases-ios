//
//  DangerousSetting.swift
//  PurchasesCoreSwift
//
//  Created by Cesar de la Vega on 1/25/22.
//  Copyright © 2022 Purchases. All rights reserved.
//

/**
 Only use a Dangerous Setting if suggested by RevenueCat support team.
 */
@objc(RCDangerousSetting) enum DangerousSetting: Int {

    /**
     Disable or enable subscribing to the StoreKit queue. If this is disabled, RevenueCat will not sync any purchase
     automatically, and you will have to call syncPurchases whenever a new purchase is completed in order to send
     the receipt to the RevenueCat's backend. Auto syncing of purchases is enabled by default.
     */
    case autoSyncPurchases = 0

}
