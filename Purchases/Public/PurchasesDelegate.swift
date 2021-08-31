//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesDelegate.swift
//
//  Created by Joshua Liebowitz on 8/18/21.
//

import Foundation
import StoreKit

/**
 * Delegate for ``Purchases`` responsible for handling updating your app's state in response to updated purchaser info
 * or promotional product purchases.
 *
 * - Note: Delegate methods can be called at any time after the `delegate` is set, not just in response to
 *  `purchaserInfo:` calls. Ensure your app is capable of handling these calls at anytime if `delegate` is set.
 */
@objc(RCPurchasesDelegate) public protocol PurchasesDelegate: NSObjectProtocol {

    /**
     * Called whenever ``Purchases`` receives updated purchaser info. This may happen periodically
     * throughout the life of the app if new information becomes available (e.g. UIApplicationDidBecomeActive).*
     * - Parameter purchases: Related ``Purchases`` object
     * - Parameter purchaserInfo: Updated ``PurchaserInfo``
     */
    @objc(purchases:didReceiveUpdatedPurchaserInfo:)
    optional func purchases(_ purchases: Purchases, didReceiveUpdated purchaserInfo: PurchaserInfo)

    /**
     * Called when a user initiates a promotional in-app purchase from the App Store.
     * If your app is able to handle a purchase at the current time, run the deferment block in this method.
     * If the app is not in a state to make a purchase: cache the defermentBlock,
     * then call the defermentBlock when the app is ready to make the promotional purchase.
     * If the purchase should never be made, you don't need to ever call the defermentBlock and
     * ``Purchases`` will not proceed with promotional purchases.

     * - Parameter product: `SKProduct` the product that was selected from the app store
     */
    @objc optional func purchases(_ purchases: Purchases,
                                  shouldPurchasePromoProduct product: SKProduct,
                                  defermentBlock makeDeferredPurchase: @escaping DeferredPromotionalPurchaseBlock)

}
