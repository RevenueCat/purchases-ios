//
//  StoreKitRequestFetcherTests.swift
//  PurchasesTests
//
//  Created by Jacob Eiting on 9/29/17.
//  Copyright © 2018 Purchases. All rights reserved.
//

import XCTest
import OHHTTPStubs
import Nimble
import StoreKit

import Purchases

@available(iOS 11.2, *)
class MockDiscount: SKProductDiscount {
    override var paymentMode: SKProductDiscount.PaymentMode {
        return SKProductDiscount.PaymentMode.payAsYouGo
    }

    override var price: NSDecimalNumber {
        return 1.99 as NSDecimalNumber
    }
}

class MockProduct: SKProduct {

    var mockProductIdentifier: String

    init(mockProductIdentifier: String) {
        self.mockProductIdentifier = mockProductIdentifier
        super.init()
    }

    override var productIdentifier: String {
        return self.mockProductIdentifier
    }

    override var priceLocale: Locale {
        return Locale.current
    }

    override var price: NSDecimalNumber {
        return 2.99 as NSDecimalNumber
    }

    @available(iOS 11.2, *)
    override var introductoryPrice: SKProductDiscount? {
        return MockDiscount()
    }
}

class StoreKitRequestFetcher: XCTestCase {

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

    enum StoreKitError: Error {
        case unknown
    }

    class MockProductRequest: SKProductsRequest {
        var startCalled = false
        var requestedIdentifiers: Set<String>
        var fails = false

        override init(productIdentifiers: Set<String>) {
            self.requestedIdentifiers = productIdentifiers
            super.init()
        }

        override func start() {
            startCalled = true
            DispatchQueue.global(qos: .background).async {
                if (self.fails) {
                    self.delegate?.request!(self, didFailWithError: StoreKitError.unknown)
                } else {
                    self.delegate?.productsRequest(self, didReceive: MockProductResponse(productIdentifiers: self.requestedIdentifiers))
                }
            }
        }
    }

    class MockReceiptRequest: SKReceiptRefreshRequest {
        var startCalled = false
        var fails = false
        override func start() {
            startCalled = true
            DispatchQueue.global(qos: .background).async {
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

        init(fails: Bool) {
            self.fails = fails
        }

        var requests: [SKRequest] = []
        override func request(forProductIdentifiers identifiers: Set<String>) -> SKProductsRequest {
            let r = MockProductRequest(productIdentifiers:identifiers)
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

    var fetcher: RCStoreKitRequestFetcher?
    var factory: MockRequestsFactory?
    var products: [SKProduct]?
    var receiptFetched = false
    var receiptFetchedCallbackCount = 0

    func setupFetcher(fails: Bool) {
        self.factory = MockRequestsFactory(fails: fails)
        self.fetcher = RCStoreKitRequestFetcher(requestFactory: self.factory!)

        self.fetcher!.fetchProducts(["com.a.product"]) { (newProducts) in
            self.products = newProducts
        }

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
        expect(self.factory!.requests.count).toEventually(equal(2))
    }

    func testSetsTheRequestDelegate() {
        setupFetcher(fails: false)
        expect(self.factory!.requests[0].delegate).toEventually(be(self.fetcher), timeout: 1.0)
    }

    func testCallsStartOnRequest() {
        setupFetcher(fails: false)
        expect((self.factory!.requests[0] as! MockProductRequest).startCalled).toEventually(beTrue(), timeout: 1.0)
    }

    func testReturnsProducts() {
        setupFetcher(fails: false)
        expect(self.products).toEventuallyNot(beNil(), timeout: 1.0)
        expect(self.products?.count).toEventually(be(1), timeout: 1.0)
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
        
        self.fetcher!.fetchReceiptData {
            fetchedAgain = true
        }
        
        expect(fetchedAgain).toEventually(beTrue())
        
        expect(self.factory?.requests).to(haveCount(3))
    }
    
}
