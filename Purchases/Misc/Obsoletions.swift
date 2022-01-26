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
// See also: docs/Deprecations.md

// swiftlint:disable file_length

public extension Purchases {

    /**
     * This method will post all purchases associated with the current App Store account to RevenueCat and become
     * associated with the current ``appUserID``. If the receipt is being used by an existing user, the current
     * ``appUserID`` will be aliased together with the `appUserID` of the existing user.
     *  Going forward, either `appUserID` will be able to reference the same user.
     *
     * You shouldn't use this method if you have your own account system. In that case "restoration" is provided
     * by your app passing the same `appUserId` used to purchase originally.
     *
     * - Note: This may force your users to enter the App Store password so should only be performed on request of
     * the user. Typically with a button in settings or near your purchase UI. Use
     * ``Purchases/syncPurchases(completion:)`` if you need to restore transactions programmatically.
     */
    @available(iOS, obsoleted: 1, renamed: "restorePurchases(completion:)")
    @available(tvOS, obsoleted: 1, renamed: "restorePurchases(completion:)")
    @available(watchOS, obsoleted: 1, renamed: "restorePurchases(completion:)")
    @available(macOS, obsoleted: 1, renamed: "restorePurchases(completion:)")
    @objc(restoreTransactionsWithCompletionBlock:)
    func restoreTransactions(completion: ((CustomerInfo?, Error?) -> Void)? = nil) {
        fatalError()
    }

