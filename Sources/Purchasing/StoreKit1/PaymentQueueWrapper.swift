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

protocol PaymentQueueWrapperDelegate: AnyObject, Sendable {

    func paymentQueueWrapper(_ wrapper: PaymentQueueWrapper,
                             shouldAddStorePayment payment: SKPayment,
                             for product: SK1Product) -> Bool
}

class PaymentQueueWrapper: NSObject {

    private let paymentQueue: SKPaymentQueue

    weak var delegate: PaymentQueueWrapperDelegate? {
        didSet {
            if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
                if self.delegate != nil {
                    self.paymentQueue.delegate = self
                } else if self.delegate == nil, self.paymentQueue.delegate === self {
                    self.paymentQueue.delegate = nil
                }
            }
        }
    }

    init(paymentQueue: SKPaymentQueue = .default()) {
        self.paymentQueue = paymentQueue

        super.init()
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

extension PaymentQueueWrapper: SKPaymentQueueDelegate {

    // Sent when a user initiated an in-app purchase from the App Store.
    @available(watchOS, unavailable)
    func paymentQueue(_ queue: SKPaymentQueue,
                      shouldAddStorePayment payment: SKPayment,
                      for product: SK1Product) -> Bool {
        return self.delegate?.paymentQueueWrapper(self,
                                                  shouldAddStorePayment: payment,
                                                  for: product) ?? false
    }

}

// `@unchecked` because:
// `weak var` requires it: https://twitter.com/dgregor79/status/1557166717721161728
// `SKPaymentQueue` is not `Sendable` until Swift 5.7
// - Not-final since it's mocked in tests.
extension PaymentQueueWrapper: @unchecked Sendable {}
