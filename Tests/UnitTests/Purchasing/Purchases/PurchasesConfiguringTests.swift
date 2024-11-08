//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesConfiguringTests.swift
//
//  Created by Nacho Soto on 5/25/22.

import Nimble
import XCTest

@testable import RevenueCat

class PurchasesConfiguringTests: BasePurchasesTests {

    func testIsAbleToBeInitialized() {
        self.setupPurchases()
        expect(self.purchases).toNot(beNil())
    }

    #if !os(watchOS)
    func testUsingSharedInstanceWithoutInitializingThrowsAssertion() {
        expect {
            _ = Purchases.shared
        }.to(throwAssertion())
    }

    func testUsingSharedInstanceAfterInitializingDoesntThrowAssertion() {
        self.setupPurchases()
        expect {
            _ = Purchases.shared
        }.toNot(throwAssertion())
    }
    #endif

    func testIsConfiguredReturnsCorrectValue() {
        expect(Purchases.isConfigured) == false
        self.setupPurchases()
        expect(Purchases.isConfigured) == true
    }

    func testConfigurationPassedThroughTimeouts() {
        let networkTimeoutSeconds: TimeInterval = 9
        let configurationBuilder = Configuration.Builder(withAPIKey: "")
            .with(networkTimeout: networkTimeoutSeconds)
            .with(storeKit1Timeout: networkTimeoutSeconds)
        let purchases = Purchases.configure(with: configurationBuilder.build())

        expect(purchases.networkTimeout) == networkTimeoutSeconds
        expect(purchases.storeKitTimeout) == networkTimeoutSeconds
    }

    func testSharedInstanceIsSetWhenConfiguring() {
        let purchases = Purchases.configure(withAPIKey: "")
        expect(Purchases.shared) === purchases
    }

    func testSharedInstanceIsSetWhenConfiguringWithConfiguration() {
        let configurationBuilder = Configuration.Builder(withAPIKey: "")
        let purchases = Purchases.configure(with: configurationBuilder.build())
        expect(Purchases.shared) === purchases
    }

    @available(*, deprecated)
    func testSharedInstanceIsSetWhenConfiguringWithAppUserID() {
        let purchases = Purchases.configure(withAPIKey: "", appUserID: "")
        expect(Purchases.shared) === purchases
    }

    @available(*, deprecated)
    func testSharedInstanceIsSetWhenConfiguringWithObserverMode() {
        let nonStaticString = String(123)
        let purchases = Purchases.configure(withAPIKey: "",
                                            appUserID: nonStaticString,
                                            purchasesAreCompletedBy: .myApp,
                                            storeKitVersion: .storeKit2)
        expect(Purchases.shared) === purchases
        expect(Purchases.shared.finishTransactions) == false
        expect(Purchases.shared.purchasesAreCompletedBy) == .myApp
    }

    @available(*, deprecated)
    func testSharedInstanceIsSetWhenConfiguringWithObserverModeDisabled() {
        let nonStaticString = String(123)
        let purchases = Purchases.configure(withAPIKey: "",
                                            appUserID: nonStaticString,
                                            purchasesAreCompletedBy: .revenueCat,
                                            storeKitVersion: .storeKit2)
        expect(Purchases.shared) === purchases
        expect(Purchases.shared.finishTransactions) == true
        expect(Purchases.shared.purchasesAreCompletedBy) == .revenueCat
    }

    @available(*, deprecated) // Ignore deprecation warnings
    func testSharedInstanceIsSetWhenConfiguringWithAppUserIDAndUserDefaults() {
        let nonStaticString = String(123)
        let configurationBuilder = Configuration.Builder(withAPIKey: "")
            .with(appUserID: nonStaticString)
            .with(userDefaults: UserDefaults.standard)
        let purchases = Purchases.configure(with: configurationBuilder.build())

        expect(Purchases.shared) === purchases
        expect(Purchases.shared.finishTransactions) == true
        expect(Purchases.shared.purchasesAreCompletedBy) == .revenueCat
    }

    func testUserIdIsSetWhenConfiguringWithUserID() {
        let purchases = Purchases.configure(
            with: .init(withAPIKey: "")
                .with(appUserID: Self.appUserID)
        )
        expect(purchases.appUserID) == Self.appUserID
    }

