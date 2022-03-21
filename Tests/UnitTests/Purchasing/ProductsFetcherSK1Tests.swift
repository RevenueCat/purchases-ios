import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class ProductsFetcherSK1Tests: XCTestCase {
    var productsRequestFactory: MockProductsRequestFactory!
    var productsFetcherSK1: ProductsFetcherSK1!

    private static let defaultTimeout: DispatchTimeInterval = .seconds(5)

    override func setUp() {
        super.setUp()
        productsRequestFactory = MockProductsRequestFactory()
        productsFetcherSK1 = ProductsFetcherSK1(productsRequestFactory: productsRequestFactory,
                                                requestTimeout: Self.defaultTimeout)
    }

    func testProductsWithIdentifiersMakesRightRequest() {
        let productIdentifiers = Set(["1", "2", "3"])
        productsFetcherSK1.sk1Products(withIdentifiers: productIdentifiers) { _ in }
        expect(self.productsRequestFactory.invokedRequestCount).toEventually(equal(1))
        expect(self.productsRequestFactory.invokedRequestParameters) == productIdentifiers
    }

    func testProductsWithIdentifiersCallsCompletionCorrectly() throws {
        let productIdentifiers = Set(["1", "2", "3"])
        var receivedProducts: Result<Set<SK1Product>, Error>?
        var completionCalled = false

        productsFetcherSK1.sk1Products(withIdentifiers: productIdentifiers) { products in
            completionCalled = true
            receivedProducts = products
        }

        expect(completionCalled).toEventually(beTrue(), timeout: Self.defaultTimeout)
        let unwrappedProducts = try XCTUnwrap(receivedProducts?.get())
        expect(unwrappedProducts.count) == productIdentifiers.count
        let receivedProductsSet = Set(unwrappedProducts.map { $0.productIdentifier })
        expect(receivedProductsSet) == productIdentifiers
    }

    func testProductsWithIdentifiersReturnsFromCacheIfProductsAlreadyCached() {
        let productIdentifiers = Set(["1", "2", "3"])
        var completionCallCount = 0

        productsFetcherSK1.sk1Products(withIdentifiers: productIdentifiers) { _ in
            completionCallCount += 1

            self.productsFetcherSK1.sk1Products(withIdentifiers: productIdentifiers) { _ in
                completionCallCount += 1
            }
        }

        expect(completionCallCount).toEventually(equal(2), timeout: Self.defaultTimeout)
        expect(self.productsRequestFactory.invokedRequestCount).toEventually(equal(1))
        expect(self.productsRequestFactory.invokedRequestParameters) == productIdentifiers
    }

    func testProductsWithIdentifiersReturnsDoesntMakeNewRequestIfProductsAreBeingFetched() {
        let productIdentifiers = Set(["1", "2", "3"])

        productsFetcherSK1.sk1Products(withIdentifiers: productIdentifiers) { _ in }
        productsFetcherSK1.sk1Products(withIdentifiers: productIdentifiers) { _ in }

        expect(self.productsRequestFactory.invokedRequestCount).toEventually(equal(1), timeout: Self.defaultTimeout)
        expect(self.productsRequestFactory.invokedRequestParameters) == productIdentifiers
    }

    func testProductsWithIdentifiersMakesNewRequestIfAtLeastOneNewProductRequested() {
        let firstCallProducts = Set(["1", "2", "3"])
        let secondCallProducts = Set(["1", "2", "3", "4"])
        productsFetcherSK1.sk1Products(withIdentifiers: firstCallProducts) { _ in }
        productsFetcherSK1.sk1Products(withIdentifiers: secondCallProducts) { _ in }

        expect(self.productsRequestFactory.invokedRequestCount).toEventually(equal(2))
        expect(self.productsRequestFactory.invokedRequestParametersList) == [firstCallProducts, secondCallProducts]
    }

    func testProductsWithIdentifiersReturnsDoesntMakeNewRequestIfProductIdentifiersEmpty() {
        productsFetcherSK1.sk1Products(withIdentifiers: []) { _ in }
        expect(self.productsRequestFactory.invokedRequestCount).toEventually(equal(0), timeout: Self.defaultTimeout)
    }

    func testProductsWithIdentifiersReturnsErrorAndEmptySetIfRequestFails() {
        let productIdentifiers = Set(["1", "2", "3"])

        let failingRequest = MockProductsRequest(productIdentifiers: productIdentifiers)
        failingRequest.fails = true
        productsRequestFactory.stubbedRequestResult = failingRequest

        // This test checks errors, so no need to wait long for the retry mechanism
        let timeout: DispatchTimeInterval = .milliseconds(10)

        let fetcher = ProductsFetcherSK1(productsRequestFactory: productsRequestFactory,
                                         requestTimeout: timeout)

        var receivedResult: Result<Set<SK1Product>, Error>?
        var completionCalled = false

        fetcher.sk1Products(withIdentifiers: productIdentifiers) { result in
            completionCalled = true
            receivedResult = result
        }
        expect(completionCalled).toEventually(beTrue(), timeout: timeout + .seconds(1))
        expect(receivedResult?.error).toNot(beNil())
    }

    func testCacheProductCachesCorrectly() {
        let productIdentifiers = Set(["1", "2", "3"])
        let mockProducts: Set<SK1Product> = Set(productIdentifiers.map {
            MockSK1Product(mockProductIdentifier: $0)
        })

        mockProducts.forEach { productsFetcherSK1.cacheProduct($0) }

        var completionCallCount = 0
        var receivedProducts: Result<Set<SK1Product>, Error>?

        productsFetcherSK1.sk1Products(withIdentifiers: productIdentifiers) { products in
            completionCallCount += 1
            receivedProducts = products
        }

        expect(completionCallCount).toEventually(equal(1), timeout: Self.defaultTimeout)
        expect(self.productsRequestFactory.invokedRequestCount).toEventually(equal(0))
        try expect(receivedProducts?.get()) == mockProducts
    }

    func testProductsWithIdentifiersTimesOutIfMaxToleranceExceeded() throws {
        let productIdentifiers = Set(["1", "2", "3"])
        let tolerance: DispatchTimeInterval = .milliseconds(10)
        let productsRequestResponseTime: DispatchTimeInterval = tolerance + .milliseconds(10)
        let request = MockProductsRequest(productIdentifiers: productIdentifiers,
                                          responseTime: productsRequestResponseTime)
        productsRequestFactory.stubbedRequestResult = request

        productsFetcherSK1 = ProductsFetcherSK1(productsRequestFactory: productsRequestFactory,
                                                requestTimeout: tolerance)

        var completionCallCount = 0
        var receivedResult: Result<Set<SKProduct>, Error>?

        productsFetcherSK1.sk1Products(withIdentifiers: productIdentifiers) { result in
            completionCallCount += 1
            receivedResult = result
        }

        expect(completionCallCount).toEventually(equal(1),
                                                 timeout: productsRequestResponseTime + .milliseconds(10))
        expect(self.productsRequestFactory.invokedRequestCount) == 1

        let error = try XCTUnwrap(receivedResult?.error as? ErrorCode)
        expect(error) == ErrorCode.productRequestTimedOut
        expect(request.cancelCalled) == true
    }

    func testProductsWithIdentifiersDoesntTimeOutIfRequestReturnsOnTime() throws {
        let productIdentifiers = Set(["1", "2", "3"])
        let tolerance: DispatchTimeInterval = .milliseconds(50)
        let productsRequestResponseTime: DispatchTimeInterval = .milliseconds(10)
        let request = MockProductsRequest(productIdentifiers: productIdentifiers,
                                          responseTime: productsRequestResponseTime)
        productsRequestFactory.stubbedRequestResult = request

        productsFetcherSK1 = ProductsFetcherSK1(productsRequestFactory: productsRequestFactory,
                                                requestTimeout: tolerance)

        var completionCallCount = 0
        var receivedResult: Result<Set<SKProduct>, Error>?

        productsFetcherSK1.sk1Products(withIdentifiers: productIdentifiers) { result in
            completionCallCount += 1
            receivedResult = result
        }

        expect(completionCallCount).toEventually(equal(1), timeout: tolerance + .milliseconds(10))
        expect(self.productsRequestFactory.invokedRequestCount) == 1

        let unwrappedProducts = try XCTUnwrap(receivedResult).get()
        expect(unwrappedProducts).toNot(beEmpty())
        expect(request.cancelCalled) == false
    }

}
