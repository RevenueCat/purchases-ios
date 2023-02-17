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
            Logger.verbose(Strings.purchase.skpayment_missing_from_skpaymenttransaction)
            return nil
        }

        return payment
    }

}

extension SKPayment {

    /// Attempts to find a non-nil `productIdentifier`.
    ///
    /// Although `SKPayment.productIdentifier` is supposed to be non-nil, we've seen instances where this is not true.
    /// To handle this case, we cast `productIdentifier` to `Optional` in order to check nullability.
    func extractProductIdentifier(fileName: String = #fileID,
                                  functionName: String = #function,
                                  line: UInt = #line) -> String? {
        guard let result = self.productIdentifier as String?,
           !result.trimmingWhitespacesAndNewLines.isEmpty else {
            Logger.appleWarning(Strings.purchase.payment_identifier_nil,
                                fileName: fileName, functionName: functionName, line: line)
            return nil
        }

        return result
    }

}

extension SubscriptionPeriod {

    /// This function simplifies large numbers of days into months and large numbers
    /// of months into years if there are no leftover units after the conversion.
    ///
    /// Occasionally, StoreKit seems to send back a value 7 days for a 7day trial
    /// instead of a value of 1 week for a trial of 7 days in length.
    /// Source: https://github.com/RevenueCat/react-native-purchases/issues/348
    internal func normalized() -> SubscriptionPeriod {
        switch unit {
        case .day:
            if value.isMultiple(of: 7) {
                let numberOfWeeks = value / 7
                return .init(value: numberOfWeeks, unit: .week)
            }
        case .month:
            if value.isMultiple(of: 12) {
                let numberOfYears = value / 12
                return .init(value: numberOfYears, unit: .year)
            }
        case .week, .year:
            break
        }

        return self
    }
}

extension ReceiptFetcher {

    func watchOSReceiptURL(_ receiptURL: URL) -> URL? {
        // as of watchOS 6.2.8, there's a bug where the receipt is stored in the sandbox receipt location,
        // but the appStoreReceiptURL method returns the URL for the production receipt.
        // This code replaces "sandboxReceipt" with "receipt" as the last component of the receiptURL so that we get the
        // correct receipt.
        // This has been filed as radar FB7699277. More info in https://github.com/RevenueCat/purchases-ios/issues/207

        let firstOSVersionWithoutBug: OperatingSystemVersion = OperatingSystemVersion(majorVersion: 7,
                                                                                      minorVersion: 0,
                                                                                      patchVersion: 0)
        let isBelowFirstOSVersionWithoutBug = !self.systemInfo.isOperatingSystemAtLeast(firstOSVersionWithoutBug)

        if isBelowFirstOSVersionWithoutBug && self.systemInfo.isSandbox {
            let receiptURLFolder: URL = receiptURL.deletingLastPathComponent()
            let productionReceiptURL: URL = receiptURLFolder.appendingPathComponent("receipt")
            return productionReceiptURL
        } else {
            return receiptURL
        }
    }

}

extension SKPaymentQueue {

    @available(iOS 14.0, *)
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @available(macCatalyst, unavailable)
    func presentCodeRedemptionSheetIfAvailable() {
        // Even though the docs in `SKPaymentQueue.presentCodeRedemptionSheet`
        // say that it's available on Catalyst 14.0, there is a note:
        // This function doesn’t affect Mac apps built with Mac Catalyst.
        // It crashes when called both from Catalyst and also when running as "Designed for iPad".
        if self.responds(to: #selector(SKPaymentQueue.presentCodeRedemptionSheet)) {
            Logger.debug(Strings.purchase.presenting_code_redemption_sheet)
            self.presentCodeRedemptionSheet()
        } else {
            Logger.appleError(Strings.purchase.unable_to_present_redemption_sheet)
        }
    }

}
