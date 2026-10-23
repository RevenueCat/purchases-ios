import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class ProductsFetcherSK1Tests: TestCase {
    var productsRequestFactory: MockProductsRequestFactory!
    var productsFetcherSK1: ProductsFetcherSK1!

    private static let defaultTimeout: TimeInterval = 2
    private static let defaultTimeoutInterval: NimbleTimeInterval = defaultTimeout.nimbleInterval

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

    func testProductsWithIdentifiersRefetchesAfterCompletion() {
        let productIdentifiers = Set(["1", "2", "3"])
        let completionCallCount = Atomic(0)

        productsFetcherSK1.products(withIdentifiers: productIdentifiers) { _ in
            completionCallCount.modify { $0 += 1 }

            self.productsFetcherSK1.products(withIdentifiers: productIdentifiers) { _ in
                completionCallCount.modify { $0 += 1 }
            }
        }

        expect(completionCallCount.value).toEventually(equal(2), timeout: Self.defaultTimeoutInterval)
        expect(self.productsRequestFactory.invokedRequestCount).toEventually(equal(2))
        expect(self.productsRequestFactory.invokedRequestParameters) == productIdentifiers
    }

    func testConcurrentCallersShareRequestAndSuccessfulRetry() throws {
        let factory = DeferredProductsRequestFactory()
        let fetcher = ProductsFetcherSK1(productsRequestFactory: factory, requestTimeout: 4)
        let firstResults = Atomic<[Result<Set<SK1StoreProduct>, PurchasesError>]>([])
        let secondResults = Atomic<[Result<Set<SK1StoreProduct>, PurchasesError>]>([])
        fetcher.products(withIdentifiers: ["product"]) { result in firstResults.modify { $0.append(result) } }
        fetcher.products(withIdentifiers: ["product"]) { result in secondResults.modify { $0.append(result) } }
        let request = try factory.startedRequest(at: 0)
        request.fail()
        let retry = try factory.startedRequest(at: 1)
        let product = MockSK1Product(mockProductIdentifier: "product")
        retry.succeed(with: [product])

        expect(firstResults.value).toEventually(haveCount(1))
        expect(secondResults.value).toEventually(haveCount(1))
        expect(try firstResults.value.first?.get().onlyElement?.underlyingSK1Product) === product
        expect(try secondResults.value.first?.get().onlyElement?.underlyingSK1Product) === product
        expect(factory.startedRequests).to(haveCount(2))
        expect(request.cancellationCount) == 1
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

    func testRetryExhaustionDoesNotCompleteRequestsStartedAfterInvalidation() throws {
        let factory = DeferredProductsRequestFactory()
        let manager = self.createCachingManager(factory: factory)
        let oldResults = Atomic<[Result<Set<StoreProduct>, PurchasesError>]>([])
        manager.products(withIdentifiers: ["product"]) { result in oldResults.modify { $0.append(result) } }
        let oldRequest = try factory.startedRequest(at: 0)

        manager.invalidate()
        let newResults = Atomic<[Result<Set<StoreProduct>, PurchasesError>]>([])
        manager.products(withIdentifiers: ["product"]) { result in newResults.modify { $0.append(result) } }
        let newRequest = try factory.startedRequest(at: 1)
        oldRequest.fail()

        // The original request gets ten retries, independent of the post-invalidation request.
        for index in 2...11 {
            let retry = try factory.startedRequest(at: index)
            expect(oldResults.value).to(beEmpty())
            retry.fail()
        }

        expect(oldResults.value).toEventually(haveCount(1))
        expect(oldResults.value.first?.error).to(matchError(ErrorCode.storeProblemError))
        expect(newResults.value).to(beEmpty())
        let newProduct = MockSK1Product(mockProductIdentifier: "product")
        newRequest.succeed(with: [newProduct])

        expect(newResults.value).toEventually(haveCount(1))
        expect(try newResults.value.first?.get().onlyElement?.sk1Product) === newProduct
        expect(factory.startedRequests).to(haveCount(12))
    }

    func testTimeoutCancelsActiveRetryAndLateResponseCannotCompleteNewRequest() throws {
        let factory = DeferredProductsRequestFactory()
        let fetcher = ProductsFetcherSK1(productsRequestFactory: factory, requestTimeout: 1)
        let firstResults = Atomic<[Result<Set<SK1StoreProduct>, PurchasesError>]>([])
        let secondResults = Atomic<[Result<Set<SK1StoreProduct>, PurchasesError>]>([])
        fetcher.products(withIdentifiers: ["product"]) { result in firstResults.modify { $0.append(result) } }
        fetcher.products(withIdentifiers: ["product"]) { result in secondResults.modify { $0.append(result) } }
        let request = try factory.startedRequest(at: 0)
        request.fail()
        let retry = try factory.startedRequest(at: 1)

        expect(firstResults.value).toEventually(haveCount(1), timeout: .seconds(2))
        expect(secondResults.value).toEventually(haveCount(1))
        expect(firstResults.value.first?.error).to(matchError(ErrorCode.productRequestTimedOut))
        expect(secondResults.value.first?.error).to(matchError(ErrorCode.productRequestTimedOut))
        expect(retry.cancellationCount) == 1

        let newResults = Atomic<[Result<Set<SK1StoreProduct>, PurchasesError>]>([])
        fetcher.products(withIdentifiers: ["product"]) { result in newResults.modify { $0.append(result) } }
        let newRequest = try factory.startedRequest(at: 2)
        let oldProduct = MockSK1Product(mockProductIdentifier: "product")
        let newProduct = MockSK1Product(mockProductIdentifier: "product")
        retry.succeed(with: [oldProduct])
        newRequest.succeed(with: [newProduct])

        expect(newResults.value).toEventually(haveCount(1))
        expect(try newResults.value.first?.get().onlyElement?.underlyingSK1Product) === newProduct
        expect(firstResults.value).to(haveCount(1))
        expect(secondResults.value).to(haveCount(1))
        expect(factory.startedRequests).to(haveCount(3))
    }

    func testTimeoutWhileWaitingForRetryCompletesCallersOnceAndDoesNotStartRetry() {
        let factory = DeferredProductsRequestFactory(failOnStart: true)
        // A five-second timeout gives each retry a one-second delay. Immediate failures keep the
        // request waiting between attempts until its original deadline expires.
        let fetcher = ProductsFetcherSK1(productsRequestFactory: factory, requestTimeout: 5)
        let firstResults = Atomic<[Result<Set<SK1StoreProduct>, PurchasesError>]>([])
        let secondResults = Atomic<[Result<Set<SK1StoreProduct>, PurchasesError>]>([])
        fetcher.products(withIdentifiers: ["product"]) { result in firstResults.modify { $0.append(result) } }
        fetcher.products(withIdentifiers: ["product"]) { result in secondResults.modify { $0.append(result) } }

        expect(firstResults.value).toEventually(haveCount(1), timeout: .seconds(6))
        expect(secondResults.value).toEventually(haveCount(1))
        expect(firstResults.value.first?.error).to(matchError(ErrorCode.productRequestTimedOut))
        expect(secondResults.value.first?.error).to(matchError(ErrorCode.productRequestTimedOut))
        let requestCountAtTimeout = factory.startedRequests.count
        expect(requestCountAtTimeout).to(beGreaterThan(1))
        expect(factory.startedRequests.map(\.cancellationCount)).to(allPass(equal(1)))

        // Observe beyond the queued retry's one-second delay, including duplicate completions.
        expect(factory.startedRequests).toAlways(haveCount(requestCountAtTimeout), until: .seconds(2))
        expect(firstResults.value).to(haveCount(1))
        expect(secondResults.value).to(haveCount(1))
    }

    func testOldRequestCompletionDoesNotPreventNewCallersFromJoiningCurrentRequest() throws {
        let factory = DeferredProductsRequestFactory()
        let fetcher = ProductsFetcherSK1(productsRequestFactory: factory, requestTimeout: 4)
        let oldResults = Atomic<[Result<Set<SK1StoreProduct>, PurchasesError>]>([])
        let currentResults = Atomic<[Result<Set<SK1StoreProduct>, PurchasesError>]>([])
        let joiningResults = Atomic<[Result<Set<SK1StoreProduct>, PurchasesError>]>([])
        fetcher.products(withIdentifiers: ["product"]) { result in oldResults.modify { $0.append(result) } }
        let oldRequest = try factory.startedRequest(at: 0)

        fetcher.invalidateRequests()
        fetcher.products(withIdentifiers: ["product"]) { result in currentResults.modify { $0.append(result) } }
        let currentRequest = try factory.startedRequest(at: 1)
        let oldProduct = MockSK1Product(mockProductIdentifier: "product")
        oldRequest.succeed(with: [oldProduct])
        expect(oldResults.value).toEventually(haveCount(1))
        expect(currentResults.value).to(beEmpty())

        fetcher.products(withIdentifiers: ["product"]) { result in joiningResults.modify { $0.append(result) } }
        let currentProduct = MockSK1Product(mockProductIdentifier: "product")
        currentRequest.succeed(with: [currentProduct])

        expect(currentResults.value).toEventually(haveCount(1))
        expect(joiningResults.value).toEventually(haveCount(1))
        expect(try oldResults.value.first?.get().onlyElement?.underlyingSK1Product) === oldProduct
        expect(try currentResults.value.first?.get().onlyElement?.underlyingSK1Product) === currentProduct
        expect(try joiningResults.value.first?.get().onlyElement?.underlyingSK1Product) === currentProduct
        expect(oldResults.value).to(haveCount(1))
        expect(factory.startedRequests).to(haveCount(2))
    }

    func testSuccessfulRetryDoesNotCompleteAgainAtOriginalTimeout() throws {
        let factory = DeferredProductsRequestFactory()
        let fetcher = ProductsFetcherSK1(productsRequestFactory: factory, requestTimeout: 0.5)
        let results = Atomic<[Result<Set<SK1StoreProduct>, PurchasesError>]>([])
        fetcher.products(withIdentifiers: ["product"]) { result in results.modify { $0.append(result) } }
        let request = try factory.startedRequest(at: 0)
        request.fail()
        let retry = try factory.startedRequest(at: 1)
        let product = MockSK1Product(mockProductIdentifier: "product")
        retry.succeed(with: [product])

        expect(results.value).toEventually(haveCount(1))
        expect(try results.value.first?.get().onlyElement?.underlyingSK1Product) === product
        expect(results.value).toAlways(haveCount(1), until: .seconds(1))
        expect(request.cancellationCount) == 1
        expect(retry.cancellationCount) == 1
    }

}

extension ProductsFetcherSK1Tests {

    func testLateSK1ResponseCannotRefillClearedProductCache() throws {
        let factory = DeferredProductsRequestFactory()
        let manager = self.createCachingManager(factory: factory)
        let oldProduct = MockSK1Product(mockProductIdentifier: "product")
        let newProduct = MockSK1Product(mockProductIdentifier: "product")
        let oldResult = Atomic<Result<Set<StoreProduct>, PurchasesError>?>(nil)
        manager.products(withIdentifiers: ["product"]) { oldResult.value = $0 }
        let oldRequest = try factory.startedRequest(at: 0)

        manager.invalidate()
        oldRequest.succeed(with: [oldProduct])
        expect(oldResult.value).toEventuallyNot(beNil())

        let newResult = Atomic<Result<Set<StoreProduct>, PurchasesError>?>(nil)
        manager.products(withIdentifiers: ["product"]) { newResult.value = $0 }
        let newRequest = try factory.startedRequest(at: 1)
        newRequest.succeed(with: [newProduct])

        expect(newResult.value).toEventuallyNot(beNil())
        expect(try oldResult.value?.get().onlyElement?.sk1Product) === oldProduct
        expect(try newResult.value?.get().onlyElement?.sk1Product) === newProduct
    }

    func testSK1InvalidationKeepsOldCallersAndStartsFreshRequest() throws {
        try self.verifyInvalidationDuringSK1Request(completeOldRequestFirst: true)
    }

    func testLateSK1ResponseCannotReplaceNewlyCachedProduct() throws {
        try self.verifyInvalidationDuringSK1Request(completeOldRequestFirst: false)
    }

    func testSK1RetryAfterInvalidationCompletesOnlyItsOriginalCallers() throws {
        let factory = DeferredProductsRequestFactory()
        let manager = self.createCachingManager(factory: factory)
        let oldProduct = MockSK1Product(mockProductIdentifier: "product")
        let newProduct = MockSK1Product(mockProductIdentifier: "product")
        let oldResults = Atomic<[Result<Set<StoreProduct>, PurchasesError>]>([])
        manager.products(withIdentifiers: ["product"]) { result in oldResults.modify { $0.append(result) } }
        let oldRequest = try factory.startedRequest(at: 0)

        manager.invalidate()
        let newResults = Atomic<[Result<Set<StoreProduct>, PurchasesError>]>([])
        manager.products(withIdentifiers: ["product"]) { result in newResults.modify { $0.append(result) } }
        let newRequest = try factory.startedRequest(at: 1)
        oldRequest.fail()
        let retry = try factory.startedRequest(at: 2)

        newRequest.succeed(with: [newProduct])
        retry.succeed(with: [oldProduct])

        expect(oldResults.value).toEventually(haveCount(1))
        expect(newResults.value).toEventually(haveCount(1))
        expect(try oldResults.value.first?.get().onlyElement?.sk1Product) === oldProduct
        expect(try newResults.value.first?.get().onlyElement?.sk1Product) === newProduct
        let cached = waitUntilValue { completed in
            manager.products(withIdentifiers: ["product"], completion: completed)
        }
        expect(try cached?.get().onlyElement?.sk1Product) === newProduct
        expect(factory.startedRequests).to(haveCount(3))
        expect(oldRequest.cancellationCount) == 1
    }

}

private extension ProductsFetcherSK1Tests {

    func createCachingManager(factory: ProductsRequestFactory) -> CachingProductsManager {
        return CachingProductsManager(manager: ProductsManager(
            productsRequestFactory: factory,
            diagnosticsTracker: nil,
            systemInfo: MockSystemInfo(finishTransactions: true, storeKitVersion: .storeKit1),
            requestTimeout: 4
        ))
    }

    func verifyInvalidationDuringSK1Request(completeOldRequestFirst: Bool) throws {
        let factory = DeferredProductsRequestFactory()
        let manager = self.createCachingManager(factory: factory)
        let oldProduct = MockSK1Product(mockProductIdentifier: "product")
        let newProduct = MockSK1Product(mockProductIdentifier: "product")
        let oldResults = Atomic<[Result<Set<StoreProduct>, PurchasesError>]>([])
        manager.products(withIdentifiers: ["product"]) { result in oldResults.modify { $0.append(result) } }
        let oldRequest = try factory.startedRequest(at: 0)

        manager.invalidate()
        let newResults = Atomic<[Result<Set<StoreProduct>, PurchasesError>]>([])
        manager.products(withIdentifiers: ["product"]) { result in newResults.modify { $0.append(result) } }
        let newRequest = try factory.startedRequest(at: 1)

        if completeOldRequestFirst {
            oldRequest.succeed(with: [oldProduct])
            expect(oldResults.value).toEventually(haveCount(1))
            expect(newResults.value).to(beEmpty())
            newRequest.succeed(with: [newProduct])
        } else {
            newRequest.succeed(with: [newProduct])
            expect(newResults.value).toEventually(haveCount(1))
            expect(oldResults.value).to(beEmpty())
            oldRequest.succeed(with: [oldProduct])
        }

        expect(oldResults.value).toEventually(haveCount(1))
        expect(newResults.value).toEventually(haveCount(1))
        expect(try oldResults.value.first?.get().onlyElement?.sk1Product) === oldProduct
        expect(try newResults.value.first?.get().onlyElement?.sk1Product) === newProduct
        let cached = waitUntilValue { completed in
            manager.products(withIdentifiers: ["product"], completion: completed)
        }
        expect(try cached?.get().onlyElement?.sk1Product) === newProduct
        expect(factory.startedRequests).to(haveCount(2))
    }

}

private final class DeferredProductsRequestFactory: ProductsRequestFactory, @unchecked Sendable {

    var startedRequests: [DeferredProductsRequest] {
        self.requests.value.filter { $0.hasStarted }
    }

    private let requests = Atomic<[DeferredProductsRequest]>([])
    private let failOnStart: Bool

    init(failOnStart: Bool = false) {
        self.failOnStart = failOnStart
        super.init()
    }

    override func request(productIdentifiers: Set<String>) -> SKProductsRequest {
        let request = DeferredProductsRequest(productIdentifiers: productIdentifiers, failOnStart: self.failOnStart)
        self.requests.modify { $0.append(request) }
        return request
    }

    func startedRequest(at index: Int) throws -> DeferredProductsRequest {
        expect(self.startedRequests.count).toEventually(beGreaterThan(index))
        return try XCTUnwrap(self.startedRequests.dropFirst(index).first)
    }

}

private final class DeferredProductsRequest: MockProductsRequest, @unchecked Sendable {

    var hasStarted: Bool { self.started.value }
    var cancellationCount: Int { self.cancellations.value }

    private let started: Atomic<Bool> = false
    private let cancellations = Atomic(0)
    private let failOnStart: Bool

    init(productIdentifiers: Set<String>, failOnStart: Bool) {
        self.failOnStart = failOnStart
        super.init(productIdentifiers: productIdentifiers)
    }

    override func start() {
        self.started.value = true
        if self.failOnStart {
            self.fail()
        }
    }

    override func cancel() {
        self.cancellations.modify { $0 += 1 }
    }

    func succeed(with products: [MockSK1Product]) {
        let response = MockProductResponse(productIdentifiers: [])
        response.mockProducts = products
        self.delegate?.productsRequest(self, didReceive: response)
        self.delegate?.requestDidFinish?(self)
    }

    func fail() {
        self.delegate?.request?(self, didFailWithError: SKError(.unknown))
    }

}
