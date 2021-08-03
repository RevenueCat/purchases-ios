//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SKPaymentTransaction+Extensions.swift
//
//  Created by Juanpe Catalán on 2/8/21.

import StoreKit

// todo: make internal after migration
public extension SKPaymentTransaction {

    /// Although neither `payment` nor `productIdentier` is optional, we must continue
    /// checking the nullability to likely fix issue https://github.com/RevenueCat/purchases-ios/issues/279
    @objc var rc_productIdentifier: String? {
        let maybePayment: SKPayment? = payment

        guard maybePayment != nil else {
            Logger.appleWarning(Strings.purchase.skpayment_missing_from_skpaymenttransaction)
            return nil
        }

        guard let productIdentifier = maybePayment?.productIdentifier, !productIdentifier.isEmpty else {
            Logger.appleWarning(Strings.purchase.skpayment_missing_product_identifier)
            return nil
        }

        return productIdentifier
    }

}
