//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesStoreMessagesTests.swift
//
//  Created by Jay Shortway on 05/01/2026.

import Nimble
import XCTest

@testable import RevenueCat

#if os(iOS) || targetEnvironment(macCatalyst) || VISION_OS

@available(iOS 16.0, *)
class PurchasesStoreMessagesTests: BasePurchasesTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        self.setupPurchases()
    }

    // MARK: - showStoreMessages with completion

    func testShowStoreMessagesWithCompletionCallsHelper() {
        let expectation = self.expectation(description: "Completion called")

        self.purchases.showStoreMessages(for: Set(StoreMessageType.allCases)) {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
        expect(self.mockStoreMessagesHelper.showStoreMessageCalled) == true
    }

    func testShowStoreMessagesNoArgsWithCompletionCallsHelper() {
        let expectation = self.expectation(description: "Completion called")

        self.purchases.showStoreMessages {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
        expect(self.mockStoreMessagesHelper.showStoreMessageCalled) == true
    }

    func testShowStoreMessagesForTypesWithCompletionCallsHelper() {
        let expectation = self.expectation(description: "Completion called")

        let types: NSSet = [NSNumber(value: StoreMessageType.billingIssue.rawValue)]
        self.purchases.showStoreMessages(forTypes: types) {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
        expect(self.mockStoreMessagesHelper.showStoreMessageCalled) == true
    }

}

#endif
