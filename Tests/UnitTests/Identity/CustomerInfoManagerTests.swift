import Nimble
import XCTest

@testable import RevenueCat

@MainActor
class BaseCustomerInfoManagerTests: TestCase {
    fileprivate static let appUserID = "app_user_id"

    fileprivate var mockBackend = MockBackend()
    fileprivate var mockOperationDispatcher = MockOperationDispatcher()
    fileprivate var mockDeviceCache: MockDeviceCache!
    fileprivate var mockSystemInfo = MockSystemInfo(finishTransactions: true)

    fileprivate var mockCustomerInfo: CustomerInfo!

    fileprivate var customerInfoManager: CustomerInfoManager!

    fileprivate var customerInfoManagerChangesCallCount = 0
    fileprivate var customerInfoManagerLastCustomerInfo: CustomerInfo?

    fileprivate var customerInfoMonitorDisposable: (() -> Void)?

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.mockCustomerInfo = try CustomerInfo(data: [
            "request_date": "2018-12-21T02:40:36Z",
            "subscriber": [
                "original_app_user_id": Self.appUserID,
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": NSNull()
            ]])

        self.mockDeviceCache = MockDeviceCache(sandboxEnvironmentDetector: self.mockSystemInfo)
        self.customerInfoManagerChangesCallCount = 0
        self.customerInfoManagerLastCustomerInfo = nil
        self.customerInfoManager = CustomerInfoManager(operationDispatcher: self.mockOperationDispatcher,
                                                       deviceCache: self.mockDeviceCache,
                                                       backend: self.mockBackend,
                                                       systemInfo: self.mockSystemInfo)
    }

}

