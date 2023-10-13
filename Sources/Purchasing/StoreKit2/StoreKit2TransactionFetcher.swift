//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKit2TransactionFetcher.swift
//
//  Created by Nacho Soto on 5/24/23.

import Foundation
import StoreKit

protocol StoreKit2TransactionFetcherType: Sendable {

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var unfinishedVerifiedTransactions: [StoreTransaction] { get async }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var hasPendingConsumablePurchase: Bool { get async }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var firstVerifiedAutoRenewableTransaction: StoreTransaction? { get async }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var firstVerifiedTransaction: StoreTransaction? { get async }

}

final class StoreKit2TransactionFetcher: StoreKit2TransactionFetcherType {

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var unfinishedVerifiedTransactions: [StoreTransaction] {
        get async {
            return await StoreKit.Transaction
                .unfinished
                .compactMap { $0.verifiedStoreTransaction }
                .extractValues()
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var hasPendingConsumablePurchase: Bool {
        get async {
            return await StoreKit.Transaction
                .unfinished
                .compactMap { $0.verifiedTransaction }
                .map(\.productType)
                .map { StoreProduct.ProductType($0) }
                .contains {  $0.productCategory == .nonSubscription }
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var firstVerifiedAutoRenewableTransaction: StoreTransaction? {
        get async {
            await StoreKit.Transaction.all
                .compactMap { $0.verifiedStoreTransaction }
                .filter { $0.sk2Transaction?.productType == .autoRenewable }
                .first { _ in true }
        }
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    var firstVerifiedTransaction: StoreTransaction? {
        get async {
            await StoreKit.Transaction.all
                .compactMap { $0.verifiedStoreTransaction }
                .first { _ in true }
        }
    }

}

// MARK: -

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension StoreKit.VerificationResult where SignedType == StoreKit.Transaction {

    var underlyingTransaction: StoreKit.Transaction {
        switch self {
        case let .unverified(transaction, _): return transaction
        case let .verified(transaction): return transaction
        }
    }

    var verifiedTransaction: StoreKit.Transaction? {
        switch self {
        case let .verified(transaction): return transaction
        case .unverified: return nil
        }
    }

    var verifiedStoreTransaction: StoreTransaction? {
        switch self {
        case let .verified(transaction): return StoreTransaction(sk2Transaction: transaction,
                                                                 jwsRepresentation: self.jwsRepresentation)
        case .unverified: return nil
        }
    }

}
