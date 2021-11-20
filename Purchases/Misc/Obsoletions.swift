//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Obsoletions.swift
//
//  Created by Nacho Soto on 11/15/21.

import StoreKit

// All these methods are `obsoleted`, which means they can't be called by users of the SDK,
// and therefore the `fatalError`s are unreachable.

public extension Purchases {

    /**
     * Get latest available purchaser info.
     *
     * - Parameter completion: A completion block called when customer info is available and not stale.
     * Called immediately if info is cached. Customer info can be nil if an error occurred.
     */
    @available(iOS, obsoleted: 1, renamed: "getCustomerInfo(completion:)")
    @available(tvOS, obsoleted: 1, renamed: "getCustomerInfo(completion:)")
    @available(watchOS, obsoleted: 1, renamed: "getCustomerInfo(completion:)")
    @available(macOS, obsoleted: 1, renamed: "getCustomerInfo(completion:)")
    @objc func customerInfo(completion: @escaping (CustomerInfo?, Error?) -> Void) {
        fatalError()
    }

    /**
     * Get latest available purchaser info.
     *
     * - Parameter completion: A completion block called when customer info is available and not stale.
     * Called immediately if info is cached. Customer info can be nil if an error occurred.
     */
    @available(iOS, obsoleted: 1, renamed: "getCustomerInfo(completion:)")
    @available(tvOS, obsoleted: 1, renamed: "getCustomerInfo(completion:)")
    @available(watchOS, obsoleted: 1, renamed: "getCustomerInfo(completion:)")
    @available(macOS, obsoleted: 1, renamed: "getCustomerInfo(completion:)")
    @objc func purchaserInfo(completion: @escaping (CustomerInfo?, Error?) -> Void) {
        fatalError()
    }

    /**
     * Fetches the `SKProducts` for your IAPs for given `productIdentifiers`.
     * Use this method if you aren't using `-offeringsWithCompletionBlock:`.
     * You should use offerings though.
     *
     * - Note: `completion` may be called without `SKProduct`s that you are expecting.
     * This is usually caused by iTunesConnect configuration errors.
     * Ensure your IAPs have the "Ready to Submit" status in iTunesConnect.
     * Also ensure that you have an active developer program subscription and you have
     * signed the latest paid application agreements.
     *
     * If you're having trouble see: https://www.revenuecat.com/2018/10/11/configuring-in-app-products-is-hard
     *
     * - Parameter productIdentifiers: A set of product identifiers for in app purchases setup via iTunesConnect.
     * This should be either hard coded in your application, from a file, or from
     * a custom endpoint if you want to be able to deploy new IAPs without an app update.
     * - Parameter completion: An @escaping callback that is called with the loaded products.
     * If the fetch fails for any reason it will return an empty array.
     */
    @available(iOS, obsoleted: 1, renamed: "getProducts(_:completion:)")
    @available(tvOS, obsoleted: 1, renamed: "getProducts(_:completion:)")
    @available(watchOS, obsoleted: 1, renamed: "getProducts(_:completion:)")
    @available(macOS, obsoleted: 1, renamed: "getProducts(_:completion:)")
    @objc(productsWithIdentifiers:completion:)
    func products(_ productIdentifiers: [String], completion: @escaping ([SKProduct]) -> Void) {
        fatalError()
    }

    /**
     * Fetch the configured offerings for this users.
     * Offerings allows you to configure your in-app products via RevenueCat and greatly simplifies management.
     * See the guide (https://docs.revenuecat.com/entitlements) for more info.
     *
     * Offerings will be fetched and cached on instantiation so that, by the time they are needed,
     * your prices are loaded for your purchase flow. Time is money.
     *
     * - Parameter completion: A completion block called when offerings are available.
     * Called immediately if offerings are cached. Offerings will be nil if an error occurred.
     */
    @available(iOS, obsoleted: 1, renamed: "getOfferings(completion:)")
    @available(tvOS, obsoleted: 1, renamed: "getOfferings(completion:)")
    @available(watchOS, obsoleted: 1, renamed: "getOfferings(completion:)")
    @available(macOS, obsoleted: 1, renamed: "getOfferings(completion:)")
    @objc func offerings(completion: @escaping (Offerings?, Error?) -> Void) {
        fatalError()
    }

    /**
     * Purchase the passed `Package`.
     * Call this method when a user has decided to purchase a product. Only call this in direct response to user input.
     * From here `Purchases` will handle the purchase with `StoreKit` and call the `RCPurchaseCompletedBlock`.
     * - Note: You do not need to finish the transaction yourself in the completion callback,
     * Purchases will handle this for you.
     * - Parameter package: The `Package` the user intends to purchase
     *
     * - Parameter completion: A completion block that is called when the purchase completes.
     * If the purchase was successful there will be a `SKPaymentTransaction` and a `RCPurchaserInfo`
     * If the purchase was not successful, there will be an `NSError`.
     * If the user cancelled, `userCancelled` will be `YES`.
     */
    @available(iOS, obsoleted: 1, renamed: "purchase(package:completion:)")
    @available(tvOS, obsoleted: 1, renamed: "purchase(package:completion:)")
    @available(watchOS, obsoleted: 1, renamed: "purchase(package:completion:)")
    @available(macOS, obsoleted: 1, renamed: "purchase(package:completion:)")
    func purchasePackage(_ package: Package, _ completion: @escaping PurchaseCompletedBlock) {
        fatalError()
    }

