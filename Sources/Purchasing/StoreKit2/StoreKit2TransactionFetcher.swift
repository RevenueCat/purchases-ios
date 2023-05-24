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

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
final class StoreKit2TransactionFetcher: StoreKit2TransactionFetcherType {

    var unfinishedVerifiedTransactions: [StoreTransaction] {
        get async {
            return await StoreKit.Transaction
                .unfinished
                .compactMap { $0.verifiedTransaction }
                .map { StoreTransaction(sk2Transaction: $0) }
                .extractValues()
        }
    }

    var hasPendingConsumablePurchase: Bool {
        get async {
            return await StoreKit.Transaction
                .unfinished
                .contains { $0.productType.productCategory == .nonSubscription }
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

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension StoreKit.VerificationResult where SignedType == StoreKit.Transaction {

    var productType: StoreProduct.ProductType {
        return .init(self.underlyingTransaction.productType)
    }

}
