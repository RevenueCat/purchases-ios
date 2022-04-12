//
// Created by RevenueCat.
// Copyright (c) 2019 RevenueCat. All rights reserved.
//

import Nimble
import XCTest

@testable import RevenueCat

class IdentityManagerTests: XCTestCase {

    private var mockDeviceCache: MockDeviceCache!
    private let mockBackend = MockBackend()
    private var mockCustomerInfoManager: MockCustomerInfoManager!

    private let mockCustomerInfo = CustomerInfo(testData: [
        "request_date": "2019-08-16T10:30:42Z",
        "subscriber": [
            "first_seen": "2019-07-17T00:05:54Z",
            "original_app_user_id": "",
            "subscriptions": [:],
            "other_purchases": [:]
        ]])!

    private func create(appUserID: String?) -> IdentityManager {
        return IdentityManager(deviceCache: mockDeviceCache,
                               backend: mockBackend,
                               customerInfoManager: mockCustomerInfoManager,
                               appUserID: appUserID)
    }

    override func setUp() {
        super.setUp()

        let systemInfo = MockSystemInfo(finishTransactions: false)

        self.mockDeviceCache = MockDeviceCache(systemInfo: systemInfo)
        self.mockCustomerInfoManager = MockCustomerInfoManager(operationDispatcher: MockOperationDispatcher(),
                                                               deviceCache: self.mockDeviceCache,
                                                               backend: MockBackend(),
                                                               systemInfo: systemInfo)
    }

    func testConfigureWithAnonymousUserIDGeneratesAnAppUserID() {
        let manager = create(appUserID: nil)
        assertCorrectlyIdentifiedWithAnonymous(manager)
    }

    func testConfigureSavesTheIDInTheCache() {
        let manager = create(appUserID: "cesar")
        assertCorrectlyIdentified(manager, expectedAppUserID: "cesar")
    }

    func testAppUserIDDoesNotTrimTrailingOrLeadingSpaces() {
        let name = "  user with spaces "
        let manager = create(appUserID: name)
        assertCorrectlyIdentified(manager, expectedAppUserID: name)
    }

    func testConfigureCleansUpSubscriberAttributes() {
        _ = create(appUserID: "andy")
        expect(self.mockDeviceCache.invokedCleanupSubscriberAttributesCount) == 1
    }

    func testIdentifyingCorrectlyIdentifies() {
        _ = create(appUserID: "appUserToBeReplaced")

        let newAppUserID = "cesar"
        let newManager = create(appUserID: newAppUserID)
        assertCorrectlyIdentified(newManager, expectedAppUserID: newAppUserID)
    }

    func testNilAppUserIDBecomesAnonimous() {
        assertCorrectlyIdentifiedWithAnonymous(create(appUserID: nil))
    }

    func testEmptyAppUserIDBecomesAnonymous() {
        assertCorrectlyIdentifiedWithAnonymous(create(appUserID: ""))
    }

    func testEmptyAppUserWithSpacesIDBecomesAnonymous() {
        assertCorrectlyIdentifiedWithAnonymous(create(appUserID: "  "))
    }

    func testMigrationFromRandomIDConfiguringAnonymously() {
        self.mockDeviceCache.stubbedLegacyAppUserID = "an_old_random"

        let manager = create(appUserID: nil)
        assertCorrectlyIdentifiedWithAnonymous(manager, usingOldID: true)
        expect(manager.currentAppUserID).to(equal("an_old_random"))
    }

    func testMigrationFromRandomIDConfiguringWithUser() {
        self.mockDeviceCache.stubbedLegacyAppUserID = "an_old_random"
        let manager = create(appUserID: "cesar")
        assertCorrectlyIdentified(manager, expectedAppUserID: "cesar")
    }

    func testLogInFailsIfEmptyAppUserID() throws {
        var receivedResult: Result<(info: CustomerInfo, created: Bool), BackendError>?

        let manager = create(appUserID: nil)

        manager.logIn(appUserID: "") { result in
            receivedResult = result
        }

        expect(receivedResult).toEventuallyNot(beNil())
        expect(receivedResult?.error) == .missingAppUserID()
    }

    func testLogInWithSameAppUserIDFetchesCustomerInfo() {
        let appUserID = "myUser"
        var receivedResult: Result<(info: CustomerInfo, created: Bool), BackendError>?

        let manager = create(appUserID: nil)

        mockDeviceCache.stubbedAppUserID = appUserID
        manager.logIn(appUserID: appUserID) { result in
            receivedResult = result
        }

        expect(receivedResult).toEventuallyNot(beNil())

        expect(self.mockBackend.invokedLogInCount) == 0
        expect(self.mockCustomerInfoManager.invokedCustomerInfoCount) == 1
    }

    func testLogInWithSameAppUserIDPassesBackendCustomerInfoErrors() {
        let appUserID = "myUser"

        let manager = create(appUserID: nil)

        mockDeviceCache.stubbedAppUserID = appUserID
        var receivedResult: Result<(info: CustomerInfo, created: Bool), BackendError>?

        let stubbedError: BackendError = .missingAppUserID()

        self.mockCustomerInfoManager.stubbedCustomerInfoResult = .failure(stubbedError)
        manager.logIn(appUserID: appUserID) { result in
            receivedResult = result
        }

        expect(receivedResult).toEventuallyNot(beNil())

        expect(receivedResult?.error) == stubbedError

        expect(self.mockBackend.invokedLogInCount) == 0
        expect(self.mockCustomerInfoManager.invokedCustomerInfoCount) == 1
    }

