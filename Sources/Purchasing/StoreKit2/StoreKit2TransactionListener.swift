//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKit2TransactionListener.swift
//
//  Created by Andrés Boedo on 31/8/21.

import Foundation
import StoreKit

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
protocol StoreKit2TransactionListenerDelegate: AnyObject, Sendable {

    func storeKit2TransactionListener(
        _ listener: StoreKit2TransactionListenerType,
        updatedTransaction transaction: StoreTransactionType
    ) async throws

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
protocol StoreKit2TransactionListenerType: Sendable {

    func listenForTransactions() async

    func set(delegate: StoreKit2TransactionListenerDelegate) async

    /// - Returns: `nil` `CustomerInfo` if purchases were not synced
    /// - Throws: Error if purchase was not completed successfully
    func handle(
        purchaseResult: StoreKit.Product.PurchaseResult
    ) async throws -> StoreKit2TransactionListener.ResultData

}

/// Observes `StoreKit.Transaction.updates`, which receives:
/// - Updates from outside `Product.purchase()`, like renewals and purchases made on other devices
/// - Purchases from SwiftUI's paywalls.
@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
actor StoreKit2TransactionListener: StoreKit2TransactionListenerType {

    /// Similar to ``PurchaseResultData`` but with an optional `CustomerInfo`
    typealias ResultData = (userCancelled: Bool, transaction: SK2Transaction?)

    private(set) var taskHandle: Task<Void, Never>?

    private weak var delegate: StoreKit2TransactionListenerDelegate?

    init(delegate: StoreKit2TransactionListenerDelegate?) {
        self.delegate = delegate
    }

    func set(delegate: StoreKit2TransactionListenerDelegate) {
        self.delegate = delegate
    }

    func listenForTransactions() {
        Logger.debug(Strings.storeKit.sk2_observing_transaction_updates)

        self.taskHandle?.cancel()
        self.taskHandle = Task(priority: .utility) { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard let self = self else { break }

                do {
                    _ = try await self.handle(transactionResult: result, fromTransactionUpdate: true)
                } catch {
                    Logger.error(error.localizedDescription)
                }
            }
        }
    }

    deinit {
        self.taskHandle?.cancel()
        self.taskHandle = nil
    }

    /// - Returns: `nil` `CustomerInfo` if purchases were not synced
    /// - Throws: Error if purchase was not completed successfully
    func handle(
        purchaseResult: StoreKit.Product.PurchaseResult
    ) async throws -> ResultData {
        switch purchaseResult {
        case let .success(verificationResult):
            let transaction = try await self.handle(transactionResult: verificationResult,
                                                    fromTransactionUpdate: false)

            return (false, transaction)
        case .pending:
            throw ErrorUtils.paymentDeferredError()
        case .userCancelled:
            return (true, nil)
        @unknown default:
            throw ErrorUtils.storeProblemError(
                withMessage: Strings.purchase.unknown_purchase_result(result: String(describing: purchaseResult))
                    .description
            )
        }
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension StoreKit2TransactionListener {

    /// - Throws: ``ErrorCode`` if the transaction fails to verify.
    /// - Parameter fromTransactionUpdate: `true` only for transactions detected outside of a manual purchase flow.
    func handle(
        transactionResult: StoreKit.VerificationResult<StoreKit.Transaction>,
        fromTransactionUpdate: Bool
    ) async throws -> SK2Transaction {
        switch transactionResult {
        case let .unverified(unverifiedTransaction, verificationError):
            throw ErrorUtils.storeProblemError(
                withMessage: Strings.purchase.transaction_unverified(
                    productID: unverifiedTransaction.productID,
                    errorMessage: verificationError.localizedDescription
                ).description,
                error: verificationError
            )

        case let .verified(verifiedTransaction):
            if fromTransactionUpdate, let delegate = self.delegate {
                Logger.debug(Strings.purchase.sk2_transactions_update_received_transaction(
                    productID: verifiedTransaction.productID
                ))

                try await delegate.storeKit2TransactionListener(
                    self,
                    updatedTransaction: StoreTransaction(sk2Transaction: verifiedTransaction)
                )
            }

            return verifiedTransaction
        }
    }

}
