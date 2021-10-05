//
// Created by RevenueCat.
// Copyright (c) 2019 RevenueCat. All rights reserved.
//

import XCTest
import Nimble

@testable import RevenueCat

class IdentityManagerTests: XCTestCase {

    private var identityManager: IdentityManager!
    private var mockDeviceCache: MockDeviceCache!
    private let mockBackend = MockBackend()
    private let mockCustomerInfoManager = MockCustomerInfoManager(operationDispatcher: MockOperationDispatcher(),
                                                                    deviceCache: MockDeviceCache(),
                                                                    backend: MockBackend(),
                                                                    systemInfo: try! MockSystemInfo(platformFlavor: nil,
                                                                                               platformFlavorVersion: nil,
                                                                                               finishTransactions: false))

    let mockCustomerInfo = CustomerInfo(data: [
        "request_date": "2019-08-16T10:30:42Z",
        "subscriber": [
            "first_seen": "2019-07-17T00:05:54Z",
            "original_app_user_id": "",
            "subscriptions": [:],
            "other_purchases": [:]
        ]])

    override func setUp() {
        super.setUp()
        self.mockDeviceCache = MockDeviceCache()
        self.identityManager = IdentityManager(deviceCache: mockDeviceCache,
                                               backend: mockBackend,
                                               customerInfoManager: mockCustomerInfoManager)
    }

    func testConfigureWithAnonymousUserIDGeneratesAnAppUserID() {
        self.identityManager.configure(appUserID: nil)
        assertCorrectlyIdentifiedWithAnonymous()
    }

    func testAnonymousIDsMatchesFormat() {
        self.identityManager.configure(appUserID: nil)
        assertCorrectlyIdentifiedWithAnonymous()
    }

    func testConfigureSavesTheIDInTheCache() {
        self.identityManager.configure(appUserID: "cesar")
        assertCorrectlyIdentified(expectedAppUserID: "cesar")
    }

    func testConfigureCleansUpSubscriberAttributes() {
        identityManager.configure(appUserID: "andy")
        expect(self.mockDeviceCache.invokedCleanupSubscriberAttributesCount) == 1
    }

    func testConfigureWithAnonymousUserSavesTheIDInTheCache() {
        self.identityManager.configure(appUserID: nil)
        assertCorrectlyIdentifiedWithAnonymous()
    }

    func testIdentifyingClearsCaches() {
        self.identityManager.configure(appUserID: "cesar")
        let initialAppUserID: String = self.identityManager.currentAppUserID
        let newAppUserID = "cesar"
        self.identityManager.identify(appUserID: newAppUserID){ (error: Error?) in }
        expect(self.mockDeviceCache.clearCachesCalledOldUserID).toEventually(equal(initialAppUserID))
    }

    func testIdentifyingCorrectlyIdentifies() {
        self.identityManager.configure(appUserID: "appUserToBeReplaced")
        let newAppUserID = "cesar"
        self.identityManager.identify(appUserID: newAppUserID){ (error: Error?) in }
        assertCorrectlyIdentified(expectedAppUserID: newAppUserID)
    }

    func testCreateAliasCallsBackend() {
        self.mockBackend.invokedCreateAlias = false
        self.mockDeviceCache.stubbedAppUserID = "appUserID"

        self.identityManager.createAlias(appUserID: "cesar"){ (error: Error?) in
        }

        expect(self.mockBackend.invokedCreateAlias).toEventually(beTrue())
    }

    func testCreateAliasFatalErrorsIfCurrentAppUserIDIsNil() {
        self.mockBackend.invokedCreateAlias = false
        self.mockDeviceCache.stubbedAppUserID = nil
        let expectedMessage = "currentAppUserID is nil. This might happen if the cache in UserDefaults is " +
                              "unintentionally cleared."
        expectFatalError(expectedMessage: expectedMessage) {
            self.identityManager.createAlias(appUserID: "cesar"){ _ in }
        }
    }

