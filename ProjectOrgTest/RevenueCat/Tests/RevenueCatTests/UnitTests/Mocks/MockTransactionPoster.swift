//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockTransactionPoster.swift
//
//  Created by Nacho Soto on 5/23/23.

import Foundation
@testable import RevenueCat

final class MockTransactionPoster: TransactionPosterType {

    private let operationDispatcher = OperationDispatcher()

    let stubbedHandlePurchasedTransactionResult: Atomic<Result<CustomerInfo, BackendError>> = .init(
        .failure(.missingCachedCustomerInfo())
    )
    let stubbedHandlePurchasedTransactionResults: Atomic<[Result<CustomerInfo, BackendError>]> = .init([])

    let invokedHandlePurchasedTransaction: Atomic<Bool> = false
    let invokedHandlePurchasedTransactionCount: Atomic<Int> = .init(0)
    let invokedHandlePurchasedTransactionParameters: Atomic<(transaction: StoreTransactionType,
                                                             data: PurchasedTransactionData)?> = nil
    let invokedHandlePurchasedTransactionParameterList: Atomic<[(transaction: StoreTransactionType,
                                                                 data: PurchasedTransactionData)]> = .init([])

    var allHandledTransactions: Set<StoreTransaction> {
        return Set(
            self
                .invokedHandlePurchasedTransactionParameterList.value
                .map(\.transaction)
                .compactMap { $0 as? StoreTransaction }
        )
    }

    func handlePurchasedTransaction(
        _ transaction: StoreTransactionType,
        data: PurchasedTransactionData,
        completion: @escaping CustomerAPI.CustomerInfoResponseHandler
    ) {
        // Returns either the first of `stubbedHandlePurchasedTransactionResults`
        // or `stubbedHandlePurchasedTransactionResult`
        func result() -> Result<CustomerInfo, BackendError> {
            return self.stubbedHandlePurchasedTransactionResults.value.popFirst()
            ?? self.stubbedHandlePurchasedTransactionResult.value
        }

        self.invokedHandlePurchasedTransaction.value = true
        self.invokedHandlePurchasedTransactionCount.modify { $0 += 1 }
        self.invokedHandlePurchasedTransactionParameters.value = (transaction, data)
        self.invokedHandlePurchasedTransactionParameterList.modify {
            $0.append((transaction, data))
        }

        self.operationDispatcher.dispatchOnMainActor { [result = result()] in
            completion(result)
        }
    }

    let invokedFinishTransactionIfNeeded: Atomic<Bool> = false
    let invokedFinishTransactionIfNeededCount: Atomic<Int> = .init(0)
    let invokedFinishTransactionIfNeededTransaction: Atomic<StoreTransactionType?> = nil

    func finishTransactionIfNeeded(
        _ transaction: StoreTransactionType,
        completion: @escaping @Sendable @MainActor () -> Void
    ) {
        self.invokedFinishTransactionIfNeeded.value = true
        self.invokedFinishTransactionIfNeededCount.value += 1
        self.invokedFinishTransactionIfNeededTransaction.value = transaction

        self.operationDispatcher.dispatchOnMainActor {
            completion()
        }
    }

}
