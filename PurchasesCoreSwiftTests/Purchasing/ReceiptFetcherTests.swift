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

@testable import PurchasesCoreSwift
import Nimble


class ReceiptFetcherTests: XCTestCase {
    var receiptFetcher: ReceiptFetcher!
    var mockRequestFetcher: MockRequestFetcher!
    var mockBundle: MockBundle!
    
    override func setUp() {
        mockBundle = MockBundle()
        mockRequestFetcher = MockRequestFetcher()
        receiptFetcher = ReceiptFetcher(requestFetcher: mockRequestFetcher, bundle: mockBundle)
    }
    
    func testReceiptDataWithRefreshPolicyNeverDoesntRefreshIfEmpty() {
        var completionCalled = false
        mockBundle.shouldReturnNilURL = true
        var receivedData: Data?
        receiptFetcher.receiptData(refreshPolicy: .never) { maybeData in
            completionCalled = true
            receivedData = maybeData
        }
        expect(completionCalled).toEventually(beTrue())
        expect(self.mockRequestFetcher.refreshReceiptCalled) == false
        expect(receivedData).to(beNil())
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

    func testReceiptDataWithRefreshPolicyOnlyIfEmptyRefreshesIfEmpty() {
        
    }

    func testReceiptDataWithRefreshPolicyOnlyIfEmptyDoesntRefreshIfTheresData() {
        
    }

    func testReceiptDataWithRefreshPolicyOnlyIfEmptyReturnsReceiptData() {
        
    }

    func testReceiptDataWithRefreshPolicyAlwaysReturnsReceiptData() {
        
    }

    func testReceiptDataWithRefreshPolicyAlwaysRefreshesEvenIfTheresData() {
        
    }
    
}
