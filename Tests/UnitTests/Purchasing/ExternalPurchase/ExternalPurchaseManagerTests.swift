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
    private var configProvider: MockExternalPurchasesConfigProvider!
    private var systemInfo: MockSystemInfo!
    private var manager: ExternalPurchaseManager!

    override func setUp() {
        super.setUp()

        self.customLink = MockExternalPurchaseCustomLink()
        self.customLink.stubbedTokenResult = .success(Self.token)

        self.externalPurchaseTokenAPI = MockExternalPurchaseTokenAPI()
        self.externalPurchaseTokenAPI.stubbedPostExternalPurchaseTokenResult = .success(.init(id: Self.tokenID))

        self.configProvider = MockExternalPurchasesConfigProvider()
        self.configProvider.stubbedAllowedStorefronts = [Self.allowedStorefront]

        self.systemInfo = Self.makeSystemInfo(useExternalPurchaseCustomLinks: true)
        self.systemInfo.stubbedStorefront = MockStorefront(countryCode: Self.allowedStorefront)
        self.manager = self.makeManager()
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

    // MARK: - Token reporting

    /// An app config that does not report to Apple is one Apple's flow has nothing to say about, so the
    /// customer buys as they did before the app had anything to do with the programme.
    func testMintsNothingAndProceedsWhileTheAppDoesNotReportTokens() async {
        self.configProvider.stubbedReportsTokens = false

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .notApplicable
        expect(self.customLink.invokedAvailabilityCount) == 0
        expect(self.customLink.invokedNoticeTypes).to(beEmpty())
        expect(self.customLink.invokedTokenTypes).to(beEmpty())
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseToken) == false
        self.logger.verifyMessageWasLogged(Strings.externalPurchase.token_reporting_disabled)
    }

    /// The storefronts are the exception to Apple's own eligibility, which an app that reports nothing is
    /// never subject to: it is offered the purchase everywhere rather than refused outside the list.
    func testAsksNothingAboutStorefrontsWhileTheAppDoesNotReportTokens() async {
        self.configProvider.stubbedReportsTokens = false
        self.systemInfo.stubbedStorefront = MockStorefront(countryCode: Self.otherStorefront)

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .notApplicable
        expect(self.configProvider.invokedAllowedStorefrontsCount) == 0
    }

    /// The toggle comes from remote config, which can change while the app runs, so no verdict is kept from
    /// an earlier purchase.
    func testResolvesTokenReportingOnEveryPurchase() async {
        self.configProvider.stubbedReportsTokens = false

        let whileNotReporting = await self.manager.prepareExternalPurchase(flow: .inApp)
        expect(whileNotReporting) == .notApplicable

        self.configProvider.stubbedReportsTokens = true

        let onceReporting = await self.manager.prepareExternalPurchase(flow: .inApp)
        expect(onceReporting) == .registered(tokenID: Self.tokenID)

        expect(self.configProvider.invokedReportsTokensCount) == 2
    }

    // MARK: - Storefronts that allow the purchase without eligibility

    /// Where Apple's flow does not apply and the storefront is not one it is waived in, the customer is
    /// offered nothing at all rather than an undisclosed purchase.
    func testStopsWhenTheStorefrontIsNotOneOfThoseAllowedWithoutEligibility() async {
        self.customLink.stubbedAvailability = .notEligible
        self.systemInfo.stubbedStorefront = MockStorefront(countryCode: Self.otherStorefront)

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .stopped(.notAllowedInStorefront)
        expect(self.customLink.invokedNoticeTypes).to(beEmpty())
        expect(self.customLink.invokedTokenTypes).to(beEmpty())
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseToken) == false
    }

    /// A storefront that cannot be read is no proof of being in one where the purchase is allowed.
    func testStopsWhenTheStorefrontIsUnknown() async {
        self.customLink.stubbedAvailability = .notEligible
        self.systemInfo.stubbedStorefront = nil

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .stopped(.notAllowedInStorefront)
    }

    /// An empty policy is what an SDK that could not read one is left with, and it offers the purchase
    /// nowhere rather than everywhere.
    func testStopsWhileNoStorefrontIsAllowed() async {
        self.customLink.stubbedAvailability = .notEligible
        self.configProvider.stubbedAllowedStorefronts = []

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .stopped(.notAllowedInStorefront)
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
        self.configProvider.stubbedAllowedStorefronts = []
        self.systemInfo.stubbedStorefront = MockStorefront(countryCode: Self.otherStorefront)

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .registered(tokenID: Self.tokenID)
        expect(self.configProvider.invokedAllowedStorefrontsCount) == 0
    }

    /// The customer can change storefront while the app runs, so no verdict is kept from an earlier purchase.
    func testResolvesTheStorefrontOnEveryPurchase() async {
        self.customLink.stubbedAvailability = .notEligible

        let whileAllowed = await self.manager.prepareExternalPurchase(flow: .inApp)
        expect(whileAllowed) == .notApplicable

        self.systemInfo.stubbedStorefront = MockStorefront(countryCode: Self.otherStorefront)

        let onceElsewhere = await self.manager.prepareExternalPurchase(flow: .inApp)
        expect(onceElsewhere) == .stopped(.notAllowedInStorefront)

        expect(self.configProvider.invokedAllowedStorefrontsCount) == 2
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
        self.manager = self.makeManager()

        let availability = await self.manager.externalPurchaseAvailability()
        expect(availability) == .notEligible

        let result = await self.manager.prepareExternalPurchase(flow: .linkOut)

        expect(result) == .notApplicable
        expect(self.customLink.invokedAvailabilityCount) == 0
        expect(self.customLink.invokedNoticeTypes).to(beEmpty())
        expect(self.customLink.invokedTokenTypes).to(beEmpty())
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseToken) == false
        expect(self.configProvider.invokedAllowedStorefrontsCount) == 0
        expect(self.configProvider.invokedReportsTokensCount) == 0
    }

    /// Apps outside the programme did not try to make an external purchase, so telling them anything about
    /// Apple's custom link is noise in their console.
    func testNothingIsLoggedWhileTheSettingIsDisabled() async {
        self.systemInfo = Self.makeSystemInfo(useExternalPurchaseCustomLinks: false)
        self.manager = self.makeManager()

        _ = await self.manager.prepareExternalPurchase(flow: .linkOut)

        self.logger.verifyMessageWasNotLogged(Strings.externalPurchase.custom_link_does_not_apply,
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

    private func makeManager() -> ExternalPurchaseManager {
        return ExternalPurchaseManager(
            customLink: self.customLink,
            externalPurchaseTokenAPI: self.externalPurchaseTokenAPI,
            currentUserProvider: MockCurrentUserProvider(mockAppUserID: Self.appUserID),
            configProvider: self.configProvider,
            systemInfo: self.systemInfo
        )
    }

}
