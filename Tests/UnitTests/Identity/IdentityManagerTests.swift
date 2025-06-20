//
// Created by RevenueCat.
// Copyright (c) 2019 RevenueCat. All rights reserved.
//

import Nimble
import XCTest

@testable @_spi(Internal) import RevenueCat

class IdentityManagerTests: TestCase {

    private var mockDeviceCache: MockDeviceCache!
    private let mockBackend = MockBackend()
    private var mockCustomerInfoManager: MockCustomerInfoManager!
    private var mockAttributeSyncing: MockAttributeSyncing!

    private var mockIdentityAPI: MockIdentityAPI!
    private var mockCustomerInfo: CustomerInfo!
    private var mockSystemInfo: MockSystemInfo!

    @discardableResult
    private func create(appUserID: String?) -> IdentityManager {
        return IdentityManager(deviceCache: self.mockDeviceCache,
                               systemInfo: self.mockSystemInfo,
                               backend: self.mockBackend,
                               customerInfoManager: self.mockCustomerInfoManager,
                               attributeSyncing: self.mockAttributeSyncing,
                               appUserID: appUserID)
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.mockIdentityAPI = try XCTUnwrap(mockBackend.identity as? MockIdentityAPI)
        self.mockCustomerInfo = .emptyInfo

        self.mockSystemInfo = MockSystemInfo(finishTransactions: false)

        self.mockDeviceCache = MockDeviceCache(systemInfo: self.mockSystemInfo)
        self.mockCustomerInfoManager = MockCustomerInfoManager(
            offlineEntitlementsManager: MockOfflineEntitlementsManager(),
            operationDispatcher: MockOperationDispatcher(),
            deviceCache: self.mockDeviceCache,
            backend: MockBackend(),
            transactionFetcher: MockStoreKit2TransactionFetcher(),
            transactionPoster: MockTransactionPoster(),
            systemInfo: self.mockSystemInfo
        )
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
        self.create(appUserID: "andy")
        expect(self.mockDeviceCache.invokedCleanupSubscriberAttributesCount) == 1
    }

    func testConfigureDoesNotInvalidateCachesIfNoCachedUserID() {
        self.mockCustomerInfoManager.stubbedCachedCustomerInfoResult = nil
        self.create(appUserID: "nacho")

        expect(self.mockDeviceCache.invokedClearCustomerInfoCache) == false
        expect(self.mockDeviceCache.invokedClearCachesForAppUserID) == false
        expect(self.mockBackend.invokedClearHTTPClientCaches) == false
    }

    func testConfigureDoesNotInvalidateCachesIfVerificationIsDisabled() {
        self.mockCustomerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo.copy(with: .notRequested)
        self.mockBackend.stubbedSignatureVerificationEnabled = false
        self.create(appUserID: "nacho")

        expect(self.mockDeviceCache.invokedClearCustomerInfoCache) == false
        expect(self.mockDeviceCache.invokedClearCachesForAppUserID) == false
        expect(self.mockBackend.invokedClearHTTPClientCaches) == false
    }

    func testConfigureDoesNotInvalidateCachesIfNoCachedUserIDAndVerificationIsEnabled() {
        self.mockCustomerInfoManager.stubbedCachedCustomerInfoResult = nil
        self.mockBackend.stubbedSignatureVerificationEnabled = true
        self.create(appUserID: "nacho")

        expect(self.mockDeviceCache.invokedClearCustomerInfoCache) == false
        expect(self.mockDeviceCache.invokedClearCachesForAppUserID) == false
        expect(self.mockBackend.invokedClearHTTPClientCaches) == false
    }

    func testConfigureDoesNotInvalidateCachesIfCachedUserIsVerified() {
        self.mockCustomerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo.copy(with: .verified)
        self.mockBackend.stubbedSignatureVerificationEnabled = true
        self.create(appUserID: "nacho")

        expect(self.mockDeviceCache.invokedClearCustomerInfoCache) == false
        expect(self.mockDeviceCache.invokedClearCachesForAppUserID) == false
        expect(self.mockBackend.invokedClearHTTPClientCaches) == false
    }

