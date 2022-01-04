import Nimble
import XCTest

@testable import RevenueCat

// swiftlint:disable file_length
// swiftlint:disable type_body_length
class CustomerInfoManagerTests: XCTestCase {
    var mockBackend = MockBackend()
    var mockOperationDispatcher = MockOperationDispatcher()
    var mockDeviceCache: MockDeviceCache!
    var mockSystemInfo = MockSystemInfo(finishTransactions: true)
    let mockCustomerInfo = CustomerInfo(testData: [
        "request_date": "2018-12-21T02:40:36Z",
        "subscriber": [
            "original_app_user_id": "app_user_id",
            "first_seen": "2019-06-17T16:05:33Z",
            "subscriptions": [:],
            "other_purchases": [:],
            "original_application_version": NSNull()
        ]])!

    var customerInfoManager: CustomerInfoManager!

    var customerInfoManagerDelegateCallCount = 0
    var customerInfoManagerDelegateCallCustomerInfo: CustomerInfo?

    override func setUp() {
        super.setUp()
        mockDeviceCache = MockDeviceCache(systemInfo: self.mockSystemInfo)
        customerInfoManagerDelegateCallCount = 0
        customerInfoManagerDelegateCallCustomerInfo = nil
        customerInfoManager = CustomerInfoManager(operationDispatcher: mockOperationDispatcher,
                                                  deviceCache: mockDeviceCache,
                                                  backend: mockBackend,
                                                  systemInfo: mockSystemInfo)
        customerInfoManager.delegate = self
    }

    func testFetchAndCacheCustomerInfoCallsBackendWithRandomDelayIfAppBackgrounded() {
        mockOperationDispatcher.shouldInvokeDispatchOnWorkerThreadBlock = true

        customerInfoManager.fetchAndCacheCustomerInfo(appUserID: "myUser",
                                                      isAppBackgrounded: true,
                                                      completion: nil)

        expect(self.mockOperationDispatcher.invokedDispatchOnWorkerThread).toEventually(beTrue())
        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
        expect(self.mockOperationDispatcher.invokedDispatchOnWorkerThreadRandomDelayParam) == true
    }

