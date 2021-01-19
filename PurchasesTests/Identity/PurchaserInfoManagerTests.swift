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

        let expectedInvocationsOnMainThread = 2 // one for the delegate, one for completion
        expect(self.mockOperationDispatcher.invokedDispatchOnMainThreadCount) == expectedInvocationsOnMainThread
    }

    func testFetchAndCachePurchaserInfoIfStaleOnlyRefreshesCacheOnce() {
        mockDeviceCache.stubbedIsPurchaserInfoCacheStale = true
        var firstCompletionCalled = false
        var secondCompletionCalled = false

        let appUserID = "myUser"
        purchaserInfoManager.fetchAndCachePurchaserInfoIfStale(withAppUserID: appUserID,
                                                               isAppBackgrounded: false) { purchaserInfo, error in
            firstCompletionCalled = true
        }
        mockDeviceCache.stubbedIsPurchaserInfoCacheStale = false
        purchaserInfoManager.cachePurchaserInfo(mockPurchaserInfo, forAppUserID: appUserID)
        purchaserInfoManager.fetchAndCachePurchaserInfoIfStale(withAppUserID: appUserID,
                                                               isAppBackgrounded: false) { purchaserInfo, error in
            secondCompletionCalled = true
        }

        expect(firstCompletionCalled).toEventually(beTrue())
        expect(secondCompletionCalled).toEventually(beTrue())
        expect(self.mockBackend.invokedGetSubscriberDataCount).toEventually(equal(1))
    }

    func testFetchAndCachePurchaserInfoIfStaleFetchesIfStale() {
        let appUserID = "myUser"
        purchaserInfoManager.cachePurchaserInfo(mockPurchaserInfo, forAppUserID: appUserID)
        mockDeviceCache.stubbedIsPurchaserInfoCacheStale = true
        var completionCalled = false

        purchaserInfoManager.fetchAndCachePurchaserInfoIfStale(withAppUserID: appUserID,
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

    func testSendCachedPurchaserInfoIfAvailableForAppUserIDSendsIfNeverSent() {
        let info = Purchases.PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:]
            ]]);

        let jsonObject = info!.jsonObject()

        let object = try! JSONSerialization.data(withJSONObject: jsonObject, options: [])
        let appUserID = "myUser"
        self.mockDeviceCache.cachedPurchaserInfo[appUserID] = object

        purchaserInfoManager.sendCachedPurchaserInfoIfAvailable(forAppUserID: appUserID)

        expect(self.purchaserInfoManagerDelegateCallCount) == 1
    }

    func testSendCachedPurchaserInfoIfAvailableForAppUserIDSendsIfDifferent() {
        let oldInfo = Purchases.PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:]
            ]]);

        var jsonObject = oldInfo!.jsonObject()

        var object = try! JSONSerialization.data(withJSONObject: jsonObject, options: [])
        let appUserID = "myUser"
        mockDeviceCache.cachedPurchaserInfo[appUserID] = object

        purchaserInfoManager.sendCachedPurchaserInfoIfAvailable(forAppUserID: appUserID)

        let newInfo = Purchases.PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": ["product_a": ["expires_date": "2018-05-27T06:24:50Z", "period_type": "normal"]],
                "other_purchases": [:]
            ]]);

        jsonObject = newInfo!.jsonObject()

        object = try! JSONSerialization.data(withJSONObject: jsonObject, options: [])
        mockDeviceCache.cachedPurchaserInfo[appUserID] = object

        purchaserInfoManager.sendCachedPurchaserInfoIfAvailable(forAppUserID: appUserID)
        expect(self.purchaserInfoManagerDelegateCallCount) == 2
    }

    func testSendCachedPurchaserInfoIfAvailableForAppUserIDSendsOnMainThread() {
        let oldInfo = Purchases.PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:]
            ]]);

        let jsonObject = oldInfo!.jsonObject()

        let object = try! JSONSerialization.data(withJSONObject: jsonObject, options: [])
        let appUserID = "myUser"
        mockDeviceCache.cachedPurchaserInfo[appUserID] = object

        purchaserInfoManager.sendCachedPurchaserInfoIfAvailable(forAppUserID: appUserID)
        expect(self.mockOperationDispatcher.invokedDispatchOnMainThreadCount) == 1
    }

    func testPurchaserInfoReturnsFromCacheIfAvailable() {
        let appUserID = "myUser"
        purchaserInfoManager.cachePurchaserInfo(mockPurchaserInfo, forAppUserID: appUserID)

        var completionCalled = false
        var receivedPurchaserInfo: Purchases.PurchaserInfo?
        var receivedError: Error?
        purchaserInfoManager.purchaserInfo(withAppUserID: appUserID) { purchaserInfo, error in
            completionCalled = true
            receivedPurchaserInfo = purchaserInfo
            receivedError = error
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.mockBackend.invokedGetSubscriberDataCount) == 0
        expect(receivedPurchaserInfo).toNot(beNil())
        expect(receivedPurchaserInfo) == mockPurchaserInfo
        expect(receivedError).to(beNil())
    }

    func testPurchaserInfoReturnsFromCacheAndRefreshesIfStale() {
        let appUserID = "myUser"
        mockDeviceCache.stubbedIsPurchaserInfoCacheStale = true
        purchaserInfoManager.cachePurchaserInfo(mockPurchaserInfo, forAppUserID: appUserID)

        var completionCalled = false
        purchaserInfoManager.purchaserInfo(withAppUserID: appUserID) { purchaserInfo, error in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
    }

    func testPurchaserInfoFetchesIfNoCache() {
        let appUserID = "myUser"

        var completionCalled = false
        purchaserInfoManager.purchaserInfo(withAppUserID: appUserID) { purchaserInfo, error in
            completionCalled = true

            // checking here to ensure that completion gets called from the backend call
            expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
        }

        expect(completionCalled).toEventually(beTrue())
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