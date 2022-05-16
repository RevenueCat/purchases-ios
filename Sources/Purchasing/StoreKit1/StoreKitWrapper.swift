//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RCStoreKitWrapper.swift
//
//  Created by RevenueCat.
//

import StoreKit

protocol StoreKitWrapperDelegate: AnyObject {

    func storeKitWrapper(_ storeKitWrapper: StoreKitWrapper, updatedTransaction transaction: SKPaymentTransaction)

    func storeKitWrapper(_ storeKitWrapper: StoreKitWrapper, removedTransaction transaction: SKPaymentTransaction)

    func storeKitWrapper(_ storeKitWrapper: StoreKitWrapper,
                         shouldAddStorePayment payment: SKPayment,
                         for product: SK1Product) -> Bool

    func storeKitWrapper(_ storeKitWrapper: StoreKitWrapper,
                         didRevokeEntitlementsForProductIdentifiers productIdentifiers: [String])

    #if os(iOS) || targetEnvironment(macCatalyst)
    @available(iOS 13.4, macCatalyst 13.4, *)
    var storeKitWrapperShouldShowPriceConsent: Bool { get }
    #endif

    func storeKitWrapperDidChangeStorefront(_ storeKitWrapper: StoreKitWrapper)

}

class StoreKitWrapper: NSObject, SKPaymentTransactionObserver {

    @available(iOS 8.0, macOS 10.14, watchOS 6.2, macCatalyst 13.0, *)
    static var simulatesAskToBuyInSandbox = false

    var currentStorefront: StorefrontType? {
        guard #available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *) else {
            return nil
        }

        return self.paymentQueue.storefront.map(SK1Storefront.init)
    }

    weak var delegate: StoreKitWrapperDelegate? {
        didSet {
            if delegate != nil {
                paymentQueue.add(self)
            } else {
                paymentQueue.remove(self)
            }
        }
    }

    private var paymentQueue: SKPaymentQueue

    init(paymentQueue: SKPaymentQueue) {
        self.paymentQueue = paymentQueue
    }

    override convenience init() {
        self.init(paymentQueue: .default())
    }

    deinit {
        paymentQueue.remove(self)
    }

    func add(_ payment: SKPayment) {
        paymentQueue.add(payment)
    }

    func finishTransaction(_ transaction: SKPaymentTransaction) {
        Logger.purchase(Strings.purchase.finishing_transaction(transaction: transaction))
        paymentQueue.finishTransaction(transaction)
    }

    static func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }

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
        if paymentQueue.responds(to: #selector(SKPaymentQueue.presentCodeRedemptionSheet)) {
            Logger.debug(Strings.purchase.presenting_code_redemption_sheet)
            paymentQueue.presentCodeRedemptionSheet()
        } else {
            Logger.appleError(Strings.purchase.unable_to_present_redemption_sheet)
        }
    }

    func payment(withProduct product: SK1Product) -> SKMutablePayment {
        let payment = SKMutablePayment(product: product)

        if #available(iOS 8.0, macOS 10.14, watchOS 6.2, macCatalyst 13.0, *) {
            payment.simulatesAskToBuyInSandbox = Self.simulatesAskToBuyInSandbox
        }
        return payment
    }

    @available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
    func payment(withProduct product: SK1Product, discount: SKPaymentDiscount) -> SKMutablePayment {
        let payment = self.payment(withProduct: product)
        payment.paymentDiscount = discount
        return payment
    }

#if os(iOS) || targetEnvironment(macCatalyst)
    @available(iOS 13.4, macCatalyst 13.4, *)
    func showPriceConsentIfNeeded() {
        paymentQueue.showPriceConsentIfNeeded()
    }
#endif

}

extension StoreKitWrapper: SKPaymentQueueDelegate {

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            Logger.debug(Strings.purchase.paymentqueue_updatedtransaction(transaction: transaction))
            delegate?.storeKitWrapper(self, updatedTransaction: transaction)
        }
    }

    // Sent when transactions are removed from the queue (via finishTransaction:).
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            Logger.debug(Strings.purchase.paymentqueue_removedtransaction(transaction: transaction))
            delegate?.storeKitWrapper(self, removedTransaction: transaction)
        }
    }

    // Sent when a user initiated an in-app purchase from the App Store.
    @available(watchOS, unavailable)
    func paymentQueue(_ queue: SKPaymentQueue,
                      shouldAddStorePayment payment: SKPayment,
                      for product: SK1Product) -> Bool {
        return delegate?.storeKitWrapper(self, shouldAddStorePayment: payment, for: product) ?? false
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
        delegate?.storeKitWrapper(self, didRevokeEntitlementsForProductIdentifiers: productIdentifiers)
    }

    #if os(iOS) || targetEnvironment(macCatalyst)
    @available(iOS 13.4, macCatalyst 13.4, *)
    func paymentQueueShouldShowPriceConsent(_ paymentQueue: SKPaymentQueue) -> Bool {
        return delegate?.storeKitWrapperShouldShowPriceConsent ?? true
    }
    #endif

    // Sent when the storefront for the payment queue has changed.
    func paymentQueueDidChangeStorefront(_ queue: SKPaymentQueue) {
        delegate?.storeKitWrapperDidChangeStorefront(self)
    }

}