    func testFetchAndCacheCustomerInfoCallsBackendWithoutRandomDelayIfAppForegrounded() {
        mockOperationDispatcher.shouldInvokeDispatchOnWorkerThreadBlock = true

        customerInfoManager.fetchAndCacheCustomerInfo(appUserID: "myUser",
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
        customerInfoManager.fetchAndCacheCustomerInfo(appUserID: "myUser",
                                                      isAppBackgrounded: false) { customerInfo, error in
            completionCalled = true
            receivedCustomerInfo = customerInfo
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
        customerInfoManager.fetchAndCacheCustomerInfo(appUserID: "myUser",
                                                      isAppBackgrounded: false) { _, _ in
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
        customerInfoManager.fetchAndCacheCustomerInfo(appUserID: "myUser",
                                                      isAppBackgrounded: false) { customerInfo, error in
            completionCalled = true
            receivedCustomerInfo = customerInfo
            receivedError = error
        }
        expect(completionCalled).toEventually(beTrue())
        expect(receivedCustomerInfo) == mockCustomerInfo
        expect(receivedError).to(beNil())

        expect(self.mockDeviceCache.cacheCustomerInfoCount) == 1
        expect(self.customerInfoManagerDelegateCallCount) == 1
        expect(self.customerInfoManagerDelegateCallCustomerInfo) == mockCustomerInfo
    }

    func testFetchAndCacheCustomerInfoCallsCompletionOnMainThread() {
        mockOperationDispatcher.shouldInvokeDispatchOnWorkerThreadBlock = true
        mockOperationDispatcher.shouldInvokeDispatchOnMainThreadBlock = true
        mockBackend.stubbedGetSubscriberDataCustomerInfo = mockCustomerInfo

        var completionCalled = false
        customerInfoManager.fetchAndCacheCustomerInfo(appUserID: "myUser",
                                                      isAppBackgrounded: false) { _, _ in
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
        customerInfoManager.fetchAndCacheCustomerInfoIfStale(appUserID: appUserID,
                                                             isAppBackgrounded: false) { _, _ in
            firstCompletionCalled = true
        }
        mockDeviceCache.stubbedIsCustomerInfoCacheStale = false
        customerInfoManager.cache(customerInfo: mockCustomerInfo, appUserID: appUserID)
        customerInfoManager.fetchAndCacheCustomerInfoIfStale(appUserID: appUserID,
                                                             isAppBackgrounded: false) { _, _ in
            secondCompletionCalled = true
        }

        expect(firstCompletionCalled).toEventually(beTrue())
        expect(secondCompletionCalled).toEventually(beTrue())
        expect(self.mockBackend.invokedGetSubscriberDataCount).toEventually(equal(1))
    }

    func testFetchAndCacheCustomerInfoIfStaleFetchesIfStale() {
        let appUserID = "myUser"
        customerInfoManager.cache(customerInfo: mockCustomerInfo, appUserID: appUserID)
        mockDeviceCache.stubbedIsCustomerInfoCacheStale = true
        var completionCalled = false

        customerInfoManager.fetchAndCacheCustomerInfoIfStale(appUserID: appUserID,
                                                             isAppBackgrounded: false) { _, _ in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.mockBackend.invokedGetSubscriberDataCount).toEventually(equal(1))
    }

    func testFetchAndCacheCustomerInfoIfStaleFetchesIfCacheEmpty() {
        mockDeviceCache.stubbedIsCustomerInfoCacheStale = false
        var completionCalled = false

        customerInfoManager.fetchAndCacheCustomerInfoIfStale(appUserID: "myUser",
                                                             isAppBackgrounded: false) { _, _ in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.mockBackend.invokedGetSubscriberDataCount).toEventually(equal(1))
    }

    func testSendCachedCustomerInfoIfAvailableForAppUserIDSendsIfNeverSent() throws {
        let info = CustomerInfo(testData: [
        "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])

        let jsonObject = info!.jsonObject()

        let object = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
        let appUserID = "myUser"
        self.mockDeviceCache.cachedCustomerInfo[appUserID] = object

        customerInfoManager.sendCachedCustomerInfoIfAvailable(appUserID: appUserID)

        expect(self.customerInfoManagerDelegateCallCount) == 1
    }

    func testSendCachedCustomerInfoIfAvailableForAppUserIDSendsIfDifferent() throws {
        let oldInfo = CustomerInfo(testData: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])

        var jsonObject = oldInfo!.jsonObject()

        var object = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
        let appUserID = "myUser"
        mockDeviceCache.cachedCustomerInfo[appUserID] = object

        customerInfoManager.sendCachedCustomerInfoIfAvailable(appUserID: appUserID)

        let newInfo = CustomerInfo(testData: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": ["product_a": ["expires_date": "2018-05-27T06:24:50Z", "period_type": "normal"]],
                "other_purchases": [:]
            ]])

        jsonObject = newInfo!.jsonObject()

        object = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
        mockDeviceCache.cachedCustomerInfo[appUserID] = object

        customerInfoManager.sendCachedCustomerInfoIfAvailable(appUserID: appUserID)
        expect(self.customerInfoManagerDelegateCallCount) == 2
    }

    func testSendCachedCustomerInfoIfAvailableForAppUserIDSendsOnMainThread() throws {
        let oldInfo = CustomerInfo(testData: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])

        let jsonObject = oldInfo!.jsonObject()

        let object = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
        let appUserID = "myUser"
        mockDeviceCache.cachedCustomerInfo[appUserID] = object

        customerInfoManager.sendCachedCustomerInfoIfAvailable(appUserID: appUserID)
        expect(self.mockOperationDispatcher.invokedDispatchOnMainThreadCount) == 1
    }

    func testCustomerInfoReturnsFromCacheIfAvailable() {
        let appUserID = "myUser"
        customerInfoManager.cache(customerInfo: mockCustomerInfo, appUserID: appUserID)

        var completionCalled = false
        var receivedCustomerInfo: CustomerInfo?
        var receivedError: Error?
        customerInfoManager.customerInfo(appUserID: appUserID) { customerInfo, error in
            completionCalled = true
            receivedCustomerInfo = customerInfo
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
        customerInfoManager.cache(customerInfo: mockCustomerInfo, appUserID: appUserID)

        var completionCalled = false
        customerInfoManager.customerInfo(appUserID: appUserID) { _, _ in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
    }

    func testCustomerInfoFetchesIfNoCache() {
        let appUserID = "myUser"

        var completionCalled = false
        customerInfoManager.customerInfo(appUserID: appUserID) { _, _ in
            completionCalled = true

            // checking here to ensure that completion gets called from the backend call
            expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
        }

        expect(completionCalled).toEventually(beTrue())
    }

    func testCachedCustomerInfoParsesCorrectly() throws {
        let appUserID = "myUser"
        let info = CustomerInfo(testData: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": ["product_a": ["expires_date": "2018-05-27T06:24:50Z", "period_type": "normal"]],
                "other_purchases": [:]
            ]])

        let jsonObject = info!.jsonObject()

        let object = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
        mockDeviceCache.cachedCustomerInfo[appUserID] = object

        let receivedCustomerInfo = customerInfoManager.cachedCustomerInfo(appUserID: appUserID)

        expect(receivedCustomerInfo).toNot(beNil())
        expect(receivedCustomerInfo!) == info
    }

    func testCachedCustomerInfoReturnsNilIfNotAvailable() {
        let receivedCustomerInfo = customerInfoManager.cachedCustomerInfo(appUserID: "myUser")
        expect(receivedCustomerInfo).to(beNil())
    }

    func testCachedCustomerInfoReturnsNilIfNotAvailableForTheAppUserID() throws {
        let info = CustomerInfo(testData: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": "app_user_id",
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": ["product_a": ["expires_date": "2018-05-27T06:24:50Z", "period_type": "normal"]],
                "other_purchases": [:]
            ]])

        let jsonObject = info!.jsonObject()

        let object = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
        mockDeviceCache.cachedCustomerInfo["firstUser"] = object

        let receivedCustomerInfo = customerInfoManager.cachedCustomerInfo(appUserID: "secondUser")
        expect(receivedCustomerInfo).to(beNil())
    }