    @available(*, deprecated)
    func testUserIdIsSetToAnonymousWhenConfiguringWithEmptyUserID() {
        self.deviceCache.userIDStoredInCache = nil

        let purchases = Purchases.configure(
            with: .init(withAPIKey: "")
                // This test requires no previously stored user
                .with(userDefaults: .emptyNewUserDefaults())
                .with(appUserID: "")
        )
        expect(purchases.appUserID).toNot(beEmpty())
        expect(IdentityManager.userIsAnonymous(purchases.appUserID))
            .to(beTrue(), description: "User '\(purchases.appUserID)' should be anonymous")
    }

    func testUserIdOverridesPreviouslyConfiguredUser() {
        // This test requires no previously stored user
        let userDefaults: UserDefaults = .emptyNewUserDefaults()

        let newUserID = Self.appUserID + "_new"

        _ = Purchases.configure(
            with: .init(withAPIKey: "")
                .with(userDefaults: userDefaults)
                .with(appUserID: Self.appUserID)
        )
        Purchases.clearSingleton()
        let purchases = Purchases.configure(
            with: .init(withAPIKey: "")
                .with(userDefaults: userDefaults)
                .with(appUserID: newUserID)
        )

        expect(purchases.appUserID) == newUserID
    }

    func testNilUserIdIsIgnoredIfPreviousUserExists() {
        // This test requires no previously stored user
        let userDefaults: UserDefaults = .emptyNewUserDefaults()

        _ = Purchases.configure(
            with: .init(withAPIKey: "")
                .with(userDefaults: userDefaults)
                .with(appUserID: Self.appUserID)
        )
        Purchases.clearSingleton()
        let purchases = Purchases.configure(
            with: .init(withAPIKey: "")
                .with(userDefaults: userDefaults)
                .with(appUserID: nil)
        )

        expect(purchases.appUserID) == Self.appUserID
    }

    @available(*, deprecated)
    func testStaticUserIdSringLogsMessage() {
        _ = Purchases.configure(
            with: .init(withAPIKey: "")
                .with(appUserID: "Static string")
        )

        self.logger.verifyMessageWasLogged(Strings.identity.logging_in_with_static_string)
    }

    func testUserIdSringDoesNotLogMessage() {
        let appUserID = "user ID"

        _ = Purchases.configure(
            with: .init(withAPIKey: "")
                .with(appUserID: appUserID)
        )

        self.logger.verifyMessageWasNotLogged(Strings.identity.logging_in_with_static_string)
    }

    func testEntitlementVerificationModeDisabledDoesNotSetPublicKey() throws {
        let purchases = Purchases.configure(
            with: .init(withAPIKey: "")
                .with(entitlementVerificationMode: .disabled)
        )
        expect(purchases.publicKey).to(beNil())
    }

    func testEntitlementVerificationModeInformationalSetsPublicKey() throws {
        let purchases = Purchases.configure(
            with: .init(withAPIKey: "")
                .with(entitlementVerificationMode: .informational)
        )
        expect(purchases.publicKey).toNot(beNil())
    }

    // Can't compile this test while `Configuration.EntitlementVerificationMode.enforced` is unavailable.
    /*
    func testEntitlementVerificationModeEnforcedSetsPublicKey() throws {
        let purchases = Purchases.configure(
            with: .init(withAPIKey: "")
                .with(entitlementVerificationMode: .enforced)
        )
        expect(purchases.publicKey).toNot(beNil())
    }
    */

