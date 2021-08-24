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
                         for product: SKProduct) -> Bool

    func storeKitWrapper(_ storeKitWrapper: StoreKitWrapper,
                         didRevokeEntitlementsForProductIdentifiers productIdentifiers: [String])

}

class StoreKitWrapper: NSObject, SKPaymentTransactionObserver {

    @available(macOS 10.14, macCatalyst 13.0, *)
    static var simulatesAskToBuyInSandbox = false

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
        Logger.purchase(String(format: Strings.purchase.finishing_transaction,
                               transaction.payment.productIdentifier,
                               transaction.transactionIdentifier ?? "",
                               transaction.original?.transactionIdentifier ?? ""))

        paymentQueue.finishTransaction(transaction)
    }

    @available(iOS 14.0, *)
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    func presentCodeRedemptionSheet() {
        Logger.debug(Strings.purchase.presenting_code_redemption_sheet)
        paymentQueue.presentCodeRedemptionSheet()
    }

    func payment(withProduct product: SKProduct) -> SKMutablePayment {
        let payment = SKMutablePayment(product: product)
        // todo: check that it's fine to omit tvOS and iOS since the relevant methods exist in targets lower than ours
        if #available(macOS 10.14, watchOS 6.2, macCatalyst 13.0, *) {
            payment.simulatesAskToBuyInSandbox = Self.simulatesAskToBuyInSandbox
        }
        return payment
    }

    @available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
    func payment(withProduct product: SKProduct, discount: SKPaymentDiscount) -> SKMutablePayment {
        let payment = self.payment(withProduct: product)
        payment.paymentDiscount = discount
        return payment
    }

}

extension StoreKitWrapper: SKPaymentQueueDelegate {

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            Logger.debug(String(format: Strings.purchase.paymentqueue_updatedtransaction,
                                transaction.payment.productIdentifier,
                                transaction.transactionIdentifier ?? "",
                                transaction.error?.localizedDescription ?? "",
                                transaction.original?.transactionIdentifier ?? "",
                                transaction.transactionState.rawValue))
            delegate?.storeKitWrapper(self, updatedTransaction: transaction)
        }
    }

    // Sent when transactions are removed from the queue (via finishTransaction:).
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            Logger.debug(String(format: Strings.purchase.paymentqueue_removedtransaction,
                                transaction.payment.productIdentifier,
                                transaction.transactionIdentifier ?? "",
                                transaction.original?.transactionIdentifier ?? "",
                                transaction.error?.localizedDescription ?? "",
                                (transaction.error as NSError?)?.userInfo ?? "",
                                transaction.transactionState.rawValue))
            delegate?.storeKitWrapper(self, removedTransaction: transaction)
        }
    }

    // Sent when a user initiated an in-app purchase from the App Store.
    @available(iOS 11.0, macOS 11.0, macCatalyst 14.0, tvOS 11.0, *)
    @available(watchOS, unavailable)
    func paymentQueue(_ queue: SKPaymentQueue,
                      shouldAddStorePayment payment: SKPayment,
                      for product: SKProduct) -> Bool {
        return delegate?.storeKitWrapper(self, shouldAddStorePayment: payment, for: product) ?? false
    }

    // Sent when access to a family shared subscription is revoked from a family member or canceled the subscription.
    @available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
    func paymentQueue(_ queue: SKPaymentQueue,
                      didRevokeEntitlementsForProductIdentifiers productIdentifiers: [String]) {
        Logger.debug(String(format: Strings.purchase.paymentqueue_revoked_entitlements_for_product_identifiers,
                            productIdentifiers))
        delegate?.storeKitWrapper(self, didRevokeEntitlementsForProductIdentifiers: productIdentifiers)
    }

}
