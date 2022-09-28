//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TransactionsManager.swift
//
//  Created by Juanpe Catalán on 9/12/21.

import StoreKit

class TransactionsManager {

    private let storeKit2Setting: StoreKit2Setting
    private let receiptParser: ReceiptParser

    init(storeKit2Setting: StoreKit2Setting,
         receiptParser: ReceiptParser) {
        self.storeKit2Setting = storeKit2Setting
        self.receiptParser = receiptParser
    }

    func customerHasTransactions(receiptData: Data, completion: @escaping (Bool) -> Void) {
        // Note: this uses SK2 (unless it's explicitly disabled) because its implementation is more accurate.
        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *), self.storeKit2Setting != .disabled {
            Async.call(with: completion) {
                return await self.sk2CheckCustomerHasTransactions()
            }
        } else {
            completion(self.sk1CheckCustomerHasTransactions(receiptData: receiptData))
        }
    }

    func sk1CheckCustomerHasTransactions(receiptData: Data) -> Bool {
        receiptParser.receiptHasTransactions(receiptData: receiptData)
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func sk2CheckCustomerHasTransactions() async -> Bool {
        await StoreKit.Transaction.all.contains { _ in true }
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension TransactionsManager: @unchecked Sendable {}
