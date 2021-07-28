import XCTest
import Nimble

@testable import Purchases

class PurchaserInfoManagerTests: XCTestCase {
    var mockBackend = MockBackend()
    var mockOperationDispatcher = MockOperationDispatcher()
    var mockDeviceCache: MockDeviceCache!
    var mockSystemInfo = try! MockSystemInfo(platformFlavor: nil, platformFlavorVersion: nil, finishTransactions: true)
    let mockPurchaserInfo = PurchaserInfo(data: [
        "request_date": "2018-12-21T02:40:36Z",
        "subscriber": [
            "original_app_user_id": "app_user_id",
            "first_seen": "2019-06-17T16:05:33Z",
            "subscriptions": [:],
            "other_purchases": [:],
            "original_application_version": NSNull()
        ]])!

    var purchaserInfoManager: PurchaserInfoManager!

    var purchaserInfoManagerDelegateCallCount = 0
    var purchaserInfoManagerDelegateCallPurchaserInfo: PurchaserInfo?

    override func setUp() {
        super.setUp()
        mockDeviceCache = MockDeviceCache()
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
        var receivedPurchaserInfo: PurchaserInfo?
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
        var receivedPurchaserInfo: PurchaserInfo?
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
        let info = PurchaserInfo(data: [
        "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "first_seen": "2019-06-17T16:05:33Z",
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
        let oldInfo = PurchaserInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": [:],
                "other_purchases": [:]
            ]]);

        var jsonObject = oldInfo!.jsonObject()

        var object = try! JSONSerialization.data(withJSONObject: jsonObject, options: [])
        let appUserID = "myUser"
        mockDeviceCache.cachedPurchaserInfo[appUserID] = object

        purchaserInfoManager.sendCachedPurchaserInfoIfAvailable(forAppUserID: appUserID)

        let newInfo = PurchaserInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "first_seen": "2019-06-17T16:05:33Z",
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
        let oldInfo = PurchaserInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "first_seen": "2019-06-17T16:05:33Z",
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
        var receivedPurchaserInfo: PurchaserInfo?
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
        let appUserID = "myUser"
        let info = PurchaserInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": ["product_a": ["expires_date": "2018-05-27T06:24:50Z", "period_type": "normal"]],
                "other_purchases": [:]
            ]]);

        let jsonObject = info!.jsonObject()

        let object = try! JSONSerialization.data(withJSONObject: jsonObject, options: [])
        mockDeviceCache.cachedPurchaserInfo[appUserID] = object

        let receivedPurchaserInfo = purchaserInfoManager.cachedPurchaserInfo(forAppUserID: appUserID)

        expect(receivedPurchaserInfo).toNot(beNil())
        expect(receivedPurchaserInfo!) == info
    }

    func testCachedPurchaserInfoReturnsNilIfNotAvailable() {
        let receivedPurchaserInfo = purchaserInfoManager.cachedPurchaserInfo(forAppUserID: "myUser")
        expect(receivedPurchaserInfo).to(beNil())
    }

    func testCachedPurchaserInfoReturnsNilIfNotAvailableForTheAppUserID() {
        let info = PurchaserInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": ["product_a": ["expires_date": "2018-05-27T06:24:50Z", "period_type": "normal"]],
                "other_purchases": [:]
            ]]);

        let jsonObject = info!.jsonObject()

        let object = try! JSONSerialization.data(withJSONObject: jsonObject, options: [])
        mockDeviceCache.cachedPurchaserInfo["firstUser"] = object

        let receivedPurchaserInfo = purchaserInfoManager.cachedPurchaserInfo(forAppUserID: "secondUser")
        expect(receivedPurchaserInfo).to(beNil())
    }

    func testCachedPurchaserInfoReturnsNilIfCantBeParsed() {
        let appUserID = "myUser"

        mockDeviceCache.cachedPurchaserInfo[appUserID] = Data()

        let receivedPurchaserInfo = purchaserInfoManager.cachedPurchaserInfo(forAppUserID: appUserID)
        expect(receivedPurchaserInfo).to(beNil())
    }

    func testCachedPurchaserInfoReturnsNilIfDifferentSchema() {
        let oldSchemaVersion = Int(PurchaserInfo.currentSchemaVersion)! - 1
        let data: [String: Any] = [
            "request_date": "2019-08-16T10:30:42Z",
            "schema_version": "\(oldSchemaVersion)",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": ["product_a": ["expires_date": "2018-05-27T06:24:50Z", "period_type": "normal"]],
                "other_purchases": [:]
            ]
        ]

        let object = try! JSONSerialization.data(withJSONObject: data, options: [])
        let appUserID = "myUser"
        mockDeviceCache.cachedPurchaserInfo[appUserID] = object

        let receivedPurchaserInfo = purchaserInfoManager.cachedPurchaserInfo(forAppUserID: appUserID)
        expect(receivedPurchaserInfo).to(beNil())
    }

    func testCachePurchaserInfoStoresCorrectly() {
        let appUserID = "myUser"
        purchaserInfoManager.cachePurchaserInfo(mockPurchaserInfo, forAppUserID: appUserID)

        expect(self.purchaserInfoManager.cachedPurchaserInfo(forAppUserID: appUserID)) == mockPurchaserInfo
        expect(self.mockDeviceCache.cachePurchaserInfoCount) == 1
    }

    func testCachePurchaserDoesntStoreIfCantBeSerialized() {
        // infinity can't be cast into JSON, so we use it to force a parsing exception. See:
        // https://developer.apple.com/documentation/foundation/nsjsonserialization?language=objc
        let invalidPurchaserInfo = PurchaserInfo(data: [
            "something": Double.infinity,
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": NSNull()
            ]])!

        purchaserInfoManager.cachePurchaserInfo(invalidPurchaserInfo, forAppUserID: "myUser")
        expect(self.mockDeviceCache.cachePurchaserInfoCount) == 0
    }

    func testCachePurchaserSendsToDelegateIfChanged() {
        purchaserInfoManager.cachePurchaserInfo(mockPurchaserInfo, forAppUserID: "myUser")
        expect(self.purchaserInfoManagerDelegateCallCount) == 1
        expect(self.purchaserInfoManagerDelegateCallPurchaserInfo) == mockPurchaserInfo
    }

    func testClearPurchaserInfoCacheClearsCorrectly() {
        let appUserID = "myUser"
        purchaserInfoManager.clearPurchaserInfoCache(forAppUserID: appUserID)
        expect(self.mockDeviceCache.invokedClearPurchaserInfoCache) == true
        expect(self.mockDeviceCache.invokedClearPurchaserInfoCacheParameters?.appUserID) == appUserID
    }

    func testClearPurchaserInfoCacheResetsLastSent() {
        let appUserID = "myUser"
        purchaserInfoManager.cachePurchaserInfo(mockPurchaserInfo, forAppUserID: appUserID)
        expect(self.purchaserInfoManager.lastSentPurchaserInfo) == mockPurchaserInfo

        purchaserInfoManager.clearPurchaserInfoCache(forAppUserID: appUserID)

        expect(self.purchaserInfoManager.lastSentPurchaserInfo).to(beNil())
    }
}

extension PurchaserInfoManagerTests: PurchaserInfoManagerDelegate {

    func purchaserInfoManagerDidReceiveUpdatedPurchaserInfo(_ purchaserInfo: PurchaserInfo) {
        purchaserInfoManagerDelegateCallCount += 1
        purchaserInfoManagerDelegateCallPurchaserInfo = purchaserInfo
    }
}