class CustomerInfoManagerTests: BaseCustomerInfoManagerTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.customerInfoMonitorDisposable = self.customerInfoManager.monitorChanges { [weak self] customerInfo in
            self?.customerInfoManagerChangesCallCount += 1
            self?.customerInfoManagerLastCustomerInfo = customerInfo
        }
    }

    override func tearDown() {
        super.tearDown()

        self.customerInfoMonitorDisposable?()
    }

    func testFetchAndCacheCustomerInfoCallsBackendWithRandomDelayIfAppBackgrounded() {
        self.customerInfoManager.fetchAndCacheCustomerInfo(appUserID: Self.appUserID,
                                                           isAppBackgrounded: true,
                                                           completion: nil)

        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
        expect(self.mockBackend.invokedGetSubscriberDataParameters?.randomDelay) == true
    }

    func testFetchAndCacheCustomerInfoCallsBackendWithoutRandomDelayIfAppForegrounded() {
        self.customerInfoManager.fetchAndCacheCustomerInfo(appUserID: Self.appUserID,
                                                           isAppBackgrounded: false,
                                                           completion: nil)

        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
        expect(self.mockBackend.invokedGetSubscriberDataParameters?.randomDelay) == false
    }

    func testFetchAndCacheCustomerInfoPassesBackendErrors() throws {
        let mockError: BackendError = .missingAppUserID()
        mockBackend.stubbedGetCustomerInfoResult = .failure(mockError)

        var receivedError: BackendError?
        customerInfoManager.fetchAndCacheCustomerInfo(appUserID: Self.appUserID,
                                                      isAppBackgrounded: false) { result in
            receivedError = result.error
        }

        expect(receivedError).toEventuallyNot(beNil())
        expect(receivedError) == mockError
    }

    func testFetchAndCacheCustomerInfoClearsCustomerInfoTimestampIfBackendError() {
        mockBackend.stubbedGetCustomerInfoResult = .failure(.missingAppUserID())

        var completionCalled = false
        customerInfoManager.fetchAndCacheCustomerInfo(appUserID: Self.appUserID,
                                                      isAppBackgrounded: false) { _ in
            completionCalled = true
        }
        expect(completionCalled).toEventually(beTrue())
        expect(self.mockDeviceCache.clearCustomerInfoCacheTimestampCount) == 1
    }

    func testFetchAndCacheCustomerInfoCachesIfSuccessful() {
        mockBackend.stubbedGetCustomerInfoResult = .success(mockCustomerInfo)

        var receivedCustomerInfo: CustomerInfo?

        customerInfoManager.fetchAndCacheCustomerInfo(appUserID: Self.appUserID,
                                                      isAppBackgrounded: false) { result in
            receivedCustomerInfo = result.value
        }
        expect(receivedCustomerInfo).toEventuallyNot(beNil())
        expect(receivedCustomerInfo) == self.mockCustomerInfo

        expect(self.mockDeviceCache.cacheCustomerInfoCount) == 1
        expect(self.customerInfoManagerChangesCallCount) == 1
        expect(self.customerInfoManagerLastCustomerInfo) == self.mockCustomerInfo
    }

    func testFetchAndCacheCustomerInfoCallsCompletionOnMainThread() {
        mockBackend.stubbedGetCustomerInfoResult = .success(mockCustomerInfo)

        var completionCalled = false
        customerInfoManager.fetchAndCacheCustomerInfo(appUserID: Self.appUserID,
                                                      isAppBackgrounded: false) { _ in
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

        customerInfoManager.fetchAndCacheCustomerInfoIfStale(appUserID: Self.appUserID,
                                                             isAppBackgrounded: false) { _ in
            firstCompletionCalled = true
        }
        mockDeviceCache.stubbedIsCustomerInfoCacheStale = false
        customerInfoManager.cache(customerInfo: mockCustomerInfo, appUserID: Self.appUserID)
        customerInfoManager.fetchAndCacheCustomerInfoIfStale(appUserID: Self.appUserID,
                                                             isAppBackgrounded: false) { _ in
            secondCompletionCalled = true
        }

        expect(firstCompletionCalled).toEventually(beTrue())
        expect(secondCompletionCalled).toEventually(beTrue())
        expect(self.mockBackend.invokedGetSubscriberDataCount).toEventually(equal(1))
    }

    func testFetchAndCacheCustomerInfoIfStaleFetchesIfStale() {
        customerInfoManager.cache(customerInfo: mockCustomerInfo, appUserID: Self.appUserID)
        mockDeviceCache.stubbedIsCustomerInfoCacheStale = true
        var completionCalled = false

        customerInfoManager.fetchAndCacheCustomerInfoIfStale(appUserID: Self.appUserID,
                                                             isAppBackgrounded: false) { _ in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.mockBackend.invokedGetSubscriberDataCount).toEventually(equal(1))
    }

    func testFetchAndCacheCustomerInfoIfStaleFetchesIfCacheEmpty() {
        mockDeviceCache.stubbedIsCustomerInfoCacheStale = false
        var completionCalled = false

        customerInfoManager.fetchAndCacheCustomerInfoIfStale(appUserID: Self.appUserID,
                                                             isAppBackgrounded: false) { _ in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.mockBackend.invokedGetSubscriberDataCount).toEventually(equal(1))
    }

    func testSendCachedCustomerInfoIfAvailableForAppUserIDSendsIfNeverSent() throws {
        let info = try CustomerInfo(data: [
        "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": Self.appUserID,
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])

        let object = try info.asData()
        self.mockDeviceCache.cachedCustomerInfo[Self.appUserID] = object

        customerInfoManager.sendCachedCustomerInfoIfAvailable(appUserID: Self.appUserID)

        expect(self.customerInfoManagerChangesCallCount) == 1
    }

    func testSendCachedCustomerInfoIfAvailableForAppUserIDSendsIfDifferent() throws {
        let oldInfo = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": Self.appUserID,
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])

        var object = try oldInfo.asData()

        mockDeviceCache.cachedCustomerInfo[Self.appUserID] = object

        customerInfoManager.sendCachedCustomerInfoIfAvailable(appUserID: Self.appUserID)

        let newInfo = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": Self.appUserID,
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": ["product_a": ["expires_date": "2018-05-27T06:24:50Z", "period_type": "normal"]],
                "other_purchases": [:]
            ]])

        object = try newInfo.asData()
        mockDeviceCache.cachedCustomerInfo[Self.appUserID] = object

        customerInfoManager.sendCachedCustomerInfoIfAvailable(appUserID: Self.appUserID)
        expect(self.customerInfoManagerChangesCallCount) == 2
    }

    func testSendCachedCustomerInfoIfAvailableForAppUserIDSendsOnMainThread() throws {
        let oldInfo = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": Self.appUserID,
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])

        let object = try oldInfo.asData()
        mockDeviceCache.cachedCustomerInfo[Self.appUserID] = object

        customerInfoManager.sendCachedCustomerInfoIfAvailable(appUserID: Self.appUserID)
        expect(self.mockOperationDispatcher.invokedDispatchOnMainThreadCount) == 1
    }

    func testCustomerInfoReturnsFromCacheIfAvailable() {
        customerInfoManager.cache(customerInfo: mockCustomerInfo, appUserID: Self.appUserID)

        var receivedCustomerInfo: CustomerInfo?

        customerInfoManager.customerInfo(appUserID: Self.appUserID, fetchPolicy: .default) { result in
            receivedCustomerInfo = result.value
        }

        expect(receivedCustomerInfo).toEventuallyNot(beNil())
        expect(receivedCustomerInfo) == self.mockCustomerInfo
        expect(self.mockBackend.invokedGetSubscriberDataCount) == 0
    }

    func testCustomerInfoReturnsFromCacheAndRefreshesIfStale() {
        mockDeviceCache.stubbedIsCustomerInfoCacheStale = true
        mockBackend.stubbedGetCustomerInfoResult = .success(mockCustomerInfo)

        customerInfoManager.cache(customerInfo: mockCustomerInfo, appUserID: Self.appUserID)

        var completionCalled = false
        customerInfoManager.customerInfo(appUserID: Self.appUserID, fetchPolicy: .default) { _ in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())
        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
    }

    func testCustomerInfoFetchesIfNoCache() {
        let appUserID = "myUser"

        var completionCalled = false
        customerInfoManager.customerInfo(appUserID: appUserID, fetchPolicy: .default) { _ in
            completionCalled = true

            // checking here to ensure that completion gets called from the backend call
            expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
        }

        expect(completionCalled).toEventually(beTrue())
    }

    func testCachedCustomerInfoParsesCorrectly() throws {
        let info = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": Self.appUserID,
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": [
                    "product_a": ["expires_date": "2098-05-27T06:24:50Z", "period_type": "normal"],
                    "Product_B": ["expires_date": "2098-05-27T06:24:50Z", "period_type": "normal"],
                    "ProductC": ["expires_date": "2098-05-27T06:24:50Z", "period_type": "normal"],
                    "Pro": ["expires_date": "2098-05-27T06:24:50Z", "period_type": "normal"],
                    "ProductD": ["expires_date": "2018-05-27T06:24:50Z", "period_type": "normal"]
                ],
                "other_purchases": [:]
            ]])

        let object = try info.asData()
        self.mockDeviceCache.cachedCustomerInfo[Self.appUserID] = object

        let receivedCustomerInfo = try XCTUnwrap(self.customerInfoManager.cachedCustomerInfo(appUserID: Self.appUserID))

        expect(receivedCustomerInfo.activeSubscriptions).to(haveCount(4))
        expect(receivedCustomerInfo.activeSubscriptions).to(contain([
            "product_a",
            "Product_B",
            "ProductC",
            "Pro"
        ]))
        expect(receivedCustomerInfo) == info
    }

    func testCachedCustomerInfoReturnsNilIfNotAvailable() {
        let receivedCustomerInfo = customerInfoManager.cachedCustomerInfo(appUserID: "myUser")
        expect(receivedCustomerInfo).to(beNil())
    }

    func testCachedCustomerInfoReturnsNilIfNotAvailableForTheAppUserID() throws {
        let info = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "original_app_user_id": Self.appUserID,
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": ["product_a": ["expires_date": "2018-05-27T06:24:50Z", "period_type": "normal"]],
                "other_purchases": [:]
            ]])

        let object = try info.asData()
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
                "original_app_user_id": Self.appUserID,
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

    func testCachePurchaserSendsToDelegateIfChanged() {
        customerInfoManager.cache(customerInfo: mockCustomerInfo, appUserID: "myUser")
        expect(self.customerInfoManagerChangesCallCount) == 1
        expect(self.customerInfoManagerLastCustomerInfo) == mockCustomerInfo
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

// iOS 13.0+ only because these tests are async
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
class CustomerInfoManagerGetCustomerInfoTests: BaseCustomerInfoManagerTests {

    private var mockRefreshedCustomerInfo: CustomerInfo!

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        self.mockRefreshedCustomerInfo = try CustomerInfo(data: [
            "request_date": "2019-12-21T02:40:36Z",
            "subscriber": [
                "original_app_user_id": Self.appUserID,
                "first_seen": "2020-06-17T16:05:33Z",
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "1.0"
            ]])
    }

    // MARK: - CacheFetchPolicy.fromCacheOnly

    func testCustomerInfoFromCacheOnlyReturnsFromCacheWhenAvailable() async throws {
        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        self.customerInfoManager.cache(customerInfo: self.mockCustomerInfo, appUserID: Self.appUserID)

        let result = try await self.customerInfoManager.customerInfo(appUserID: Self.appUserID,
                                                                     fetchPolicy: .fromCacheOnly)

        expect(result) == self.mockCustomerInfo
        expect(self.mockBackend.invokedGetSubscriberData) == false
    }

    func testCustomerInfoFromCacheOnlyReturnsFromCacheEvenIfExpired() async throws {
        self.mockDeviceCache.stubbedIsCustomerInfoCacheStale = true
        self.customerInfoManager.cache(customerInfo: self.mockCustomerInfo, appUserID: Self.appUserID)

        let result = try await self.customerInfoManager.customerInfo(appUserID: Self.appUserID,
                                                                     fetchPolicy: .fromCacheOnly)

        expect(result) == self.mockCustomerInfo
        expect(self.mockBackend.invokedGetSubscriberData) == false
    }

    func testCustomerInfoFromCacheOnlyThrowsWhenNotAvailable() async throws {
        do {
            _ = try await self.customerInfoManager.customerInfo(appUserID: Self.appUserID,
                                                                fetchPolicy: .fromCacheOnly)

            fail("Expected error")
        } catch BackendError.missingCachedCustomerInfo {
            // Expected error
        } catch {
            fail("Unexpected error: \(error)")
        }

        expect(self.mockBackend.invokedGetSubscriberData) == false
    }

    // MARK: - CacheFetchPolicy.cachedOrFetched

    func testCustomerInfoCachedOrFetchedReturnsFromCacheIfAvailable() async throws {
        self.customerInfoManager.cache(customerInfo: self.mockCustomerInfo, appUserID: Self.appUserID)

        let result = try await self.customerInfoManager.customerInfo(appUserID: Self.appUserID,
                                                                     fetchPolicy: .cachedOrFetched)
        expect(result) == self.mockCustomerInfo
        expect(self.mockBackend.invokedGetSubscriberData) == false
    }

    func testCustomerInfoCachedOrFetchedReturnsFromCacheAndRefreshesIfStale() async throws {
        self.mockDeviceCache.stubbedIsCustomerInfoCacheStale = true
        self.mockBackend.stubbedGetCustomerInfoResult = .success(self.mockRefreshedCustomerInfo)

        self.customerInfoManager.cache(customerInfo: self.mockCustomerInfo, appUserID: Self.appUserID)

        let result = try await self.customerInfoManager.customerInfo(appUserID: Self.appUserID,
                                                                     fetchPolicy: .cachedOrFetched)

        expect(result) == self.mockCustomerInfo
        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
    }

    func testCustomerInfoCachedOrFetchedFetchesIfNoCache() async throws {
        self.mockBackend.stubbedGetCustomerInfoResult = .success(self.mockRefreshedCustomerInfo)

        let result = try await self.customerInfoManager.customerInfo(appUserID: Self.appUserID,
                                                                     fetchPolicy: .cachedOrFetched)

        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
        expect(result) === self.mockRefreshedCustomerInfo
    }

    func testCustomerInfoCachedOrFetchedReturnsErrorIfNoCacheAndFailsToFetch() async throws {
        let expectedError: BackendError = .networkError(.offlineConnection())

        self.mockBackend.stubbedGetCustomerInfoResult = .failure(expectedError)

        do {
            _ = try await self.customerInfoManager.customerInfo(appUserID: Self.appUserID,
                                                                fetchPolicy: .cachedOrFetched)

            fail("Expected error")
        } catch {
            expect(error).to(matchError(expectedError))
        }
    }

    // MARK: - CacheFetchPolicy.notStaleCachedOrFetched

    func testCustomerInfoNotStaleCachedOrFetchedReturnsFromCacheIfAvailableAndNotStale() async throws {
        self.customerInfoManager.cache(customerInfo: self.mockCustomerInfo, appUserID: Self.appUserID)

        let result = try await self.customerInfoManager.customerInfo(appUserID: Self.appUserID,
                                                                     fetchPolicy: .notStaleCachedOrFetched)
        expect(result) == self.mockCustomerInfo
        expect(self.mockBackend.invokedGetSubscriberData) == false
    }

    func testCustomerInfoNotStaleCachedOrFetchedFetchesIfStale() async throws {
        self.customerInfoManager.cache(customerInfo: self.mockCustomerInfo, appUserID: Self.appUserID)
        self.mockDeviceCache.stubbedIsCustomerInfoCacheStale = true

        self.mockBackend.stubbedGetCustomerInfoResult = .success(self.mockRefreshedCustomerInfo)

        let result = try await self.customerInfoManager.customerInfo(appUserID: Self.appUserID,
                                                                     fetchPolicy: .notStaleCachedOrFetched)

        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
        expect(result) === self.mockRefreshedCustomerInfo
    }

    func testCustomerInfoNotStaleCachedOrFetchedReturnsFromCacheAndRefreshesIfStale() async throws {
        self.mockDeviceCache.stubbedIsCustomerInfoCacheStale = true
        self.mockBackend.stubbedGetCustomerInfoResult = .success(self.mockRefreshedCustomerInfo)

        self.customerInfoManager.cache(customerInfo: self.mockCustomerInfo, appUserID: Self.appUserID)

        let result = try await self.customerInfoManager.customerInfo(appUserID: Self.appUserID,
                                                                     fetchPolicy: .notStaleCachedOrFetched)

        expect(result) == self.mockRefreshedCustomerInfo
        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
    }

    func testCustomerInfoNotStaleCachedOrFetchedFetchesIfNoCache() async throws {
        self.mockBackend.stubbedGetCustomerInfoResult = .success(self.mockRefreshedCustomerInfo)

        let result = try await self.customerInfoManager.customerInfo(appUserID: Self.appUserID,
                                                                     fetchPolicy: .notStaleCachedOrFetched)

        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
        expect(result) === self.mockRefreshedCustomerInfo
    }

    func testCustomerInfoNotStaleCachedOrFetchedReturnsErrorIfNoCacheAndFailsToFetch() async throws {
        let expectedError: BackendError = .networkError(.offlineConnection())

        self.mockDeviceCache.stubbedIsCustomerInfoCacheStale = true
        self.customerInfoManager.cache(customerInfo: self.mockCustomerInfo, appUserID: Self.appUserID)
        self.mockBackend.stubbedGetCustomerInfoResult = .failure(expectedError)

        do {
            _ = try await self.customerInfoManager.customerInfo(appUserID: Self.appUserID,
                                                                fetchPolicy: .notStaleCachedOrFetched)

            fail("Expected error")
        } catch {
            expect(error).to(matchError(expectedError))
        }
    }

    // MARK: - CacheFetchPolicy.fetchCurrent

    func testCustomerInfoFetchCurrentFetchesEvenIfCacheIsAvailable() async throws {
        self.customerInfoManager.cache(customerInfo: self.mockCustomerInfo, appUserID: Self.appUserID)
        self.mockDeviceCache.stubbedIsCustomerInfoCacheStale = false
        self.mockBackend.stubbedGetCustomerInfoResult = .success(self.mockRefreshedCustomerInfo)

        let result = try await self.customerInfoManager.customerInfo(appUserID: Self.appUserID,
                                                                     fetchPolicy: .fetchCurrent)
        expect(result) == self.mockRefreshedCustomerInfo
        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
    }

    func testCustomerInfoFetchCurrentFailsIfRequestFails() async throws {
        self.customerInfoManager.cache(customerInfo: self.mockCustomerInfo, appUserID: Self.appUserID)
        self.mockDeviceCache.stubbedIsCustomerInfoCacheStale = false
        self.mockBackend.stubbedGetCustomerInfoResult = .failure(.networkError(.offlineConnection()))

        do {
            _ = try await self.customerInfoManager.customerInfo(appUserID: Self.appUserID,
                                                                fetchPolicy: .fetchCurrent)
        } catch BackendError.networkError {
            // Expected error
        } catch {
            fail("Unexpected error: \(error)")
        }
    }

}
