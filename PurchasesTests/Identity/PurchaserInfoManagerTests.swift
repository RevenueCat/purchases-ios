import XCTest
import Nimble

@testable import Purchases

class PurchaserInfoManagerTests: XCTestCase {
    var mockBackend = MockBackend()
    var mockOperationDispatcher = MockOperationDispatcher()
    var mockDeviceCache = MockDeviceCache()
    var mockSystemInfo = MockSystemInfo(platformFlavor: nil, platformFlavorVersion: nil, finishTransactions: true)
    let mockPurchaserInfo = Purchases.PurchaserInfo(data: [
        "subscriber": [
            "subscriptions": [:],
            "other_purchases": [:],
            "original_application_version": NSNull()
        ]])!

    var purchaserInfoManager: PurchaserInfoManager!

    var purchaserInfoManagerDelegateCallCount = 0
    var purchaserInfoManagerDelegateCallPurchaserInfo: Purchases.PurchaserInfo?

    override func setUp() {
        super.setUp()
        purchaserInfoManagerDelegateCallCount = 0
        purchaserInfoManagerDelegateCallPurchaserInfo = nil
        purchaserInfoManager = PurchaserInfoManager(operationDispatcher: mockOperationDispatcher,
                                                    deviceCache: mockDeviceCache,
                                                    backend: mockBackend,
                                                    systemInfo: mockSystemInfo)
        purchaserInfoManager.delegate = self
    }

    func testFetchAndCachePurchaserInfoCallsBackendWithRandomDelayIfAppBackgrounded() {
        mockOperationDispatcher.shouldInvokeDispatchOnWorkerThreadBlock = true

        purchaserInfoManager.fetchAndCachePurchaserInfo(withAppUserID: "myUser",
                                                        isAppBackgrounded: true,
                                                        completion: nil)

        expect(self.mockOperationDispatcher.invokedDispatchOnWorkerThread).toEventually(beTrue())
        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
        expect(self.mockOperationDispatcher.invokedDispatchOnWorkerThreadRandomDelayParam) == true
    }

    func testFetchAndCachePurchaserInfoCallsBackendWithoutRandomDelayIfAppForegrounded() {
        mockOperationDispatcher.shouldInvokeDispatchOnWorkerThreadBlock = true

        purchaserInfoManager.fetchAndCachePurchaserInfo(withAppUserID: "myUser",
                                                        isAppBackgrounded: false,
                                                        completion: nil)

        expect(self.mockOperationDispatcher.invokedDispatchOnWorkerThread).toEventually(beTrue())
        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
        expect(self.mockOperationDispatcher.invokedDispatchOnWorkerThreadRandomDelayParam) == false
    }

    func testFetchAndCachePurchaserInfoPassesBackendErrors() {
        mockOperationDispatcher.shouldInvokeDispatchOnWorkerThreadBlock = true
        let mockError = NSError(domain: "revenuecat", code: 123)
        mockBackend.stubbedGetSubscriberDataError = mockError

        var completionCalled = false
        var receivedPurchaserInfo: Purchases.PurchaserInfo?
        var receivedError: Error?
        purchaserInfoManager.fetchAndCachePurchaserInfo(withAppUserID: "myUser",
                                                        isAppBackgrounded: false) { purchaserInfo, error in
            completionCalled = true
            receivedPurchaserInfo = purchaserInfo
            receivedError = error
        }
        expect(completionCalled).toEventually(beTrue())
        expect(receivedPurchaserInfo).to(beNil())
        expect(receivedError).toNot(beNil())
        let receivedNSError = receivedError! as NSError
        expect(receivedNSError) == mockError
    }

    func testFetchAndCachePurchaserInfoClearsPurchaserInfoTimestampIfBackendError() {
        mockOperationDispatcher.shouldInvokeDispatchOnWorkerThreadBlock = true
        mockBackend.stubbedGetSubscriberDataError = NSError(domain: "revenuecat", code: 123)

        var completionCalled = false
        purchaserInfoManager.fetchAndCachePurchaserInfo(withAppUserID: "myUser",
                                                        isAppBackgrounded: false) { purchaserInfo, error in
            completionCalled = true
        }
        expect(completionCalled).toEventually(beTrue())
        expect(self.mockDeviceCache.clearPurchaserInfoCacheTimestampCount) == 1
    }

    func testFetchAndCachePurchaserInfoCachesIfSuccessful() {
        mockOperationDispatcher.shouldInvokeDispatchOnWorkerThreadBlock = true
        mockOperationDispatcher.shouldInvokeDispatchOnMainThreadBlock = true
        mockBackend.stubbedGetSubscriberDataPurchaserInfo = mockPurchaserInfo

        var completionCalled = false
        var receivedPurchaserInfo: Purchases.PurchaserInfo?
        var receivedError: Error?
        purchaserInfoManager.fetchAndCachePurchaserInfo(withAppUserID: "myUser",
                                                        isAppBackgrounded: false) { purchaserInfo, error in
            completionCalled = true
            receivedPurchaserInfo = purchaserInfo
            receivedError = error
        }
        expect(completionCalled).toEventually(beTrue())
        expect(receivedPurchaserInfo) == mockPurchaserInfo
        expect(receivedError).to(beNil())

        expect(self.mockDeviceCache.cachePurchaserInfoCount) == 1
        expect(self.purchaserInfoManagerDelegateCallCount) == 1
        expect(self.purchaserInfoManagerDelegateCallPurchaserInfo) == mockPurchaserInfo
    }

