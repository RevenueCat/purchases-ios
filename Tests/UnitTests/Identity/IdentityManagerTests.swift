//
// Created by RevenueCat.
// Copyright (c) 2019 RevenueCat. All rights reserved.
//

import Nimble
import XCTest

@testable import RevenueCat

class IdentityManagerTests: TestCase {

    private var mockDeviceCache: MockDeviceCache!
    private let mockBackend = MockBackend()
    private var mockCustomerInfoManager: MockCustomerInfoManager!
    private var mockAttributeSyncing: MockAttributeSyncing!

    private var mockIdentityAPI: MockIdentityAPI!
    private var mockCustomerInfo: CustomerInfo!

    private func create(appUserID: String?) -> IdentityManager {
        return IdentityManager(deviceCache: self.mockDeviceCache,
                               backend: self.mockBackend,
                               customerInfoManager: self.mockCustomerInfoManager,
                               attributeSyncing: self.mockAttributeSyncing,
                               appUserID: appUserID)
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.mockIdentityAPI = try XCTUnwrap(mockBackend.identity as? MockIdentityAPI)
        self.mockCustomerInfo = try CustomerInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "",
                "subscriptions": [:],
                "other_purchases": [:]
            ]])

        let systemInfo = MockSystemInfo(finishTransactions: false)

        self.mockDeviceCache = MockDeviceCache(sandboxEnvironmentDetector: systemInfo)
        self.mockCustomerInfoManager = MockCustomerInfoManager(operationDispatcher: MockOperationDispatcher(),
                                                               deviceCache: self.mockDeviceCache,
                                                               backend: MockBackend(),
                                                               systemInfo: systemInfo)
        self.mockAttributeSyncing = MockAttributeSyncing()
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
        let manager = self.create(appUserID: nil)

        let receivedResult = waitUntilValue { completed in
            manager.logIn(appUserID: "", completion: completed)
        }

        expect(receivedResult?.error) == .missingAppUserID()
    }

    func testLogInWithSameAppUserIDFetchesCustomerInfo() {
        let appUserID = "myUser"

        let manager = self.create(appUserID: nil)

        self.mockDeviceCache.stubbedAppUserID = appUserID

        let receivedResult = waitUntilValue { completed in
            manager.logIn(appUserID: appUserID, completion: completed)
        }

        expect(receivedResult).toNot(beNil())

        expect(self.mockIdentityAPI.invokedLogInCount) == 0
        expect(self.mockCustomerInfoManager.invokedCustomerInfoCount) == 1
    }

    func testLogInWithSameAppUserIDPassesBackendCustomerInfoErrors() {
        let appUserID = "myUser"

        let manager = create(appUserID: nil)

        self.mockDeviceCache.stubbedAppUserID = appUserID

        let stubbedError: BackendError = .missingAppUserID()

        self.mockCustomerInfoManager.stubbedCustomerInfoResult = .failure(stubbedError)

        let receivedResult = waitUntilValue { completed in
            manager.logIn(appUserID: appUserID, completion: completed)
        }

        expect(receivedResult?.error) == stubbedError

        expect(self.mockIdentityAPI.invokedLogInCount) == 0
        expect(self.mockCustomerInfoManager.invokedCustomerInfoCount) == 1
    }

    func testLogInCallsBackendLogin() {
        let oldAppUserID = "anonymous"
        let newAppUserID = "myUser"

        let manager = self.create(appUserID: nil)

        self.mockDeviceCache.stubbedAppUserID = oldAppUserID

        self.mockIdentityAPI.stubbedLogInCompletionResult = .success((mockCustomerInfo, true))

        let receivedResult = waitUntilValue { completed in
            manager.logIn(appUserID: newAppUserID, completion: completed)
        }

        expect(receivedResult?.value?.created) == true
        expect(receivedResult?.value?.info) == mockCustomerInfo

        expect(self.mockIdentityAPI.invokedLogInCount) == 1
        expect(self.mockCustomerInfoManager.invokedCustomerInfoCount) == 0
    }

    func testLogInPassesBackendLoginErrors() {
        let oldAppUserID = "anonymous"
        let newAppUserID = "myUser"
        self.mockDeviceCache.stubbedAppUserID = oldAppUserID

        let manager = self.create(appUserID: nil)

        let stubbedError: BackendError = .missingAppUserID()
        self.mockIdentityAPI.stubbedLogInCompletionResult = .failure(stubbedError)

        self.mockCustomerInfoManager.stubbedCustomerInfoResult = .failure(stubbedError)

        let receivedResult = waitUntilValue { completed in
            manager.logIn(appUserID: newAppUserID, completion: completed)
        }

        expect(receivedResult?.error) == stubbedError

        expect(self.mockIdentityAPI.invokedLogInCount) == 1
        expect(self.mockCustomerInfoManager.invokedCustomerInfoCount) == 0

        expect(self.mockDeviceCache.invokedClearCachesForAppUserID) == false
        expect(self.mockCustomerInfoManager.invokedCachedCustomerInfo) == false
    }

    func testLogInClearsCachesIfSuccessful() {
        let oldAppUserID = "anonymous"
        let newAppUserID = "myUser"
        self.mockDeviceCache.stubbedAppUserID = oldAppUserID

        let manager = self.create(appUserID: nil)

        self.mockIdentityAPI.stubbedLogInCompletionResult = .success((mockCustomerInfo, true))

        waitUntil { completed in
            manager.logIn(appUserID: newAppUserID) { _ in
                completed()
            }
        }

        expect(self.mockDeviceCache.invokedClearCachesForAppUserID) == true
    }

    func testLogInCachesNewCustomerInfoIfSuccessful() {
        let oldAppUserID = "anonymous"
        let newAppUserID = "myUser"

        let manager = self.create(appUserID: nil)

        self.mockDeviceCache.stubbedAppUserID = oldAppUserID

        self.mockIdentityAPI.stubbedLogInCompletionResult = .success((mockCustomerInfo, true))

        waitUntil { completed in
            manager.logIn(appUserID: newAppUserID) { _ in
                completed()
            }
        }

        expect(self.mockCustomerInfoManager.invokedCacheCustomerInfo) == true
        expect(self.mockCustomerInfoManager.invokedCacheCustomerInfoParameters?.info) == mockCustomerInfo
        expect(self.mockCustomerInfoManager.invokedCacheCustomerInfoParameters?.appUserID) == newAppUserID
    }

    func testLogOutCallsCompletionWithErrorIfUserAnonymous() {
        let manager = self.create(appUserID: nil)

        self.mockDeviceCache.stubbedAppUserID = IdentityManager.generateRandomID()

        let receivedError = waitUntilValue { completed in
            manager.logOut { error in
                completed(error as NSError?)
            }
        }

        expect(receivedError?.code) == ErrorCode.logOutAnonymousUserError.rawValue
    }

    func testLogOutCallsCompletionWithNoErrorIfSuccessful() {
        let manager = self.create(appUserID: nil)

        self.mockDeviceCache.stubbedAppUserID = "myUser"

        let receivedError = waitUntilValue { completed in
            manager.logOut(completion: completed)
        }

        expect(receivedError).to(beNil())
    }

    func testLogOutClearsCachesAndAttributionData() {
        let manager = self.create(appUserID: nil)

        self.mockDeviceCache.stubbedAppUserID = "myUser"
        waitUntil { completed in
            manager.logOut { _ in
                completed()
            }
        }

        expect(self.mockDeviceCache.invokedClearCachesForAppUserID) == true
        expect(self.mockDeviceCache.invokedClearLatestNetworkAndAdvertisingIdsSent) == true
    }

    func testLogInSyncsAttributes() {
        let manager = self.create(appUserID: "old_user")

        manager.logIn(appUserID: "nacho") { _ in }

        expect(self.mockAttributeSyncing.invokedSyncAttributesUserIDs) == ["old_user"]
    }

    func testLogOutSyncsAttributes() {
        let manager = self.create(appUserID: "nacho")

        manager.logOut { _ in }

        expect(self.mockAttributeSyncing.invokedSyncAttributesUserIDs) == ["nacho"]
    }

}

private extension IdentityManagerTests {

    func assertCorrectlyIdentified(_ manager: IdentityManager, expectedAppUserID: String) {
        expect(manager.currentAppUserID) == expectedAppUserID
        expect(self.mockDeviceCache.userIDStoredInCache!) == expectedAppUserID
        expect(manager.currentUserIsAnonymous) == false
    }

    func assertCorrectlyIdentifiedWithAnonymous(_ manager: IdentityManager, usingOldID: Bool = false) {
        if !usingOldID {
            expect(IdentityManager.userIsAnonymous(manager.currentAppUserID)) == true
            expect(IdentityManager.userIsAnonymous(self.mockDeviceCache.userIDStoredInCache!)) == true
        }
        expect(manager.currentUserIsAnonymous) == true
    }

}
