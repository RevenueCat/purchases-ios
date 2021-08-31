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

    private var taskHandle: Task<Void, Error>?
    weak var delegate: StoreKit2TransactionListenerDelegate?

    init(delegate: StoreKit2TransactionListenerDelegate?) {
        self.delegate = delegate
    }

    func listenForTransactions() {
        self.taskHandle = Task.init {
            for await result in StoreKit.Transaction.updates {
                switch result {
                case .unverified(let unverifiedTransaction, let verificationError):
                    // todo: update once StoreKit fixes the issue with verifying sandbox purchases.
                    #if DEBUG
                    Logger.debug("The transaction has failed verification, but Sandbox purchases dont' support" +
                                 "verification as of Beta 8. Details: \(verificationError.localizedDescription)")
                    await finish(transaction: unverifiedTransaction)
                    #else
                    Logger.error("StoreKit has parsed the JWS but failed verification. The content will not be" +
                                 "made available to the user. Details: \(verificationError.localizedDescription)")
                    #endif
                case .verified(let verifiedTransaction):
                    await finish(transaction: verifiedTransaction)
                }
            }
        }
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension StoreKit2TransactionListener {

    func finish(transaction: StoreKit.Transaction) async {
        await transaction.finish()
        delegate?.transactionsUpdated()
    }
}
