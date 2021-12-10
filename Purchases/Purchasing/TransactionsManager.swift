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
    private let systemInfo: SystemInfo

    init(receiptParser: ReceiptParser,
         systemInfo: SystemInfo) {
        self.receiptParser = receiptParser
        self.systemInfo = systemInfo
    }

    func customerHasTransactions(receiptData: Data, completion: @escaping (Bool) -> Void) {
        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *),
           self.systemInfo.useStoreKit2IfAvailable {
            _ = Task<Void, Never> {
                let hasTransactions = await StoreKit.Transaction.all.contains { _ in true }
                completion(hasTransactions)
            }
        } else {
            completion(receiptParser.receiptHasTransactions(receiptData: receiptData))
        }
    }

}
