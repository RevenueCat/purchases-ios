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

    #if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS
    @available(iOS 13.4, macCatalyst 13.4, *)
    var storeKit1WrapperShouldShowPriceConsent: Bool { get }
    #endif

    func storeKit1WrapperDidChangeStorefront(_ storeKit1Wrapper: StoreKit1Wrapper)

}

class StoreKit1Wrapper: NSObject {

    @available(iOS 8.0, macOS 10.14, watchOS 6.2, macCatalyst 13.0, *)
    static var simulatesAskToBuyInSandbox = false

    var currentStorefront: Storefront? {
        return self.paymentQueue.storefront
            .map(SK1Storefront.init)
            .map(Storefront.from(storefront:))
    }

    /// - Note: this is not thread-safe
    weak var delegate: StoreKit1WrapperDelegate? {
        didSet {
            if self.delegate != nil {
                self.notifyDelegateOfExistingTransactionsIfNeeded()

                self.paymentQueue.add(self)
            } else {
                self.paymentQueue.remove(self)
            }
        }
    }

    private let finishedTransactionCallbacks: Atomic<[SKPaymentTransaction: [() -> Void]]> = .init([:])

    private let paymentQueue: SKPaymentQueue
    private let operationDispatcher: OperationDispatcher
    private let observerMode: Bool
    private let sandboxEnvironmentDetector: SandboxEnvironmentDetector
    private let diagnosticsTracker: DiagnosticsTrackerType?

    init(paymentQueue: SKPaymentQueue = .default(),
         operationDispatcher: OperationDispatcher = .default,
         observerMode: Bool,
         sandboxEnvironmentDetector: SandboxEnvironmentDetector = BundleSandboxEnvironmentDetector.default,
         diagnosticsTracker: DiagnosticsTrackerType?) {
        self.paymentQueue = paymentQueue
        self.operationDispatcher = operationDispatcher
        self.observerMode = observerMode
        self.sandboxEnvironmentDetector = sandboxEnvironmentDetector
        self.diagnosticsTracker = diagnosticsTracker

        super.init()

        Logger.verbose(Strings.purchase.storekit1_wrapper_init(self))
    }

    deinit {
        Logger.verbose(Strings.purchase.storekit1_wrapper_deinit(self))

        self.paymentQueue.remove(self)
    }

    func add(_ payment: SKPayment) {
        Logger.debug(Strings.purchase.paymentqueue_adding_payment(self.paymentQueue, payment))

        self.paymentQueue.add(payment)
    }

    static func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }

    func payment(with product: SK1Product) -> SKMutablePayment {
        let payment = SKMutablePayment(product: product)
        payment.simulatesAskToBuyInSandbox = Self.simulatesAskToBuyInSandbox

        return payment
    }

    func payment(with product: SK1Product, discount: SKPaymentDiscount?) -> SKMutablePayment {
        let payment = self.payment(with: product)
        payment.paymentDiscount = discount
        return payment
    }

    private func notifyDelegateOfExistingTransactionsIfNeeded() {
        // Here be dragons. Explanation:
        // When initializing the SDK after an app opens, `SKPaymentQueue` notifies its
        // transaction observers of _existing_ transactions, so this method is normally not required.
        //
        // However: `BaseOfflineStoreKitIntegrationTests` simulates restarting apps.
        // When it re-creates `Purchases` to do that, `StoreKit 1` doesn't know to re-notify
        // its observers. This does so manually.
        // This isn't required in StoreKit 2 because resubscribing to
        // `StoreKit.Transaction.updates` does forward existing transactions.

        #if DEBUG
        guard ProcessInfo.isRunningIntegrationTests, let delegate = self.delegate else { return }

        let transactions = self.paymentQueue.transactions
        guard !transactions.isEmpty else { return }

        Logger.appleWarning(
            Strings.storeKit.sk1_wrapper_notifying_delegate_of_existing_transactions(count: transactions.count)
        )

        for transaction in transactions {
            delegate.storeKit1Wrapper(self, updatedTransaction: transaction)
        }
        #endif
    }

}

extension StoreKit1Wrapper: PaymentQueueWrapperType {

