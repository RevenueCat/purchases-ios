//
//  StoreKitRequestFetcherTests.swift
//  PurchasesTests
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class StoreKitRequestFetcherTests: TestCase {

    class MockReceiptRequest: SKReceiptRefreshRequest {
        // swiftlint:disable:next nesting
        enum Error: Swift.Error {
            case unknown
        }

        var startCalled = false
        var fails = false
        override func start() {
            startCalled = true
            DispatchQueue.main.async {
                if self.fails {
                    self.delegate?.request!(self, didFailWithError: Error.unknown)
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
            let request = MockReceiptRequest()
            requests.append(request)
            request.fails = self.fails
            return request
        }
    }

    var fetcher: StoreKitRequestFetcher?
    var factory: MockRequestsFactory?
    var operationDispatcher = MockOperationDispatcher()
    var receiptFetched = false
    var receiptFetchedCallbackCount = 0

    func setupFetcher(fails: Bool) {
        self.operationDispatcher = MockOperationDispatcher()
        self.factory = MockRequestsFactory(fails: fails)
        self.fetcher = StoreKitRequestFetcher(requestFactory: self.factory!, operationDispatcher: operationDispatcher)

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

    func testCallsStartOnRequest() throws {
        setupFetcher(fails: false)
        let request = try XCTUnwrap(self.factory?.requests[0] as? MockReceiptRequest)
        expect(request.startCalled).toEventually(beTrue(), timeout: .seconds(1))
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
        expect(self.factory?.requests).toEventually(haveCount(1))
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