    func testCreateAliasCallsCompletionWithErrorIfNilAppUserID() {
        self.mockBackend.invokedCreateAlias = false
        self.mockDeviceCache.stubbedAppUserID = "cesar"
        var completionCalled = false
        var receivedNSError: NSError?
        self.identityManager.createAlias(appUserID: ""){ (error: Error?) in
            completionCalled = true

            guard let receivedError = error else { fatalError() }
            receivedNSError = receivedError as NSError
            expect(receivedNSError!.code) == ErrorCode.missingAppUserIDForAliasCreationError.rawValue
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedNSError).toNotEventually(beNil())
    }

    func testCreateAliasIdentifiesWhenSuccessful() {
        self.mockDeviceCache.cache(appUserID: "appUserID")
        mockBackend.stubbedCreateAliasCompletionResult = (nil, ())

        self.identityManager.createAlias(appUserID: "cesar"){ (error: Error?) in
        }
        assertCorrectlyIdentified(expectedAppUserID: "cesar")
    }

    func testCreateAliasClearsCachesForPreviousUser() {
        self.identityManager.configure(appUserID: nil)
        let initialAppUserID: String = self.identityManager.currentAppUserID
        mockBackend.stubbedCreateAliasCompletionResult = (nil, ())
        self.identityManager.createAlias(appUserID: "cesar"){ (error: Error?) in
        }
        expect(self.mockDeviceCache.clearCachesCalledOldUserID).to(equal(initialAppUserID))
    }

    func testCreateAliasForwardsErrors() {
        self.mockBackend.stubbedCreateAliasCompletionResult = (ErrorUtils.backendError(withBackendCode: BackendErrorCode.invalidAPIKey.rawValue as NSNumber,
                                                                                       backendMessage: "Invalid credentials",
                                                                                       finishable: false), ())
        var error: Error? = nil
        self.mockDeviceCache.stubbedAppUserID = "appUserID"

        self.identityManager.createAlias(appUserID: "cesar"){ (newError: Error?) in
            error = newError
        }
        expect(error).toNot(beNil())
    }

    func testResetClearsOldCaches() {
        self.identityManager.configure(appUserID: nil)
        let initialAppUserID: String = self.identityManager.currentAppUserID
        self.identityManager.resetAppUserID()
        expect(self.mockDeviceCache.clearCachesCalledOldUserID).to(equal(initialAppUserID))
    }

    func testResetCreatesRandomIDAndCachesIt() {
        self.identityManager.configure(appUserID: "cesar")
        self.identityManager.resetAppUserID()
        assertCorrectlyIdentifiedWithAnonymous()
    }

    func testIdentifyingWhenUserIsAnonymousCreatesAlias() {
        self.identityManager.configure(appUserID: nil)
        self.mockBackend.stubbedCreateAliasCompletionResult = (nil, ())
        self.mockDeviceCache.cache(appUserID: "$RCAnonymousID:5d73fc46744f4e0b99e524c6763dd7fc")

        self.identityManager.identify(appUserID: "cesar"){ (error: Error?) in }
        expect(self.mockBackend.invokedCreateAlias).toEventually(beTrue())
    }

    func testMigrationFromRandomIDConfiguringAnonymously() {
        self.mockDeviceCache.stubbedLegacyAppUserID = "an_old_random"

        self.identityManager.configure(appUserID: nil)
        assertCorrectlyIdentifiedWithAnonymous(usingOldID: true)
        expect(self.identityManager.currentAppUserID).to(equal("an_old_random"))
    }

    func testMigrationFromRandomIDConfiguringWithUser() {
        self.mockDeviceCache.stubbedLegacyAppUserID = "an_old_random"
        self.identityManager.configure(appUserID: "cesar")
        assertCorrectlyIdentified(expectedAppUserID: "cesar")
    }

