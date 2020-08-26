import XCTest
import Nimble
import StoreKit

@testable import PurchasesCoreSwift

class ProductsManagerTests: XCTestCase {
    var productsRequestFactory: MockProductsRequestFactory!
    var productsManager: ProductsManager!

    override func setUp() {
        super.setUp()
        productsRequestFactory = MockProductsRequestFactory()
        productsManager = ProductsManager(productsRequestFactory: productsRequestFactory)
    }

    func testProductsWithIdentifiersMakesRightRequest() {
        let productIdentifiers = Set(["1", "2", "3"])
        productsManager.products(withIdentifiers: productIdentifiers) { _ in }
        expect(self.productsRequestFactory.invokedRequestCount).toEventually(equal(1))
        expect(self.productsRequestFactory.invokedRequestParameters) == productIdentifiers
    }

    func testProductsWithIdentifiersCallsCompletionCorrectly() {
        let productIdentifiers = Set(["1", "2", "3"])
        var receivedProducts: Set<SKProduct>?
        var completionCalled = false

        productsManager.products(withIdentifiers: productIdentifiers) { products in
            completionCalled = true
            receivedProducts = products
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedProducts?.count) == productIdentifiers.count
        let receivedProductsSet = Set(receivedProducts!.map { $0.productIdentifier })
        expect(receivedProductsSet) == productIdentifiers
    }

    func testProductsWithIdentifiersReturnsFromCacheIfProductsAlreadyCached() {
        let productIdentifiers = Set(["1", "2", "3"])
        var completionCallCount = 0

        productsManager.products(withIdentifiers: productIdentifiers) { products in
            completionCallCount += 1

            self.productsManager.products(withIdentifiers: productIdentifiers) { products in
                completionCallCount += 1
            }
        }

        expect(completionCallCount).toEventually(equal(2))
        expect(self.productsRequestFactory.invokedRequestCount).toEventually(equal(1))
        expect(self.productsRequestFactory.invokedRequestParameters) == productIdentifiers
    }

    func testProductsWithIdentifiersReturnsDoesntMakeNewRequestIfProductsAreBeingFetched() {
        let productIdentifiers = Set(["1", "2", "3"])

        productsManager.products(withIdentifiers: productIdentifiers) { _ in }
        productsManager.products(withIdentifiers: productIdentifiers) { _ in }

        expect(self.productsRequestFactory.invokedRequestCount).toEventually(equal(1))
        expect(self.productsRequestFactory.invokedRequestParameters) == productIdentifiers
    }

    func testProductsWithIdentifiersMakesNewRequestIfAtLeastOneNewProductRequested() {
        let firstCallProducts = Set(["1", "2", "3"])
        let secondCallProducts = Set(["1", "2", "3", "4"])
        productsManager.products(withIdentifiers: firstCallProducts) { _ in }
        productsManager.products(withIdentifiers: secondCallProducts) { _ in }

        expect(self.productsRequestFactory.invokedRequestCount).toEventually(equal(2))
        expect(self.productsRequestFactory.invokedRequestParametersList) == [firstCallProducts, secondCallProducts]
    }

    func testProductsWithIdentifiersReturnsErrorAndEmptySetIfRequestFails() {
        let productIdentifiers = Set(["1", "2", "3"])

        let failingRequest = MockProductsRequest(productIdentifiers: productIdentifiers)
        failingRequest.fails = true
        productsRequestFactory.stubbedRequestResult = failingRequest

        var receivedProducts: Set<SKProduct>?
        var completionCalled = false

        productsManager.products(withIdentifiers: productIdentifiers) { products in
            completionCalled = true
            receivedProducts = products
        }
        expect(completionCalled).toEventually(beTrue())
        expect(receivedProducts).to(beEmpty())
    }
}
