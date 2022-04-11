//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TransactionsManagerSK1Tests.swift
//
//  Created by Juanpe Catalán on 10/12/21.

import Nimble
@testable import RevenueCat
import XCTest

class TransactionsManagerSK1Tests: StoreKitConfigTestCase {

    var mockReceiptParser: MockReceiptParser!
    var transactionsManager: TransactionsManager!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockReceiptParser = MockReceiptParser()

        transactionsManager = TransactionsManager(storeKit2Setting: .disabled,
                                                  receiptParser: mockReceiptParser)
    }

    func testSK1CheckCustomerHasTransactionsParserIsCalled() {
        _ = transactionsManager.sk1CheckCustomerHasTransactions(receiptData: Data())
        expect(self.mockReceiptParser.invokedReceiptHasTransactions) ==  true
    }

    func testSK1CheckCustomerHasTransactionsCalculatedFromReceiptData() {
        mockReceiptParser.stubbedReceiptHasTransactionsResult = true
        let receivedHasTransactionsValue = transactionsManager.sk1CheckCustomerHasTransactions(receiptData: Data())
        expect(receivedHasTransactionsValue) == true
    }

}