    func testLogInFailsIfEmptyAppUserID() {
        var completionCalled: Bool = false
        var receivedCreated: Bool = false
        var receivedCustomerInfo: CustomerInfo?
        var receivedError: Error?
        identityManager.logIn(appUserID: ""){ customerInfo, created, error in
            completionCalled = true
            receivedCreated = created
            receivedCustomerInfo = customerInfo
            receivedError = error
        }

        expect(completionCalled).toEventually(beTrue())

        expect(receivedCreated) == false
        expect(receivedCustomerInfo).to(beNil())
        expect(receivedError).toNot(beNil())

        let receivedNSError = (receivedError! as NSError)
        expect(receivedNSError.code) == ErrorCode.invalidAppUserIdError.rawValue
    }


    func testLogInWithSameAppUserIDFetchesCustomerInfo() {
        var completionCalled: Bool = false
        let appUserID = "myUser"
        mockDeviceCache.stubbedAppUserID = appUserID
        identityManager.logIn(appUserID: appUserID){ customerInfo, created, error in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())

        expect(self.mockBackend.invokedLogInCount) == 0
        expect(self.mockCustomerInfoManager.invokedCustomerInfoCount) == 1
    }

    func testLogInWithSameAppUserIDPassesBackendCustomerInfoErrors() {
        var completionCalled: Bool = false
        let appUserID = "myUser"
        mockDeviceCache.stubbedAppUserID = appUserID
        var receivedCreated: Bool = true
        var receivedCustomerInfo: CustomerInfo?
        var receivedError: NSError?

        let stubbedError = NSError(domain: RCPurchasesErrorCodeDomain,
                                   code: ErrorCode.invalidAppUserIdError.rawValue,
                                   userInfo: [:])

        self.mockCustomerInfoManager.stubbedError = stubbedError
        identityManager.logIn(appUserID: appUserID){ customerInfo, created, error in
            completionCalled = true
            receivedCreated = created
            receivedCustomerInfo = customerInfo
            receivedError = error as NSError?
        }

        expect(completionCalled).toEventually(beTrue())

        expect(receivedCreated) == false
        expect(receivedCustomerInfo).to(beNil())
        expect(receivedError) == stubbedError

        expect(self.mockBackend.invokedLogInCount) == 0
        expect(self.mockCustomerInfoManager.invokedCustomerInfoCount) == 1
    }

    func testLogInCallsBackendLogin() {
        var completionCalled: Bool = false
        let oldAppUserID = "anonymous"
        let newAppUserID = "myUser"
        mockDeviceCache.stubbedAppUserID = oldAppUserID
        var receivedCreated: Bool = false
        var receivedCustomerInfo: CustomerInfo?
        var receivedError: NSError?

        self.mockBackend.stubbedLogInCompletionResult = (mockCustomerInfo, true, nil)

        identityManager.logIn(appUserID: newAppUserID){ customerInfo, created, error in
            completionCalled = true
            receivedCreated = created
            receivedCustomerInfo = customerInfo
            receivedError = error as NSError?
        }

        expect(completionCalled).toEventually(beTrue())

        expect(receivedCreated).to(equal(true))
        expect(receivedCustomerInfo).to(equal(mockCustomerInfo))
        expect(receivedError).to(beNil())

        expect(self.mockBackend.invokedLogInCount) == 1
        expect(self.mockCustomerInfoManager.invokedCustomerInfoCount) == 0
    }

