//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RCStoreKit1Wrapper.swift
//
//  Created by RevenueCat.
//

import StoreKit

protocol StoreKit1WrapperDelegate: AnyObject {

    func storeKit1Wrapper(_ storeKit1Wrapper: StoreKit1Wrapper, updatedTransaction transaction: SKPaymentTransaction)

    func storeKit1Wrapper(_ storeKit1Wrapper: StoreKit1Wrapper, removedTransaction transaction: SKPaymentTransaction)

    func storeKit1Wrapper(_ storeKit1Wrapper: StoreKit1Wrapper,
                          shouldAddStorePayment payment: SKPayment,
                          for product: SK1Product) -> Bool

    func storeKit1Wrapper(_ storeKit1Wrapper: StoreKit1Wrapper,
                          didRevokeEntitlementsForProductIdentifiers productIdentifiers: [String])

    #if os(iOS) || targetEnvironment(macCatalyst)
    @available(iOS 13.4, macCatalyst 13.4, *)
    var storeKit1WrapperShouldShowPriceConsent: Bool { get }
    #endif

    func storeKit1WrapperDidChangeStorefront(_ storeKit1Wrapper: StoreKit1Wrapper)

}

class StoreKit1Wrapper: NSObject, SKPaymentTransactionObserver {

    @available(iOS 8.0, macOS 10.14, watchOS 6.2, macCatalyst 13.0, *)
    static var simulatesAskToBuyInSandbox = false

    var currentStorefront: StorefrontType? {
        guard #available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *) else {
            return nil
        }

        return self.paymentQueue.storefront.map(SK1Storefront.init)
    }

    /// - Note: this is not thread-safe
    weak var delegate: StoreKit1WrapperDelegate? {
        didSet {
            if self.delegate != nil {
                self.paymentQueue.add(self)
            } else {
                self.paymentQueue.remove(self)
            }
        }
    }

    private let paymentQueue: SKPaymentQueue

    init(paymentQueue: SKPaymentQueue) {
        self.paymentQueue = paymentQueue
    }

    override convenience init() {
        self.init(paymentQueue: .default())
    }

    deinit {
        self.paymentQueue.remove(self)
    }

    func add(_ payment: SKPayment) {
        self.paymentQueue.add(payment)
    }

    func finishTransaction(_ transaction: SKPaymentTransaction) {
        Logger.purchase(Strings.purchase.finishing_transaction(transaction: transaction))
        self.paymentQueue.finishTransaction(transaction)
    }

    static func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }

    func payment(with product: SK1Product) -> SKMutablePayment {
        let payment = SKMutablePayment(product: product)

        if #available(iOS 8.0, macOS 10.14, watchOS 6.2, macCatalyst 13.0, *) {
            payment.simulatesAskToBuyInSandbox = Self.simulatesAskToBuyInSandbox
        }
        return payment
    }

    @available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
    func payment(with product: SK1Product, discount: SKPaymentDiscount?) -> SKMutablePayment {
        let payment = self.payment(with: product)
        payment.paymentDiscount = discount
        return payment
    }

}

extension StoreKit1Wrapper: SKPaymentQueueDelegate {

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            Logger.debug(Strings.purchase.paymentqueue_updatedtransaction(transaction: transaction))
            self.delegate?.storeKit1Wrapper(self, updatedTransaction: transaction)
        }
    }

    // Sent when transactions are removed from the queue (via finishTransaction:).
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            Logger.debug(Strings.purchase.paymentqueue_removedtransaction(transaction: transaction))
            self.delegate?.storeKit1Wrapper(self, removedTransaction: transaction)
        }
    }

    // Sent when a user initiated an in-app purchase from the App Store.
    @available(watchOS, unavailable)
    func paymentQueue(_ queue: SKPaymentQueue,
                      shouldAddStorePayment payment: SKPayment,
                      for product: SK1Product) -> Bool {
        return self.delegate?.storeKit1Wrapper(self, shouldAddStorePayment: payment, for: product) ?? false
    }

    // Sent when access to a family shared subscription is revoked from a family member or canceled the subscription.
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    func paymentQueue(_ queue: SKPaymentQueue,
                      didRevokeEntitlementsForProductIdentifiers productIdentifiers: [String]) {
        Logger.debug(
            Strings.purchase.paymentqueue_revoked_entitlements_for_product_identifiers(
                productIdentifiers: productIdentifiers
            )
        )
        self.delegate?.storeKit1Wrapper(self, didRevokeEntitlementsForProductIdentifiers: productIdentifiers)
    }

    #if os(iOS) || targetEnvironment(macCatalyst)
    @available(iOS 13.4, macCatalyst 13.4, *)
    func paymentQueueShouldShowPriceConsent(_ paymentQueue: SKPaymentQueue) -> Bool {
        return self.delegate?.storeKit1WrapperShouldShowPriceConsent ?? true
    }
    #endif

    // Sent when the storefront for the payment queue has changed.
    func paymentQueueDidChangeStorefront(_ queue: SKPaymentQueue) {
        self.delegate?.storeKit1WrapperDidChangeStorefront(self)
    }

}

extension StoreKit1Wrapper {

    /// Creates a `PaymentQueueWrapper` backed by the same `SKPaymentQueue`.
    func createPaymentQueueWrapper() -> PaymentQueueWrapper {
        return .init(paymentQueue: self.paymentQueue)
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension StoreKit1Wrapper: @unchecked Sendable {}
