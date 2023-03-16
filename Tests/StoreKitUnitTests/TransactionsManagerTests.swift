//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TransactionsManagerTests.swift
//
//  Created by Juanpe Catalán on 10/12/21.

import Nimble
@testable import RevenueCat
import XCTest

@available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 7.0, *)
class TransactionsManagerTests: StoreKitConfigTestCase {

    private var mockReceiptParser: MockReceiptParser!
    private var transactionsManager: TransactionsManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.mockReceiptParser = MockReceiptParser()
        self.transactionsManager = TransactionsManager(receiptParser: self.mockReceiptParser)
    }

    func testCheckCustomerHasTransactionsParserIsCalled() {
        _ = transactionsManager.customerHasTransactions(receiptData: .init())
        expect(self.mockReceiptParser.invokedReceiptHasTransactions) == true
    }

    func testCheckCustomerHasTransactionsCalculatedFromReceiptData() {
        self.mockReceiptParser.stubbedReceiptHasTransactionsResult = true
        expect(self.transactionsManager.customerHasTransactions(receiptData: .init())) == true
    }

}
