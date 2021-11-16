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
     * Deprecated
     */
    @available(swift, obsoleted: 1, renamed: "getCustomerInfo(completion:)")
    @available(*, deprecated, message: "use getCustomerInfoWithCompletion:", renamed: "getOfferingsWithCompletion")
    @objc func customerInfo(completion: @escaping (CustomerInfo?, Error?) -> Void) {
        fatalError()
    }

    /**
     * Deprecated
     */
    @available(swift, obsoleted: 1, renamed: "getCustomerInfo(completion:)")
    @available(*, deprecated, message: "use getCustomerInfoWithCompletion:", renamed: "getOfferingsWithCompletion")
    @objc func purchaserInfo(completion: @escaping (CustomerInfo?, Error?) -> Void) {
        fatalError()
    }

    /**
     * Deprecated
     */
    @available(*,
                deprecated,
                message: "use getProductsWithIdentifiers:completion:",
                renamed: "getProductsWithIdentifiers")
    @available(swift, obsoleted: 1, renamed: "getProducts(_:completion:)")
    @objc(productsWithIdentifiers:completion:)
    func products(_ productIdentifiers: [String], completion: @escaping ([SKProduct]) -> Void) {
        fatalError()
    }

    /**
     * Deprecated
     */
    @available(swift, obsoleted: 1, renamed: "getOfferings(completion:)")
    @available(*, deprecated, message: "use getOfferingsWithCompletion:", renamed: "getOfferingsWithCompletion")
    @objc func offerings(completion: @escaping (Offerings?, Error?) -> Void) {
        fatalError()
    }

    /**
     * Deprecated
     */
    @available(swift, obsoleted: 1, renamed: "purchase(package:completion:)")
    func purchasePackage(_ package: Package, _ completion: @escaping PurchaseCompletedBlock) {
        fatalError()
    }

    /**
     * Deprecated
     */
    @available(swift, obsoleted: 1, renamed: "purchase(package:discount:completion:)")
    @available(iOS 12.2, macOS 10.14.4, macCatalyst 13.0, tvOS 12.2, watchOS 6.2, *)
    func purchasePackage(_ package: Package,
                         discount: SKPaymentDiscount,
                         _ completion: @escaping PurchaseCompletedBlock) {
        fatalError()
    }

    /**
     * Deprecated
     */
    @available(swift, obsoleted: 1, renamed: "purchase(product:_:)")
    func purchaseProduct(_ product: SKProduct, _ completion: @escaping PurchaseCompletedBlock) {
        fatalError()
    }

    /**
     * Deprecated
     */
    @available(swift, obsoleted: 1, renamed: "purchase(product:discount:completion:)")
    @available(iOS 12.2, macOS 10.14.4, macCatalyst 13.0, tvOS 12.2, watchOS 6.2, *)
    func purchaseProduct(_ product: SKProduct,
                         discount: SKPaymentDiscount,
                         _ completion: @escaping PurchaseCompletedBlock) {
        fatalError()
    }

}

@available(swift, obsoleted: 1, renamed: "CustomerInfo")
@available(*, deprecated, message: "use RCCustomerInfo:", renamed: "RCCustomerInfo")
@objc(RCPurchaserInfo) public class PurchaserInfo: NSObject { }
