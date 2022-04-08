//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TransactionsManagerSK2Tests.swift
//
//  Created by Juanpe Catalán on 10/12/21.

import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

class TransactionsManagerSK2Tests: StoreKitConfigTestCase {

    var mockReceiptParser: MockReceiptParser!
    var transactionsManager: TransactionsManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        mockReceiptParser = MockReceiptParser()
        transactionsManager = TransactionsManager(storeKit2Setting: .enabledForCompatibleDevices,
                                                  receiptParser: mockReceiptParser)
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSK2CheckCustomerHasTransactionsWithoutPurchasesAsync() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let receivedHasTransactionsValue = await transactionsManager.sk2CheckCustomerHasTransactions()

        expect(receivedHasTransactionsValue) == false
    }

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func testSK2CheckCustomerHasTransactionsWithOnePurchaseAsync() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        try await self.simulateAnyPurchase()

        let receivedHasTransactionsValue = await transactionsManager.sk2CheckCustomerHasTransactions()

        expect(receivedHasTransactionsValue) == true
    }

}
