//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SK1StoreTransaction.swift
//
//  Created by Nacho Soto on 1/4/22.

import StoreKit

internal struct SK1StoreTransaction: StoreTransactionType {

    init(sk1Transaction: SK1Transaction) {
        self.underlyingSK1Transaction = sk1Transaction

        self.productIdentifier = sk1Transaction.productIdentifier ?? ""
        (self.purchaseDate, self.hasKnownPurchaseDate) = sk1Transaction.purchaseDate
        (self.transactionIdentifier, self.hasKnownTransactionIdentifier) = sk1Transaction.transactionID
        self.quantity = sk1Transaction.quantity
    }

    let underlyingSK1Transaction: SK1Transaction

    let productIdentifier: String
    let purchaseDate: Date
    let transactionIdentifier: String
    let quantity: Int
    let hasKnownPurchaseDate: Bool
    let hasKnownTransactionIdentifier: Bool

    var storefront: Storefront? {
        // This is only available on StoreKit 2 transactions.
        return nil
    }

    internal var jwsRepresentation: String? {
        // This is only available on StoreKit 2 transactions.
        return nil
    }

    internal var environment: StoreEnvironment? {
        // This is only available on StoreKit 2 transactions.
        return nil
    }

    var reason: TransactionReason? {
        // StoreKit 1 does not expose a transaction reason.
        return nil
    }

    var revocationDate: Date? {
        // StoreKit 1 does not expose revocation metadata.
        return nil
    }

    var revocationReason: RevocationReason? {
        // StoreKit 1 does not expose revocation metadata.
        return nil
    }

    func finish(_ wrapper: PaymentQueueWrapperType, completion: @escaping @Sendable () -> Void) {
        wrapper.finishTransaction(self.underlyingSK1Transaction, completion: completion)
    }

}

extension SKPaymentTransaction {

    var productIdentifier: String? {
        guard let payment = self.paymentIfPresent else { return nil }

        guard let productIdentifier = payment.productIdentifier as String?,
              !productIdentifier.isEmpty else {
                  Logger.verbose(Strings.purchase.skpayment_missing_product_identifier)
                  return nil
              }

        return productIdentifier
    }

    fileprivate var purchaseDate: (value: Date, isKnown: Bool) {
        guard let date = self.transactionDate else {
            Logger.verbose(Strings.purchase.sktransaction_missing_transaction_date(self.transactionState))

            return (Date(timeIntervalSince1970: 0), false)
        }

        return (date, true)
    }

    fileprivate var transactionID: (value: String, isKnown: Bool) {
        guard let identifier = self.transactionIdentifier else {
            Logger.verbose(Strings.purchase.sktransaction_missing_transaction_identifier)

            return (UUID().uuidString, false)
        }

        return (identifier, true)
    }

    fileprivate var quantity: Int {
        // Note: multi-quantity purchases aren't supported.
        // Defaulting to `1` if `self.payment` is `nil` (which shouldn't happen) as a reasonable default.
        return self.paymentIfPresent?.quantity ?? 1
    }

}