    func testLogInPassesBackendLoginErrors() {
        var completionCalled: Bool = false
        let oldAppUserID = "anonymous"
        let newAppUserID = "myUser"
        mockDeviceCache.stubbedAppUserID = oldAppUserID
        var receivedCreated: Bool = false
        var receivedCustomerInfo: CustomerInfo?
        var receivedError: NSError?

        let stubbedError = NSError(domain: RCPurchasesErrorCodeDomain,
                                   code: ErrorCode.invalidAppUserIdError.rawValue,
                                   userInfo: [:])
        self.mockBackend.stubbedLogInCompletionResult = (nil, false, stubbedError)

        self.mockCustomerInfoManager.stubbedError = stubbedError

        identityManager.logIn(appUserID: newAppUserID){ customerInfo, created, error in
            completionCalled = true
            receivedCreated = created
            receivedCustomerInfo = customerInfo
            receivedError = error as NSError?
        }

        expect(completionCalled).toEventually(beTrue())

        expect(receivedCreated) == false
        expect(receivedCustomerInfo).to(beNil())
        expect(receivedError) == stubbedError

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

        self.mockBackend.stubbedLogInCompletionResult = (mockCustomerInfo, true, nil)

        identityManager.logIn(appUserID: newAppUserID){ customerInfo, created, error in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())

        expect(self.mockDeviceCache.invokedClearCachesForAppUserID) == true
    }

    func testLogInCachesNewCustomerInfoIfSuccessful() {
        var completionCalled: Bool = false
        let oldAppUserID = "anonymous"
        let newAppUserID = "myUser"
        mockDeviceCache.stubbedAppUserID = oldAppUserID

        self.mockBackend.stubbedLogInCompletionResult = (mockCustomerInfo, true, nil)

        identityManager.logIn(appUserID: newAppUserID){ customerInfo, created, error in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())

        expect(self.mockCustomerInfoManager.invokedCacheCustomerInfo) == true
        expect(self.mockCustomerInfoManager.invokedCacheCustomerInfoParameters?.info) == mockCustomerInfo
        expect(self.mockCustomerInfoManager.invokedCacheCustomerInfoParameters?.appUserID) == newAppUserID
    }

    func testLogOutCallsCompletionWithErrorIfUserAnonymous() {
        mockDeviceCache.stubbedAppUserID = identityManager.generateRandomID()
        var completionCalled = false
        var receivedError: Error?
        identityManager.logOut { error in
            completionCalled = true
            receivedError = error
        }
        expect(completionCalled).toEventually(beTrue())
        expect(receivedError).toNot(beNil())
        expect((receivedError as NSError?)?.code) == ErrorCode.logOutAnonymousUserError.rawValue
    }

    func testLogOutCallsCompletionWithNoErrorIfSuccessful() {
        mockDeviceCache.stubbedAppUserID = "myUser"
        var completionCalled = false
        var receivedError: Error?
        identityManager.logOut { error in
            completionCalled = true
            receivedError = error
        }
        expect(completionCalled).toEventually(beTrue())
        expect(receivedError).to(beNil())
    }

    func testLogOutClearsCachesAndAttributionData() {
        mockDeviceCache.stubbedAppUserID = "myUser"
        var completionCalled = false
        identityManager.logOut { error in
            completionCalled = true
        }
        expect(completionCalled).toEventually(beTrue())

        expect(self.mockDeviceCache.invokedClearCachesForAppUserID) == true
        expect(self.mockDeviceCache.invokedClearLatestNetworkAndAdvertisingIdsSent) == true
    }

}

private extension IdentityManagerTests {

    func assertCorrectlyIdentified(expectedAppUserID: String) {
        expect(self.identityManager.currentAppUserID).to(equal(expectedAppUserID))
        expect(self.mockDeviceCache.userIDStoredInCache!).to(equal(expectedAppUserID));
        expect(self.identityManager.currentUserIsAnonymous).to(beFalse())
    }

    func assertCorrectlyIdentifiedWithAnonymous(usingOldID: Bool = false) {
        if (!usingOldID) {
            expect(self.identityManager.currentAppUserID.range(of: #"\$RCAnonymousID:([a-z0-9]{32})$"#, options: .regularExpression)).toNot(beNil())
            expect(self.mockDeviceCache.userIDStoredInCache!.range(of: #"\$RCAnonymousID:([a-z0-9]{32})$"#, options: .regularExpression)).toNot(beNil())
        }
        expect(self.identityManager.currentUserIsAnonymous).to(beTrue())
    }

}
