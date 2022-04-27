//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKitWorkarounds.swift
//
//  Created by Nacho Soto on 4/27/22.

import StoreKit

@available(iOS 11.2, macOS 10.13.2, tvOS 11.2, watchOS 6.2, *)
extension SK1ProductDiscount {

    // See https://github.com/RevenueCat/purchases-ios/issues/1521
    // Despite `SKProductDiscount.priceLocale` being non-optional, StoreKit might return `nil` `NSLocale`s.
    // This works around that to make sure the SDK doesn't crash when bridging to `Locale`.
    var optionalLocale: Locale? {
        guard let locale = self.priceLocale as NSLocale? else {
            Logger.appleWarning(Strings.storeKit.sk1_discount_missing_locale)
            return nil
        }

        return locale as Locale
    }

}

extension SKPaymentTransaction {

    /// Considering issue https://github.com/RevenueCat/purchases-ios/issues/279, sometimes `payment`
    /// and `productIdentifier` can be `nil`, in this case, they must be treated as nullable.
    /// Due to that an optional reference is created so that the compiler would allow us to check for nullability.
    var paymentIfPresent: SKPayment? {
        guard let payment = self.payment as SKPayment? else {
            Logger.appleWarning(Strings.purchase.skpayment_missing_from_skpaymenttransaction)
            return nil
        }

        return payment
    }

}
