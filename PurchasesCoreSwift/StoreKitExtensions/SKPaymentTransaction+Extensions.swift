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

extension SKPaymentTransaction {

    /// Considering issue https://github.com/RevenueCat/purchases-ios/issues/279, sometimes `payment`
    /// and `productIdentifier` can be `nil`, in this case, they must be have treated as nullable.
    /// Due of that an optional reference is created so that the compiler would allow us to check for nullability.
    var productIdentifier: String? {
        guard let maybePayment = payment as SKPayment? else {
            Logger.appleWarning(Strings.purchase.skpayment_missing_from_skpaymenttransaction)
            return nil
        }

        guard let productIdentifier = maybePayment.productIdentifier as String?,
              !productIdentifier.isEmpty else {
            Logger.appleWarning(Strings.purchase.skpayment_missing_product_identifier)
            return nil
        }

        return productIdentifier
    }

}
