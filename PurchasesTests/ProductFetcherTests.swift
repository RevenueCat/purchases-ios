//
//  ProductFetcherTests.swift
//  PurchasesTests
//
//  Created by Jacob Eiting on 9/29/17.
//  Copyright © 2017 Purchases. All rights reserved.
//

import XCTest
import OHHTTPStubs
import Nimble
import StoreKit

import Purchases

class MockProduct: SKProduct {
    var mockProductIdentifier: String

    init(mockProductIdentifier: String) {
        self.mockProductIdentifier = mockProductIdentifier
        super.init()
    }

    override var productIdentifier: String {
        return self.mockProductIdentifier
    }
}

class ProductFetcherTests: XCTestCase {

    class MockProductResponse: SKProductsResponse {
        var mockProducts: [MockProduct]
        init(productIdentifiers: Set<String>) {
            self.mockProducts = productIdentifiers.map { identifier in
                return MockProduct(mockProductIdentifier: identifier)
            }
            super.init()
        }

        override var products: [SKProduct] {
            return self.mockProducts
        }
    }

    class MockProductRequest: SKProductsRequest {
        var startCalled = false
        var requestedIdentifiers: Set<String>

        override init(productIdentifiers: Set<String>) {
            self.requestedIdentifiers = productIdentifiers
            super.init()
        }

        override func start() {
            startCalled = true
            DispatchQueue.global(qos: .background).async {
                self.delegate?.productsRequest(self, didReceive: MockProductResponse(productIdentifiers: self.requestedIdentifiers))
            }
        }
    }

    class MockReceiptRequest: SKReceiptRefreshRequest {
        var startCalled = false
        override func start() {
            startCalled = true
            DispatchQueue.global(qos: .background).async {
                self.delegate?.requestDidFinish!(self)
            }
        }
    }


    class MockRequestsFactory: RCProductsRequestFactory {
        var requests: [SKRequest] = []
        override func request(forProductIdentifiers identifiers: Set<String>) -> SKProductsRequest {
            let r = MockProductRequest(productIdentifiers:identifiers)
            requests.append(r)
            return r
        }

        override func receiptRefreshRequest() -> SKReceiptRefreshRequest {
            let r = MockReceiptRequest()
            requests.append(r)
            return r
        }
    }

    var fetcher: RCStoreKitRequestFetcher?
    var factory: MockRequestsFactory?
    var products: [SKProduct]?
    var receiptFetched = false

    override func setUp() {
        super.setUp()
        self.factory = MockRequestsFactory()
        self.fetcher = RCStoreKitRequestFetcher(requestFactory: self.factory!)

        self.fetcher!.fetchProducts(["com.a.product"]) { (newProducts) in
            self.products = newProducts
        }

        self.fetcher!.fetchReceiptData {
            self.receiptFetched = true
        }
    }

    func testCreatesARequest() {
        expect(self.factory!.requests.count).toEventually(equal(2))
    }

    func testSetsTheRequestDelegate() {
        expect(self.factory!.requests[0].delegate).toEventually(be(self.fetcher), timeout: 1.0)
    }

    func testCallsStartOnRequest() {
        expect((self.factory!.requests[0] as! MockProductRequest).startCalled).toEventually(beTrue(), timeout: 1.0)
    }

    func testReturnsProducts() {
        expect(self.products).toEventuallyNot(beNil(), timeout: 1.0)
        expect(self.products?.count).toEventually(be(1), timeout: 1.0)
    }

    func testFetchesReceipt() {
        expect(self.receiptFetched).toEventually(beTrue())
    }
}
