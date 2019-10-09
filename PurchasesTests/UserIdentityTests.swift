//
// Created by RevenueCat.
// Copyright (c) 2019 RevenueCat. All rights reserved.
//

import XCTest
import Nimble

import Purchases

class UserIdentityTests: XCTestCase {

    private var userIdentity: RCUserIdentity!

    class MockBackend: RCBackend {
        var userID: String?
        var originalApplicationVersion: String?
        var timeout = false
        var getSubscriberCallCount = 0
        var overridePurchaserInfo = PurchaserInfo(data: [
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

        var postReceiptPurchaserInfo: PurchaserInfo?
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
        var userIDStoredInCache: String? = nil
        var isAnonymousStoredInCache: Bool? = nil
        var mockAnonymous: Bool = false
        var isAnonymousCalled: Bool = false

        override var cachedAppUserID: String? {
            return mockedAppUserID
        }

        override func clearCaches(forAppUserID appUserId: String) {
            clearCachesCalledUserID = appUserId
        }

        override func cacheAppUserID(_ appUserID: String, isAnonymous anonymous: Bool) {
            userIDStoredInCache = appUserID
            isAnonymousStoredInCache = anonymous
        }

        override func isAnonymous() -> Bool {
            isAnonymousCalled = true
            return mockAnonymous
        }
    }

    private let mockDeviceCache = MockDeviceCache()
    private let mockBackend = MockBackend()

    override func setUp() {
        super.setUp()
        self.userIdentity = RCUserIdentity(mockDeviceCache, backend: mockBackend)
    }

    func testConfigureWithAnonymousUserIDGeneratesAnAppUserID() {
        self.userIdentity.configureAppUserID(nil)
        assertCorrectlyIdentifiedWithRandom()
    }

    func testAnonymousIDsMatchesFormat() {
        self.userIdentity.configureAppUserID(nil)
        assertCorrectlyIdentifiedWithRandom()
    }

    func testConfigureSavesTheIDInTheCache() {
        self.userIdentity.configureAppUserID("cesar")
        assertCorrectlyIdentified(expectedAppUserID: "cesar")
    }

    func testConfigureWithAnonymousUserSavesTheIDInTheCache() {
        self.userIdentity.configureAppUserID(nil)
        assertCorrectlyIdentifiedWithRandom()
    }

    func testWhenConfiguringAnonymouslyAndPreviouslyIdentifiedReuseIDAndCheckIfAnonymous() {
        let appUserID = "cesar"
        self.mockDeviceCache.mockAnonymous = false
        self.mockDeviceCache.mockedAppUserID = appUserID
        self.userIdentity.configureAppUserID(nil)
        expect(self.mockDeviceCache.isAnonymousCalled).to(beTrue())
        assertCorrectlyIdentified(expectedAppUserID: appUserID)
    }

    func testWhenConfiguringAnonymouslyAndPreviouslyAnonymousReuseIDAndCheckIfAnonymous() {
        self.mockDeviceCache.mockedAppUserID = "random_user_id"
        self.mockDeviceCache.mockAnonymous = true
        self.userIdentity.configureAppUserID(nil)
        expect(self.mockDeviceCache.isAnonymousCalled).to(beTrue())
        assertCorrectlyIdentifiedWithRandom(usingOldID: true)
    }

    func testIdentifyingClearsCaches() {
        self.userIdentity.configureAppUserID("cesar")
        let initialAppUserID: String = self.userIdentity.appUserID
        let newAppUserID = "cesar"
        self.userIdentity.identifyAppUserID(newAppUserID) { (error: Error?) in  }
        expect(self.mockDeviceCache.clearCachesCalledUserID).toEventually(equal(initialAppUserID))
    }

    func testIdentifyingCorrectlyIdentifies() {
        let newAppUserID = "cesar"
        self.userIdentity.identifyAppUserID(newAppUserID) { (error: Error?) in  }
        assertCorrectlyIdentified(expectedAppUserID: newAppUserID)
    }

    func testCreateAliasCallsBackend() {
        self.mockBackend.aliasCalled = false
        self.userIdentity.createAlias("cesar") { (error: Error?) in
        }

        expect(self.mockBackend.aliasCalled).toEventually(beTrue())
    }

    func testCreateAliasIdentifiesWhenSuccessful() {
        self.userIdentity.createAlias("cesar") { (error: Error?) in
        }
        assertCorrectlyIdentified(expectedAppUserID: "cesar")
    }

    func testCreateAliasClearsCachesForPreviousUser() {
        self.userIdentity.configureAppUserID(nil)
        let initialAppUserID: String = self.userIdentity.appUserID
        self.userIdentity.createAlias("cesar") { (error: Error?) in
        }
        expect(self.mockDeviceCache.clearCachesCalledUserID).to(equal(initialAppUserID))
    }

    func testCreateAliasForwardsErrors() {
        self.mockBackend.aliasError = PurchasesErrorUtils.backendError(withBackendCode: RevenueCatBackendErrorCode.invalidAPIKey.rawValue as NSNumber, backendMessage: "Invalid credentials", finishable: false)
        var error: Error? = nil
        self.userIdentity.createAlias("cesar") { (newError: Error?) in
            error = newError
        }
        expect(error).toNot(beNil())
    }

    func testResetClearsOldCaches() {
        self.userIdentity.configureAppUserID(nil)
        let initialAppUserID: String = self.userIdentity.appUserID
        self.userIdentity.resetAppUserID()
        expect(self.mockDeviceCache.clearCachesCalledUserID).to(equal(initialAppUserID))
    }

    func testResetCreatesRandomIDAndCachesIt() {
        self.userIdentity.configureAppUserID("cesar")
        self.userIdentity.resetAppUserID()
        assertCorrectlyIdentifiedWithRandom()
    }

    func testIdentifyingWhenUserIsAnonymousCreatesAlias() {
        self.userIdentity.configureAppUserID(nil)
        let newAppUserID = "cesar"
        self.mockBackend.aliasError = nil
        self.userIdentity.identifyAppUserID(newAppUserID) { (error: Error?) in  }
        expect(self.mockBackend.aliasCalled).toEventually(beTrue())
    }

    func testTryingToIdentifyWithAnonymousIDSendsError() {
        var error: Error? = nil
        self.userIdentity.identifyAppUserID("$RCAnonymousID:ff68f26e432648369a713849a9f93b58") { (newError: Error?) in
            error = newError
        }
        expect(error).toNot(beNil())
        expect((error! as NSError).code).toNot(be(PurchasesErrorCode.invalidAppUserIdError))
    }

    func testTryingToCreateAliasWithAnonymousIDSendsError() {
        var error: Error? = nil
        self.userIdentity.identifyAppUserID("$RCAnonymousID:ff68f26e432648369a713849a9f93b58") { (newError: Error?) in
            error = newError
        }
        expect(error).toNot(beNil())
        expect((error! as NSError).code).toNot(be(PurchasesErrorCode.invalidAppUserIdError))
    }

    func testConfiguringWithWhatLooksAnonymousReturnsNegative() {
        let configuredSuccessfully: Bool = self.userIdentity.configureAppUserID("$RCAnonymousID:ff68f26e432648369a713849a9f93b58")
        expect(configuredSuccessfully).to(beFalse())
    }

    func testConfigureWithAnonymousUserIDReturnsPositive() {
        let configuredSuccessfully: Bool = self.userIdentity.configureAppUserID(nil)
        expect(configuredSuccessfully).to(beTrue())
        assertCorrectlyIdentifiedWithRandom()
    }

    func testConfigureWithUserIDReturnsPositive() {
        let configuredSuccessfully: Bool = self.userIdentity.configureAppUserID("cesar")
        expect(configuredSuccessfully).to(beTrue())
        assertCorrectlyIdentified(expectedAppUserID: "cesar")
    }

    private func assertCorrectlyIdentified(expectedAppUserID: String) {
        expect(self.userIdentity.appUserID).to(equal(expectedAppUserID))
        expect(self.mockDeviceCache.userIDStoredInCache!).to(equal(expectedAppUserID));
        expect(self.mockDeviceCache.isAnonymousStoredInCache).to(beFalse())
        expect(self.userIdentity.isAnonymous).to(beFalse())
    }

    private func assertCorrectlyIdentifiedWithRandom(usingOldID: Bool = false) {
        if (!usingOldID) {
            expect(self.userIdentity.appUserID.range(of: #"\$RCAnonymousID:([a-z0-9]{32})$"#, options: .regularExpression)).toNot(beNil())
            expect(self.mockDeviceCache.userIDStoredInCache!.range(of: #"\$RCAnonymousID:([a-z0-9]{32})$"#, options: .regularExpression)).toNot(beNil())   
        }
        expect(self.userIdentity.appUserID).to(equal(self.mockDeviceCache.userIDStoredInCache!))
        expect(self.mockDeviceCache.isAnonymousStoredInCache).to(beTrue())
        expect(self.userIdentity.isAnonymous).to(beTrue())
    }

}
