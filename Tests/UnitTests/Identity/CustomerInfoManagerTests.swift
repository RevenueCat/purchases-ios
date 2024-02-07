import Nimble
import XCTest

@testable import RevenueCat

class BaseCustomerInfoManagerTests: TestCase {

    static let appUserID = "app_user_id"

    var mockOfflineEntitlementsManager: MockOfflineEntitlementsManager!
    var mockBackend = MockBackend()
    var mockOperationDispatcher = MockOperationDispatcher()
    var mockDeviceCache: MockDeviceCache!
    var mockSystemInfo = MockSystemInfo(finishTransactions: true)
    var mockTransationFetcher: MockStoreKit2TransactionFetcher!
    var mockTransactionPoster: MockTransactionPoster!

    var mockCustomerInfo: CustomerInfo!
    var mockCustomerInfo2: CustomerInfo!

    var customerInfoManager: CustomerInfoManager!

    fileprivate var customerInfoManagerChangesCallCount = 0
    fileprivate var customerInfoManagerLastCustomerInfoChange: (old: CustomerInfo?, new: CustomerInfo)?

    fileprivate var customerInfoMonitorDisposable: (() -> Void)?

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.mockCustomerInfo = try CustomerInfo(data: [
            "request_date": "2018-12-21T02:40:36Z",
            "subscriber": [
                "original_app_user_id": Self.appUserID,
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": [:] as [String: Any],
                "other_purchases": [:] as [String: Any],
                "original_application_version": NSNull()
            ]  as [String: Any]
        ])
        self.mockCustomerInfo2 = try CustomerInfo(data: [
            "request_date": "2020-12-21T02:40:36Z",
            "subscriber": [
                "original_app_user_id": "another_user",
                "first_seen": "2020-06-17T16:05:33Z",
                "subscriptions": [:] as [String: Any],
                "other_purchases": [:] as [String: Any],
                "original_application_version": NSNull()
            ]  as [String: Any]
        ])

        self.mockOfflineEntitlementsManager = MockOfflineEntitlementsManager()
        self.mockDeviceCache = MockDeviceCache(sandboxEnvironmentDetector: self.mockSystemInfo)
        self.mockTransationFetcher = MockStoreKit2TransactionFetcher()
        self.mockTransactionPoster = MockTransactionPoster()

        self.customerInfoManagerChangesCallCount = 0
        self.customerInfoManagerLastCustomerInfoChange = nil

        self.customerInfoManager = CustomerInfoManager(
            offlineEntitlementsManager: self.mockOfflineEntitlementsManager,
            operationDispatcher: self.mockOperationDispatcher,
            deviceCache: self.mockDeviceCache,
            backend: self.mockBackend,
            transactionFetcher: self.mockTransationFetcher,
            transactionPoster: self.mockTransactionPoster,
            systemInfo: self.mockSystemInfo
        )
    }

    @discardableResult
    func fetchAndCacheCustomerInfo(isAppBackground: Bool = true) throws -> Result<CustomerInfo, BackendError> {
        let result = waitUntilValue { completion in
            self.customerInfoManager.fetchAndCacheCustomerInfo(appUserID: Self.appUserID,
                                                               isAppBackgrounded: isAppBackground,
                                                               completion: completion)
        }

        return try XCTUnwrap(result)
    }
}