    func testFetchAndCachePurchaserInfoCallsCompletionOnMainThread() {
        mockOperationDispatcher.shouldInvokeDispatchOnWorkerThreadBlock = true
        mockOperationDispatcher.shouldInvokeDispatchOnMainThreadBlock = true
        mockBackend.stubbedGetSubscriberDataPurchaserInfo = mockPurchaserInfo

        var completionCalled = false
        purchaserInfoManager.fetchAndCachePurchaserInfo(withAppUserID: "myUser",
                                                        isAppBackgrounded: false) { purchaserInfo, error in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())

        let expectedInvokationsOnMainThread = 2 // one for the delegate, one for completion
        expect(self.mockOperationDispatcher.invokedDispatchOnMainThreadCount) == expectedInvokationsOnMainThread
    }

    func testFetchAndCachePurchaserInfoIfStaleOnlyRefreshesCacheOnce() {
        mockDeviceCache.stubbedIsPurchaserInfoCacheStale = true
        var firstCompletionCalled = false
        var secondCompletionCalled = false

        purchaserInfoManager.fetchAndCachePurchaserInfoIfStale(withAppUserID: "myUser",
                                                               isAppBackgrounded: false) { purchaserInfo, error in
            firstCompletionCalled = true
        }
        mockDeviceCache.stubbedIsPurchaserInfoCacheStale = false
        purchaserInfoManager.cachePurchaserInfo(mockPurchaserInfo, forAppUserID: "myUser")
        purchaserInfoManager.fetchAndCachePurchaserInfoIfStale(withAppUserID: "myUser",
                                                               isAppBackgrounded: false) { purchaserInfo, error in
            secondCompletionCalled = true
        }

        expect(firstCompletionCalled).toEventually(beTrue())
        expect(secondCompletionCalled).toEventually(beTrue())
        expect(self.mockBackend.invokedGetSubscriberDataCount).toEventually(equal(1))
    }

    func testFetchAndCachePurchaserInfoIfStaleFetchesIfStale() {
        purchaserInfoManager.cachePurchaserInfo(mockPurchaserInfo, forAppUserID: "myUser")
        mockDeviceCache.stubbedIsPurchaserInfoCacheStale = true
        var completionCalled = false

        purchaserInfoManager.fetchAndCachePurchaserInfoIfStale(withAppUserID: "myUser",
                                                               isAppBackgrounded: false) { purchaserInfo, error in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.mockBackend.invokedGetSubscriberDataCount).toEventually(equal(1))
    }

    func testFetchAndCachePurchaserInfoIfStaleFetchesIfCacheEmpty() {
        mockDeviceCache.stubbedIsPurchaserInfoCacheStale = false
        var completionCalled = false

        purchaserInfoManager.fetchAndCachePurchaserInfoIfStale(withAppUserID: "myUser",
                                                               isAppBackgrounded: false) { purchaserInfo, error in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.mockBackend.invokedGetSubscriberDataCount).toEventually(equal(1))
    }

    func testSendUpdatedPurchaserInfoToDelegateIfChangedSendsIfNeverSent() {
        // TODO: implement
    }

    func testSendUpdatedPurchaserInfoToDelegateIfChangedSendsIfDifferent() {
        // TODO: implement
    }

    func testSendUpdatedPurchaserInfoToDelegateIfChangedSendsOnMainThread() {
        // TODO: implement
    }

    func testPurchaserInfoReturnsFromCacheIfAvailable() {
        // TODO: implement
    }

    func testPurchaserInfoReturnsFromCacheAndRefreshesIfStale() {
        // TODO: implement
    }

    func testPurchaserInfoFetchesIfNoCache() {
        // TODO: implement
    }

    func testCachedPurchaserInfoParsesCorrectly() {
        // TODO: implement
    }

    func testCachedPurchaserInfoReturnsNilIfNotAvailable() {
        // TODO: implement
    }

    func testCachedPurchaserInfoReturnsNilIfCantBeParsed() {
        // TODO: implement
    }

    func testCachedPurchaserInfoReturnsNilIfDifferentSchema() {
        // TODO: implement
    }

    func testCachePurchaserInfoStoresCorrectly() {
        // TODO: implement
    }

    func testCachePurchaserDoesntStoreIfEmpty() {
        // TODO: implement
    }

    func testCachePurchaserDoesntStoreNoJsonObject() {
        // TODO: implement
    }

    func testCachePurchaserDoesntStoreIfCantBeSerialized() {
        // TODO: implement
    }

    func testCachePurchaserSendsToDelegateIfChanged() {
        // TODO: implement
    }

    func testClearPurchaserInfoCacheClearsCorrectly() {
        // TODO: implement
    }

    func testClearPurchaserInfoCacheResetsLastSent() {
        // TODO: implement
    }
}

extension PurchaserInfoManagerTests: PurchaserInfoManagerDelegate {

    func purchaserInfoManagerDidReceiveUpdatedPurchaserInfo(_ purchaserInfo: Purchases.PurchaserInfo) {
        purchaserInfoManagerDelegateCallCount += 1
        purchaserInfoManagerDelegateCallPurchaserInfo = purchaserInfo
    }
}