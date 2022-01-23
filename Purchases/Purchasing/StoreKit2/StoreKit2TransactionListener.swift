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

                _ = await self.handle(transactionResult: result)
            }
        }
    }

    deinit {
        self.taskHandle?.cancel()
        self.taskHandle = nil
    }

    /// - Returns: whether the user cancelled
    /// - Throws: Error if purchase was not completed successfully
    func handle(purchaseResult: StoreKit.Product.PurchaseResult) async throws -> Bool {
        switch purchaseResult {
        case .success(let verificationResult):
            if await handle(transactionResult: verificationResult) {
                return false
            } else {
                throw ErrorCode.purchaseInvalidError
            }
        case .pending:
            throw ErrorUtils.paymentDeferredError()
        case .userCancelled:
            return true
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

    /// - Returns: whether the transaction was verified
    func handle(transactionResult: VerificationResult<StoreKit.Transaction>) async -> Bool {
        switch transactionResult {
        case let .unverified(unverifiedTransaction, verificationError):
            Logger.error(Strings.purchase.transaction_unverified(
                productID: unverifiedTransaction.productID,
                errorMessage: verificationError.localizedDescription
            ))

            return false

        case .verified(let verifiedTransaction):
            await finish(transaction: verifiedTransaction)

            return true
        }
    }

    func finish(transaction: StoreKit.Transaction) async {
        await transaction.finish()
        delegate?.transactionsUpdated()
    }

}
