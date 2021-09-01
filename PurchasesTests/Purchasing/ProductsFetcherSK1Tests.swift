import XCTest
import Nimble
import StoreKit

@testable import RevenueCat

class ProductsFetcherSK1Tests: XCTestCase {
    var productsRequestFactory: MockProductsRequestFactory!
    var productsFetcherSK1: ProductsFetcherSK1!

    override func setUp() {
        super.setUp()
        productsRequestFactory = MockProductsRequestFactory()
        productsFetcherSK1 = ProductsFetcherSK1(productsRequestFactory: productsRequestFactory)
    }

    func testProductsWithIdentifiersMakesRightRequest() {
        let productIdentifiers = Set(["1", "2", "3"])
        productsFetcherSK1.sk1Products(withIdentifiers: productIdentifiers) { _ in }
        expect(self.productsRequestFactory.invokedRequestCount).toEventually(equal(1))
        expect(self.productsRequestFactory.invokedRequestParameters) == productIdentifiers
    }

    func testProductsWithIdentifiersCallsCompletionCorrectly() throws {
        let productIdentifiers = Set(["1", "2", "3"])
        var maybeReceivedProducts: Set<SKProduct>?
        var completionCalled = false

        productsFetcherSK1.sk1Products(withIdentifiers: productIdentifiers) { products in
            completionCalled = true
            maybeReceivedProducts = products
        }

        expect(completionCalled).toEventually(beTrue())
        let receivedProducts = try XCTUnwrap(maybeReceivedProducts)
        expect(receivedProducts.count) == productIdentifiers.count
        let receivedProductsSet = Set(receivedProducts.map { $0.productIdentifier })
        expect(receivedProductsSet) == productIdentifiers
    }

    func testProductsWithIdentifiersReturnsFromCacheIfProductsAlreadyCached() {
        let productIdentifiers = Set(["1", "2", "3"])
        var completionCallCount = 0

        productsFetcherSK1.sk1Products(withIdentifiers: productIdentifiers) { products in
            completionCallCount += 1

            self.productsFetcherSK1.sk1Products(withIdentifiers: productIdentifiers) { products in
                completionCallCount += 1
            }
        }

        expect(completionCallCount).toEventually(equal(2))
        expect(self.productsRequestFactory.invokedRequestCount).toEventually(equal(1))
        expect(self.productsRequestFactory.invokedRequestParameters) == productIdentifiers
    }

    func testProductsWithIdentifiersReturnsDoesntMakeNewRequestIfProductsAreBeingFetched() {
        let productIdentifiers = Set(["1", "2", "3"])

        productsFetcherSK1.sk1Products(withIdentifiers: productIdentifiers) { _ in }
        productsFetcherSK1.sk1Products(withIdentifiers: productIdentifiers) { _ in }

        expect(self.productsRequestFactory.invokedRequestCount).toEventually(equal(1))
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
        expect(self.productsRequestFactory.invokedRequestCount).toEventually(equal(0))
    }

    func testProductsWithIdentifiersReturnsErrorAndEmptySetIfRequestFails() {
        let productIdentifiers = Set(["1", "2", "3"])

        let failingRequest = MockProductsRequest(productIdentifiers: productIdentifiers)
        failingRequest.fails = true
        productsRequestFactory.stubbedRequestResult = failingRequest

        var receivedProducts: Set<SKProduct>?
        var completionCalled = false

        productsFetcherSK1.sk1Products(withIdentifiers: productIdentifiers) { products in
            completionCalled = true
            receivedProducts = products
        }
        expect(completionCalled).toEventually(beTrue())
        expect(receivedProducts).to(beEmpty())
    }
    
    func testCacheProductCachesCorrectly() {
        let productIdentifiers = Set(["1", "2", "3"])
        let mockProducts:Set<SKProduct> = Set(productIdentifiers.map {
            MockSKProduct(mockProductIdentifier: $0)
        })

        mockProducts.forEach { productsFetcherSK1.cacheProduct($0) }

        var completionCallCount = 0
        var receivedProducts: Set<SKProduct>?

        productsFetcherSK1.sk1Products(withIdentifiers: productIdentifiers) { products in
            completionCallCount += 1
            receivedProducts = products
        }

        expect(completionCallCount).toEventually(equal(1))
        expect(self.productsRequestFactory.invokedRequestCount).toEventually(equal(0))
        expect(receivedProducts) == mockProducts
    }
}
