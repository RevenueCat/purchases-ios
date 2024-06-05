import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class ProductsFetcherSK1Tests: TestCase {
    var productsRequestFactory: MockProductsRequestFactory!
    var productsFetcherSK1: ProductsFetcherSK1!

    private static let defaultTimeout: TimeInterval = 2
    private static let defaultTimeoutInterval: DispatchTimeInterval = .init(ProductsFetcherSK1Tests.defaultTimeout)

    override func setUp() {
        super.setUp()
        productsRequestFactory = MockProductsRequestFactory()
        productsFetcherSK1 = ProductsFetcherSK1(productsRequestFactory: productsRequestFactory,
                                                requestTimeout: Self.defaultTimeout)
    }

    func testProductsWithIdentifiersMakesRightRequest() {
        let productIdentifiers = Set(["1", "2", "3"])
        productsFetcherSK1.products(withIdentifiers: productIdentifiers) { _ in }
        expect(self.productsRequestFactory.invokedRequestCount).toEventually(equal(1))
        expect(self.productsRequestFactory.invokedRequestParameters) == productIdentifiers
    }

    func testProductsWithIdentifiersCallsCompletionCorrectly() throws {
        let productIdentifiers = Set(["1", "2", "3"])
        var receivedProducts: Result<Set<SK1StoreProduct>, PurchasesError>?

        productsFetcherSK1.products(withIdentifiers: productIdentifiers) { products in
            receivedProducts = products
        }

        expect(receivedProducts).toEventuallyNot(beNil(), timeout: Self.defaultTimeoutInterval)

        let unwrappedProducts = try XCTUnwrap(receivedProducts?.get())
        expect(unwrappedProducts).to(haveCount(productIdentifiers.count))
        let receivedProductsSet = Set(unwrappedProducts.map { $0.productIdentifier })
        expect(receivedProductsSet) == productIdentifiers
    }

    func testProductsWithIdentifiersReturnsFromCacheIfProductsAlreadyCached() {
        let productIdentifiers = Set(["1", "2", "3"])
        var completionCallCount = 0

        productsFetcherSK1.products(withIdentifiers: productIdentifiers) { _ in
            completionCallCount += 1

            self.productsFetcherSK1.products(withIdentifiers: productIdentifiers) { _ in
                completionCallCount += 1
            }
        }

        expect(completionCallCount).toEventually(equal(2), timeout: Self.defaultTimeoutInterval)
        expect(self.productsRequestFactory.invokedRequestCount).toEventually(equal(1))
        expect(self.productsRequestFactory.invokedRequestParameters) == productIdentifiers
    }

    func testProductsWithIdentifiersReturnsDoesntMakeNewRequestIfProductsAreBeingFetched() {
        let productIdentifiers = Set(["1", "2", "3"])

        productsFetcherSK1.products(withIdentifiers: productIdentifiers) { _ in }
        productsFetcherSK1.products(withIdentifiers: productIdentifiers) { _ in }

        expect(self.productsRequestFactory.invokedRequestCount).toEventually(equal(1),
                                                                             timeout: Self.defaultTimeoutInterval)
        expect(self.productsRequestFactory.invokedRequestParameters) == productIdentifiers
    }

    func testProductsWithIdentifiersMakesNewRequestIfAtLeastOneNewProductRequested() {
        let firstCallProducts = Set(["1", "2", "3"])
        let secondCallProducts = Set(["1", "2", "3", "4"])
        productsFetcherSK1.products(withIdentifiers: firstCallProducts) { _ in }
        productsFetcherSK1.products(withIdentifiers: secondCallProducts) { _ in }

        expect(self.productsRequestFactory.invokedRequestCount).toEventually(equal(2))
        expect(self.productsRequestFactory.invokedRequestParametersList) == [firstCallProducts, secondCallProducts]
    }

    func testProductsWithIdentifiersReturnsDoesntMakeNewRequestIfProductIdentifiersEmpty() {
        productsFetcherSK1.products(withIdentifiers: []) { _ in }
        expect(self.productsRequestFactory.invokedRequestCount).toEventually(equal(0),
                                                                             timeout: Self.defaultTimeoutInterval)
    }

    func testProductsWithIdentifiersReturnsErrorAndEmptySetIfRequestFails() {
        let productIdentifiers = Set(["1", "2", "3"])

        let failingRequest = MockProductsRequest(productIdentifiers: productIdentifiers)
        failingRequest.fails = true
        productsRequestFactory.stubbedRequestResult = failingRequest

        // This test checks errors, so no need to wait long for the retry mechanism
        let timeout: DispatchTimeInterval = .milliseconds(10)

        let fetcher = ProductsFetcherSK1(productsRequestFactory: productsRequestFactory,
                                         requestTimeout: timeout.seconds)

        var receivedResult: Result<Set<SK1StoreProduct>, PurchasesError>?

        fetcher.products(withIdentifiers: productIdentifiers) { result in
            receivedResult = result
        }

        expect(receivedResult).toEventuallyNot(beNil(), timeout: timeout + .seconds(1))
        expect(receivedResult).to(beFailure())
    }

    func testCacheProductCachesCorrectly() {
        let productIdentifiers = Set(["1", "2", "3"])
        let mockProducts: Set<SK1StoreProduct> = Set(productIdentifiers.map {
            SK1StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: $0))
        })

        mockProducts.forEach { self.productsFetcherSK1.cacheProduct($0.underlyingSK1Product) }

        var completionCallCount = 0
        var receivedProducts: Result<Set<SK1StoreProduct>, PurchasesError>?

        productsFetcherSK1.products(withIdentifiers: productIdentifiers) { products in
            receivedProducts = products
            completionCallCount += 1
        }

        expect(completionCallCount).toEventually(equal(1), timeout: Self.defaultTimeoutInterval)
        expect(self.productsRequestFactory.invokedRequestCount).toEventually(equal(0))
        expect(try receivedProducts?.get()) == mockProducts
    }

    func testProductsWithIdentifiersTimesOutIfMaxToleranceExceeded() throws {
        let productIdentifiers = Set(["1", "2", "3"])
        let tolerance: DispatchTimeInterval = .milliseconds(10)
        let productsRequestResponseTime: DispatchTimeInterval = tolerance + .milliseconds(10)
        let request = MockProductsRequest(productIdentifiers: productIdentifiers,
                                          responseTime: productsRequestResponseTime)
        productsRequestFactory.stubbedRequestResult = request

        productsFetcherSK1 = ProductsFetcherSK1(productsRequestFactory: productsRequestFactory,
                                                requestTimeout: tolerance.seconds)

        var completionCallCount = 0
        var receivedResult: Result<Set<SK1StoreProduct>, PurchasesError>?

        productsFetcherSK1.products(withIdentifiers: productIdentifiers) { result in
            receivedResult = result
            completionCallCount += 1
        }

        expect(completionCallCount).toEventually(equal(1),
                                                 timeout: productsRequestResponseTime + .milliseconds(30))
        expect(self.productsRequestFactory.invokedRequestCount) == 1

        expect(receivedResult).to(beFailure())
        expect(receivedResult?.error).to(matchError(ErrorCode.productRequestTimedOut))
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
                                                requestTimeout: tolerance.seconds)

        var completionCallCount = 0
        var receivedResult: Result<Set<SK1StoreProduct>, PurchasesError>?

        productsFetcherSK1.products(withIdentifiers: productIdentifiers) { result in
            receivedResult = result
            completionCallCount += 1
        }

        expect(completionCallCount).toEventually(equal(1), timeout: tolerance + .milliseconds(10))
        expect(self.productsRequestFactory.invokedRequestCount) == 1

        let unwrappedProducts = try XCTUnwrap(receivedResult).get()
        expect(unwrappedProducts).toNot(beEmpty())
        expect(request.cancelCalled) == false
    }

    func testMakesNewRequestAfterClearingCachedProductCorrectly() {
        let productIdentifiers = Set(["1", "2", "3"])
        let mockProducts: Set<SK1Product> = Set(productIdentifiers.map {
            MockSK1Product(mockProductIdentifier: $0)
        })

        mockProducts.forEach(self.productsFetcherSK1.cacheProduct)

        productsFetcherSK1.clearCache()

        productsFetcherSK1.products(withIdentifiers: productIdentifiers) { _ in }

        expect(self.productsRequestFactory.invokedRequestCount).toEventually(equal(1),
                                                                             timeout: Self.defaultTimeoutInterval)
        expect(self.productsRequestFactory.invokedRequestParameters) == productIdentifiers
    }

}
