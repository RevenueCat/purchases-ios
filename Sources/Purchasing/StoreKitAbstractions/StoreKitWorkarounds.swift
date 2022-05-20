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

extension SK1Product {

    /// Attempts to find a non-nil `productIdentifier`.
    ///
    /// Although both `SK1Product.productIdentifier` and `SKPayment.productIdentifier`
    /// are supposed to be non-nil, we've seen instances where this is not true.
    /// so we cast into optionals in order to check nullability, and try to fall back if possible.
    func extractProductIdentifier(withPayment payment: SKPayment,
                                  fileName: String = #fileID,
                                  functionName: String = #function,
                                  line: UInt = #line) -> String? {
        if let identifierFromProduct = self.productIdentifier as String?,
           !identifierFromProduct.trimmingWhitespacesAndNewLines.isEmpty {
            return identifierFromProduct
        }
        Logger.appleWarning(Strings.purchase.product_identifier_nil,
                            fileName: fileName, functionName: functionName, line: line)

        if let identifierFromPayment = payment.productIdentifier as String?,
           !identifierFromPayment.trimmingWhitespacesAndNewLines.isEmpty {
            return identifierFromPayment
        }
        Logger.appleWarning(Strings.purchase.payment_identifier_nil,
                            fileName: fileName, functionName: functionName, line: line)

        return nil
    }

}

extension SubscriptionPeriod {

    /// This function simplifies large numbers of days into months and large numbers
    /// of months into years if there are no leftover units after the conversion.
    ///
    /// Occassionally, StoreKit seems to send back a value 7 days for a 7day trial
    /// instesad of a value of 1 week for a trial of 7 days in length.
    /// Source: https://github.com/RevenueCat/react-native-purchases/issues/348
    internal static func normalizeValueAndUnits(
        value: Int,
        unit: Unit
    ) -> (value: Int, unit: Unit) {
        switch unit {
        case .day:
            if value % 7 == 0 {
                let numberOfWeeks = value / 7
                return (value: numberOfWeeks, unit: .week)
            }
        case .month:
            if value % 12 == 0 {
                let numberOfYears = value / 12
                return (value: numberOfYears, unit: .year)
            }
        case .week, .year:
            break
        }

        return (value: value, unit: unit)
    }
}
