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

class ReceiptFetcherTests: TestCase {

    private var receiptFetcher: ReceiptFetcher!
    private var mockRequestFetcher: MockRequestFetcher!
    private var mockBundle: MockBundle!
    private var mockSystemInfo: MockSystemInfo!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.mockBundle = MockBundle()
        self.mockRequestFetcher = MockRequestFetcher()
        self.mockSystemInfo = try MockSystemInfo(platformInfo: nil,
                                                 finishTransactions: false,
                                                 bundle: self.mockBundle)
        self.receiptFetcher = ReceiptFetcher(requestFetcher: self.mockRequestFetcher, systemInfo: self.mockSystemInfo)
    }

    func testReceiptDataWithRefreshPolicyNeverReturnsReceiptData() {
        var receivedData: Data?
        self.receiptFetcher.receiptData(refreshPolicy: .never) { data in
            receivedData = data
        }

        expect(receivedData).toEventuallyNot(beNil())
    }

    func testReceiptDataWithRefreshPolicyOnlyIfEmptyReturnsReceiptData() {
        var receivedData: Data?
        self.receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty) { data in
            receivedData = data
        }

        expect(receivedData).toEventuallyNot(beNil())
    }

    func testReceiptDataWithRefreshPolicyAlwaysReturnsReceiptData() {
        var receivedData: Data?
        self.receiptFetcher.receiptData(refreshPolicy: .always) { data in
            receivedData = data
        }

        expect(receivedData).toEventuallyNot(beNil())
    }

    func testReceiptDataWithRefreshPolicyNeverDoesntRefreshIfEmpty() {
        mockBundle.receiptURLResult = .emptyReceipt

        var completionCalled = false
        var receivedData: Data?
        receiptFetcher.receiptData(refreshPolicy: .never) { data in
            receivedData = data
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.mockRequestFetcher.refreshReceiptCalled) == false
        expect(receivedData).to(beNil())
    }

    func testReceiptDataWithRefreshPolicyOnlyIfEmptyRefreshesIfEmpty() {
        mockBundle.receiptURLResult = .emptyReceipt

        var receivedData: Data?
        receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty) { data in
            receivedData = data
        }

        expect(receivedData).toEventuallyNot(beNil())
        expect(receivedData).to(beEmpty())
        expect(self.mockRequestFetcher.refreshReceiptCalled) == true
    }

    func testReceiptDataWithRefreshPolicyOnlyIfEmptyRefreshesIfNil() {
        mockBundle.receiptURLResult = .nilURL

        var receivedData: Data?
        receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty) { data in
            receivedData = data
        }

        expect(receivedData).toEventuallyNot(beNil())
        expect(receivedData).to(beEmpty())
        expect(self.mockRequestFetcher.refreshReceiptCalled) == true
    }

    func testReceiptDataWithRefreshPolicyOnlyIfEmptyDoesntRefreshIfTheresData() {
        mockBundle.receiptURLResult = .receiptWithData

        var receivedData: Data?
        receiptFetcher.receiptData(refreshPolicy: .onlyIfEmpty) { data in
            receivedData = data
        }

        expect(receivedData).toEventuallyNot(beNil())
        expect(receivedData).toNot(beEmpty())
        expect(self.mockRequestFetcher.refreshReceiptCalled) == false
    }

    func testReceiptDataWithRefreshPolicyAlwaysRefreshesEvenIfTheresData() {
        mockBundle.receiptURLResult = .receiptWithData

        var receivedData: Data?
        receiptFetcher.receiptData(refreshPolicy: .always) { data in
            receivedData = data
        }

        expect(receivedData).toEventuallyNot(beNil())
        expect(receivedData).toNot(beEmpty())
        expect(receivedData).toNot(beNil())
    }

}
