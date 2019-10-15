//
// Created by RevenueCat.
// Copyright (c) 2019 RevenueCat. All rights reserved.
//

import XCTest
import Nimble

import Purchases

class UserManagerTests: XCTestCase {

    private var userManager: RCUserManager!

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

    class MockDeviceCache: RCDeviceCache {

        var clearCachesCalledUserID: String? = nil
        var mockedAppUserID: String? = nil
        var mockedLegacyAppUserID: String? = nil
        var userIDStoredInCache: String? = nil
        var mockAnonymous: Bool = false

        override var cachedLegacyAppUserID: String? {
            return mockedLegacyAppUserID
        }

        override var cachedAppUserID: String? {
            if (mockedAppUserID != nil) {
                return mockedAppUserID
            } else {
                return userIDStoredInCache
            }
        }

        override func cacheAppUserID(_ appUserID: String) {
            userIDStoredInCache = appUserID
        }

        override func clearCaches(forAppUserID appUserId: String) {
            clearCachesCalledUserID = appUserId
        }

    }

    private let mockDeviceCache = MockDeviceCache()
    private let mockBackend = MockBackend()

    override func setUp() {
        super.setUp()
        self.userManager = RCUserManager(mockDeviceCache, backend: mockBackend)
    }

    func testConfigureWithAnonymousUserIDGeneratesAnAppUserID() {
        self.userManager.configure(withAppUserID: nil)
        assertCorrectlyIdentifiedWithAnonymous()
    }

    func testAnonymousIDsMatchesFormat() {
        self.userManager.configure(withAppUserID: nil)
        assertCorrectlyIdentifiedWithAnonymous()
    }

    func testConfigureSavesTheIDInTheCache() {
        self.userManager.configure(withAppUserID: "cesar")
        assertCorrectlyIdentified(expectedAppUserID: "cesar")
    }

    func testConfigureWithAnonymousUserSavesTheIDInTheCache() {
        self.userManager.configure(withAppUserID: nil)
        assertCorrectlyIdentifiedWithAnonymous()
    }

    func testIdentifyingClearsCaches() {
        self.userManager.configure(withAppUserID: "cesar")
        let initialAppUserID: String = self.userManager.currentAppUserID
        let newAppUserID = "cesar"
        self.userManager.identifyAppUserID(newAppUserID) { (error: Error?) in  }
        expect(self.mockDeviceCache.clearCachesCalledUserID).toEventually(equal(initialAppUserID))
    }

    func testIdentifyingCorrectlyIdentifies() {
        let newAppUserID = "cesar"
        self.userManager.identifyAppUserID(newAppUserID) { (error: Error?) in  }
        assertCorrectlyIdentified(expectedAppUserID: newAppUserID)
    }

    func testCreateAliasCallsBackend() {
        self.mockBackend.aliasCalled = false
        self.userManager.createAlias("cesar") { (error: Error?) in
        }

        expect(self.mockBackend.aliasCalled).toEventually(beTrue())
    }

    func testCreateAliasIdentifiesWhenSuccessful() {
        self.userManager.createAlias("cesar") { (error: Error?) in
        }
        assertCorrectlyIdentified(expectedAppUserID: "cesar")
    }

    func testCreateAliasClearsCachesForPreviousUser() {
        self.userManager.configure(withAppUserID: nil)
        let initialAppUserID: String = self.userManager.currentAppUserID
        self.userManager.createAlias("cesar") { (error: Error?) in
        }
        expect(self.mockDeviceCache.clearCachesCalledUserID).to(equal(initialAppUserID))
    }

    func testCreateAliasForwardsErrors() {
        self.mockBackend.aliasError = Purchases.ErrorUtils.backendError(withBackendCode: Purchases.RevenueCatBackendErrorCode.invalidAPIKey.rawValue as NSNumber, backendMessage: "Invalid credentials", finishable: false)
        var error: Error? = nil
        self.userManager.createAlias("cesar") { (newError: Error?) in
            error = newError
        }
        expect(error).toNot(beNil())
    }

    func testResetClearsOldCaches() {
        self.userManager.configure(withAppUserID: nil)
        let initialAppUserID: String = self.userManager.currentAppUserID
        self.userManager.resetAppUserID()
        expect(self.mockDeviceCache.clearCachesCalledUserID).to(equal(initialAppUserID))
    }

    func testResetCreatesRandomIDAndCachesIt() {
        self.userManager.configure(withAppUserID: "cesar")
        self.userManager.resetAppUserID()
        assertCorrectlyIdentifiedWithAnonymous()
    }

    func testIdentifyingWhenUserIsAnonymousCreatesAlias() {
        self.userManager.configure(withAppUserID: nil)
        self.mockBackend.aliasError = nil
        self.userManager.identifyAppUserID("cesar") { (error: Error?) in  }
        expect(self.mockBackend.aliasCalled).toEventually(beTrue())
    }

    func testMigrationFromRandomIDConfiguringAnonymously() {
        self.mockDeviceCache.mockedLegacyAppUserID = "an_old_random"
        self.userManager.configure(withAppUserID: nil)
        assertCorrectlyIdentifiedWithAnonymous(usingOldID: true)
        expect(self.userManager.currentAppUserID).to(equal("an_old_random"))
    }

    func testMigrationFromRandomIDConfiguringWithUser() {
        self.mockDeviceCache.mockedLegacyAppUserID = "an_old_random"
        self.userManager.configure(withAppUserID: "cesar")
        assertCorrectlyIdentified(expectedAppUserID: "cesar")
    }

    private func assertCorrectlyIdentified(expectedAppUserID: String) {
        expect(self.userManager.currentAppUserID).to(equal(expectedAppUserID))
        expect(self.mockDeviceCache.userIDStoredInCache!).to(equal(expectedAppUserID));
        expect(self.userManager.currentUserIsAnonymous).to(beFalse())
    }

    private func assertCorrectlyIdentifiedWithAnonymous(usingOldID: Bool = false) {
        if (!usingOldID) {
            expect(self.userManager.currentAppUserID.range(of: #"\$RCAnonymousID:([a-z0-9]{32})$"#, options: .regularExpression)).toNot(beNil())
            expect(self.mockDeviceCache.userIDStoredInCache!.range(of: #"\$RCAnonymousID:([a-z0-9]{32})$"#, options: .regularExpression)).toNot(beNil())
        }
        expect(self.userManager.currentUserIsAnonymous).to(beTrue())
    }

}
