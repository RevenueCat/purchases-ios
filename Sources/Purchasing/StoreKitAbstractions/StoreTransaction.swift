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

/// TypeAlias to StoreKit 1's Transaction type, called `StoreKit.SKPaymentTransaction`
public typealias SK1Transaction = SKPaymentTransaction

/// TypeAlias to StoreKit 2's Transaction type, called `StoreKit.Transaction`
@available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
public typealias SK2Transaction = StoreKit.Transaction

/// Abstract class that provides access to properties of a transaction.
/// ``StoreTransaction``s can represent transactions from StoreKit 1, StoreKit 2 or
/// transactions made from other places, like Stripe, Google Play or Amazon Store.
@objc(RCStoreTransaction) public final class StoreTransaction: NSObject, StoreTransactionType {

    private let transaction: StoreTransactionType

    init(_ transaction: StoreTransactionType) {
        self.transaction = transaction

        super.init()
    }

    // Note: docs are inherited through `StoreTransactionType`
    // swiftlint:disable missing_docs

    @objc public var productIdentifier: String { self.transaction.productIdentifier }
    @objc public var purchaseDate: Date { self.transaction.purchaseDate }
    @objc public var transactionIdentifier: String { self.transaction.transactionIdentifier }
    @objc public var quantity: Int { self.transaction.quantity }
    @objc public var storefront: Storefront? { self.transaction.storefront }
    @objc internal var jwsRepresentation: String? { self.transaction.jwsRepresentation }
    internal var environment: StoreEnvironment? { self.transaction.environment }

    var hasKnownPurchaseDate: Bool { return self.transaction.hasKnownPurchaseDate }
    var hasKnownTransactionIdentifier: Bool { self.transaction.hasKnownTransactionIdentifier }

    func finish(_ wrapper: PaymentQueueWrapperType, completion: @escaping @Sendable () -> Void) {
        self.transaction.finish(wrapper, completion: completion)
    }

    // swiftlint:enable missing_docs

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

    public override var description: String {
        return """
            <\(String(describing: StoreTransaction.self)):
                identifier="\(self.transactionIdentifier)"
                product="\(self.productIdentifier)"
                date="\(self.purchaseDate)"
                quantity=\(self.quantity)
            >
            """
    }

}

/// Information that represents the customer’s purchase of a product.
internal protocol StoreTransactionType: Sendable {

    /// The product identifier.
    var productIdentifier: String { get }

    /// The date that App Store charged the user’s account for a purchased or restored product,
    /// or for a subscription purchase or renewal after a lapse.
    var purchaseDate: Date { get }

    /// Whether the underlying transaction has a non-nil purchase date.
    /// See `SK1StoreTransaction/purchaseDate``
    var hasKnownPurchaseDate: Bool { get }

    /// The unique identifier for the transaction.
    var transactionIdentifier: String { get }

    /// Whether the underlying transaction has a known transaction identifier.
    /// See `SKPaymentTransaction.transactionID`.
    var hasKnownTransactionIdentifier: Bool { get }

    /// The number of consumable products purchased.
    /// - Note: multi-quantity purchases aren't currently supported.
    var quantity: Int { get }

    /// The App Store storefront associated with the transaction.
    /// - Note: this is only available for StoreKit 2 transactions starting with iOS 17.
    var storefront: Storefront? { get }

    /// The raw JWS repesentation of the transaction.
    /// - Note: this is only available for StoreKit 2 transactions.
    var jwsRepresentation: String? { get }

    /// The server environment where the receipt was generated.
    /// - Note: this is only available for StoreKit 2 transactions.
    var environment: StoreEnvironment? { get }

    /// Indicates to the App Store that the app delivered the purchased content
    /// or enabled the service to finish the transaction.
    func finish(_ wrapper: PaymentQueueWrapperType, completion: @escaping @Sendable () -> Void)

}

// MARK: - Wrapper constructors / getters

extension StoreTransaction {

    internal convenience init(sk1Transaction: SK1Transaction) {
        self.init(SK1StoreTransaction(sk1Transaction: sk1Transaction))
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    internal convenience init(sk2Transaction: SK2Transaction,
                              jwsRepresentation: String,
                              environmentOverride: StoreEnvironment? = nil) {
        self.init(SK2StoreTransaction(sk2Transaction: sk2Transaction,
                                      jwsRepresentation: jwsRepresentation,
                                      environmentOverride: environmentOverride))
    }

    /// Returns the `SKPaymentTransaction` if this `StoreTransaction` represents a `SKPaymentTransaction`.
    @objc public var sk1Transaction: SK1Transaction? {
        return (self.transaction as? SK1StoreTransaction)?.underlyingSK1Transaction
    }

    /// Returns the `StoreKit.Transaction` if this `StoreTransaction` represents a `StoreKit.Transaction`.
    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    public var sk2Transaction: SK2Transaction? {
        return (self.transaction as? SK2StoreTransaction)?.underlyingSK2Transaction
    }

}

extension StoreTransactionType {

    /// - Returns: the `Storefront` associated to this transaction, or `Storefront.currentStorefront` if not available.
    var storefrontOrCurrent: Storefront? {
        get async {
            return await self.storefront ??? (await Storefront.currentStorefront)
        }
    }

}

extension StoreTransaction: Identifiable {

    /// The stable identity of the entity associated with this instance.
    public var id: String { return self.transactionIdentifier }

}
