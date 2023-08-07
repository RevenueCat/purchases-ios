//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PostedTransactionCacheTests.swift
//
//  Created by Nacho Soto on 7/28/23.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class PostedTransactionCacheTests: TestCase {

    private var userDefaults: UserDefaults!
    private var deviceCache: DeviceCache!
    private var cache: PostedTransactionCache!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.userDefaults = try XCTUnwrap(.init(suiteName: UUID().uuidString))
        self.deviceCache = .init(sandboxEnvironmentDetector: MockSandboxEnvironmentDetector(isSandbox: true),
                                 userDefaults: self.userDefaults)
        self.cache = .init(deviceCache: self.deviceCache)
    }

    func testNoPostedTransactions() {
        expect(self.cache.hasPostedTransaction(MockStoreTransaction())) == false
    }

    func testSavesFirstTransaction() {
        let transaction = MockStoreTransaction()

        self.cache.savePostedTransaction(transaction)
        expect(self.cache.hasPostedTransaction(transaction)) == true
    }

    func testSaveMultipleTransactions() {
        let transaction1 = MockStoreTransaction()
        let transaction2 = MockStoreTransaction()

        self.cache.savePostedTransaction(transaction1)
        self.cache.savePostedTransaction(transaction2)

        expect(self.cache.hasPostedTransaction(transaction1)) == true
        expect(self.cache.hasPostedTransaction(transaction2)) == true
    }

}
