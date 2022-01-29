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

protocol StoreKit2TransactionListenerDelegate: AnyObject {
    func transactionsUpdated()
}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class StoreKit2TransactionListener {

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

    /// - Returns: whether the user cancelled
    /// - Throws: Error if purchase was not completed successfully
    func handle(
        purchaseResult: StoreKit.Product.PurchaseResult
    ) async throws -> (userCancelled: Bool, transaction: SK2Transaction?) {
        switch purchaseResult {
        case .success(let verificationResult):
            let transaction = try await handle(transactionResult: verificationResult)

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
    func handle(transactionResult: VerificationResult<StoreKit.Transaction>) async throws -> SK2Transaction {
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
            await finish(transaction: verifiedTransaction)

            return verifiedTransaction
        }
    }

    func finish(transaction: StoreKit.Transaction) async {
        await transaction.finish()
        delegate?.transactionsUpdated()
    }

}
