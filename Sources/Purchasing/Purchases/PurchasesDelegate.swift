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

/**
 * Delegate for ``Purchases`` responsible for handling updating your app's state in response to updated customer info
 * or promotional product purchases.
 *
 * - Note: Delegate methods can be called at any time after the `delegate` is set, not just in response to
 *  `customerInfo:` calls. Ensure your app is capable of handling these calls at anytime if `delegate` is set.
 */
@objc(RCPurchasesDelegate) public protocol PurchasesDelegate: NSObjectProtocol {

    /**
     * - Note: Deprecated, use purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) or
     * objc: purchases:receivedUpdatedCustomerInfo:
     */
    @available(swift, obsoleted: 1, renamed: "purchases(_:receivedUpdated:)")
    @available(iOS, obsoleted: 1)
    @available(macOS, obsoleted: 1)
    @available(tvOS, obsoleted: 1)
    @available(watchOS, obsoleted: 1)
    @objc(purchases:didReceiveUpdatedPurchaserInfo:)
    optional func purchases(_ purchases: Purchases, didReceiveUpdated purchaserInfo: CustomerInfo)

    /**
     * Called whenever ``Purchases`` receives updated customer info. This may happen periodically
     * throughout the life of the app if new information becomes available (e.g. UIApplicationDidBecomeActive).*
     * - Parameter purchases: Related ``Purchases`` object
     * - Parameter customerInfo: Updated ``CustomerInfo``
     */
    @objc(purchases:receivedUpdatedCustomerInfo:)
    optional func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo)

    /**
     * Called when a user initiates a promotional in-app purchase from the App Store.
     * If your app is able to handle a purchase at the current time, run the deferment block in this method.
     * If the app is not in a state to make a purchase: cache the `startPurchase` block,
     * then call the `startPurchase` block when the app is ready to make the promotional purchase.
     *
     * If the purchase should never be made, you don't need to ever call the block and
     * ``Purchases`` will not proceed with the promotional purchase.
     *
     * This can be tested by opening a link like:
     * itms-services://?action=purchaseIntent&bundleId=<BUNDLE_ID>&productIdentifier=<SKPRODUCT_ID>
     *
     * - Parameter product: `StoreProduct` the product that was selected from the app store
     * - Parameter startPurchase: call this block when the app is ready to handle the purchase
     *
     * ### Related Articles:
     * - [Apple Documentation](https://rev.cat/testing-promoted-in-app-purchases)
     */
    @objc optional func purchases(_ purchases: Purchases,
                                  readyForPromotedProduct product: StoreProduct,
                                  purchase startPurchase: @escaping StartPurchaseBlock)

    @available(iOS, obsoleted: 1, renamed: "purchases(_:readyForPromotedProduct:purchase:)")
    @available(tvOS, obsoleted: 1, renamed: "purchases(_:readyForPromotedProduct:purchase:)")
    @available(watchOS, obsoleted: 1, renamed: "purchases(_:readyForPromotedProduct:purchase:)")
    @available(macOS, obsoleted: 1, renamed: "purchases(_:readyForPromotedProduct:purchase:)")
    @available(macCatalyst, obsoleted: 1, renamed: "purchases(_:readyForPromotedProduct:purchase:)")
    // swiftlint:disable:next missing_docs
    @objc optional func purchases(_ purchases: Purchases,
                                  shouldPurchasePromoProduct product: StoreProduct,
                                  defermentBlock makeDeferredPurchase: @escaping StartPurchaseBlock)

    /**
     * The default return value for this optional method is true. By default, the system displays the price consent
     * sheet when you increase the subscription price in App Store Connect and the subscriber hasn’t yet taken action.
     *
     * The system calls your delegate’s method, if appropriate, when RevenueCat starts observing the `SKPaymentQueue`,
     * and any time the app comes to foreground.
     *
     * If you return false, the system won’t show the price consent sheet. You can choose to display it later by
     * calling ``Purchases/showPriceConsentIfNeeded()``.
     * You may want to delay showing the sheet if it would interrupt your user’s interaction in your app.
     *
     * ### Related Articles
     * - [Apple Documentation](https://rev.cat/testing-promoted-in-app-purchases)
     */
    @available(iOS 13.4, macCatalyst 13.4, *)
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @objc optional var shouldShowPriceConsent: Bool { get }

}
