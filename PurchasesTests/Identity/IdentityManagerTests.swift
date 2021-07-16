//
// Created by RevenueCat.
// Copyright (c) 2019 RevenueCat. All rights reserved.
//

import XCTest
import Nimble

import Purchases

class IdentityManagerTests: XCTestCase {

    private var identityManager: RCIdentityManager!
    private var mockDeviceCache: MockDeviceCache!
    private let mockBackend = MockBackend()
    private let mockPurchaserInfoManager = MockPurchaserInfoManager()

    let mockPurchaserInfo = Purchases.PurchaserInfo(data: [
        "subscriber": [
            "subscriptions": [:],
            "other_purchases": [:],
            "original_application_version": NSNull()
        ]])!

    override func setUp() {
        super.setUp()
        self.mockDeviceCache = MockDeviceCache()
        self.identityManager = RCIdentityManager(mockDeviceCache,
                                                 backend: mockBackend,
                                                 purchaserInfoManager: mockPurchaserInfoManager)
    }

    func testConfigureWithAnonymousUserIDGeneratesAnAppUserID() {
        self.identityManager.configure(withAppUserID: nil)
        assertCorrectlyIdentifiedWithAnonymous()
    }

    func testAnonymousIDsMatchesFormat() {
        self.identityManager.configure(withAppUserID: nil)
        assertCorrectlyIdentifiedWithAnonymous()
    }

    func testConfigureSavesTheIDInTheCache() {
        self.identityManager.configure(withAppUserID: "cesar")
        assertCorrectlyIdentified(expectedAppUserID: "cesar")
    }

    func testConfigureCleansUpSubscriberAttributes() {
        identityManager.configure(withAppUserID: "andy")
        expect(self.mockDeviceCache.invokedCleanupSubscriberAttributesCount) == 1
    }

    func testConfigureWithAnonymousUserSavesTheIDInTheCache() {
        self.identityManager.configure(withAppUserID: nil)
        assertCorrectlyIdentifiedWithAnonymous()
    }

    func testIdentifyingClearsCaches() {
        self.identityManager.configure(withAppUserID: "cesar")
        let initialAppUserID: String = self.identityManager.currentAppUserID
        let newAppUserID = "cesar"
        self.identityManager.identifyAppUserID(newAppUserID){ (error: Error?) in }
        expect(self.mockDeviceCache.clearCachesCalledOldUserID).toEventually(equal(initialAppUserID))
    }

    func testIdentifyingCorrectlyIdentifies() {
        let newAppUserID = "cesar"
        self.identityManager.identifyAppUserID(newAppUserID){ (error: Error?) in }
        assertCorrectlyIdentified(expectedAppUserID: newAppUserID)
    }

    func testCreateAliasCallsBackend() {
        self.mockBackend.invokedCreateAlias = false
        self.mockDeviceCache.stubbedAppUserID = "appUserID"

        self.identityManager.createAlias(forAppUserID: "cesar"){ (error: Error?) in
        }

        expect(self.mockBackend.invokedCreateAlias).toEventually(beTrue())
    }

    func testCreateAliasNoOpsIfNilAppUserID() {
        self.mockBackend.invokedCreateAlias = false
        self.mockDeviceCache.stubbedAppUserID = nil
        self.identityManager.createAlias(forAppUserID: "cesar"){ (error: Error?) in
        }

        expect(self.mockBackend.invokedCreateAlias).toEventually(beFalse())
    }

    func testCreateAliasCallsCompletionWithErrorIfNilAppUserID() {
        self.mockBackend.invokedCreateAlias = false
        self.mockDeviceCache.stubbedAppUserID = nil
        var completionCalled = false
        var receivedNSError: NSError?
        self.identityManager.createAlias(forAppUserID: "cesar"){ (error: Error?) in
            completionCalled = true

            guard let receivedError = error else { fatalError() }
            receivedNSError = receivedError as NSError
            expect(receivedNSError!.code) == ErrorCodes.invalidAppUserIdError.rawValue
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedNSError).toNotEventually(beNil())
    }

    func testCreateAliasIdentifiesWhenSuccessful() {
        self.mockDeviceCache.cache(appUserID: "appUserID")
        mockBackend.stubbedCreateAliasCompletionResult = (nil, ())

        self.identityManager.createAlias(forAppUserID: "cesar"){ (error: Error?) in
        }
        assertCorrectlyIdentified(expectedAppUserID: "cesar")
    }

    func testCreateAliasClearsCachesForPreviousUser() {
        self.identityManager.configure(withAppUserID: nil)
        let initialAppUserID: String = self.identityManager.currentAppUserID
        mockBackend.stubbedCreateAliasCompletionResult = (nil, ())
        self.identityManager.createAlias(forAppUserID: "cesar"){ (error: Error?) in
        }
        expect(self.mockDeviceCache.clearCachesCalledOldUserID).to(equal(initialAppUserID))
    }

