import XCTest
import Nimble

@testable import RevenueCat

class CustomerInfoManagerTests: XCTestCase {
    var mockBackend = MockBackend()
    var mockOperationDispatcher = MockOperationDispatcher()
    var mockDeviceCache: MockDeviceCache!
    var mockSystemInfo = try! MockSystemInfo(platformFlavor: nil, platformFlavorVersion: nil, finishTransactions: true)
    let mockCustomerInfo = CustomerInfo(data: [
        "request_date": "2018-12-21T02:40:36Z",
        "subscriber": [
            "original_app_user_id": "app_user_id",
            "first_seen": "2019-06-17T16:05:33Z",
            "subscriptions": [:],
            "other_purchases": [:],
            "original_application_version": NSNull()
        ]])!

    var purchaserInfoManager: CustomerInfoManager!

    var purchaserInfoManagerDelegateCallCount = 0
    var purchaserInfoManagerDelegateCallCustomerInfo: CustomerInfo?

    override func setUp() {
        super.setUp()
        mockDeviceCache = MockDeviceCache()
        purchaserInfoManagerDelegateCallCount = 0
        purchaserInfoManagerDelegateCallCustomerInfo = nil
        purchaserInfoManager = CustomerInfoManager(operationDispatcher: mockOperationDispatcher,
                                                    deviceCache: mockDeviceCache,
                                                    backend: mockBackend,
                                                    systemInfo: mockSystemInfo)
        purchaserInfoManager.delegate = self
    }

    func testFetchAndCacheCustomerInfoCallsBackendWithRandomDelayIfAppBackgrounded() {
        mockOperationDispatcher.shouldInvokeDispatchOnWorkerThreadBlock = true


        purchaserInfoManager.fetchAndCacheCustomerInfo(appUserID: "myUser",
                                                        isAppBackgrounded: true,
                                                        completion: nil)

        expect(self.mockOperationDispatcher.invokedDispatchOnWorkerThread).toEventually(beTrue())
        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
        expect(self.mockOperationDispatcher.invokedDispatchOnWorkerThreadRandomDelayParam) == true
    }

    func testFetchAndCacheCustomerInfoCallsBackendWithoutRandomDelayIfAppForegrounded() {
        mockOperationDispatcher.shouldInvokeDispatchOnWorkerThreadBlock = true

        purchaserInfoManager.fetchAndCacheCustomerInfo(appUserID: "myUser",
                                                        isAppBackgrounded: false,
                                                        completion: nil)

        expect(self.mockOperationDispatcher.invokedDispatchOnWorkerThread).toEventually(beTrue())
        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
        expect(self.mockOperationDispatcher.invokedDispatchOnWorkerThreadRandomDelayParam) == false
    }

    func testFetchAndCacheCustomerInfoPassesBackendErrors() {
        mockOperationDispatcher.shouldInvokeDispatchOnWorkerThreadBlock = true
        let mockError = NSError(domain: "revenuecat", code: 123)
        mockBackend.stubbedGetSubscriberDataError = mockError

        var completionCalled = false
        var receivedCustomerInfo: CustomerInfo?
        var receivedError: Error?
        purchaserInfoManager.fetchAndCacheCustomerInfo(appUserID: "myUser",
                                                        isAppBackgrounded: false) { purchaserInfo, error in
            completionCalled = true
            receivedCustomerInfo = purchaserInfo
            receivedError = error
        }
        expect(completionCalled).toEventually(beTrue())
        expect(receivedCustomerInfo).to(beNil())
        expect(receivedError).toNot(beNil())
        let receivedNSError = receivedError! as NSError
        expect(receivedNSError) == mockError
    }

    func testFetchAndCacheCustomerInfoClearsCustomerInfoTimestampIfBackendError() {
        mockOperationDispatcher.shouldInvokeDispatchOnWorkerThreadBlock = true
        mockBackend.stubbedGetSubscriberDataError = NSError(domain: "revenuecat", code: 123)

        var completionCalled = false
        purchaserInfoManager.fetchAndCacheCustomerInfo(appUserID: "myUser",
                                                        isAppBackgrounded: false) { purchaserInfo, error in
            completionCalled = true
        }
        expect(completionCalled).toEventually(beTrue())
        expect(self.mockDeviceCache.clearCustomerInfoCacheTimestampCount) == 1
    }

