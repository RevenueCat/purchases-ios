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

    #if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS
    @available(iOS 13.4, macCatalyst 13.4, *)
    var paymentQueueWrapperShouldShowPriceConsent: Bool { get }
    #endif

}

/// A wrapper for `SKPaymentQueue`
@objc
protocol PaymentQueueWrapperType: AnyObject {

    func finishTransaction(_ transaction: SKPaymentTransaction, completion: @escaping () -> Void)

    #if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS
    @available(iOS 13.4, macCatalyst 13.4, *)
    func showPriceConsentIfNeeded()
    #endif

    @available(iOS 14.0, *)
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @available(macCatalyst, unavailable)
    func presentCodeRedemptionSheet()

}

/// The choice between SK1's `StoreKit1Wrapper` or `PaymentQueueWrapper` when SK2 is enabled.
typealias EitherPaymentQueueWrapper = Either<StoreKit1Wrapper, PaymentQueueWrapper>

// MARK: -

/// Implementation of `PaymentQueueWrapperType` used when SK1 is not enabled.
class PaymentQueueWrapper: NSObject, PaymentQueueWrapperType {

    private let paymentQueue: SKPaymentQueue

    private lazy var purchaseIntentsAPIAvailable: Bool = {
        // PurchaseIntents was introduced in macOS with macOS 14.4, which was first shipped with Xcode 15.3,
        // which shipped with version 5.10 of the Swift compiler. We need to check for the Swift compiler version
        // because the PurchaseIntents symbol isn't available on Xcode versions <15.3.
        #if compiler(>=5.10)
        if #available(iOS 16.4, macOS 14.4, *) {
            return true
        } else {
            return false
        }
        #else
        return false
        #endif
    }()

    weak var delegate: PaymentQueueWrapperDelegate? {
        didSet {
            if self.delegate != nil {
                self.paymentQueue.delegate = self

                if !purchaseIntentsAPIAvailable {
                    // The PurchaseIntent documentation states that we shouldn't use both the PurchaseIntents API and
                    // `SKPaymentTransactionObserver/paymentQueue(queue:shouldAddStorePayment:for:) -> Bool` at the same
                    // time. So, we only observe the payment queue when using StoreKit 2 if the PurchaseIntents API
                    // is unavailable. See https://developer.apple.com/documentation/storekit/purchaseintent
                    // for more info.
                    //
                    // We don't need to check that SK2 is available and used since PaymentQueueWrapper itself
                    // is only used in SK2 mode. When running in SK1 mode, the StoreKit1Wrapper is used instead.
                    self.paymentQueue.add(self)
                }
            } else if self.delegate == nil, self.paymentQueue.delegate === self {
                self.paymentQueue.delegate = nil

                if !purchaseIntentsAPIAvailable {
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

    #if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS
    @available(iOS 13.4, macCatalyst 13.4, *)
    func showPriceConsentIfNeeded() {
        self.paymentQueue.showPriceConsentIfNeeded()
    }
    #endif

    #if (os(iOS) && !targetEnvironment(macCatalyst)) || VISION_OS
    @available(iOS 14.0, *)
    func presentCodeRedemptionSheet() {
        self.paymentQueue.presentCodeRedemptionSheetIfAvailable()
    }
    #endif

}

extension PaymentQueueWrapper: SKPaymentQueueDelegate {

    #if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS
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

    var sk1Wrapper: StoreKit1Wrapper? { return self.left }
    var sk2Wrapper: PaymentQueueWrapper? { return self.right }

}