    /**
     * This method will post all purchases associated with the current App Store account to RevenueCat and become
     * associated with the current ``appUserID``. If the receipt is being used by an existing user, the current
     * ``appUserID`` will be aliased together with the `appUserID` of the existing user.
     *  Going forward, either `appUserID` will be able to reference the same user.
     *
     * You shouldn't use this method if you have your own account system. In that case "restoration" is provided
     * by your app passing the same `appUserId` used to purchase originally.
     *
     * - Note: This may force your users to enter the App Store password so should only be performed on request of
     * the user. Typically with a button in settings or near your purchase UI. Use
     * ``Purchases/syncPurchases(completion:)`` if you need to restore transactions programmatically.
     */
    @available(iOS, introduced: 13.0, obsoleted: 13.0, renamed: "restorePurchases()")
    @available(tvOS, introduced: 13.0, obsoleted: 13.0, renamed: "restorePurchases()")
    @available(watchOS, introduced: 6.2, obsoleted: 6.2, renamed: "restorePurchases()")
    @available(macOS, introduced: 10.15, obsoleted: 10.15, renamed: "restorePurchases()")
    @available(macCatalyst, introduced: 13.0, obsoleted: 13.0, renamed: "restorePurchases()")
    func restoreTransactions() async throws -> CustomerInfo {
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
    @objc(purchaserInfoWithCompletionBlock:)
    func purchaserInfo(completion: @escaping (CustomerInfo?, Error?) -> Void) {
        fatalError()
    }

    /**
     * Get latest available purchaser info.
     */
    @available(iOS, introduced: 13.0, obsoleted: 13.0, renamed: "customerInfo()")
    @available(tvOS, introduced: 13.0, obsoleted: 13.0, renamed: "customerInfo()")
    @available(watchOS, introduced: 6.2, obsoleted: 6.2, renamed: "customerInfo()")
    @available(macOS, introduced: 10.15, obsoleted: 10.15, renamed: "customerInfo()")
    @available(macCatalyst, introduced: 13.0, obsoleted: 13.0, renamed: "customerInfo()")
    func purchaserInfo() async throws -> CustomerInfo {
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
    @objc(productsWithIdentifiers:completionBlock:)
    func products(_ productIdentifiers: [String], completion: @escaping ([SKProduct]) -> Void) {
        fatalError()
    }

    /**
     * Fetch the configured offerings for this users.
     * Offerings allows you to configure your in-app products via RevenueCat and greatly simplifies management.
     * See [the guide](https://docs.revenuecat.com/entitlements) for more info.
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
    @objc(offeringsWithCompletionBlock:)
    func offerings(completion: @escaping (Offerings?, Error?) -> Void) {
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
    @objc(purchasePackage:withCompletionBlock:)
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
     */
    @available(iOS, introduced: 13.0, obsoleted: 13.0, renamed: "purchase(package:)")
    @available(tvOS, introduced: 13.0, obsoleted: 13.0, renamed: "purchase(package:)")
    @available(watchOS, introduced: 6.2, obsoleted: 6.2, renamed: "purchase(package:)")
    @available(macOS, introduced: 10.15, obsoleted: 10.15, renamed: "purchase(package:)")
    @available(macCatalyst, introduced: 13.0, obsoleted: 13.0, renamed: "purchase(package:)")
    func purchasePackage(_ package: Package) async throws ->
    // swiftlint:disable:next large_tuple
    (transaction: StoreTransaction, customerInfo: CustomerInfo, userCancelled: Bool) {
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
    @available(iOS, introduced: 12.2, obsoleted: 12.2, renamed: "purchase(package:discount:completion:)")
    @available(tvOS, introduced: 12.2, obsoleted: 12.2, renamed: "purchase(package:discount:completion:)")
    @available(watchOS, introduced: 6.2, obsoleted: 6.2, renamed: "purchase(package:discount:completion:)")
    @available(macOS, introduced: 10.14.4, obsoleted: 10.14.4, renamed: "purchase(package:discount:completion:)")
    @available(macCatalyst, introduced: 13.0, obsoleted: 13.0, renamed: "purchase(package:discount:completion:)")
    @objc(purchasePackage:withDiscount:completionBlock:)
    func purchasePackage(_ package: Package,
                         discount: SKPaymentDiscount,
                         _ completion: @escaping PurchaseCompletedBlock) {
        fatalError()
    }

    /**
     * Purchase the passed `Package`.
     * Call this method when a user has decided to purchase a product. Only call this in direct response to user input.
     * From here `Purchases` will handle the purchase with `StoreKit` and call the `RCPurchaseCompletedBlock`.
     * - Note: You do not need to finish the transaction yourself in the completion callback,
     * Purchases will handle this for you.
     * - Parameter package: The `Package` the user intends to purchase
     */
    @available(iOS, introduced: 13.0, obsoleted: 13.0, renamed: "purchase(package:discount:)")
    @available(tvOS, introduced: 13.0, obsoleted: 13.0, renamed: "purchase(package:discount:)")
    @available(watchOS, introduced: 6.2, obsoleted: 6.2, renamed: "purchase(package:discount:)")
    @available(macOS, introduced: 10.15, obsoleted: 10.15, renamed: "purchase(package:discount:)")
    @available(macCatalyst, introduced: 13.0, obsoleted: 13.0, renamed: "purchase(package:discount:)")
    func purchasePackage(_ package: Package,
                         discount: SKPaymentDiscount) async throws ->
    // swiftlint:disable:next large_tuple
    (transaction: StoreTransaction, customerInfo: CustomerInfo, userCancelled: Bool) {
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
    @objc(purchaseProduct:withCompletionBlock:)
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
     */
    @available(iOS, introduced: 13.0, obsoleted: 13.0, renamed: "purchase(product:)")
    @available(tvOS, introduced: 13.0, obsoleted: 13.0, renamed: "purchase(product:)")
    @available(watchOS, introduced: 6.2, obsoleted: 6.2, renamed: "purchase(product:)")
    @available(macOS, introduced: 10.15, obsoleted: 10.15, renamed: "purchase(product:)")
    @available(macCatalyst, introduced: 13.0, obsoleted: 13.0, renamed: "purchase(product:)")
    func purchaseProduct(_ product: SKProduct) async throws {
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
    @available(iOS, introduced: 12.2, obsoleted: 12.2, renamed: "purchase(product:discount:completion:)")
    @available(tvOS, introduced: 12.2, obsoleted: 12.2, renamed: "purchase(product:discount:completion:)")
    @available(watchOS, introduced: 6.2, obsoleted: 6.2, renamed: "purchase(product:discount:completion:)")
    @available(macOS, introduced: 10.14.4, obsoleted: 10.14.4, renamed: "purchase(product:discount:completion:)")
    @available(macCatalyst, introduced: 13.0, obsoleted: 13.0, renamed: "purchase(product:discount:completion:)")
    @objc(purchaseProduct:withDiscount:completionBlock:)
    func purchaseProduct(_ product: SKProduct,
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
     */
    @available(iOS, introduced: 13.0, obsoleted: 13.0, renamed: "purchase(product:discount:)")
    @available(tvOS, introduced: 13.0, obsoleted: 13.0, renamed: "purchase(product:discount:)")
    @available(watchOS, introduced: 6.2, obsoleted: 6.2, renamed: "purchase(product:discount:)")
    @available(macOS, introduced: 10.15, obsoleted: 10.15, renamed: "purchase(product:discount:)")
    @available(macCatalyst, introduced: 13.0, obsoleted: 13.0, renamed: "purchase(product:discount:)")
    func purchaseProduct(_ product: SKProduct, discount: SKPaymentDiscount) async throws {
        fatalError()
    }

    /**
     * Use this function to retrieve the `SKPaymentDiscount` for a given `SKProduct`.
     *
     * - Parameter discount: The `SKProductDiscount` to apply to the product.
     * - Parameter product: The `SKProduct` the user intends to purchase.
     * - Parameter completion: A completion block that is called when the `SKPaymentDiscount` is returned.
     * If it was not successful, there will be an `Error`.
     */
    @available(iOS, introduced: 12.2, obsoleted: 12.2,
               message: "Obtain StoreProductDiscount from StoreProduct or use checkPromotionalOfferEligibility")
    @available(tvOS, introduced: 12.2, obsoleted: 12.2,
               message: "Obtain StoreProductDiscount from StoreProduct or use checkPromotionalOfferEligibility")
    @available(watchOS, introduced: 6.2, obsoleted: 6.2,
               message: "Obtain StoreProductDiscount from StoreProduct or use checkPromotionalOfferEligibility")
    @available(macOS, introduced: 10.14.4, obsoleted: 10.14.4,
               message: "Obtain StoreProductDiscount from StoreProduct or use checkPromotionalOfferEligibility")
    @available(macCatalyst, introduced: 13.0, obsoleted: 13.0,
               message: "Obtain StoreProductDiscount from StoreProduct or use checkPromotionalOfferEligibility")
    @objc(paymentDiscountForProductDiscount:product:completion:)
    func paymentDiscount(for discount: SKProductDiscount,
                         product: SKProduct,
                         completion: @escaping (SKPaymentDiscount?, Error?) -> Void) {
        fatalError()
    }

    /**
     * Use this function to retrieve the `SKPaymentDiscount` for a given `SKProduct`.
     *
     * - Parameter discount: The `SKProductDiscount` to apply to the product.
     * - Parameter product: The `SKProduct` the user intends to purchase.
     */
    @available(iOS, introduced: 13.0, obsoleted: 13.0,
               message: "Obtain StoreProductDiscount from StoreProduct or use checkPromotionalOfferEligibility")
    @available(tvOS, introduced: 13.0, obsoleted: 13.0,
               message: "Obtain StoreProductDiscount from StoreProduct or use checkPromotionalOfferEligibility")
    @available(watchOS, introduced: 6.2, obsoleted: 6.2,
               message: "Obtain StoreProductDiscount from StoreProduct or use checkPromotionalOfferEligibility")
    @available(macOS, introduced: 10.15, obsoleted: 10.15,
               message: "Obtain StoreProductDiscount from StoreProduct or use checkPromotionalOfferEligibility")
    @available(macCatalyst, introduced: 13.0, obsoleted: 13.0,
               message: "Obtain StoreProductDiscount from StoreProduct or use checkPromotionalOfferEligibility")
    func paymentDiscount(for discount: SKProductDiscount,
                         product: SKProduct) async throws -> SKPaymentDiscount {
        fatalError()
    }

    /**
     * This function will alias two appUserIDs together.
     *
     * - Parameter alias: The new appUserID that should be linked to the currently identified appUserID
     * - Parameter completion: An optional completion block called when the aliasing has been successful.
     * This completion block will receive an error if there's been one.
     */
    @available(iOS, obsoleted: 1, renamed: "logIn")
    @available(tvOS, obsoleted: 1, renamed: "logIn")
    @available(watchOS, obsoleted: 1, renamed: "logIn")
    @available(macOS, obsoleted: 1, renamed: "logIn")
    @objc(createAlias:completionBlock:)
    func createAlias(_ alias: String, _ completion: ((CustomerInfo?, Error?) -> Void)?) {
       fatalError()
    }

    /**
     * This function will identify the current user with an appUserID. Typically this would be used after a
     * logout to identify a new user without calling configure.
     *
     * - Parameter appUserID: The appUserID that should be linked to the current user.
     * - Parameter completion: An optional completion block called when the identify call has completed.
     * This completion block will receive an error if there's been one.
     */
    @available(iOS, obsoleted: 1, renamed: "logIn")
    @available(tvOS, obsoleted: 1, renamed: "logIn")
    @available(watchOS, obsoleted: 1, renamed: "logIn")
    @available(macOS, obsoleted: 1, renamed: "logIn")
    @objc(identify:completionBlock:)
    func identify(_ appUserID: String, _ completion: ((CustomerInfo?, Error?) -> Void)?) {
        fatalError()
    }

    /**
     * Resets the Purchases client clearing the saved appUserID.
     * This will generate a random user id and save it in the cache.
     */
    @available(iOS, obsoleted: 1, renamed: "logOut")
    @available(tvOS, obsoleted: 1, renamed: "logOut")
    @available(watchOS, obsoleted: 1, renamed: "logOut")
    @available(macOS, obsoleted: 1, renamed: "logOut")
    @objc(resetWithCompletionBlock:)
    func reset(completion: ((CustomerInfo?, Error?) -> Void)?) {
        fatalError()
    }

}

@available(iOS, obsoleted: 1, renamed: "CustomerInfo")
@available(tvOS, obsoleted: 1, renamed: "CustomerInfo")
@available(watchOS, obsoleted: 1, renamed: "CustomerInfo")
@available(macOS, obsoleted: 1, renamed: "CustomerInfo")
@objc(RCPurchaserInfo) public class PurchaserInfo: NSObject { }

@available(iOS, obsoleted: 1, renamed: "StoreTransaction")
@available(tvOS, obsoleted: 1, renamed: "StoreTransaction")
@available(watchOS, obsoleted: 1, renamed: "StoreTransaction")
@available(macOS, obsoleted: 1, renamed: "StoreTransaction")
@objc(RCTransaction) public class Transaction: NSObject { }

public extension Package {
    /**
     `SKProduct` assigned to this package. https://developer.apple.com/documentation/storekit/skproduct
     */
    @available(iOS, obsoleted: 1, renamed: "storeProduct", message: "Use StoreProduct instead")
    @available(tvOS, obsoleted: 1, renamed: "storeProduct", message: "Use StoreProduct instead")
    @available(watchOS, obsoleted: 1, renamed: "storeProduct", message: "Use StoreProduct instead")
    @available(macOS, obsoleted: 1, renamed: "storeProduct", message: "Use StoreProduct instead")
    @available(macCatalyst, obsoleted: 1, renamed: "storeProduct", message: "Use StoreProduct instead")
    @objc var product: SKProduct { fatalError() }
}

/// `NSErrorDomain` for errors occurring within the scope of the Purchases SDK.
@available(iOS, obsoleted: 1, message: "Use ErrorCode instead")
@available(tvOS, obsoleted: 1, message: "Use ErrorCode instead")
@available(watchOS, obsoleted: 1, message: "Use ErrorCode instead")
@available(macOS, obsoleted: 1, message: "Use ErrorCode instead")
@available(macCatalyst, obsoleted: 1, message: "Use ErrorCode instead")
// swiftlint:disable:next identifier_name
public var ErrorDomain: NSErrorDomain { fatalError() }