class CustomerInfoManagerTests: BaseCustomerInfoManagerTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.customerInfoMonitorDisposable = self.customerInfoManager.monitorChanges { [weak self] old, new in
            self?.customerInfoManagerChangesCallCount += 1
            self?.customerInfoManagerLastCustomerInfoChange = (old, new)
        }
    }

    override func tearDown() {
        super.tearDown()

        self.customerInfoMonitorDisposable?()
    }

    func testFetchAndCacheCustomerInfoAllowOfflineCustomerInfo() throws {
        self.mockOfflineEntitlementsManager.stubbedShouldComputeOfflineCustomerInfo = true

        try self.fetchAndCacheCustomerInfo(isAppBackground: true)

        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
        expect(self.mockBackend.invokedGetSubscriberDataParameters?.allowComputingOffline) == true
    }

    func testFetchAndCacheCustomerInfoDontAllowOfflineCustomerInfo() throws {
        self.mockOfflineEntitlementsManager.stubbedShouldComputeOfflineCustomerInfo = false

        try self.fetchAndCacheCustomerInfo(isAppBackground: true)

        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
        expect(self.mockBackend.invokedGetSubscriberDataParameters?.allowComputingOffline) == false
    }

    func testFetchAndCacheCustomerInfoCallsBackendWithRandomDelayIfAppBackgrounded() throws {
        try self.fetchAndCacheCustomerInfo(isAppBackground: true)

        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
        expect(self.mockBackend.invokedGetSubscriberDataParameters?.isAppBackgrounded) == true
    }

    func testFetchAndCacheCustomerInfoCallsBackendWithoutRandomDelayIfAppForegrounded() throws {
        try self.fetchAndCacheCustomerInfo(isAppBackground: false)

        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
        expect(self.mockBackend.invokedGetSubscriberDataParameters?.isAppBackgrounded) == false
    }

    func testFetchAndCacheCustomerInfoPassesBackendErrors() throws {
        let mockError: BackendError = .missingAppUserID()
        mockBackend.stubbedGetCustomerInfoResult = .failure(mockError)

        let receivedError = try self.fetchAndCacheCustomerInfo(isAppBackground: false).error
        expect(receivedError) == mockError
    }

    func testFetchAndCacheCustomerInfoClearsCustomerInfoTimestampIfBackendError() throws {
        mockBackend.stubbedGetCustomerInfoResult = .failure(.missingAppUserID())

        try self.fetchAndCacheCustomerInfo(isAppBackground: false)

        expect(self.mockDeviceCache.clearCustomerInfoCacheTimestampCount) == 1
    }

    func testFetchAndCacheCustomerInfoCachesIfSuccessful() throws {
        mockBackend.stubbedGetCustomerInfoResult = .success(mockCustomerInfo)

        let receivedCustomerInfo = try self.fetchAndCacheCustomerInfo(isAppBackground: false).value
        expect(receivedCustomerInfo) == self.mockCustomerInfo

        expect(self.mockDeviceCache.cacheCustomerInfoCount) == 1
        expect(self.customerInfoManagerChangesCallCount) == 1
        expect(self.customerInfoManagerLastCustomerInfoChange) == (old: nil, new: self.mockCustomerInfo)
    }

    func testFetchAndCacheCustomerInfoCallsCompletionOnMainThread() throws {
        mockBackend.stubbedGetCustomerInfoResult = .success(mockCustomerInfo)

        try self.fetchAndCacheCustomerInfo(isAppBackground: false)

        expect(self.mockOperationDispatcher.invokedDispatchAsyncOnMainThreadCount) == 1
    }

    @MainActor
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

        waitUntil { completed in
            self.customerInfoManager.fetchAndCacheCustomerInfoIfStale(appUserID: Self.appUserID,
                                                                      isAppBackgrounded: false) { _ in
                completed()
            }
        }

        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
    }

    func testFetchAndCacheCustomerInfoIfStaleFetchesIfCacheEmpty() throws {
        mockDeviceCache.stubbedIsCustomerInfoCacheStale = false

        try self.fetchAndCacheCustomerInfo(isAppBackground: false)

        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
    }

    func testSetLastSentCustomerInfo() {
        expect(self.customerInfoManager.lastSentCustomerInfo).to(beNil())
        self.customerInfoManager.setLastSentCustomerInfo(self.mockCustomerInfo)
        expect(self.customerInfoManager.lastSentCustomerInfo) === self.mockCustomerInfo
    }

    func testCustomerInfoReturnsFromCacheIfAvailable() {
        customerInfoManager.cache(customerInfo: mockCustomerInfo, appUserID: Self.appUserID)

        let receivedCustomerInfo = waitUntilValue { completed in
            self.customerInfoManager.customerInfo(appUserID: Self.appUserID, fetchPolicy: .default) { result in
                completed(result.value)
            }
        }

        expect(receivedCustomerInfo) == self.mockCustomerInfo
        expect(self.mockBackend.invokedGetSubscriberDataCount) == 0
    }

    func testCustomerInfoReturnsFromCacheAndRefreshesIfStale() {
        self.mockDeviceCache.stubbedIsCustomerInfoCacheStale = true
        self.mockBackend.stubbedGetCustomerInfoResult = .success(self.mockCustomerInfo)

        self.customerInfoManager.cache(customerInfo: self.mockCustomerInfo, appUserID: Self.appUserID)

        let info = waitUntilValue { completed in
            self.customerInfoManager.customerInfo(appUserID: Self.appUserID, fetchPolicy: .default) {
                completed($0.value)
            }
        }

        expect(info) == self.mockCustomerInfo
        expect(self.mockBackend.invokedGetSubscriberDataCount).toEventually(equal(1))
    }

    @MainActor
    func testCustomerInfoFetchesIfNoCache() {
        let appUserID = "myUser"

        waitUntil { completed in
            self.customerInfoManager.customerInfo(appUserID: appUserID, fetchPolicy: .default) { _ in
                // checking here to ensure that completion gets called from the backend call
                expect(self.mockBackend.invokedGetSubscriberDataCount) == 1

                completed()
            }
        }
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
                ]  as [String: Any],
                "other_purchases": [:] as [String: Any]
            ]  as [String: Any]
        ])

        let object = try info.jsonEncodedData
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
                "other_purchases": [:] as [String: Any]
            ]  as [String: Any]
        ])

        let object = try info.jsonEncodedData
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
        let oldSchemaVersion = Int(CustomerInfo.currentSchemaVersion)! - 2
        let data: [String: Any] = [
            "request_date": "2019-08-16T10:30:42Z",
            "schema_version": "\(oldSchemaVersion)",
            "subscriber": [
                "original_app_user_id": Self.appUserID,
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": ["product_a": ["expires_date": "2018-05-27T06:24:50Z", "period_type": "normal"]],
                "other_purchases": [:] as [String: Any]
            ] as [String: Any]
        ]

        let object = try JSONSerialization.data(withJSONObject: data, options: [])
        let appUserID = "myUser"
        mockDeviceCache.cachedCustomerInfo[appUserID] = object

        let receivedCustomerInfo = customerInfoManager.cachedCustomerInfo(appUserID: appUserID)
        expect(receivedCustomerInfo).to(beNil())
    }

    func testCachedCustomerInfoParsesVersion2() throws {
        let oldSchemaVersion = 2
        let data: [String: Any] = [
            "request_date": "2019-08-16T10:30:42Z",
            "schema_version": "\(oldSchemaVersion)",
            "subscriber": [
                "original_app_user_id": Self.appUserID,
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": ["product_a": ["expires_date": "2018-05-27T06:24:50Z", "period_type": "normal"]],
                "other_purchases": [:] as [String: Any]
            ]  as [String: Any]
        ]

        let object = try JSONSerialization.data(withJSONObject: data, options: [])
        let appUserID = "myUser"
        self.mockDeviceCache.cachedCustomerInfo[appUserID] = object

        let receivedCustomerInfo = self.customerInfoManager.cachedCustomerInfo(appUserID: appUserID)
        expect(receivedCustomerInfo).toNot(beNil())
    }

    func testCacheCustomerInfoStoresCorrectly() {
        let appUserID = "myUser"
        customerInfoManager.cache(customerInfo: mockCustomerInfo, appUserID: appUserID)

        expect(self.customerInfoManager.cachedCustomerInfo(appUserID: appUserID)) == mockCustomerInfo
        expect(self.mockDeviceCache.cacheCustomerInfoCount) == 1
    }

    func testCachesCustomerInfoWithVerifiedEntitlements() {
        let appUserID = "myUser"
        let info = self.mockCustomerInfo.copy(with: .verified)

        self.customerInfoManager.cache(customerInfo: info, appUserID: appUserID)

        expect(self.customerInfoManager.cachedCustomerInfo(appUserID: appUserID)) == info
        expect(self.mockDeviceCache.cacheCustomerInfoCount) == 1
    }

    func testCachesCustomerInfoWithEntitlementVerificationNotRequested() {
        let appUserID = "myUser"
        let info = self.mockCustomerInfo.copy(with: .notRequested)

        self.customerInfoManager.cache(customerInfo: info, appUserID: appUserID)

        expect(self.customerInfoManager.cachedCustomerInfo(appUserID: appUserID)) == info
        expect(self.mockDeviceCache.cacheCustomerInfoCount) == 1
    }

    func testCachesCustomerInfoWithFailedVerification() {
        let appUserID = "myUser"
        let info = self.mockCustomerInfo.copy(with: .failed)

        self.customerInfoManager.cache(customerInfo: info, appUserID: appUserID)

        expect(self.customerInfoManager.cachedCustomerInfo(appUserID: appUserID)) == info
        expect(self.mockDeviceCache.cacheCustomerInfoCount) == 1
    }

    func testDoesNotCacheCustomerInfoWithLocalEntitlements() throws {
        let appUserID = "myUser"
        let info = self.mockCustomerInfo.copy(with: .verifiedOnDevice)

        self.customerInfoManager.cache(customerInfo: info, appUserID: appUserID)

        expect(self.customerInfoManager.cachedCustomerInfo(appUserID: appUserID)).to(beNil())
        expect(self.mockDeviceCache.cacheCustomerInfoCount) == 0
        expect(self.mockDeviceCache.invokedClearCustomerInfoCache) == true

        self.logger.verifyMessageWasLogged(Strings.customerInfo.not_caching_offline_customer_info, level: .debug)
    }

    func testCacheCustomerInfoSendsToDelegateIfChanged() {
        self.customerInfoManager.cache(customerInfo: self.mockCustomerInfo, appUserID: "myUser")
        expect(self.customerInfoManagerChangesCallCount).toEventually(equal(1))
        expect(self.customerInfoManagerLastCustomerInfoChange) == (old: nil, new: self.mockCustomerInfo)
    }

    func testCacheCustomerInfoSendsMultipleUpdatesIfChange() throws {
        let newCustomerInfo = try CustomerInfo(data: [
            "request_date": "2023-12-21T02:40:36Z",
            "subscriber": [
                "original_app_user_id": "new user",
                "first_seen": "2019-06-17T16:05:33Z",
                "subscriptions": [:] as [String: Any],
                "other_purchases": [:] as [String: Any],
                "original_application_version": NSNull()
            ]  as [String: Any]
        ])

        self.customerInfoManager.cache(customerInfo: self.mockCustomerInfo, appUserID: "myUser")
        self.customerInfoManager.cache(customerInfo: newCustomerInfo, appUserID: "myUser")

        expect(self.customerInfoManagerChangesCallCount).toEventually(equal(2))
        expect(self.customerInfoManagerLastCustomerInfoChange) == (old: self.mockCustomerInfo, new: newCustomerInfo)
    }

    func testCacheCustomerInfoSendsToDelegateWhenComputedOnDevice() {
        let info = self.mockCustomerInfo.copy(with: .verifiedOnDevice)

        self.customerInfoManager.cache(customerInfo: info, appUserID: "myUser")
        expect(self.customerInfoManagerChangesCallCount).toEventually(equal(1))
        expect(self.customerInfoManagerLastCustomerInfoChange) == (old: nil, new: info)
    }

    func testCacheCustomerInfoSendsToDelegateAfterCachingComputedOnDevice() {
        let info1 = self.mockCustomerInfo.copy(with: .verifiedOnDevice)
        let info2 = self.mockCustomerInfo2.copy(with: .verifiedOnDevice)

        self.customerInfoManager.cache(customerInfo: info1, appUserID: info1.originalAppUserId)
        self.customerInfoManager.cache(customerInfo: info2, appUserID: info2.originalAppUserId)

        expect(self.customerInfoManagerChangesCallCount).toEventually(equal(2))
        expect(self.customerInfoManagerLastCustomerInfoChange) == (old: info1, new: info2)
    }

    func testClearCustomerInfoCacheClearsCorrectly() {
        let appUserID = "myUser"
        customerInfoManager.clearCustomerInfoCache(forAppUserID: appUserID)
        expect(self.mockDeviceCache.invokedClearCustomerInfoCache) == true
        expect(self.mockDeviceCache.invokedClearCustomerInfoCacheParameters?.appUserID) == appUserID
    }

    func testClearCustomerInfoCacheDoesNotResetLastSent() {
        let appUserID = "myUser"
        customerInfoManager.cache(customerInfo: mockCustomerInfo, appUserID: appUserID)
        expect(self.customerInfoManager.lastSentCustomerInfo) == self.mockCustomerInfo

        customerInfoManager.clearCustomerInfoCache(forAppUserID: appUserID)

        expect(self.customerInfoManager.lastSentCustomerInfo) === self.mockCustomerInfo
    }

}