    func testFirstInitializationCallDelegate() {
        self.setupPurchases()
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(1))
    }

    func testFirstInitializationDoesNotClearIntroEligibilityCache() {
        self.setupPurchases()
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(1))

        expect(self.cachingTrialOrIntroPriceEligibilityChecker.invokedClearCache) == false
    }

    func testFirstInitializationDoesNotClearPurchasedProductsCache() {
        self.setupPurchases()
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(1))

        expect(self.mockPurchasedProductsFetcher.invokedClearCache) == false
    }

    func testFirstInitializationFromForegroundDelegateForAnonIfNothingCached() {
        self.systemInfo.stubbedIsApplicationBackgrounded = false
        self.setupPurchases()
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(1))
    }

    func testFirstInitializationFromBackgroundDoesntCallDelegateForAnonIfNothingCached() {
        self.systemInfo.stubbedIsApplicationBackgrounded = true
        self.setupPurchases()
        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(0))
    }

    func testFirstInitializationFromBackgroundCallsDelegateForAnonIfInfoCached() throws {
        self.systemInfo.stubbedIsApplicationBackgrounded = true

        let info = try CustomerInfo(data: Self.emptyCustomerInfoData)
        let object = try info.jsonEncodedData

        self.deviceCache.cachedCustomerInfo[self.identityManager.currentAppUserID] = object

        self.setupPurchases()

        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(1))
        expect(self.purchasesDelegate.customerInfo) == info
    }

    func testSettingTheDelegateAfterInitializationSendsCachedCustomerInfo() throws {
        let info = try CustomerInfo(data: Self.emptyCustomerInfoData)
        let object = try info.jsonEncodedData

        self.deviceCache.cachedCustomerInfo[identityManager.currentAppUserID] = object

        self.setupPurchases(withDelegate: false)
        expect(self.purchasesDelegate.customerInfoReceivedCount) == 0

        self.purchases.delegate = self.purchasesDelegate
        expect(self.purchasesDelegate.customerInfoReceivedCount) == 1
        expect(self.purchasesDelegate.customerInfo) == info
    }

    func testSettingTheDelegateLaterPastInitializationSendsCachedCustomerInfo() throws {
        let info = try CustomerInfo(data: Self.emptyCustomerInfoData)
        let object = try info.jsonEncodedData

        self.deviceCache.cachedCustomerInfo[identityManager.currentAppUserID] = object

        self.setupPurchases(withDelegate: false)
        expect(self.purchasesDelegate.customerInfoReceivedCount) == 0

        let expectation = XCTestExpectation()

        DispatchQueue.main.async {
            self.purchases.delegate = self.purchasesDelegate
            expect(self.purchasesDelegate.customerInfoReceivedCount) == 1
            expect(self.purchasesDelegate.customerInfo) == info

            expectation.fulfill()
        }

        self.wait(for: [expectation], timeout: 5)
    }

    func testFirstInitializationFromBackgroundDoesntUpdateCustomerInfoCache() {
        self.systemInfo.stubbedIsApplicationBackgrounded = true
        self.setupPurchases()
        expect(self.backend.getCustomerInfoCallCount).toEventually(equal(0))
    }

    func testFirstInitializationFromForegroundUpdatesCustomerInfoCacheIfNotInUserDefaults() {
        self.systemInfo.stubbedIsApplicationBackgrounded = false
        self.setupPurchases()
        expect(self.backend.getCustomerInfoCallCount).toEventually(equal(1))
    }

    func testFirstInitializationFromForegroundUpdatesCustomerInfoCacheIfUserDefaultsCacheStale() {
        let staleCacheDateForForeground = Calendar.current.date(byAdding: .minute, value: -20, to: Date())!
        self.deviceCache.setCustomerInfoCache(timestamp: staleCacheDateForForeground,
                                              appUserID: identityManager.currentAppUserID)
        self.systemInfo.stubbedIsApplicationBackgrounded = false

        self.setupPurchases()

        expect(self.backend.getCustomerInfoCallCount).toEventually(equal(1))
    }

    func testFirstInitializationFromForegroundUpdatesCustomerInfoEvenIfCacheValid() {
        let staleCacheDateForForeground = Calendar.current.date(byAdding: .minute, value: -2, to: Date())!
        self.deviceCache.setCustomerInfoCache(timestamp: staleCacheDateForForeground,
                                              appUserID: identityManager.currentAppUserID)

        self.systemInfo.stubbedIsApplicationBackgrounded = false

        self.setupPurchases()

        expect(self.backend.getCustomerInfoCallCount).toEventually(equal(1))
    }

    func testIsAnonymous() {
        setupAnonPurchases()
        expect(self.purchases.isAnonymous).to(beTrue())
    }

    func testIsNotAnonymous() {
        setupPurchases()
        expect(self.purchases.isAnonymous).to(beFalse())
    }

    func testSetsSelfAsStoreKit1WrapperDelegate() {
        self.setupPurchases()

        expect(self.storeKit1Wrapper.delegate) === self.purchasesOrchestrator
    }

    func testSetsSelfAsStoreKit1WrapperDelegateForSK1() {
        let configurationBuilder = Configuration.Builder(withAPIKey: "")
            .with(storeKitVersion: .storeKit1)
        let purchases = Purchases.configure(with: configurationBuilder.build())

        expect(purchases.isStoreKit1Configured) == true
    }

    func testDoesNotInitializeSK1IfSK2Enabled() throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        let configurationBuilder = Configuration.Builder(withAPIKey: "")
            .with(storeKitVersion: .storeKit2)
        let purchases = Purchases.configure(with: configurationBuilder.build())

        expect(purchases.isStoreKit1Configured) == false
    }

    func testSetsPaymentQueueWrapperDelegateToPurchasesOrchestratorIfSK1IsEnabled() {
        self.systemInfo = MockSystemInfo(finishTransactions: false,
                                         storeKitVersion: .storeKit1)

        self.setupPurchases()

        expect(self.mockPaymentQueueWrapper.delegate).to(beNil())
    }

    func testSetsPaymentQueueWrapperDelegateToPaymentQueueWrapperIfSK1IsNotEnabled() throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        self.systemInfo = MockSystemInfo(finishTransactions: false,
                                         storeKitVersion: .storeKit2)

        self.setupPurchases()

        expect(self.mockPaymentQueueWrapper.delegate) === self.purchasesOrchestrator
    }

    // MARK: - Custom Entitlement Computation
    func testCustomEntitlementComputationSkipsFirstDelegateCall() throws {
        self.systemInfo = MockSystemInfo(finishTransactions: true,
                                         customEntitlementsComputation: true)
        self.setupPurchases()

        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(0))
    }

    func testWithoutCustomEntitlementComputationDoesntSkipFirstDelegateCall() throws {
        self.systemInfo = MockSystemInfo(finishTransactions: true,
                                         customEntitlementsComputation: false)
        self.setupPurchases()

        expect(self.purchasesDelegate.customerInfoReceivedCount).toEventually(equal(1))
    }

    #if !os(watchOS)
    func testConfigureWithCustomEntitlementComputationFatalErrorIfNoAppUserID() throws {
        expect {
            _ = Purchases(apiKey: "",
                          appUserID: nil,
                          userDefaults: .emptyNewUserDefaults(),
                          observerMode: false,
                          responseVerificationMode: .default,
                          dangerousSettings: .init(customEntitlementComputation: true),
                          showStoreMessagesAutomatically: true)
        }.to(throwAssertion())
    }

    func testConfigureWithCustomEntitlementComputationNoFatalErrorIfAppUserIDPassedIn() throws {
        self.systemInfo = MockSystemInfo(finishTransactions: true,
                                         customEntitlementsComputation: true)
        expect {
            self.setupPurchases()
        }.toNot(throwAssertion())
    }
    #endif

    func testConfigureWithCustomEntitlementComputationLogsInformationMessage() throws {
        self.systemInfo = MockSystemInfo(finishTransactions: true,
                                         customEntitlementsComputation: true)
        self.setupPurchases()

        self.logger.verifyMessageWasLogged(Strings.configure.custom_entitlements_computation_enabled, level: .info)
    }

    func testConfigureWithoutCustomEntitlementComputationDoesntLogInformationMessage() throws {
        self.setupPurchases()

        self.logger.verifyMessageWasNotLogged(Strings.configure.custom_entitlements_computation_enabled)
    }

    func testConfigureWithCustomEntitlementComputationDisablesLogOut() throws {
        self.systemInfo = MockSystemInfo(finishTransactions: true,
                                         customEntitlementsComputation: true)
        self.setupPurchases()

        var receivedCustomerInfo: CustomerInfo?
        var receivedError: PublicError?
        var completionCalled = false

        self.purchases.logOut { customerInfo, error in
            completionCalled = true
            receivedCustomerInfo = customerInfo
            receivedError = error
        }

        expect(completionCalled).toEventually(beTrue())
        expect(receivedCustomerInfo).to(beNil())
        let unwrappedError = try XCTUnwrap(receivedError)
        expect(unwrappedError).to(matchError(ErrorUtils.featureNotAvailableInCustomEntitlementsComputationModeError()))
    }

    func testConfigureWithCustomEntitlementComputationDisablesAutomaticCacheUpdateForCustomerInfo() throws {
        self.systemInfo = MockSystemInfo(finishTransactions: true,
                                         customEntitlementsComputation: true)
        self.systemInfo.stubbedIsApplicationBackgrounded = false

        self.setupPurchases()

        expect(self.backend.getCustomerInfoCallCount).toEventually(equal(0))
    }

    // MARK: - UserDefaults

    func testCustomUserDefaultsIsUsed() {
        expect(Self.create(userDefaults: Self.customUserDefaults).configuredUserDefaults) === Self.customUserDefaults
    }

    func testDefaultUserDefaultsIsUsedByDefault() {
        expect(Self.create(userDefaults: nil).configuredUserDefaults) === UserDefaults.computeDefault()
    }

    private static func create(userDefaults: UserDefaults?) -> Purchases {
        var configurationBuilder: Configuration.Builder = .init(withAPIKey: "")

        if let userDefaults = userDefaults {
            configurationBuilder = configurationBuilder.with(userDefaults: userDefaults)
        }

        return Purchases.configure(with: configurationBuilder.build())
    }

    private static let customUserDefaults: UserDefaults = .init(suiteName: "com.revenuecat.testing_user_defaults")!

    // MARK: - OfflineCustomerInfoCreator

    func testPurchasesAreCompletedByMyAppDoesNotCreateOfflineCustomerInfoCreator() {
        expect(Self.create(purchasesAreCompletedBy: .myApp).offlineCustomerInfoEnabled) == false
    }

    func testOlderVersionsDoNoCreateOfflineCustomerInfo() throws {
        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
            throw XCTSkip("Test for older versions")
        }

        expect(Self.create(purchasesAreCompletedBy: .revenueCat).offlineCustomerInfoEnabled) == false
    }

    func testOfflineCustomerInfoEnabled() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        expect(Self.create(purchasesAreCompletedBy: .revenueCat).offlineCustomerInfoEnabled) == true
    }

    func testOfflineCustomerInfoDisabledForCustomEntitlementsComputation() throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        expect(
            Self.create(
                purchasesAreCompletedBy: .revenueCat,
                dangerousSettings: .init(customEntitlementComputation: true)
            ).offlineCustomerInfoEnabled
        ) == false
    }

    // MARK: StoreKit2PurchaseIntentListener Configuration Tests
    func testDoesntSetPurchasesOrchestratorStoreKit2PurchaseIntentListenerIfSK1IsEnabled() {
        self.systemInfo = MockSystemInfo(finishTransactions: false,
                                         storeKitVersion: .storeKit1)

        self.setupPurchases()

        expect(self.purchasesOrchestrator._storeKit2PurchaseIntentListener).to(beNil())
    }

    func testSetsPurchasesOrchestratorStoreKit2PurchaseIntentListenerIfSK2IsEnabled() {
        self.systemInfo = MockSystemInfo(finishTransactions: false,
                                         storeKitVersion: .storeKit2)

        self.setupPurchases()

        #if os(watchOS) || os(tvOS) || os(visionOS)
        expect(self.purchasesOrchestrator._storeKit2PurchaseIntentListener).to(beNil())
        #else
        if #available(iOS 16.4, macOS 14.4, *) {
            expect(self.purchasesOrchestrator._storeKit2PurchaseIntentListener).toEventuallyNot(beNil())
        } else {
            expect(self.purchasesOrchestrator._storeKit2PurchaseIntentListener).to(beNil())
        }
        #endif
    }

  private static func create(
      purchasesAreCompletedBy: PurchasesAreCompletedBy,
      dangerousSettings: DangerousSettings = .init()
  ) -> Purchases {
        return Purchases.configure(
            with: .init(withAPIKey: "")
                .with(purchasesAreCompletedBy: purchasesAreCompletedBy, storeKitVersion: .storeKit1)
                .with(dangerousSettings: dangerousSettings)
        )
    }

}

private extension UserDefaults {

    static func emptyNewUserDefaults() -> Self {
        return .init(suiteName: UUID().uuidString)!
    }

}
