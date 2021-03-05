//
// Created by RevenueCat.
// Copyright (c) 2019 RevenueCat. All rights reserved.
//

import XCTest
import Nimble

import Purchases

class IdentityManagerTests: XCTestCase {

    private var identityManager: RCIdentityManager!

    class MockBackend: RCBackend {
        var userID: String?
        var originalApplicationVersion: String?
        var timeout = false
        var getSubscriberCallCount = 0
        var overridePurchaserInfo = Purchases.PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:]
            ]])

        var postReceiptDataCalled = false
        var postedIsRestore: Bool?
        var postedProductID: String?
        var postedPrice: NSDecimalNumber?
        var postedPaymentMode: RCPaymentMode?
        var postedIntroPrice: NSDecimalNumber?
        var postedCurrencyCode: String?
        var postedSubscriptionGroup: String?
        var postedDiscounts: Array<RCPromotionalOffer>?
        var postedOfferingIdentifier: String?

        var postReceiptPurchaserInfo: Purchases.PurchaserInfo?
        var postReceiptError: Error?
        var aliasError: Error?
        var aliasCalled = false

        var postedProductIdentifiers: [String]?

        var failOfferings = false
        var badOfferingsResponse = false
        var gotOfferings = 0

        override func createAlias(forAppUserID appUserID: String, withNewAppUserID newAppUserID: String, completion: ((Error?) -> Void)? = nil) {
            aliasCalled = true
            if (aliasError != nil) {
                completion!(aliasError)
            } else {
                userID = newAppUserID
                completion!(nil)
            }
        }
    }

    private let mockDeviceCache = MockDeviceCache()
    private let mockBackend = MockBackend()
    private let mockPurchaserInfoManager = MockPurchaserInfoManager()

    override func setUp() {
        super.setUp()
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
        self.identityManager.identifyAppUserID(newAppUserID){ (error: Error?) in  }
        expect(self.mockDeviceCache.clearCachesCalledOldUserID).toEventually(equal(initialAppUserID))
    }

    func testIdentifyingCorrectlyIdentifies() {
        let newAppUserID = "cesar"
        self.identityManager.identifyAppUserID(newAppUserID){ (error: Error?) in  }
        assertCorrectlyIdentified(expectedAppUserID: newAppUserID)
    }

    func testCreateAliasCallsBackend() {
        self.mockBackend.aliasCalled = false
        self.mockDeviceCache.stubbedAppUserID = "appUserID"

        self.identityManager.createAlias(forAppUserID: "cesar"){ (error: Error?) in
        }

        expect(self.mockBackend.aliasCalled).toEventually(beTrue())
    }

    func testCreateAliasNoOpsIfNilAppUserID() {
        self.mockBackend.aliasCalled = false
        self.mockDeviceCache.stubbedAppUserID = nil
        self.identityManager.createAlias(forAppUserID: "cesar"){ (error: Error?) in
        }

        expect(self.mockBackend.aliasCalled).toEventually(beFalse())
    }

    func testCreateAliasCallsCompletionWithErrorIfNilAppUserID() {
        self.mockBackend.aliasCalled = false
        self.mockDeviceCache.stubbedAppUserID = nil
        var completionCalled = false
        var receivedNSError: NSError?
        self.identityManager.createAlias(forAppUserID: "cesar"){ (error: Error?) in
            completionCalled = true

            guard let receivedError = error else { fatalError() }
            receivedNSError = receivedError as NSError
            expect(receivedNSError!.code) == Purchases.ErrorCode.invalidAppUserIdError.rawValue
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedNSError).toNotEventually(beNil())
    }

    func testCreateAliasIdentifiesWhenSuccessful() {
        self.mockDeviceCache.cacheAppUserID("appUserID")

        self.identityManager.createAlias(forAppUserID: "cesar"){ (error: Error?) in
        }
        assertCorrectlyIdentified(expectedAppUserID: "cesar")
    }

    func testCreateAliasClearsCachesForPreviousUser() {
        self.identityManager.configure(withAppUserID: nil)
        let initialAppUserID: String = self.identityManager.currentAppUserID
        self.identityManager.createAlias(forAppUserID: "cesar"){ (error: Error?) in
        }
        expect(self.mockDeviceCache.clearCachesCalledOldUserID).to(equal(initialAppUserID))
    }

    func testCreateAliasForwardsErrors() {
        self.mockBackend.aliasError = Purchases.ErrorUtils.backendError(withBackendCode: Purchases.RevenueCatBackendErrorCode.invalidAPIKey.rawValue as NSNumber, backendMessage: "Invalid credentials", finishable: false)
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
        self.mockBackend.aliasError = nil
        self.mockDeviceCache.cacheAppUserID("$RCAnonymousID:5d73fc46744f4e0b99e524c6763dd7fc")

        self.identityManager.identifyAppUserID("cesar"){ (error: Error?) in  }
        expect(self.mockBackend.aliasCalled).toEventually(beTrue())
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

    private func assertCorrectlyIdentified(expectedAppUserID: String) {
        expect(self.identityManager.currentAppUserID).to(equal(expectedAppUserID))
        expect(self.mockDeviceCache.userIDStoredInCache!).to(equal(expectedAppUserID));
        expect(self.identityManager.currentUserIsAnonymous).to(beFalse())
    }

    private func assertCorrectlyIdentifiedWithAnonymous(usingOldID: Bool = false) {
        if (!usingOldID) {
            expect(self.identityManager.currentAppUserID.range(of: #"\$RCAnonymousID:([a-z0-9]{32})$"#, options: .regularExpression)).toNot(beNil())
            expect(self.mockDeviceCache.userIDStoredInCache!.range(of: #"\$RCAnonymousID:([a-z0-9]{32})$"#, options: .regularExpression)).toNot(beNil())
        }
        expect(self.identityManager.currentUserIsAnonymous).to(beTrue())
    }

}
