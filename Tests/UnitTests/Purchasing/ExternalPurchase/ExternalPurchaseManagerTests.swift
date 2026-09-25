//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ExternalPurchaseManagerTests.swift
//
//  Created by Antonio Pallares on 4/9/26.

import Foundation
import Nimble
import XCTest

@_spi(Experimental) @testable import RevenueCat

class ExternalPurchaseManagerTests: TestCase {

    private static let appUserID = "test-app-user-id"
    private static let token = "test-external-purchase-token"
    private static let tokenID = "ept13dcbc01adaa44db9b1691a6be2f9929"
    private static let allowedStorefront = "USA"
    private static let otherStorefront = "ESP"

    private var customLink: MockExternalPurchaseCustomLink!
    private var externalPurchaseTokenAPI: MockExternalPurchaseTokenAPI!
    private var settingsProvider: MockSDKSettingsConfigProvider!
    private var systemInfo: MockSystemInfo!
    private var manager: ExternalPurchaseManager!

    override func setUp() {
        super.setUp()

        self.customLink = MockExternalPurchaseCustomLink()
        self.customLink.stubbedTokenResult = .success(Self.token)

        self.externalPurchaseTokenAPI = MockExternalPurchaseTokenAPI()
        self.externalPurchaseTokenAPI.stubbedPostExternalPurchaseTokenResult = .success(.init(id: Self.tokenID))

        self.settingsProvider = MockSDKSettingsConfigProvider()
        self.settingsProvider.stubbedSettings = .allowingExternalPurchases(in: [Self.allowedStorefront])

        self.systemInfo = Self.makeSystemInfo(useExternalPurchaseCustomLinks: true)
        self.systemInfo.stubbedStorefront = MockStorefront(countryCode: Self.allowedStorefront)
        self.manager = self.makeManager(isRunningInSimulator: false)
    }

    // MARK: - Flow types

    /// Also covers the case where the system suppresses the notice because the customer chose not to see it
    /// again: `showNotice` returns `.continued` with no interaction, which is what the mock does.
    func testInAppPurchasesShowTheWithinAppNoticeAndRequestAnInAppToken() async {
        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .registered(tokenID: Self.tokenID)
        expect(self.customLink.invokedNoticeTypes) == [.withinApp]
        expect(self.customLink.invokedTokenTypes) == [.inApp]

        let parameters = self.externalPurchaseTokenAPI.invokedPostExternalPurchaseTokenParameters
        expect(parameters?.appUserID) == Self.appUserID
        expect(parameters?.purchaseType) == .inApp
        expect(parameters?.token) == Self.token
    }

