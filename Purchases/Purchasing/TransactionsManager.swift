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

    private let receiptParser: ReceiptParser

    init(receiptParser: ReceiptParser) {
        self.receiptParser = receiptParser
    }

    func customerHasTransactions(receiptData: Data, completion: @escaping (Bool) -> Void) {
        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
            _ = Task<Void, Never> {
                completion(await sk2CheckCustomerHasTransactions())
            }
        } else {
            completion(sk1CheckCustomerHasTransactions(receiptData: receiptData))
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
