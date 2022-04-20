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
protocol StoreKit2TransactionListenerDelegate: AnyObject {

    func transactionsUpdated() async throws -> CustomerInfo

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class StoreKit2TransactionListener {

    /// Similar to ``PurchaseResultData`` but with an optional `CustomerInfo`
    typealias ResultData = (userCancelled: Bool, customerInfo: CustomerInfo?, transaction: SK2Transaction?)

    private(set) var taskHandle: Task<Void, Never>?
    weak var delegate: StoreKit2TransactionListenerDelegate?

    init(delegate: StoreKit2TransactionListenerDelegate?) {
        self.delegate = delegate
    }

    func listenForTransactions() {
        self.taskHandle?.cancel()
        self.taskHandle = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard let self = self else { break }

                do {
                    _ = try await self.handle(transactionResult: result)
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
        case .success(let verificationResult):
            let (transaction, customerInfo) = try await handle(transactionResult: verificationResult)

            return (false, customerInfo, transaction)
        case .pending:
            throw ErrorUtils.paymentDeferredError()
        case .userCancelled:
            return (true, nil, nil)
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
    func handle(
        transactionResult: VerificationResult<StoreKit.Transaction>
    ) async throws -> (SK2Transaction, CustomerInfo?) {
        switch transactionResult {
        case let .unverified(unverifiedTransaction, verificationError):
            throw ErrorUtils.storeProblemError(
                withMessage: Strings.purchase.transaction_unverified(
                    productID: unverifiedTransaction.productID,
                    errorMessage: verificationError.localizedDescription
                ).description,
                error: verificationError
            )

        case .verified(let verifiedTransaction):
            let customerInfo = try await self.finish(transaction: verifiedTransaction)

            return (verifiedTransaction, customerInfo)
        }
    }

    /// - Returns `nil` only if the delegate isn't set.
    func finish(transaction: StoreKit.Transaction) async throws -> CustomerInfo? {
        await transaction.finish()

        guard let delegate = self.delegate else { return nil }

        return try await delegate.transactionsUpdated()
    }

}