    func testLinkOutPurchasesShowTheBrowserNoticeAndRequestALinkOutToken() async {
        let result = await self.manager.prepareExternalPurchase(flow: .linkOut)

        expect(result) == .registered(tokenID: Self.tokenID)
        expect(self.customLink.invokedNoticeTypes) == [.browser]
        expect(self.customLink.invokedTokenTypes) == [.linkOut]
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseTokenParameters?.purchaseType) == .linkOut
    }

    // MARK: - Outside the programme

    /// Nothing is disclosed and nothing is minted, so the caller is left to take the customer where it took
    /// them before the app had anything to do with Apple's programme.
    func testMintsNothingAndProceedsWhenTheAppIsNotEligible() async {
        self.customLink.stubbedAvailability = .notEligible

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .notApplicable
        expect(self.customLink.invokedNoticeTypes).to(beEmpty())
        expect(self.customLink.invokedTokenTypes).to(beEmpty())
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseToken) == false
    }

    // MARK: - Storefronts that do not require Apple's external purchase APIs

    /// Where Apple's external purchase APIs are required and cannot be used for this customer, they are
    /// offered nothing at all rather than an undisclosed purchase.
    func testStopsWhenTheStorefrontIsNotOneOfThoseAllowedWithoutEligibility() async {
        self.customLink.stubbedAvailability = .notEligible
        self.systemInfo.stubbedStorefront = MockStorefront(countryCode: Self.otherStorefront)

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .stopped(.notEligible)
        expect(self.customLink.invokedNoticeTypes).to(beEmpty())
        expect(self.customLink.invokedTokenTypes).to(beEmpty())
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseToken) == false
    }

    /// A storefront that cannot be read is no proof of being in one where the purchase is allowed.
    func testStopsWhenTheStorefrontIsUnknown() async {
        self.customLink.stubbedAvailability = .notEligible
        self.systemInfo.stubbedStorefront = nil

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .stopped(.notEligible)
    }

    /// An empty policy is what an SDK that could not read one is left with, and it offers the purchase
    /// nowhere rather than everywhere.
    func testStopsWhileNoStorefrontIsAllowed() async {
        self.customLink.stubbedAvailability = .notEligible
        self.settingsProvider.stubbedSettings = .allowingExternalPurchases(in: [])

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .stopped(.notEligible)
    }

    func testMatchesTheStorefrontRegardlessOfCase() async {
        self.customLink.stubbedAvailability = .notEligible
        self.systemInfo.stubbedStorefront = MockStorefront(countryCode: "usa")

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .notApplicable
    }

    /// Being eligible is Apple's own answer for this customer in this storefront, so the policy has no say:
    /// the notice is shown and the token is minted wherever they are.
    func testAsksNothingAboutStorefrontsWhileTheCustomerIsEligible() async {
        self.settingsProvider.stubbedSettings = .allowingExternalPurchases(in: [])
        self.systemInfo.stubbedStorefront = MockStorefront(countryCode: Self.otherStorefront)

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .registered(tokenID: Self.tokenID)
        expect(self.settingsProvider.invokedSettingsCount) == 0
    }

    /// The customer can change storefront while the app runs, so no verdict is kept from an earlier purchase.
    func testResolvesTheStorefrontOnEveryPurchase() async {
        self.customLink.stubbedAvailability = .notEligible

        let whileAllowed = await self.manager.prepareExternalPurchase(flow: .inApp)
        expect(whileAllowed) == .notApplicable

        self.systemInfo.stubbedStorefront = MockStorefront(countryCode: Self.otherStorefront)

        let onceElsewhere = await self.manager.prepareExternalPurchase(flow: .inApp)
        expect(onceElsewhere) == .stopped(.notEligible)

        expect(self.settingsProvider.invokedSettingsCount) == 2
    }

    // MARK: - Stopping

    /// Kept apart from being ineligible: the caller has nothing to offer instead, so it must not fall back to a
    /// purchase of any kind.
    func testMintsNothingWhenTheDeviceDoesNotAuthorizePayments() async {
        self.customLink.stubbedAvailability = .paymentsNotAuthorized

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .stopped(.paymentsNotAuthorized)
        expect(self.customLink.invokedNoticeTypes).to(beEmpty())
        expect(self.customLink.invokedTokenTypes).to(beEmpty())
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseToken) == false
    }

    /// Nothing is minted when the customer declines, so there is nothing to report back to Apple.
    func testMintsNothingWhenTheCustomerDeclinesTheNotice() async {
        self.customLink.stubbedNoticeResult = .success(.cancelled)

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .stopped(.customerCancelledNotice)
        expect(self.customLink.invokedTokenTypes).to(beEmpty())
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseToken) == false
    }

    /// Requesting a token without having disclosed anything is not an option, so a failing notice stops the
    /// purchase even though the customer did not decline.
    func testStopsWhenTheNoticeCannotBeShown() async {
        self.customLink.stubbedNoticeResult = .failure(ExternalPurchaseError.apiUnavailable)

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .stopped(.noticeFailed)
        expect(self.customLink.invokedTokenTypes).to(beEmpty())
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseToken) == false
    }

    // MARK: - Registering without a StoreKit token

    /// StoreKit has no token to give where its API is not available yet, and the backend generates one instead,
    /// so the registration still happens and the checkout still gets an identifier.
    func testRegistersWithoutATokenWhenStoreKitHasNone() async {
        self.customLink.stubbedTokenResult = .success(nil)

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .registered(tokenID: Self.tokenID)
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseTokenCount) == 1
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseTokenParameters?.token).to(beNil())
    }

    // MARK: - Proceeding without an identifier

    func testProceedsWithoutRegisteringWhenTheTokenRequestFails() async {
        self.customLink.stubbedTokenResult = .failure(ErrorUtils.storeProblemError())

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .unregistered(.tokenRequestFailed)
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseToken) == false
    }

    /// A failed registration leaves the checkout with nothing to tie the purchase to, which is knowingly accepted
    /// rather than getting in the way of the customer buying.
    func testProceedsWhenRegistrationFails() async {
        self.externalPurchaseTokenAPI.stubbedPostExternalPurchaseTokenResult = .failure(
            .networkError(.offlineConnection())
        )

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .unregistered(.registrationFailed)
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseTokenCount) == 1
    }

    // MARK: - Dangerous setting

    /// The setting stands for the app taking part in Apple's programme at all, so it gates every flow rather
    /// than any one call site.
    func testTheWholeSequenceIsSkippedWhileTheSettingIsDisabled() async {
        self.systemInfo = Self.makeSystemInfo(useExternalPurchaseCustomLinks: false)
        self.manager = self.makeManager(isRunningInSimulator: false)

        let availability = await self.manager.externalPurchaseAvailability()
        expect(availability) == .notEligible

        let result = await self.manager.prepareExternalPurchase(flow: .linkOut)

        expect(result) == .notApplicable
        expect(self.customLink.invokedAvailabilityCount) == 0
        expect(self.customLink.invokedNoticeTypes).to(beEmpty())
        expect(self.customLink.invokedTokenTypes).to(beEmpty())
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseToken) == false
        expect(self.settingsProvider.invokedSettingsCount) == 0
    }

    /// Apps outside the programme did not try to make an external purchase, so telling them anything about
    /// Apple's custom link is noise in their console.
    func testNothingIsLoggedWhileTheSettingIsDisabled() async {
        self.systemInfo = Self.makeSystemInfo(useExternalPurchaseCustomLinks: false)
        self.manager = self.makeManager(isRunningInSimulator: false)

        _ = await self.manager.prepareExternalPurchase(flow: .linkOut)

        self.logger.verifyMessageWasNotLogged(
            Strings.externalPurchase.custom_link_does_not_apply(Self.allowedStorefront),
            allowNoMessages: true
        )
    }

    // MARK: - Simulator

    /// StoreKit never finds the customer eligible in the simulator, so asking it would only ever stop the purchase
    /// outside the storefronts allowed without eligibility.
    func testRunsNoneOfTheSequenceInTheSimulator() async {
        self.manager = self.makeManager(isRunningInSimulator: true)

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .notApplicable
        expect(self.customLink.invokedAvailabilityCount) == 0
        expect(self.customLink.invokedNoticeTypes).to(beEmpty())
        expect(self.customLink.invokedTokenTypes).to(beEmpty())
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseToken) == false
        self.logger.verifyMessageWasLogged(Strings.externalPurchase.custom_link_skipped_in_simulator,
                                           level: .debug)
    }

    /// Developers try their web purchases out in the simulator from wherever they are.
    func testProceedsInTheSimulatorWhateverTheStorefront() async {
        self.settingsProvider.stubbedSettings = .allowingExternalPurchases(in: [])
        self.systemInfo.stubbedStorefront = MockStorefront(countryCode: Self.otherStorefront)
        self.manager = self.makeManager(isRunningInSimulator: true)

        let result = await self.manager.prepareExternalPurchase(flow: .linkOut)

        expect(result) == .notApplicable
        expect(self.settingsProvider.invokedSettingsCount) == 0
    }

    /// Offers nothing even in a storefront allowed without eligibility, so the path taken by a customer who is
    /// offered nothing can be tried out in the simulator wherever the developer is.
    func testOffersNothingInTheSimulatorWhileExternalPurchasesAreDisabledThere() async {
        self.systemInfo = Self.makeSystemInfoDisablingExternalPurchasesInSimulator()
        self.systemInfo.stubbedStorefront = MockStorefront(countryCode: Self.allowedStorefront)
        self.manager = self.makeManager(isRunningInSimulator: true)

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .stopped(.notEligible)
        expect(self.customLink.invokedAvailabilityCount) == 0
        expect(self.customLink.invokedNoticeTypes).to(beEmpty())
        expect(self.customLink.invokedTokenTypes).to(beEmpty())
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseToken) == false
        expect(self.settingsProvider.invokedSettingsCount) == 0
        self.logger.verifyMessageWasLogged(Strings.externalPurchase.disabled_in_simulator, level: .warn)
    }

    func testDisablingExternalPurchasesInTheSimulatorChangesNothingOnADevice() async {
        self.systemInfo = Self.makeSystemInfoDisablingExternalPurchasesInSimulator()
        self.manager = self.makeManager(isRunningInSimulator: false)

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .registered(tokenID: Self.tokenID)
        expect(self.customLink.invokedNoticeTypes) == [.withinApp]
    }

    /// Apps outside the programme hear nothing about Apple's custom link, in the simulator or anywhere else.
    func testNothingIsLoggedInTheSimulatorWhileTheSettingIsDisabled() async {
        self.systemInfo = Self.makeSystemInfo(useExternalPurchaseCustomLinks: false)
        self.manager = self.makeManager(isRunningInSimulator: true)

        let result = await self.manager.prepareExternalPurchase(flow: .linkOut)

        expect(result) == .notApplicable
        self.logger.verifyMessageWasNotLogged(Strings.externalPurchase.custom_link_skipped_in_simulator,
                                              allowNoMessages: true)
    }

    // MARK: - Test Store

    /// Eligibility follows the app's entitlement and the customer's storefront, neither of which has anything
    /// to do with the key the SDK was configured with, so StoreKit is asked as it is for any other key.
    func testTheTestStoreResolvesEligibilityThroughStoreKit() async {
        self.systemInfo.stubbedApiKeyValidationResult = .simulatedStore

        let availability = await self.manager.externalPurchaseAvailability()

        expect(availability) == .available
        expect(self.customLink.invokedAvailabilityCount) == 1
    }

    /// A Test Store key is the shortest path a developer has to trying the flow out, so it runs in full. The
    /// purchase behind the token is a sandbox one, which is what it would have been anyway.
    func testTheTestStoreRunsTheWholeSequence() async {
        self.systemInfo.stubbedApiKeyValidationResult = .simulatedStore

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .registered(tokenID: Self.tokenID)
        expect(self.customLink.invokedNoticeTypes) == [.withinApp]
        expect(self.customLink.invokedTokenTypes) == [.inApp]
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseTokenCount) == 1
    }

    // MARK: - Eligibility

    /// Eligibility can change while the app is running, so every purchase asks for it again.
    func testResolvesEligibilityOnEveryPurchase() async {
        self.customLink.stubbedAvailability = .notEligible

        let whileIneligible = await self.manager.prepareExternalPurchase(flow: .inApp)
        expect(whileIneligible) == .notApplicable

        self.customLink.stubbedAvailability = .available

        let onceEligible = await self.manager.prepareExternalPurchase(flow: .inApp)
        expect(onceEligible) == .registered(tokenID: Self.tokenID)

        expect(self.customLink.invokedAvailabilityCount) == 2
    }

    // MARK: - One preparation at a time

    /// Every token minted is one Apple expects a report for, and a customer who taps twice while the notice is
    /// coming up asked to buy once.
    func testStopsAPreparationAskedForWhileAnotherIsUnderWay() async {
        let manager = self.manager!
        let secondResult: Atomic<ExternalPurchasePreparationResult?> = nil

        self.customLink.whileShowingNotice = {
            secondResult.value = await manager.prepareExternalPurchase(flow: .linkOut)
        }

        let firstResult = await manager.prepareExternalPurchase(flow: .linkOut)

        expect(secondResult.value) == .stopped(.alreadyPreparing)
        expect(firstResult) == .registered(tokenID: Self.tokenID)
        expect(self.customLink.invokedNoticeTypes) == [.browser]
        expect(self.customLink.invokedTokenTypes) == [.linkOut]
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseTokenCount) == 1
    }

    func testPreparesAgainOnceTheFirstOneIsDone() async {
        let first = await self.manager.prepareExternalPurchase(flow: .linkOut)
        let second = await self.manager.prepareExternalPurchase(flow: .linkOut)

        expect(first) == .registered(tokenID: Self.tokenID)
        expect(second) == .registered(tokenID: Self.tokenID)
        expect(self.customLink.invokedNoticeTypes) == [.browser, .browser]
    }

    // MARK: - Helpers

    private static func makeSystemInfo(useExternalPurchaseCustomLinks: Bool) -> MockSystemInfo {
        return MockSystemInfo(
            finishTransactions: true,
            dangerousSettings: DangerousSettings(
                autoSyncPurchases: true,
                useExternalPurchaseCustomLinks: useExternalPurchaseCustomLinks
            )
        )
    }

    private static func makeSystemInfoDisablingExternalPurchasesInSimulator() -> MockSystemInfo {
        return MockSystemInfo(
            finishTransactions: true,
            dangerousSettings: DangerousSettings(
                autoSyncPurchases: true,
                useExternalPurchaseCustomLinks: true,
                disableExternalPurchasesInSimulator: true
            )
        )
    }

    private func makeManager(isRunningInSimulator: Bool) -> ExternalPurchaseManager {
        return ExternalPurchaseManager(
            customLink: self.customLink,
            externalPurchaseTokenAPI: self.externalPurchaseTokenAPI,
            currentUserProvider: MockCurrentUserProvider(mockAppUserID: Self.appUserID),
            settingsProvider: self.settingsProvider,
            systemInfo: self.systemInfo,
            isRunningInSimulator: isRunningInSimulator
        )
    }

}
