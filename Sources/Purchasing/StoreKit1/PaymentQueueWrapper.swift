//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaymentQueueWrapper.swift
//
//  Created by Nacho Soto on 9/4/22.

import Foundation
import StoreKit

final class PaymentQueueWrapper {

    private let paymentQueue: SKPaymentQueue

    init(paymentQueue: SKPaymentQueue = .default()) {
        self.paymentQueue = paymentQueue
    }

    #if os(iOS) || targetEnvironment(macCatalyst)
    @available(iOS 13.4, macCatalyst 13.4, *)
    func showPriceConsentIfNeeded() {
        self.paymentQueue.showPriceConsentIfNeeded()
    }
    #endif

    @available(iOS 14.0, *)
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @available(macCatalyst, unavailable)
    func presentCodeRedemptionSheet() {
        // Even though the docs in `SKPaymentQueue.presentCodeRedemptionSheet`
        // say that it's available on Catalyst 14.0, there is a note:
        // This function doesn’t affect Mac apps built with Mac Catalyst.
        // It crashes when called both from Catalyst and also when running as "Designed for iPad".
        if self.paymentQueue.responds(to: #selector(SKPaymentQueue.presentCodeRedemptionSheet)) {
            Logger.debug(Strings.purchase.presenting_code_redemption_sheet)
            self.paymentQueue.presentCodeRedemptionSheet()
        } else {
            Logger.appleError(Strings.purchase.unable_to_present_redemption_sheet)
        }
    }
}

#if swift(>=5.7)
extension PaymentQueueWrapper: Sendable {}
#else
// `SKPaymentQueue` is not `Sendable` until Swift 5.7
extension PaymentQueueWrapper: @unchecked Sendable {}
#endif
