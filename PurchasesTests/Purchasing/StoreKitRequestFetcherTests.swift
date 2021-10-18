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

import Purchases


class StoreKitRequestFetcher: XCTestCase {

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

    class MockRequestsFactory: RCProductsRequestFactory {
        let fails: Bool
        var requestResponseTimeInSeconds: Int = 0
        var invokedRequestCount = 0
        var stubbedRequestResult: MockProductsRequest?

        init(fails: Bool) {
            self.fails = fails
        }

        var requests: [SKRequest] = []
        override func request(forProductIdentifiers identifiers: Set<String>) -> SKProductsRequest {
            invokedRequestCount += 1
            let r = stubbedRequestResult ?? MockProductsRequest(productIdentifiers:identifiers, responseTimeInSeconds: requestResponseTimeInSeconds)
            requests.append(r)
            r.fails = self.fails
            return r
        }

        override func receiptRefreshRequest() -> SKReceiptRefreshRequest {
            let r = MockReceiptRequest()
            requests.append(r)
            r.fails = self.fails
            return r
        }
    }

    var fetcher: RCStoreKitRequestFetcher!
    var factory: MockRequestsFactory!
    var products: [SKProduct]?
    var receiptFetched = false
    var receiptFetchedCallbackCount = 0

    func setupFetcher(fails: Bool) {
        self.factory = MockRequestsFactory(fails: fails)
        self.fetcher = RCStoreKitRequestFetcher(requestFactory: self.factory,
                                                operationDispatcher: MockOperationDispatcher())

        self.fetcher.fetchProducts(["com.a.product"]) { (newProducts) in
            self.products = newProducts
        }

        self.fetcher.fetchReceiptData {
            self.receiptFetched = true
            self.receiptFetchedCallbackCount += 1
        }
        
        self.fetcher.fetchReceiptData {
            self.receiptFetchedCallbackCount += 1
        }
        
        self.fetcher.fetchReceiptData {
            self.receiptFetchedCallbackCount += 1
        }
    }

    func testCreatesARequest() {
        setupFetcher(fails: false)
        expect(self.factory.requests.count).toEventually(equal(2))
    }

    func testSetsTheRequestDelegate() {
        setupFetcher(fails: false)
        expect(self.factory.requests[0].delegate).toEventually(be(self.fetcher), timeout: .seconds(1))
    }

    func testCallsStartOnRequest() {
        setupFetcher(fails: false)
        expect((self.factory.requests[0] as! MockProductsRequest).startCalled).toEventually(beTrue(), timeout: .seconds(1))
    }

    func testReturnsProducts() {
        setupFetcher(fails: false)
        expect(self.products).toEventuallyNot(beNil(), timeout: .seconds(1))
        expect(self.products?.count).toEventually(be(1), timeout: .seconds(1))
    }
    
    func testReusesRequestsForSameProducts() {
        setupFetcher(fails: false)
        
        var callbackCount = 0
        self.fetcher.fetchProducts(["com.a.product", "com.b.product"]) { (newProducts) in
            callbackCount += 1
        }
        
        self.fetcher.fetchProducts(["com.a.product", "com.b.product"]) { (newProducts) in
            callbackCount += 1
        }
        
        expect(self.factory?.requests).to(haveCount(3))
        expect(callbackCount).toEventually(equal(2))
    }

    func testFetchesReceipt() {
        setupFetcher(fails: false)
        expect(self.receiptFetched).toEventually(beTrue())
    }

    func testCallsDelegateWithEmptyProducts() {
        setupFetcher(fails: true)
        expect(self.products).toEventually(beEmpty())
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
        expect(self.factory?.requests).to(haveCount(2))
    }
    
    func testFetchesReceiptMultipleTimes() {
        setupFetcher(fails: false)
        expect(self.receiptFetched).toEventually(beTrue())
        var fetchedAgain = false
        
        self.fetcher.fetchReceiptData {
            fetchedAgain = true
        }
        
        expect(fetchedAgain).toEventually(beTrue())
        
        expect(self.factory?.requests).to(haveCount(3))
    }

    func testProductsWithIdentifiersTimesOutIfMaxToleranceExceeded() throws {
        setupFetcher(fails: false)
        let productIdentifiers = Set(["1", "2", "3"])
        let toleranceInSeconds = 1
        let productsRequestResponseTimeInSeconds = 2
        let request = MockProductsRequest(productIdentifiers: productIdentifiers,
                                          responseTimeInSeconds: productsRequestResponseTimeInSeconds)
        factory.stubbedRequestResult = request
        fetcher.requestTimeoutInSeconds = toleranceInSeconds;

        var completionCallCount = 0
        var maybeReceivedProducts: [SKProduct]?

        fetcher.fetchProducts(productIdentifiers) { products in
            completionCallCount += 1
            maybeReceivedProducts = products
        }

        expect(completionCallCount).toEventually(equal(1), timeout: .seconds(3))
        expect(self.factory.invokedRequestCount) == 1
        let receivedProducts = try XCTUnwrap(maybeReceivedProducts)
        expect(receivedProducts).to(beEmpty())
        expect(request.cancelCalled) == true
    }

    func testProductsWithIdentifiersDoesntTimeOutIfRequestReturnsOnTime() throws {
        setupFetcher(fails: false)
        let productIdentifiers = Set(["1", "2", "3"])
        let toleranceInSeconds = 2
        let productsRequestResponseTimeInSeconds = 1
        let request = MockProductsRequest(productIdentifiers: productIdentifiers,
                                          responseTimeInSeconds: productsRequestResponseTimeInSeconds)
        factory.stubbedRequestResult = request
        fetcher.requestTimeoutInSeconds = toleranceInSeconds;

        var completionCallCount = 0
        var maybeReceivedProducts: [SKProduct]?

        fetcher.fetchProducts(productIdentifiers) { products in
            completionCallCount += 1
            maybeReceivedProducts = products
        }

        expect(completionCallCount).toEventually(equal(1), timeout: .seconds(3))
        expect(self.factory.invokedRequestCount) == 1
        let receivedProducts = try XCTUnwrap(maybeReceivedProducts)
        expect(receivedProducts).toNot(beEmpty())
        expect(request.cancelCalled) == false
    }

}
