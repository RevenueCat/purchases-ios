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
        completion(self.sk1CheckCustomerHasTransactions(receiptData: receiptData))
    }

    func sk1CheckCustomerHasTransactions(receiptData: Data) -> Bool {
        receiptParser.receiptHasTransactions(receiptData: receiptData)
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension TransactionsManager: @unchecked Sendable {}
