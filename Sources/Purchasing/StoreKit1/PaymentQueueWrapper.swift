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

    #if os(iOS) || targetEnvironment(macCatalyst)
    @available(iOS 13.4, macCatalyst 13.4, *)
    var paymentQueueWrapperShouldShowPriceConsent: Bool { get }
    #endif

}

/// A wrapper for `SKPaymentQueue`
@objc
protocol PaymentQueueWrapperType: AnyObject {

    func finishTransaction(_ transaction: SKPaymentTransaction, completion: @escaping () -> Void)

    #if os(iOS) || targetEnvironment(macCatalyst)
    @available(iOS 13.4, macCatalyst 13.4, *)
    func showPriceConsentIfNeeded()
    #endif

    @available(iOS 14.0, *)
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @available(macCatalyst, unavailable)
    func presentCodeRedemptionSheet()

    var currentStorefront: Storefront? { get }

}

/// The choice between SK1's `StoreKit1Wrapper` or `PaymentQueueWrapper` when SK2 is enabled.
typealias EitherPaymentQueueWrapper = Either<StoreKit1Wrapper, PaymentQueueWrapper>

// MARK: -

/// Implementation of `PaymentQueueWrapperType` used when SK1 is not enabled.
class PaymentQueueWrapper: NSObject, PaymentQueueWrapperType {

    private let paymentQueue: SKPaymentQueue

    weak var delegate: PaymentQueueWrapperDelegate? {
        didSet {
            if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *) {
                if self.delegate != nil {
                    self.paymentQueue.delegate = self
                    self.paymentQueue.add(self)
                } else if self.delegate == nil, self.paymentQueue.delegate === self {
                    self.paymentQueue.delegate = nil
                    self.paymentQueue.remove(self)
                }
            }
        }
    }

    init(paymentQueue: SKPaymentQueue = .default()) {
        self.paymentQueue = paymentQueue

        super.init()
    }

    func finishTransaction(_ transaction: SKPaymentTransaction, completion: @escaping () -> Void) {
        // See `StoreKit1Wrapper.finishTransaction(:completion:)`.
        // Technically this is a race condition, because `SKPaymentQueue.finishTransaction` is asynchronous
        // In practice this method won't be used, because this class is only used in SK2 mode,
        // and those transactions are finished through `SK2StoreTransaction`.

        self.paymentQueue.finishTransaction(transaction)
        completion()
    }

    #if os(iOS) || targetEnvironment(macCatalyst)
    @available(iOS 13.4, macCatalyst 13.4, *)
    func showPriceConsentIfNeeded() {
        self.paymentQueue.showPriceConsentIfNeeded()
    }
    #endif

    #if os(iOS) && !targetEnvironment(macCatalyst)
    @available(iOS 14.0, *)
    func presentCodeRedemptionSheet() {
        self.paymentQueue.presentCodeRedemptionSheetIfAvailable()
    }
    #endif

    var currentStorefront: Storefront? {
        guard #available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *) else {
            return nil
        }

        return self.paymentQueue.storefront
            .map(SK1Storefront.init)
            .map(Storefront.from(storefront:))
    }

}

extension PaymentQueueWrapper: SKPaymentQueueDelegate {

    #if os(iOS) || targetEnvironment(macCatalyst)
    @available(iOS 13.4, macCatalyst 13.4, *)
    func paymentQueueShouldShowPriceConsent(_ paymentQueue: SKPaymentQueue) -> Bool {
        return self.delegate?.paymentQueueWrapperShouldShowPriceConsent ?? true
    }
    #endif

}

extension PaymentQueueWrapper: SKPaymentTransactionObserver {

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        // Ignored. Either `StoreKit1Wrapper` will handle this, or `StoreKit2TransactionListener` if `SK2` is enabled.
    }

    #if !os(watchOS)
    // Sent when a user initiated an in-app purchase from the App Store.
    func paymentQueue(_ queue: SKPaymentQueue,
                      shouldAddStorePayment payment: SKPayment,
                      for product: SK1Product) -> Bool {
        return self.delegate?.paymentQueueWrapper(self,
                                                  shouldAddStorePayment: payment,
                                                  for: product) ?? false
    }
    #endif

}

// `@unchecked` because:
// `weak var` requires it: https://twitter.com/dgregor79/status/1557166717721161728
// `SKPaymentQueue` is not `Sendable` until Swift 5.7
// - Not-final since it's mocked in tests.
extension PaymentQueueWrapper: @unchecked Sendable {}

extension EitherPaymentQueueWrapper {

    var paymentQueueWrapperType: PaymentQueueWrapperType {
        switch self {
        case let .left(storeKit1Wrapper): return storeKit1Wrapper
        case let .right(paymentQueueWrapper): return paymentQueueWrapper
        }
    }

    var currentStorefront: StorefrontType? { self.paymentQueueWrapperType.currentStorefront }

    var sk1Wrapper: StoreKit1Wrapper? { return self.left }
    var sk2Wrapper: PaymentQueueWrapper? { return self.right }

}
