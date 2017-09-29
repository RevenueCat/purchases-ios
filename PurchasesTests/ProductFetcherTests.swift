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

    class MockRequestsFactory: RCProductsRequestFactory {
        var requests: [MockProductRequest] = []
        override func request(forProductIdentifiers identifiers: Set<String>) -> SKProductsRequest {
            let r = MockProductRequest(productIdentifiers:identifiers)
            requests.append(r)
            return r
        }
    }

    var fetcher: RCProductFetcher?
    var factory: MockRequestsFactory?
    var products: [SKProduct]?

    override func setUp() {
        super.setUp()
        self.factory = MockRequestsFactory()
        self.fetcher = RCProductFetcher(requestFactory: self.factory!)

        self.fetcher!.fetchProducts(["com.a.product"]) { (newProducts) in
            self.products = newProducts
        }
    }

    func testCreatesARequest() {
        expect(self.factory!.requests.count).toEventually(be(1), timeout: 1.0)
    }

    func testSetsTheRequestDelegate() {
        expect(self.factory!.requests[0].delegate).toEventually(be(self.fetcher), timeout: 1.0)
    }

    func testCallsStartOnRequest() {
        expect(self.factory!.requests[0].startCalled).toEventually(beTrue(), timeout: 1.0)
    }

    func testReturnsProducts() {
        expect(self.products).toEventuallyNot(beNil(), timeout: 1.0)
        expect(self.products?.count).toEventually(be(1), timeout: 1.0)
    }
}