    func testFetchAndCacheCustomerInfoCachesIfSuccessful() {
        mockOperationDispatcher.shouldInvokeDispatchOnWorkerThreadBlock = true
        mockOperationDispatcher.shouldInvokeDispatchOnMainThreadBlock = true
        mockBackend.stubbedGetSubscriberDataCustomerInfo = mockCustomerInfo

        var completionCalled = false
        var receivedCustomerInfo: CustomerInfo?
        var receivedError: Error?
        purchaserInfoManager.fetchAndCacheCustomerInfo(appUserID: "myUser",
                                                        isAppBackgrounded: false) { purchaserInfo, error in
            completionCalled = true
            receivedCustomerInfo = purchaserInfo
            receivedError = error
        }
        expect(completionCalled).toEventually(beTrue())
        expect(receivedCustomerInfo) == mockCustomerInfo
        expect(receivedError).to(beNil())

        expect(self.mockDeviceCache.cacheCustomerInfoCount) == 1
        expect(self.purchaserInfoManagerDelegateCallCount) == 1
        expect(self.purchaserInfoManagerDelegateCallCustomerInfo) == mockCustomerInfo
    }

    func testFetchAndCacheCustomerInfoCallsCompletionOnMainThread() {
        mockOperationDispatcher.shouldInvokeDispatchOnWorkerThreadBlock = true
        mockOperationDispatcher.shouldInvokeDispatchOnMainThreadBlock = true
        mockBackend.stubbedGetSubscriberDataCustomerInfo = mockCustomerInfo

        var completionCalled = false
        purchaserInfoManager.fetchAndCacheCustomerInfo(appUserID: "myUser",
                                                        isAppBackgrounded: false) { purchaserInfo, error in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())

        let expectedInvocationsOnMainThread = 2 // one for the delegate, one for completion
        expect(self.mockOperationDispatcher.invokedDispatchOnMainThreadCount) == expectedInvocationsOnMainThread
    }

    func testFetchAndCacheCustomerInfoIfStaleOnlyRefreshesCacheOnce() {
        mockDeviceCache.stubbedIsCustomerInfoCacheStale = true
        var firstCompletionCalled = false
        var secondCompletionCalled = false

        let appUserID = "myUser"
        purchaserInfoManager.fetchAndCacheCustomerInfoIfStale(appUserID: appUserID,
                                                               isAppBackgrounded: false) { purchaserInfo, error in
            firstCompletionCalled = true
        }
        mockDeviceCache.stubbedIsCustomerInfoCacheStale = false
        purchaserInfoManager.cache(customerInfo: mockCustomerInfo, appUserID: appUserID)
        purchaserInfoManager.fetchAndCacheCustomerInfoIfStale(appUserID: appUserID,
                                                               isAppBackgrounded: false) { purchaserInfo, error in
            secondCompletionCalled = true
        }

        expect(firstCompletionCalled).toEventually(beTrue())
        expect(secondCompletionCalled).toEventually(beTrue())
        expect(self.mockBackend.invokedGetSubscriberDataCount).toEventually(equal(1))
    }

    func testFetchAndCacheCustomerInfoIfStaleFetchesIfStale() {
        let appUserID = "myUser"
        purchaserInfoManager.cache(customerInfo: mockCustomerInfo, appUserID: appUserID)
        mockDeviceCache.stubbedIsCustomerInfoCacheStale = true
        var completionCalled = false

        purchaserInfoManager.fetchAndCacheCustomerInfoIfStale(appUserID: appUserID,
                                                               isAppBackgrounded: false) { purchaserInfo, error in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.mockBackend.invokedGetSubscriberDataCount).toEventually(equal(1))
    }

    func testFetchAndCacheCustomerInfoIfStaleFetchesIfCacheEmpty() {
        mockDeviceCache.stubbedIsCustomerInfoCacheStale = false
        var completionCalled = false

        purchaserInfoManager.fetchAndCacheCustomerInfoIfStale(appUserID: "myUser",
                                                               isAppBackgrounded: false) { purchaserInfo, error in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.mockBackend.invokedGetSubscriberDataCount).toEventually(equal(1))
    }

