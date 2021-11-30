//
// Created by RevenueCat.
// Copyright (c) 2019 RevenueCat. All rights reserved.
//

import XCTest
import Nimble

@testable import RevenueCat

class IdentityManagerTests: XCTestCase {

    private var mockDeviceCache: MockDeviceCache!
    private let mockBackend = MockBackend()
    private let mockCustomerInfoManager = MockCustomerInfoManager(
        operationDispatcher: MockOperationDispatcher(),
        deviceCache: MockDeviceCache(),
        backend: MockBackend(),
        systemInfo: try! MockSystemInfo(platformFlavor: nil,
                                        platformFlavorVersion: nil,
                                        finishTransactions: false)
    )

    private let mockCustomerInfo = CustomerInfo(testData: [
        "request_date": "2019-08-16T10:30:42Z",
        "subscriber": [
            "first_seen": "2019-07-17T00:05:54Z",
            "original_app_user_id": "",
            "subscriptions": [:],
            "other_purchases": [:]
        ]])

    private func create(appUserID: String?) -> IdentityManager {
        return IdentityManager(deviceCache: mockDeviceCache,
                               backend: mockBackend,
                               customerInfoManager: mockCustomerInfoManager,
                               appUserID: appUserID)
    }
 
    override func setUp() {
        super.setUp()

        self.mockDeviceCache = MockDeviceCache()
    }

    func testConfigureWithAnonymousUserIDGeneratesAnAppUserID() {
        let manager = create(appUserID: nil)
        assertCorrectlyIdentifiedWithAnonymous(manager)
    }

    func testConfigureSavesTheIDInTheCache() {
        let manager = create(appUserID: "cesar")
        assertCorrectlyIdentified(manager, expectedAppUserID: "cesar")
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

    func testLogInFailsIfEmptyAppUserID() {
        var completionCalled: Bool = false
        var receivedCreated: Bool = false
        var receivedCustomerInfo: CustomerInfo?
        var receivedError: Error?

        let manager = create(appUserID: nil)

        manager.logIn(appUserID: "") { customerInfo, created, error in
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

        let manager = create(appUserID: nil)

        mockDeviceCache.stubbedAppUserID = appUserID
        manager.logIn(appUserID: appUserID){ customerInfo, created, error in
            completionCalled = true
        }

        expect(completionCalled).toEventually(beTrue())

        expect(self.mockBackend.invokedLogInCount) == 0
        expect(self.mockCustomerInfoManager.invokedCustomerInfoCount) == 1
    }

    func testLogInWithSameAppUserIDPassesBackendCustomerInfoErrors() {
        var completionCalled: Bool = false
        let appUserID = "myUser"

        let manager = create(appUserID: nil)

        mockDeviceCache.stubbedAppUserID = appUserID
        var receivedCreated: Bool = true
        var receivedCustomerInfo: CustomerInfo?
        var receivedError: NSError?

        let stubbedError = NSError(domain: RCPurchasesErrorCodeDomain,
                                   code: ErrorCode.invalidAppUserIdError.rawValue,
                                   userInfo: [:])

        self.mockCustomerInfoManager.stubbedError = stubbedError
        manager.logIn(appUserID: appUserID) { customerInfo, created, error in
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

        let manager = create(appUserID: nil)

        mockDeviceCache.stubbedAppUserID = oldAppUserID
        var receivedCreated: Bool = false
        var receivedCustomerInfo: CustomerInfo?
        var receivedError: NSError?

        self.mockBackend.stubbedLogInCompletionResult = (mockCustomerInfo, true, nil)

        manager.logIn(appUserID: newAppUserID) { customerInfo, created, error in
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

        let manager = create(appUserID: nil)

        let stubbedError = NSError(domain: RCPurchasesErrorCodeDomain,
                                   code: ErrorCode.invalidAppUserIdError.rawValue,
                                   userInfo: [:])
        self.mockBackend.stubbedLogInCompletionResult = (nil, false, stubbedError)

        self.mockCustomerInfoManager.stubbedError = stubbedError

        manager.logIn(appUserID: newAppUserID) { customerInfo, created, error in
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

        let manager = create(appUserID: nil)

        self.mockBackend.stubbedLogInCompletionResult = (mockCustomerInfo, true, nil)

        manager.logIn(appUserID: newAppUserID) { customerInfo, created, error in
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

        self.mockBackend.stubbedLogInCompletionResult = (mockCustomerInfo, true, nil)

        manager.logIn(appUserID: newAppUserID){ customerInfo, created, error in
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
        manager.logOut { error in
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
        expect(self.mockDeviceCache.userIDStoredInCache!).to(equal(expectedAppUserID));
        expect(manager.currentUserIsAnonymous).to(beFalse())
    }

    func assertCorrectlyIdentifiedWithAnonymous(_ manager: IdentityManager, usingOldID: Bool = false) {
        if (!usingOldID) {
            expect(manager.currentAppUserID.range(of: IdentityManager.anonymousRegex, options: .regularExpression)).toNot(beNil())
            expect(self.mockDeviceCache.userIDStoredInCache!.range(of: IdentityManager.anonymousRegex, options: .regularExpression)).toNot(beNil())
        }
        expect(manager.currentUserIsAnonymous).to(beTrue())
    }

}