    @objc
    func finishTransaction(_ transaction: SKPaymentTransaction, completion: @escaping () -> Void) {
        let existingCompletion: Bool = self.finishedTransactionCallbacks.modify { callbacks in
            let existingCompletion = callbacks[transaction] != nil

            callbacks[transaction, default: []].append(completion)

            return existingCompletion
        }

        if existingCompletion {
            Logger.debug(Strings.storeKit.sk1_finish_transaction_called_with_existing_completion(transaction))
        } else {
            self.paymentQueue.finishTransaction(transaction)
        }
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

extension StoreKit1Wrapper: SKPaymentTransactionObserver {

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        guard let delegate = self.delegate else { return }

        if transactions.count >= Self.highTransactionCountThreshold {
            Logger.appleWarning(Strings.storeKit.sk1_payment_queue_too_many_transactions(
                count: transactions.count,
                isSandbox: self.sandboxEnvironmentDetector.isSandbox
            ))
        }

        self.trackTransactionQueueReceivedIfNeeded(transactions)

        self.operationDispatcher.dispatchOnWorkerThread {
            for transaction in transactions {
                Logger.debug(Strings.purchase.paymentqueue_updated_transaction(self, transaction))
                delegate.storeKit1Wrapper(self, updatedTransaction: transaction)
            }
        }
    }

    // Sent when transactions are removed from the queue (via finishTransaction:).
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        guard let delegate = self.delegate else { return }

        self.operationDispatcher.dispatchOnWorkerThread {
            for transaction in transactions {
                Logger.debug(Strings.purchase.paymentqueue_removed_transaction(self, transaction))
                delegate.storeKit1Wrapper(self, removedTransaction: transaction)

                if let callbacks = self.finishedTransactionCallbacks.value.removeValue(forKey: transaction),
                    !callbacks.isEmpty {
                    callbacks.forEach { $0() }
                } else {
                    Logger.debug(Strings.purchase.paymentqueue_removed_transaction_no_callbacks_found(
                        self,
                        transaction,
                        observerMode: self.observerMode
                    ))
                }
            }
        }
    }

    #if !os(watchOS)
    // Sent when a user initiated an in-app purchase from the App Store.
    func paymentQueue(_ queue: SKPaymentQueue,
                      shouldAddStorePayment payment: SKPayment,
                      for product: SK1Product) -> Bool {
        return self.delegate?.storeKit1Wrapper(self, shouldAddStorePayment: payment, for: product) ?? false
    }
    #endif

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

    // Sent when the storefront for the payment queue has changed.
    func paymentQueueDidChangeStorefront(_ queue: SKPaymentQueue) {
        self.delegate?.storeKit1WrapperDidChangeStorefront(self)
    }

    /// Receiving this many or more will produce a warning.
    private static let highTransactionCountThreshold: Int = 100

    private func trackTransactionQueueReceivedIfNeeded(_ transactions: [SKPaymentTransaction]) {
        guard #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *),
              let diagnosticsTracker = self.diagnosticsTracker else { return }

        transactions.forEach { transaction in
            diagnosticsTracker.trackAppleTransactionQueueReceived(
                productId: transaction.payment.productIdentifier,
                paymentDiscountId: transaction.payment.paymentDiscount?.identifier,
                transactionState: transaction.transactionState.diagnosticsName,
                errorMessage: transaction.error?.localizedDescription
            )
        }
    }

}

extension StoreKit1Wrapper: SKPaymentQueueDelegate {

    #if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS
    @available(iOS 13.4, macCatalyst 13.4, *)
    func paymentQueueShouldShowPriceConsent(_ paymentQueue: SKPaymentQueue) -> Bool {
        return self.delegate?.storeKit1WrapperShouldShowPriceConsent ?? true
    }
    #endif

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension StoreKit1Wrapper: @unchecked Sendable {}

fileprivate extension SKPaymentTransactionState {

    var diagnosticsName: String {
        switch self {
        case .purchasing:
            return "PURCHASING"
        case .purchased:
            return "PURCHASED"
        case .failed:
            return "FAILED"
        case .restored:
            return "RESTORED"
        case .deferred:
            return "DEFERRED"
        @unknown default:
            return "UNKNOWN (RAW VALUE: \(self.rawValue))"
        }
    }
}
