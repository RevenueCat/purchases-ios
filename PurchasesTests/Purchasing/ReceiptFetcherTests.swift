//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ReceiptFetcherTests.swift
//
//  Created by Andrés Boedo on 8/3/21.

import Foundation
import XCTest

import Nimble
@testable import RevenueCat

class ReceiptFetcherTests: XCTestCase {
    var receiptFetcher: ReceiptFetcher!
    var mockRequestFetcher: MockRequestFetcher!
    var mockBundle: MockBundle!
    var mockSystemInfo: MockSystemInfo!

    override func setUpWithError() throws {
        try super.setUpWithError()

        mockBundle = MockBundle()
        mockRequestFetcher = MockRequestFetcher()
        mockSystemInfo = try MockSystemInfo(platformFlavor: nil,
                                            platformFlavorVersion: nil,
                                            finishTransactions: false,
                                            bundle: mockBundle)
        receiptFetcher = ReceiptFetcher(requestFetcher: mockRequestFetcher, systemInfo: mockSystemInfo)
    }

    func testReceiptDataWithRefreshPolicyNeverReturnsReceiptData() {
        var completionCalled = false
        var receivedData: Data?
        receiptFetcher.receiptData(refreshPolicy: .never) { maybeData in
            completionCalled = true
            receivedData = maybeData
        }
        expect(completionCalled).toEventually(beTrue())
        expect(receivedData).toNot(beNil())
    }

    func testReceiptDataWithRefreshPolicyOnlyIfEmptyReturnsReceiptData() {
        var completionCalled = false
        var receivedData: Data?
        receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty) { maybeData in
            completionCalled = true
            receivedData = maybeData
        }
        expect(completionCalled).toEventually(beTrue())
        expect(receivedData).toNot(beNil())
    }

    func testReceiptDataWithRefreshPolicyAlwaysReturnsReceiptData() {
        var completionCalled = false
        var receivedData: Data?
        receiptFetcher.receiptData(refreshPolicy: .always) { maybeData in
            completionCalled = true
            receivedData = maybeData
        }
        expect(completionCalled).toEventually(beTrue())
        expect(receivedData).toNot(beNil())
    }

    func testReceiptDataWithRefreshPolicyNeverDoesntRefreshIfEmpty() {
        var completionCalled = false
        mockBundle.receiptURLResult = .emptyReceipt
        var receivedData: Data?
        receiptFetcher.receiptData(refreshPolicy: .never) { maybeData in
            completionCalled = true
            receivedData = maybeData
        }
        expect(completionCalled).toEventually(beTrue())
        expect(self.mockRequestFetcher.refreshReceiptCalled) == false
        expect(receivedData).to(beNil())
    }

    func testReceiptDataWithRefreshPolicyOnlyIfEmptyRefreshesIfEmpty() {
        var completionCalled = false
        mockBundle.receiptURLResult = .emptyReceipt
        var receivedData: Data?
        receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty) { maybeData in
            completionCalled = true
            receivedData = maybeData
        }
        expect(completionCalled).toEventually(beTrue())
        expect(self.mockRequestFetcher.refreshReceiptCalled) == true
        expect(receivedData).toNot(beNil())
        expect(receivedData).to(beEmpty())
    }

    func testReceiptDataWithRefreshPolicyOnlyIfEmptyRefreshesIfNil() {
        var completionCalled = false
        mockBundle.receiptURLResult = .nilURL
        var receivedData: Data?
        receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty) { maybeData in
            completionCalled = true
            receivedData = maybeData
        }
        expect(completionCalled).toEventually(beTrue())
        expect(self.mockRequestFetcher.refreshReceiptCalled) == true
        expect(receivedData).toNot(beNil())
        expect(receivedData).to(beEmpty())
    }

    func testReceiptDataWithRefreshPolicyOnlyIfEmptyDoesntRefreshIfTheresData() {
        var completionCalled = false
        mockBundle.receiptURLResult = .receiptWithData
        var receivedData: Data?
        receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty) { maybeData in
            completionCalled = true
            receivedData = maybeData
        }
        expect(completionCalled).toEventually(beTrue())
        expect(self.mockRequestFetcher.refreshReceiptCalled) == false
        expect(receivedData).toNot(beNil())
        expect(receivedData).toNot(beEmpty())
    }

    func testReceiptDataWithRefreshPolicyAlwaysRefreshesEvenIfTheresData() {
        var completionCalled = false
        mockBundle.receiptURLResult = .receiptWithData
        var receivedData: Data?
        receiptFetcher.receiptData(refreshPolicy: .always) { maybeData in
            completionCalled = true
            receivedData = maybeData
        }
        expect(completionCalled).toEventually(beTrue())
        expect(self.mockRequestFetcher.refreshReceiptCalled) == true
        expect(receivedData).toNot(beNil())
        expect(receivedData).toNot(beEmpty())
    }

}