    func testCreateAliasForwardsErrors() {
        self.mockBackend.stubbedCreateAliasCompletionResult = (Purchases.ErrorUtils.backendError(withBackendCode: BackendErrorCodes.invalidAPIKey.rawValue as NSNumber,
                                                                        backendMessage: "Invalid credentials",
                                                                        finishable: false), ())
        var error: Error? = nil
        self.mockDeviceCache.stubbedAppUserID = "appUserID"

        self.identityManager.createAlias(forAppUserID: "cesar"){ (newError: Error?) in
            error = newError
        }
        expect(error).toNot(beNil())
    }

    func testResetClearsOldCaches() {
        self.identityManager.configure(withAppUserID: nil)
        let initialAppUserID: String = self.identityManager.currentAppUserID
        self.identityManager.resetAppUserID()
        expect(self.mockDeviceCache.clearCachesCalledOldUserID).to(equal(initialAppUserID))
    }

    func testResetCreatesRandomIDAndCachesIt() {
        self.identityManager.configure(withAppUserID: "cesar")
        self.identityManager.resetAppUserID()
        assertCorrectlyIdentifiedWithAnonymous()
    }

    func testIdentifyingWhenUserIsAnonymousCreatesAlias() {
        self.identityManager.configure(withAppUserID: nil)
        self.mockBackend.stubbedCreateAliasCompletionResult = (nil, ())
        self.mockDeviceCache.cache(appUserID: "$RCAnonymousID:5d73fc46744f4e0b99e524c6763dd7fc")

        self.identityManager.identifyAppUserID("cesar"){ (error: Error?) in }
        expect(self.mockBackend.invokedCreateAlias).toEventually(beTrue())
    }

    func testMigrationFromRandomIDConfiguringAnonymously() {
        self.mockDeviceCache.stubbedLegacyAppUserID = "an_old_random"

        self.identityManager.configure(withAppUserID: nil)
        assertCorrectlyIdentifiedWithAnonymous(usingOldID: true)
        expect(self.identityManager.currentAppUserID).to(equal("an_old_random"))
    }

    func testMigrationFromRandomIDConfiguringWithUser() {
        self.mockDeviceCache.stubbedLegacyAppUserID = "an_old_random"
        self.identityManager.configure(withAppUserID: "cesar")
        assertCorrectlyIdentified(expectedAppUserID: "cesar")
    }

    func testLogInFailsIfEmptyAppUserID() {
        var completionCalled: Bool = false
        var receivedCreated: Bool = false
        var receivedPurchaserInfo: Purchases.PurchaserInfo?
        var receivedError: Error?
        identityManager.logIn(withAppUserID: ""){ purchaserInfo, created, error in
            completionCalled = true
            receivedCreated = created
            receivedPurchaserInfo = purchaserInfo
            receivedError = error
        }

        expect(completionCalled).toEventually(beTrue())

        expect(receivedCreated) == false
        expect(receivedPurchaserInfo).to(beNil())
        expect(receivedError).toNot(beNil())

        let receivedNSError = (receivedError! as NSError)
        expect(receivedNSError.code) == ErrorCodes.invalidAppUserIdError.rawValue
    }

    func testLogInErrorsOutIfOldAppUserIDEmpty() {
        var completionCalled: Bool = false
        let newAppUserID = "myUser"
        mockDeviceCache.stubbedAppUserID = nil
        var receivedCreated: Bool = false
        var receivedPurchaserInfo: Purchases.PurchaserInfo?
        var receivedError: NSError?

        self.mockBackend.stubbedLogInCompletionResult = (mockPurchaserInfo, true, nil)

        identityManager.logIn(withAppUserID: newAppUserID){ purchaserInfo, created, error in
            completionCalled = true
            receivedCreated = created
            receivedPurchaserInfo = purchaserInfo
            receivedError = error as NSError?
        }

        expect(completionCalled).toEventually(beTrue())

        expect(receivedCreated) == false
        expect(receivedPurchaserInfo).to(beNil())
        expect(receivedError).toNot(beNil())
        let receivedNSError = (receivedError! as NSError)
        expect(receivedNSError.code) == ErrorCodes.invalidAppUserIdError.rawValue

        expect(self.mockBackend.invokedLogInCount) == 0
        expect(self.mockPurchaserInfoManager.invokedPurchaserInfoCount) == 0
    }

    func testLogInWithSameAppUserIDFetchesPurchaserInfo() {
        var completionCalled: Bool = false
        let appUserID = "myUser"
        mockDeviceCache.stubbedAppUserID = appUserID
        identityManager.logIn(withAppUserID: appUserID){ purchaserInfo, created, error in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())

        expect(self.mockBackend.invokedLogInCount) == 0
        expect(self.mockPurchaserInfoManager.invokedPurchaserInfoCount) == 1
    }