    func testSendCachedCustomerInfoIfAvailableForAppUserIDSendsIfNeverSent() {
        let info = CustomerInfo(data: [
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
        self.mockDeviceCache.cachedCustomerInfo[appUserID] = object

        purchaserInfoManager.sendCachedCustomerInfoIfAvailable(appUserID: appUserID)

        expect(self.purchaserInfoManagerDelegateCallCount) == 1
    }

    func testSendCachedCustomerInfoIfAvailableForAppUserIDSendsIfDifferent() {
        let oldInfo = CustomerInfo(data: [
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
        mockDeviceCache.cachedCustomerInfo[appUserID] = object

        purchaserInfoManager.sendCachedCustomerInfoIfAvailable(appUserID: appUserID)

        let newInfo = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": ["product_a": ["expires_date": "2018-05-27T06:24:50Z", "period_type": "normal"]],
                "other_purchases": [:]
            ]]);

        jsonObject = newInfo!.jsonObject()

        object = try! JSONSerialization.data(withJSONObject: jsonObject, options: [])
        mockDeviceCache.cachedCustomerInfo[appUserID] = object

        purchaserInfoManager.sendCachedCustomerInfoIfAvailable(appUserID: appUserID)
        expect(self.purchaserInfoManagerDelegateCallCount) == 2
    }

    func testSendCachedCustomerInfoIfAvailableForAppUserIDSendsOnMainThread() {
        let oldInfo = CustomerInfo(data: [
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
        mockDeviceCache.cachedCustomerInfo[appUserID] = object

        purchaserInfoManager.sendCachedCustomerInfoIfAvailable(appUserID: appUserID)
        expect(self.mockOperationDispatcher.invokedDispatchOnMainThreadCount) == 1
    }

    func testCustomerInfoReturnsFromCacheIfAvailable() {
        let appUserID = "myUser"
        purchaserInfoManager.cache(customerInfo: mockCustomerInfo, appUserID: appUserID)

        var completionCalled = false
        var receivedCustomerInfo: CustomerInfo?
        var receivedError: Error?
        purchaserInfoManager.customerInfo(appUserID: appUserID) { purchaserInfo, error in
            completionCalled = true
            receivedCustomerInfo = purchaserInfo
            receivedError = error
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.mockBackend.invokedGetSubscriberDataCount) == 0
        expect(receivedCustomerInfo).toNot(beNil())
        expect(receivedCustomerInfo) == mockCustomerInfo
        expect(receivedError).to(beNil())
    }

    func testCustomerInfoReturnsFromCacheAndRefreshesIfStale() {
        let appUserID = "myUser"
        mockDeviceCache.stubbedIsCustomerInfoCacheStale = true
        purchaserInfoManager.cache(customerInfo: mockCustomerInfo, appUserID: appUserID)

        var completionCalled = false
        purchaserInfoManager.customerInfo(appUserID: appUserID) { purchaserInfo, error in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
    }

    func testCustomerInfoFetchesIfNoCache() {
        let appUserID = "myUser"

        var completionCalled = false
        purchaserInfoManager.customerInfo(appUserID: appUserID) { purchaserInfo, error in
            completionCalled = true

            // checking here to ensure that completion gets called from the backend call
            expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
        }

        expect(completionCalled).toEventually(beTrue())
    }

    func testCachedCustomerInfoParsesCorrectly() {
        let appUserID = "myUser"
        let info = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": ["product_a": ["expires_date": "2018-05-27T06:24:50Z", "period_type": "normal"]],
                "other_purchases": [:]
            ]]);

        let jsonObject = info!.jsonObject()

        let object = try! JSONSerialization.data(withJSONObject: jsonObject, options: [])
        mockDeviceCache.cachedCustomerInfo[appUserID] = object

        let receivedCustomerInfo = purchaserInfoManager.cachedCustomerInfo(appUserID: appUserID)

        expect(receivedCustomerInfo).toNot(beNil())
        expect(receivedCustomerInfo!) == info
    }

    func testCachedCustomerInfoReturnsNilIfNotAvailable() {
        let receivedCustomerInfo = purchaserInfoManager.cachedCustomerInfo(appUserID: "myUser")
        expect(receivedCustomerInfo).to(beNil())
    }

    func testCachedCustomerInfoReturnsNilIfNotAvailableForTheAppUserID() {
        let info = CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": ["product_a": ["expires_date": "2018-05-27T06:24:50Z", "period_type": "normal"]],
                "other_purchases": [:]
            ]]);

        let jsonObject = info!.jsonObject()

        let object = try! JSONSerialization.data(withJSONObject: jsonObject, options: [])
        mockDeviceCache.cachedCustomerInfo["firstUser"] = object

        let receivedCustomerInfo = purchaserInfoManager.cachedCustomerInfo(appUserID: "secondUser")
        expect(receivedCustomerInfo).to(beNil())
    }

    func testCachedCustomerInfoReturnsNilIfCantBeParsed() {
        let appUserID = "myUser"

        mockDeviceCache.cachedCustomerInfo[appUserID] = Data()

        let receivedCustomerInfo = purchaserInfoManager.cachedCustomerInfo(appUserID: appUserID)
        expect(receivedCustomerInfo).to(beNil())
    }

    func testCachedCustomerInfoReturnsNilIfDifferentSchema() {
        let oldSchemaVersion = Int(CustomerInfo.currentSchemaVersion)! - 1
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
        mockDeviceCache.cachedCustomerInfo[appUserID] = object

        let receivedCustomerInfo = purchaserInfoManager.cachedCustomerInfo(appUserID: appUserID)
        expect(receivedCustomerInfo).to(beNil())
    }

    func testCacheCustomerInfoStoresCorrectly() {
        let appUserID = "myUser"
        purchaserInfoManager.cache(customerInfo: mockCustomerInfo, appUserID: appUserID)

        expect(self.purchaserInfoManager.cachedCustomerInfo(appUserID: appUserID)) == mockCustomerInfo
        expect(self.mockDeviceCache.cacheCustomerInfoCount) == 1
    }

    func testCachePurchaserDoesntStoreIfCantBeSerialized() {
        // infinity can't be cast into JSON, so we use it to force a parsing exception. See:
        // https://developer.apple.com/documentation/foundation/nsjsonserialization?language=objc
        let invalidCustomerInfo = CustomerInfo(data: [
            "something": Double.infinity,
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": NSNull()
            ]])!

        expect {
            self.purchaserInfoManager.cache(customerInfo: invalidCustomerInfo, appUserID: "myUser")
        }.toNot(throwError())

        expect(self.mockDeviceCache.cacheCustomerInfoCount).toEventually(be(0))
    }

    func testCachePurchaserSendsToDelegateIfChanged() {
        purchaserInfoManager.cache(customerInfo: mockCustomerInfo, appUserID: "myUser")
        expect(self.purchaserInfoManagerDelegateCallCount) == 1
        expect(self.purchaserInfoManagerDelegateCallCustomerInfo) == mockCustomerInfo
    }

    func testClearCustomerInfoCacheClearsCorrectly() {
        let appUserID = "myUser"
        purchaserInfoManager.clearCustomerInfoCache(forAppUserID: appUserID)
        expect(self.mockDeviceCache.invokedClearCustomerInfoCache) == true
        expect(self.mockDeviceCache.invokedClearCustomerInfoCacheParameters?.appUserID) == appUserID
    }

    func testClearCustomerInfoCacheResetsLastSent() {
        let appUserID = "myUser"
        purchaserInfoManager.cache(customerInfo: mockCustomerInfo, appUserID: appUserID)
        expect(self.purchaserInfoManager.lastSentCustomerInfo) == mockCustomerInfo

        purchaserInfoManager.clearCustomerInfoCache(forAppUserID: appUserID)

        expect(self.purchaserInfoManager.lastSentCustomerInfo).to(beNil())
    }
}

extension CustomerInfoManagerTests: CustomerInfoManagerDelegate {

    func customerInfoManagerDidReceiveUpdated(customerInfo: CustomerInfo) {
        purchaserInfoManagerDelegateCallCount += 1
        purchaserInfoManagerDelegateCallCustomerInfo = customerInfo
    }

}