    func testCachedCustomerInfoReturnsNilIfCantBeParsed() {
        let appUserID = "myUser"

        mockDeviceCache.cachedCustomerInfo[appUserID] = Data()

        let receivedCustomerInfo = customerInfoManager.cachedCustomerInfo(appUserID: appUserID)
        expect(receivedCustomerInfo).to(beNil())
    }

    func testCachedCustomerInfoReturnsNilIfDifferentSchema() throws {
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

        let object = try JSONSerialization.data(withJSONObject: data, options: [])
        let appUserID = "myUser"
        mockDeviceCache.cachedCustomerInfo[appUserID] = object

        let receivedCustomerInfo = customerInfoManager.cachedCustomerInfo(appUserID: appUserID)
        expect(receivedCustomerInfo).to(beNil())
    }

    func testCacheCustomerInfoStoresCorrectly() {
        let appUserID = "myUser"
        customerInfoManager.cache(customerInfo: mockCustomerInfo, appUserID: appUserID)

        expect(self.customerInfoManager.cachedCustomerInfo(appUserID: appUserID)) == mockCustomerInfo
        expect(self.mockDeviceCache.cacheCustomerInfoCount) == 1
    }

    func testCachePurchaserDoesntStoreIfCantBeSerialized() {
        // infinity can't be cast into JSON, so we use it to force a parsing exception. See:
        // https://developer.apple.com/documentation/foundation/nsjsonserialization?language=objc
        let invalidCustomerInfo = CustomerInfo(testData: [
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
            self.customerInfoManager.cache(customerInfo: invalidCustomerInfo, appUserID: "myUser")
        }.toNot(throwError())

        expect(self.mockDeviceCache.cacheCustomerInfoCount).toEventually(be(0))
    }

    func testCachePurchaserSendsToDelegateIfChanged() {
        customerInfoManager.cache(customerInfo: mockCustomerInfo, appUserID: "myUser")
        expect(self.customerInfoManagerDelegateCallCount) == 1
        expect(self.customerInfoManagerDelegateCallCustomerInfo) == mockCustomerInfo
    }

    func testClearCustomerInfoCacheClearsCorrectly() {
        let appUserID = "myUser"
        customerInfoManager.clearCustomerInfoCache(forAppUserID: appUserID)
        expect(self.mockDeviceCache.invokedClearCustomerInfoCache) == true
        expect(self.mockDeviceCache.invokedClearCustomerInfoCacheParameters?.appUserID) == appUserID
    }

    func testClearCustomerInfoCacheResetsLastSent() {
        let appUserID = "myUser"
        customerInfoManager.cache(customerInfo: mockCustomerInfo, appUserID: appUserID)
        expect(self.customerInfoManager.lastSentCustomerInfo) == mockCustomerInfo

        customerInfoManager.clearCustomerInfoCache(forAppUserID: appUserID)

        expect(self.customerInfoManager.lastSentCustomerInfo).to(beNil())
    }
}

extension CustomerInfoManagerTests: CustomerInfoManagerDelegate {

    func customerInfoManagerDidReceiveUpdated(customerInfo: CustomerInfo) {
        customerInfoManagerDelegateCallCount += 1
        customerInfoManagerDelegateCallCustomerInfo = customerInfo
    }

}
