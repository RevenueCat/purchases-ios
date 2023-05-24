//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfoManagerFetchInfoAndPostReceiptTests.swift
//
//  Created by Nacho Soto on 5/24/23.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
class CustomerInfoManagerPostReceiptTests: BaseCustomerInfoManagerTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()
    }

    func testDoesNotTryToPostUnfinishedTransactionIfThereIsNoHandler() async throws {
        self.mockTransationFetcher.stubbedUnfinishedTransactions = [Self.createTransaction()]
        self.mockBackend.stubbedGetCustomerInfoResult = .success(self.mockCustomerInfo)

        let result = try await self.customerInfoManager.fetchAndCacheCustomerInfo(appUserID: "user",
                                                                                  isAppBackgrounded: false)

        expect(result) === self.mockCustomerInfo

        expect(self.mockTransactionPoster.invokedHandlePurchasedTransaction.value) == false
    }

    private static func createTransaction() -> StoreTransaction {
        return .init(sk1Transaction: MockTransaction())
    }

}
