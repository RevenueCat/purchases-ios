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

    let stubbedHandlePurchasedTransactionResult: Atomic<Swift.Result<CustomerInfo, BackendError>> = .init(
        .failure(.missingCachedCustomerInfo())
    )
    let invokedHandlePurchasedTransaction: Atomic<Bool> = false
    let invokedHandlePurchasedTransactionCount: Atomic<Int> = .init(0)
    let invokedHandlePurchasedTransactionParameters: Atomic<(StoreTransaction, PurchasedTransactionData)?> = nil

    func handlePurchasedTransaction(
        _ transaction: StoreTransaction,
        data: PurchasedTransactionData,
        completion: @escaping CustomerAPI.CustomerInfoResponseHandler
    ) {
        self.invokedHandlePurchasedTransaction.value = true
        self.invokedHandlePurchasedTransactionCount.value += 1
        self.invokedHandlePurchasedTransactionParameters.value = (transaction, data)

        self.operationDispatcher.dispatchOnMainActor { [result = self.stubbedHandlePurchasedTransactionResult.value] in
            completion(result)
        }
    }

    let invokedFinishTransactionIfNeeded: Atomic<Bool> = false
    let invokedFinishTransactionIfNeededCount: Atomic<Int> = .init(0)
    let invokedFinishTransactionIfNeededTransaction: Atomic<StoreTransactionType?> = nil

    func finishTransactionIfNeeded(
        _ transaction: StoreTransactionType,
        completion: @escaping @MainActor () -> Void
    ) {
        self.invokedFinishTransactionIfNeeded.value = true
        self.invokedFinishTransactionIfNeededCount.value += 1
        self.invokedFinishTransactionIfNeededTransaction.value = transaction

        self.operationDispatcher.dispatchOnMainActor {
            completion()
        }
    }

    let invokedMarkSyncIfNeeded: Atomic<Bool> = false
    let invokedMarkSyncIfNeededCount: Atomic<Int> = .init(0)

    func markSyncedIfNeeded(
        subscriberAttributes: SubscriberAttribute.Dictionary?,
        error: BackendError?
    ) {
        self.invokedMarkSyncIfNeeded.value = true
        self.invokedMarkSyncIfNeededCount.value += 1
    }

}