    func testLogInWithSameAppUserIDPassesBackendPurchaserInfoErrors() {
        var completionCalled: Bool = false
        let appUserID = "myUser"
        mockDeviceCache.stubbedAppUserID = appUserID
        var receivedCreated: Bool = true
        var receivedPurchaserInfo: Purchases.PurchaserInfo?
        var receivedError: NSError?

        let stubbedError = NSError(domain: RCPurchasesErrorCodeDomain,
                                   code: ErrorCodes.invalidAppUserIdError.rawValue,
                                   userInfo: [:])

        self.mockPurchaserInfoManager.stubbedError = stubbedError
        identityManager.logIn(withAppUserID: appUserID){ purchaserInfo, created, error in
            completionCalled = true
            receivedCreated = created
            receivedPurchaserInfo = purchaserInfo
            receivedError = error as NSError?
        }

        expect(completionCalled).toEventually(beTrue())

        expect(receivedCreated) == false
        expect(receivedPurchaserInfo).to(beNil())
        expect(receivedError) == stubbedError

        expect(self.mockBackend.invokedLogInCount) == 0
        expect(self.mockPurchaserInfoManager.invokedPurchaserInfoCount) == 1
    }

    func testLogInCallsBackendLogin() {
        var completionCalled: Bool = false
        let oldAppUserID = "anonymous"
        let newAppUserID = "myUser"
        mockDeviceCache.stubbedAppUserID = oldAppUserID
        var receivedCreated: Bool = false
        var receivedPurchaserInfo: Purchases.PurchaserInfo?
        var receivedError: NSError?

        self.mockBackend.stubbedLogInCompletionResult = (mockPurchaserInfo, true, nil)

        identityManager.logIn(withAppUserID: newAppUserID){ purchaserInfo, created, error in
            completionCalled = true
            receivedCreated = created
            receivedPurchaserInfo = purchaserInfo
            receivedError = error as NSError?
        }

        expect(completionCalled).toEventually(beTrue())

        expect(receivedCreated) == true
        expect(receivedPurchaserInfo) == mockPurchaserInfo
        expect(receivedError).to(beNil())

        expect(self.mockBackend.invokedLogInCount) == 1
        expect(self.mockPurchaserInfoManager.invokedPurchaserInfoCount) == 0
    }

    func testLogInPassesBackendLoginErrors() {
        var completionCalled: Bool = false
        let oldAppUserID = "anonymous"
        let newAppUserID = "myUser"
        mockDeviceCache.stubbedAppUserID = oldAppUserID
        var receivedCreated: Bool = false
        var receivedPurchaserInfo: Purchases.PurchaserInfo?
        var receivedError: NSError?

        let stubbedError = NSError(domain: RCPurchasesErrorCodeDomain,
                                   code: ErrorCodes.invalidAppUserIdError.rawValue,
                                   userInfo: [:])
        self.mockBackend.stubbedLogInCompletionResult = (nil, false, stubbedError)

        self.mockPurchaserInfoManager.stubbedError = stubbedError

        identityManager.logIn(withAppUserID: newAppUserID){ purchaserInfo, created, error in
            completionCalled = true
            receivedCreated = created
            receivedPurchaserInfo = purchaserInfo
            receivedError = error as NSError?
        }

        expect(completionCalled).toEventually(beTrue())

        expect(receivedCreated) == false
        expect(receivedPurchaserInfo).to(beNil())
        expect(receivedError) == stubbedError

        expect(self.mockBackend.invokedLogInCount) == 1
        expect(self.mockPurchaserInfoManager.invokedPurchaserInfoCount) == 0

        expect(self.mockDeviceCache.invokedClearCachesForAppUserID) == false
        expect(self.mockPurchaserInfoManager.invokedCachedPurchaserInfo) == false
    }

    func testLogInClearsCachesIfSuccessful() {
        var completionCalled: Bool = false
        let oldAppUserID = "anonymous"
        let newAppUserID = "myUser"
        mockDeviceCache.stubbedAppUserID = oldAppUserID

        self.mockBackend.stubbedLogInCompletionResult = (mockPurchaserInfo, true, nil)

        identityManager.logIn(withAppUserID: newAppUserID){ purchaserInfo, created, error in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())

        expect(self.mockDeviceCache.invokedClearCachesForAppUserID) == true
    }

    func testLogInCachesNewPurchaserInfoIfSuccessful() {
        var completionCalled: Bool = false
        let oldAppUserID = "anonymous"
        let newAppUserID = "myUser"
        mockDeviceCache.stubbedAppUserID = oldAppUserID

        self.mockBackend.stubbedLogInCompletionResult = (mockPurchaserInfo, true, nil)

        identityManager.logIn(withAppUserID: newAppUserID){ purchaserInfo, created, error in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())

        expect(self.mockPurchaserInfoManager.invokedCachePurchaserInfo) == true
        expect(self.mockPurchaserInfoManager.invokedCachePurchaserInfoParameters?.info) == mockPurchaserInfo
        expect(self.mockPurchaserInfoManager.invokedCachePurchaserInfoParameters?.appUserID) == newAppUserID
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
        expect((receivedError! as NSError).code) == ErrorCodes.logOutAnonymousUserError.rawValue
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
