//
// Created by Andrés Boedo on 8/11/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
@testable import RevenueCat

class MockReceiptParser: ReceiptParser {

    var invokedParse = false
    var invokedParseCount = 0
    var invokedParseParameters: Data?
    var invokedParseParametersList = [Data]()
    var stubbedParseError: Error?
    var stubbedParseResult = AppleReceipt(bundleId: "com.revenuecat.test",
                                          applicationVersion: "5.6.7",
                                          originalApplicationVersion: "3.4.5",
                                          opaqueValue: Data(),
                                          sha1Hash: Data(),
                                          creationDate: Date(),
                                          expirationDate: nil,
                                          inAppPurchases: [])

    convenience init() {
        self.init(containerBuilder: MockASN1ContainerBuilder(),
                  receiptBuilder: MockAppleReceiptBuilder())
    }

    override func parse(from receiptData: Data) throws -> AppleReceipt {
        invokedParse = true
        invokedParseCount += 1
        invokedParseParameters = receiptData
        invokedParseParametersList.append(receiptData)
        if let error = stubbedParseError {
            throw error
        }
        return stubbedParseResult
    }

    var invokedReceiptHasTransactions = false
    var invokedReceiptHasTransactionsCount = 0
    var invokedReceiptHasTransactionsParameters: (receiptData: Data, Void)?
    var invokedReceiptHasTransactionsParametersList = [(receiptData: Data, Void)]()
    var stubbedReceiptHasTransactionsResult: Bool! = false

    override func receiptHasTransactions(receiptData: Data) -> Bool {
        invokedReceiptHasTransactions = true
        invokedReceiptHasTransactionsCount += 1
        invokedReceiptHasTransactionsParameters = (receiptData, ())
        invokedReceiptHasTransactionsParametersList.append((receiptData, ()))
        return stubbedReceiptHasTransactionsResult
    }
}
