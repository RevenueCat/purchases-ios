//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreTransaction.swift
//
//  Created by Andrés Boedo on 2/12/21.

import Foundation
import StoreKit

// todo: API tester!

/// TypeAlias to StoreKit 1's Transaction type, called `StoreKit.SKPaymentTransaction`
public typealias SK1Transaction = SKPaymentTransaction

/// TypeAlias to StoreKit 2's Transaction type, called `StoreKit.Transaction`
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
public typealias SK2Transaction = StoreKit.Transaction

/// Abstract class that provides access to all of StoreKit's product type's properties.
@objc(RCStoreTransaction) public final class StoreTransaction: NSObject, StoreTransactionType {

    private let transaction: StoreTransactionType

    init(_ transaction: StoreTransactionType) {
        self.transaction = transaction

        super.init()
    }

    @objc public var productIdentifier: String { self.transaction.productIdentifier }
    @objc public var purchaseDate: Date { self.transaction.purchaseDate }
    @objc public var transactionIdentifier: String { self.transaction.transactionIdentifier }

    /// Creates an instance from any `StoreTransactionType`.
    /// If `transaction` is already a wrapped `StoreTransaction` then this returns it instead.
    static func from(transaction: StoreTransactionType) -> StoreTransaction {
        return transaction as? StoreTransaction
            ?? StoreTransaction(transaction)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        self.transactionIdentifier == (object as? StoreTransactionType)?.transactionIdentifier
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(self.transactionIdentifier)

        return hasher.finalize()

    }

}

/// Information that represents the customer’s purchase of a product.
internal protocol StoreTransactionType {
    /// The product identifier.
    var productIdentifier: String { get }

    /// The date that App Store charged the user’s account for a purchased or restored product,
    /// or for a subscription purchase or renewal after a lapse.
    var purchaseDate: Date { get }

    /// The unique identifier for the transaction.
    var transactionIdentifier: String { get }
}

// MARK: - Wrapper constructors

extension StoreTransaction {
    internal convenience init(sk1Transaction: SK1Transaction) {
        self.init(SK1StoreTransaction(sk1Transaction: sk1Transaction))
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    internal convenience init(sk2Transaction: SK2Transaction) {
        self.init(SK2StoreTransaction(sk2Transaction: sk2Transaction))
    }
}