class CustomerInfoManagerGetCustomerInfoTests: BaseCustomerInfoManagerTests {

    private var mockRefreshedCustomerInfo: CustomerInfo!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.mockRefreshedCustomerInfo = try CustomerInfo(data: [
            "request_date": "2019-12-21T02:40:36Z",
            "subscriber": [
                "original_app_user_id": Self.appUserID,
                "first_seen": "2020-06-17T16:05:33Z",
                "subscriptions": [:] as [String: Any],
                "other_purchases": [:] as [String: Any],
                "original_application_version": "1.0"
            ]  as [String: Any]
        ])
    }

    // MARK: - CacheFetchPolicy.fromCacheOnly

    func testCustomerInfoFromCacheOnlyReturnsFromCacheWhenAvailable() async throws {
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

    // See https://github.com/RevenueCat/purchases-ios/issues/2410
    func testObserverFetchingCustomerInfoDoesNotDeadlock() throws {
        let expectation = XCTestExpectation()

        let removeObservation = self.customerInfoManager.monitorChanges { [manager = self.customerInfoManager!] _, _ in
            // Re-fetch customer info when it changes.
            // This isn't necessary since it's passed as part of the change,
            // but it should not deadlock.
            manager.customerInfo(appUserID: Self.appUserID, fetchPolicy: .fetchCurrent) { _ in }
            expectation.fulfill()
        }
        defer { removeObservation() }

        self.customerInfoManager.cache(customerInfo: .emptyInfo, appUserID: Self.appUserID)
        self.wait(for: [expectation], timeout: 1)
    }

}
