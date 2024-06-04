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

    private let receiptParser: PurchasesReceiptParser

    init(receiptParser: PurchasesReceiptParser) {
        self.receiptParser = receiptParser
    }

    func customerHasTransactions(receiptData: Data) -> Bool {
        // Note: even though SK2's implementation (using `StoreKit.Transaction.all`) might be more accurate
        // we need to check what will be reflected in the posted receipt.
        return self.receiptParser.receiptHasTransactions(receiptData: receiptData)
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension TransactionsManager: @unchecked Sendable {}