    /**
     * Purchase the passed `Package`.
     * Call this method when a user has decided to purchase a product. Only call this in direct response to user input.
     * From here `Purchases` will handle the purchase with `StoreKit` and call the `RCPurchaseCompletedBlock`.
     * - Note: You do not need to finish the transaction yourself in the completion callback,
     * Purchases will handle this for you.
     * - Parameter package: The `Package` the user intends to purchase
     *
     * - Parameter completion: A completion block that is called when the purchase completes.
     * If the purchase was successful there will be a `SKPaymentTransaction` and a `RCPurchaserInfo`.
     * If the purchase was not successful, there will be an `NSError`.
     * If the user cancelled, `userCancelled` will be `YES`.
     */
    @available(iOS, obsoleted: 1, renamed: "purchase(package:discount:completion:)")
    @available(tvOS, obsoleted: 1, renamed: "purchase(package:discount:completion:)")
    @available(watchOS, obsoleted: 1, renamed: "purchase(package:discount:completion:)")
    @available(macOS, obsoleted: 1, renamed: "purchase(package:discount:completion:)")
    @available(iOS 12.2, macOS 10.14.4, macCatalyst 13.0, tvOS 12.2, watchOS 6.2, *)
    func purchasePackage(_ package: Package,
                         discount: SKPaymentDiscount,
                         _ completion: @escaping PurchaseCompletedBlock) {
        fatalError()
    }

    /**
     * Use this function if you are not using the Offerings system to purchase an `SKProduct`.
     * If you are using the Offerings system, use `-[RCPurchases purchasePackage:withCompletionBlock]` instead.
     * Call this method when a user has decided to purchase a product. Only call this in direct response to user input.
     * From here `Purchases` will handle the purchase with `StoreKit` and call the `RCPurchaseCompletedBlock`.
     *
     * - Note: You do not need to finish the transaction yourself in the completion callback,
     * Purchases will handle this for you.
     * - Parameter product: The `SKProduct` the user intends to purchase
     * - Parameter completion: A completion block that is called when the purchase completes.
     * If the purchase was successful there will be a `SKPaymentTransaction` and a `RCPurchaserInfo`.
     * If the purchase was not successful, there will be an `NSError`.
     * If the user cancelled, `userCancelled` will be `YES`.
     */
    @available(iOS, obsoleted: 1, renamed: "purchase(product:_:)")
    @available(tvOS, obsoleted: 1, renamed: "purchase(product:_:)")
    @available(watchOS, obsoleted: 1, renamed: "purchase(product:_:)")
    @available(macOS, obsoleted: 1, renamed: "purchase(product:_:)")
    func purchaseProduct(_ product: SKProduct, _ completion: @escaping PurchaseCompletedBlock) {
        fatalError()
    }

    /**
     * Use this function if you are not using the Offerings system to purchase an `SKProduct`.
     * If you are using the Offerings system, use `-[RCPurchases purchasePackage:withCompletionBlock]` instead.
     * Call this method when a user has decided to purchase a product. Only call this in direct response to user input.
     * From here `Purchases` will handle the purchase with `StoreKit` and call the `RCPurchaseCompletedBlock`.
     *
     * - Note: You do not need to finish the transaction yourself in the completion callback,
     * Purchases will handle this for you.
     * - Parameter product: The `SKProduct` the user intends to purchase
     * - Parameter completion: A completion block that is called when the purchase completes.
     * If the purchase was successful there will be a `SKPaymentTransaction` and a `RCPurchaserInfo`.
     * If the purchase was not successful, there will be an `NSError`.
     * If the user cancelled, `userCancelled` will be `YES`.
     */
    @available(iOS, obsoleted: 1, renamed: "purchase(product:discount:completion:)")
    @available(tvOS, obsoleted: 1, renamed: "purchase(product:discount:completion:)")
    @available(watchOS, obsoleted: 1, renamed: "purchase(product:discount:completion:)")
    @available(macOS, obsoleted: 1, renamed: "purchase(product:discount:completion:)")
    @available(iOS 12.2, macOS 10.14.4, macCatalyst 13.0, tvOS 12.2, watchOS 6.2, *)
    func purchaseProduct(_ product: SKProduct,
                         discount: SKPaymentDiscount,
                         _ completion: @escaping PurchaseCompletedBlock) {
        fatalError()
    }

}

@available(iOS, obsoleted: 1, renamed: "CustomerInfo")
@available(tvOS, obsoleted: 1, renamed: "CustomerInfo")
@available(watchOS, obsoleted: 1, renamed: "CustomerInfo")
@available(macOS, obsoleted: 1, renamed: "CustomerInfo")
@objc(RCPurchaserInfo) public class PurchaserInfo: NSObject { }
