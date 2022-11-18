//
// Created by Andrés Boedo on 8/11/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

@testable import ReceiptParser
@testable import RevenueCat

import XCTest

class MockReceiptParser: ParserType {

    var invokedParse = false
    var invokedParseCount = 0
    var invokedParseParameters: Data?
    var invokedParseParametersList = [Data]()
    var stubbedParseError: Error?

    var stubbedParseResult: AppleReceipt {
        get { return self.stubbedParseResults.onlyElement!.value! }
        set { self.stubbedParseResults = [.success(newValue)] }
    }

    var stubbedParseResults: [Result<AppleReceipt, Error>] = [
        .success(
            .init(bundleId: "com.revenuecat.test",
                  applicationVersion: "5.6.7",
                  originalApplicationVersion: "3.4.5",
                  opaqueValue: Data(),
                  sha1Hash: Data(),
                  creationDate: Date(),
                  expirationDate: nil,
                  inAppPurchases: [])
        )
    ]

    init() {}

    func parse(from receiptData: Data) throws -> AppleReceipt {
        self.invokedParse = true
        self.invokedParseCount += 1
        self.invokedParseParameters = receiptData
        self.invokedParseParametersList.append(receiptData)
        if let error = self.stubbedParseError {
            throw error
        }

        if self.stubbedParseResults.count > 1 {
            // If `stubbedParseResults` contains multiple elements
            // this returns a different result every time.
            // This is used to mock changing receipts over time.
            return try self.stubbedParseResults[self.invokedParseCount - 1].get()
        } else {
            return try XCTUnwrap(self.stubbedParseResults.first).get()
        }
    }

    var invokedReceiptHasTransactions = false
    var invokedReceiptHasTransactionsCount = 0
    var invokedReceiptHasTransactionsParameters: (receiptData: Data, Void)?
    var invokedReceiptHasTransactionsParametersList = [(receiptData: Data, Void)]()
    var stubbedReceiptHasTransactionsResult: Bool! = false

    func receiptHasTransactions(receiptData: Data) -> Bool {
        invokedReceiptHasTransactions = true
        invokedReceiptHasTransactionsCount += 1
        invokedReceiptHasTransactionsParameters = (receiptData, ())
        invokedReceiptHasTransactionsParametersList.append((receiptData, ()))
        return stubbedReceiptHasTransactionsResult
    }
}