    func testConfigureInvalidesCacheIfVerificationIsEnabledButCachedUserIsNotVerified() throws {
        self.mockCustomerInfoManager.stubbedCachedCustomerInfoResult = self.mockCustomerInfo.copy(with: .notRequested)
        self.mockBackend.stubbedSignatureVerificationEnabled = true
        self.create(appUserID: "nacho")

        expect(self.mockDeviceCache.invokedClearCachesForAppUserID) == false
        expect(self.mockBackend.invokedClearHTTPClientCaches) == true
        expect(self.mockBackend.invokedClearHTTPClientCachesCount) == 1
        expect(self.mockDeviceCache.invokedClearCustomerInfoCache) == false

        self.logger.verifyMessageWasLogged(Strings.identity.invalidating_http_cache, level: .info)
    }

    func testIdentifyingCorrectlyIdentifies() {
        self.create(appUserID: "appUserToBeReplaced")

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
        expect(self.mockBackend.invokedClearHTTPClientCachesCount) == 1
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

    func testLogInCopiesAttributesToNewUserIfPreviousUserWasAnonymous() {
        let manager = self.create(appUserID: nil)
        let anonymousUserID = manager.currentAppUserID

        self.mockIdentityAPI.stubbedLogInCompletionResult = .success((mockCustomerInfo, true))

        waitUntil { completed in
            manager.logIn(appUserID: "test-user-id") { _ in
                completed()
            }
        }

        expect(self.mockDeviceCache.invokedCopySubscriberAttributesCount) == 1
        expect(self.mockDeviceCache.invokedCopySubscriberAttributesParameters?.oldAppUserID) == anonymousUserID
        expect(self.mockDeviceCache.invokedCopySubscriberAttributesParameters?.newAppUserID) == "test-user-id"
    }

    func testLogInDoesNotCopyAttributesToNewUserIfPreviousUserWasNotAnonymous() {
        let manager = self.create(appUserID: "old-user-id")

        self.mockIdentityAPI.stubbedLogInCompletionResult = .success((mockCustomerInfo, true))

        waitUntil { completed in
            manager.logIn(appUserID: "test-user-id") { _ in
                completed()
            }
        }

        expect(self.mockDeviceCache.invokedCopySubscriberAttributes) == false
    }

    // MARK: - Switch user

    func testSwitchUserResetsAllCaches() {
        let manager = self.create(appUserID: "old-test-user-id")

        manager.switchUser(to: "test-user-id")

        expect(self.mockDeviceCache.clearCachesCalledOldUserID) == "old-test-user-id"
        expect(self.mockDeviceCache.clearCachesCalleNewUserID) == "test-user-id"
        expect(self.mockDeviceCache.invokedClearLatestNetworkAndAdvertisingIdsSentCount) == 1
        expect(self.mockDeviceCache
            .invokedClearLatestNetworkAndAdvertisingIdsSentParameters?.appUserID) == "test-user-id"
        expect(self.mockBackend.invokedClearHTTPClientCachesCount) == 1
    }

    // MARK: - UI Preview mode user

    func testConfigureWithUIPreviewModeUsesPreviewModeUserID() {
        let dangerousSettings = DangerousSettings(uiPreviewMode: true)
        self.mockSystemInfo = MockSystemInfo(
            platformInfo: nil,
            finishTransactions: false,
            dangerousSettings: dangerousSettings,
            preferredLocalesProvider: .mock()
        )

        let manager = create(appUserID: nil)

        expect(manager.currentAppUserID) == IdentityManager.uiPreviewModeAppUserID
        expect(manager.currentUserIsAnonymous) == false
    }

    func testConfigureWithUIPreviewModeIgnoresProvidedAppUserID() {
        let dangerousSettings = DangerousSettings(uiPreviewMode: true)
        self.mockSystemInfo = MockSystemInfo(
            platformInfo: nil,
            finishTransactions: false,
            dangerousSettings: dangerousSettings,
            preferredLocalesProvider: .mock()
        )

        let manager = create(appUserID: "test_user")

        expect(manager.currentAppUserID) == IdentityManager.uiPreviewModeAppUserID
        expect(manager.currentUserIsAnonymous) == false
    }

    func testConfigureWithoutUIPreviewModeUsesNormalAppUserID() {
        let dangerousSettings = DangerousSettings(uiPreviewMode: false)
        self.mockSystemInfo = MockSystemInfo(
            platformInfo: nil,
            finishTransactions: false,
            dangerousSettings: dangerousSettings
        )

        let manager = create(appUserID: "test_user")

        expect(manager.currentAppUserID) == "test_user"
        expect(manager.currentUserIsAnonymous) == false
    }

    func testConfigureWithoutUIPreviewModeUsesAnonymousIDWhenNoUserProvided() {
        let dangerousSettings = DangerousSettings(uiPreviewMode: false)
        self.mockSystemInfo = MockSystemInfo(
            platformInfo: nil,
            finishTransactions: false,
            dangerousSettings: dangerousSettings
        )

        let manager = create(appUserID: nil)

        expect(manager.currentAppUserID) != IdentityManager.uiPreviewModeAppUserID
        assertCorrectlyIdentifiedWithAnonymous(manager)
    }

    func testLogInFailsInUIPreviewMode() throws {
        let dangerousSettings = DangerousSettings(uiPreviewMode: true)
        self.mockSystemInfo = MockSystemInfo(
            platformInfo: nil,
            finishTransactions: false,
            dangerousSettings: dangerousSettings
        )

        let manager = create(appUserID: nil)

        let receivedResult = waitUntilValue { completed in
            manager.logIn(appUserID: "user_id", completion: completed)
        }

        expect(receivedResult?.error) == .unsupportedInUIPreviewMode()
    }

    func testLogInFailsWhenUsingUIPreviewModeAppUserID() throws {
        let dangerousSettings = DangerousSettings(uiPreviewMode: false)
        self.mockSystemInfo = MockSystemInfo(
            platformInfo: nil,
            finishTransactions: false,
            dangerousSettings: dangerousSettings
        )

        let manager = create(appUserID: nil)

        let receivedResult = waitUntilValue { completed in
            manager.logIn(appUserID: IdentityManager.uiPreviewModeAppUserID, completion: completed)
        }

        expect(receivedResult?.error) == .unsupportedInUIPreviewMode()
    }

    func testLogOutCallsCompletionWithErrorInUIPreviewMode() {
        let dangerousSettings = DangerousSettings(uiPreviewMode: true)
        self.mockSystemInfo = MockSystemInfo(
            platformInfo: nil,
            finishTransactions: false,
            dangerousSettings: dangerousSettings
        )

        let manager = create(appUserID: "my_user_id")

        let receivedError = waitUntilValue { completed in
            manager.logOut { error in
                completed(error as NSError?)
            }
        }

        expect(receivedError?.code) == ErrorCode.unsupportedError.rawValue
    }

    func testLogOutCallsCompletionWithErrorInUIPreviewModeIfInitializedWithAnonymousUser() {
        let dangerousSettings = DangerousSettings(uiPreviewMode: true)
        self.mockSystemInfo = MockSystemInfo(
            platformInfo: nil,
            finishTransactions: false,
            dangerousSettings: dangerousSettings
        )

        let manager = create(appUserID: nil)

        let receivedError = waitUntilValue { completed in
            manager.logOut { error in
                completed(error as NSError?)
            }
        }

        expect(receivedError?.code) == ErrorCode.unsupportedError.rawValue
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
