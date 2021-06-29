//
//  StoreKitRequestFetcherTests.swift
//  PurchasesTests
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

import XCTest
import OHHTTPStubs
import Nimble
import StoreKit

@testable import PurchasesCoreSwift

class StoreKitRequestFetcherTests: XCTestCase {

    class MockReceiptRequest: SKReceiptRefreshRequest {
        var startCalled = false
        var fails = false
        override func start() {
            startCalled = true
            DispatchQueue.main.async {
                if (self.fails) {
                    self.delegate?.request!(self, didFailWithError: StoreKitError.unknown)
                } else {
                    self.delegate?.requestDidFinish!(self)
                }
            }
        }
    }

    class MockRequestsFactory: ReceiptRefreshRequestFactory {
        let fails: Bool

        init(fails: Bool) {
            self.fails = fails
        }

        var requests: [SKRequest] = []

        override func receiptRefreshRequest() -> SKReceiptRefreshRequest {
            let r = MockReceiptRequest()
            requests.append(r)
            r.fails = self.fails
            return r
        }
    }

    var fetcher: StoreKitRequestFetcher?
    var factory: MockRequestsFactory?
    var receiptFetched = false
    var receiptFetchedCallbackCount = 0

    func setupFetcher(fails: Bool) {
        self.factory = MockRequestsFactory(fails: fails)
        self.fetcher = StoreKitRequestFetcher(requestFactory: self.factory!)

        self.fetcher!.fetchReceiptData {
            self.receiptFetched = true
            self.receiptFetchedCallbackCount += 1
        }
        
        self.fetcher!.fetchReceiptData {
            self.receiptFetchedCallbackCount += 1
        }
        
        self.fetcher!.fetchReceiptData {
            self.receiptFetchedCallbackCount += 1
        }
    }

    func testCreatesARequest() {
        setupFetcher(fails: false)
        expect(self.factory!.requests.count).toEventually(equal(1))
    }

    func testSetsTheRequestDelegate() {
        setupFetcher(fails: false)
        expect(self.factory!.requests[0].delegate).toEventually(be(self.fetcher), timeout: .seconds(1))
    }

    func testCallsStartOnRequest() {
        setupFetcher(fails: false)
        expect((self.factory!.requests[0] as! MockReceiptRequest).startCalled).toEventually(beTrue(), timeout: .seconds(1))
    }
    func testFetchesReceipt() {
        setupFetcher(fails: false)
        expect(self.receiptFetched).toEventually(beTrue())
    }

    func testStillCallsReceiptFetchDelegate() {
        setupFetcher(fails: true)
        expect(self.receiptFetched).toEventually(beTrue())
    }
    
    func testCanSupportMultipleReceiptCalls() {
        setupFetcher(fails: false)
        expect(self.receiptFetchedCallbackCount).toEventually(equal(3))
    }
    
    func testOnlyCreatesOneRefreshRequest() {
        setupFetcher(fails: false)
        expect(self.factory?.requests).to(haveCount(1))
    }
    
    func testFetchesReceiptMultipleTimes() {
        setupFetcher(fails: false)
        expect(self.receiptFetched).toEventually(beTrue())
        var fetchedAgain = false
        
        self.fetcher!.fetchReceiptData {
            fetchedAgain = true
        }
        
        expect(fetchedAgain).toEventually(beTrue())
        
        expect(self.factory?.requests).to(haveCount(2))
    }
    
}