    func testLogInCallsBackendLogin() {
        let oldAppUserID = "anonymous"
        let newAppUserID = "myUser"

        let manager = create(appUserID: nil)

        mockDeviceCache.stubbedAppUserID = oldAppUserID
        var receivedResult: Result<(info: CustomerInfo, created: Bool), BackendError>?

        self.mockBackend.stubbedLogInCompletionResult = .success((mockCustomerInfo, true))

        manager.logIn(appUserID: newAppUserID) { result in
            receivedResult = result
        }

        expect(receivedResult).toEventuallyNot(beNil())

        expect(receivedResult?.value?.created) == true
        expect(receivedResult?.value?.info) == mockCustomerInfo

        expect(self.mockBackend.invokedLogInCount) == 1
        expect(self.mockCustomerInfoManager.invokedCustomerInfoCount) == 0
    }

    func testLogInPassesBackendLoginErrors() {
        let oldAppUserID = "anonymous"
        let newAppUserID = "myUser"
        mockDeviceCache.stubbedAppUserID = oldAppUserID

        var receivedResult: Result<(info: CustomerInfo, created: Bool), BackendError>?

        let manager = create(appUserID: nil)

        let stubbedError: BackendError = .missingAppUserID()
        self.mockBackend.stubbedLogInCompletionResult = .failure(stubbedError)

        self.mockCustomerInfoManager.stubbedCustomerInfoResult = .failure(stubbedError)

        manager.logIn(appUserID: newAppUserID) { result in
            receivedResult = result
        }

        expect(receivedResult).toEventuallyNot(beNil())

        expect(receivedResult?.error) == stubbedError

        expect(self.mockBackend.invokedLogInCount) == 1
        expect(self.mockCustomerInfoManager.invokedCustomerInfoCount) == 0

        expect(self.mockDeviceCache.invokedClearCachesForAppUserID) == false
        expect(self.mockCustomerInfoManager.invokedCachedCustomerInfo) == false
    }

    func testLogInClearsCachesIfSuccessful() {
        var completionCalled: Bool = false
        let oldAppUserID = "anonymous"
        let newAppUserID = "myUser"
        mockDeviceCache.stubbedAppUserID = oldAppUserID

        let manager = create(appUserID: nil)

        self.mockBackend.stubbedLogInCompletionResult = .success((mockCustomerInfo, true))

        manager.logIn(appUserID: newAppUserID) { _ in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())

        expect(self.mockDeviceCache.invokedClearCachesForAppUserID) == true
    }

    func testLogInCachesNewCustomerInfoIfSuccessful() {
        var completionCalled: Bool = false
        let oldAppUserID = "anonymous"
        let newAppUserID = "myUser"

        let manager = create(appUserID: nil)

        mockDeviceCache.stubbedAppUserID = oldAppUserID

        self.mockBackend.stubbedLogInCompletionResult = .success((mockCustomerInfo, true))

        manager.logIn(appUserID: newAppUserID) { _ in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())

        expect(self.mockCustomerInfoManager.invokedCacheCustomerInfo) == true
        expect(self.mockCustomerInfoManager.invokedCacheCustomerInfoParameters?.info) == mockCustomerInfo
        expect(self.mockCustomerInfoManager.invokedCacheCustomerInfoParameters?.appUserID) == newAppUserID
    }

    func testLogOutCallsCompletionWithErrorIfUserAnonymous() {
        let manager = create(appUserID: nil)

        mockDeviceCache.stubbedAppUserID = IdentityManager.generateRandomID()
        var completionCalled = false
        var receivedError: Error?
        manager.logOut { error in
            completionCalled = true
            receivedError = error
        }
        expect(completionCalled).toEventually(beTrue())
        expect(receivedError).toNot(beNil())
        expect((receivedError as NSError?)?.code) == ErrorCode.logOutAnonymousUserError.rawValue
    }

    func testLogOutCallsCompletionWithNoErrorIfSuccessful() {
        let manager = create(appUserID: nil)

        mockDeviceCache.stubbedAppUserID = "myUser"
        var completionCalled = false
        var receivedError: Error?
        manager.logOut { error in
            completionCalled = true
            receivedError = error
        }
        expect(completionCalled).toEventually(beTrue())
        expect(receivedError).to(beNil())
    }

    func testLogOutClearsCachesAndAttributionData() {
        let manager = create(appUserID: nil)

        mockDeviceCache.stubbedAppUserID = "myUser"
        var completionCalled = false
        manager.logOut { _ in
            completionCalled = true
        }
        expect(completionCalled).toEventually(beTrue())

        expect(self.mockDeviceCache.invokedClearCachesForAppUserID) == true
        expect(self.mockDeviceCache.invokedClearLatestNetworkAndAdvertisingIdsSent) == true
    }

}

private extension IdentityManagerTests {

    func assertCorrectlyIdentified(_ manager: IdentityManager, expectedAppUserID: String) {
        expect(manager.currentAppUserID).to(equal(expectedAppUserID))
        expect(self.mockDeviceCache.userIDStoredInCache!).to(equal(expectedAppUserID))
        expect(manager.currentUserIsAnonymous).to(beFalse())
    }

    func assertCorrectlyIdentifiedWithAnonymous(_ manager: IdentityManager, usingOldID: Bool = false) {
        if !usingOldID {
            var obtainedRange = manager.currentAppUserID.range(
                of: IdentityManager.anonymousRegex,
                options: .regularExpression
            )
            expect(obtainedRange).toNot(beNil())

            obtainedRange = self.mockDeviceCache.userIDStoredInCache!.range(
                of: IdentityManager.anonymousRegex,
                options: .regularExpression
            )
            expect(obtainedRange).toNot(beNil())
        }
        expect(manager.currentUserIsAnonymous).to(beTrue())
    }

}
