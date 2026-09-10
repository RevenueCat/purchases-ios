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

    private var customLink: MockExternalPurchaseCustomLink!
    private var externalPurchaseTokenAPI: MockExternalPurchaseTokenAPI!
    private var tokenStore: MockExternalPurchaseTokenStore!
    private var operationDispatcher: MockOperationDispatcher!
    private var systemInfo: MockSystemInfo!
    private var manager: ExternalPurchaseManager!

    override func setUp() {
        super.setUp()

        self.customLink = MockExternalPurchaseCustomLink()
        self.customLink.stubbedTokenResult = .success(Self.token)

        self.externalPurchaseTokenAPI = MockExternalPurchaseTokenAPI()
        self.tokenStore = MockExternalPurchaseTokenStore()
        self.operationDispatcher = MockOperationDispatcher()

        self.systemInfo = Self.makeSystemInfo(useExternalPurchaseCustomLinks: true)
        self.manager = self.makeManager()
    }

    // MARK: - Flow types

    /// Also covers the case where the system suppresses the notice because the customer chose not to see it
    /// again: `showNotice` returns `.continued` with no interaction, which is what the mock does.
    func testInAppPurchasesShowTheWithinAppNoticeAndRequestAnInAppToken() async throws {
        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .registered(tokenID: try XCTUnwrap(self.postedTokenID))
        expect(self.customLink.invokedNoticeTypes) == [.withinApp]
        expect(self.customLink.invokedTokenTypes) == [.inApp]

        let parameters = self.externalPurchaseTokenAPI.invokedPostExternalPurchaseTokenParameters
        expect(parameters?.appUserID) == Self.appUserID
        expect(parameters?.purchaseType) == .inApp
        expect(parameters?.token) == Self.token
    }

    func testLinkOutPurchasesShowTheBrowserNoticeAndRequestALinkOutToken() async throws {
        let result = await self.manager.prepareExternalPurchase(flow: .linkOut)

        expect(result) == .registered(tokenID: try XCTUnwrap(self.postedTokenID))
        expect(self.customLink.invokedNoticeTypes) == [.browser]
        expect(self.customLink.invokedTokenTypes) == [.linkOut]
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseTokenParameters?.purchaseType) == .linkOut
    }

    // MARK: - Stopping

    func testMintsNothingWhenTheAppIsNotEligible() async {
        self.customLink.stubbedAvailability = .notEligible

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .stopped(.notEligible)
        expect(result.shouldProceed) == false
        expect(self.customLink.invokedNoticeTypes).to(beEmpty())
        expect(self.customLink.invokedTokenTypes).to(beEmpty())
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseToken) == false
    }

    /// Kept apart from being ineligible: the caller has nothing to offer instead, so it must not fall back to a
    /// purchase of any kind.
    func testMintsNothingWhenTheDeviceDoesNotAuthorizePayments() async {
        self.customLink.stubbedAvailability = .paymentsNotAuthorized

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .stopped(.paymentsNotAuthorized)
        expect(result.shouldProceed) == false
        expect(self.customLink.invokedNoticeTypes).to(beEmpty())
        expect(self.customLink.invokedTokenTypes).to(beEmpty())
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseToken) == false
    }

    /// Nothing is minted when the customer declines, so there is nothing to report back to Apple.
    func testMintsNothingWhenTheCustomerDeclinesTheNotice() async {
        self.customLink.stubbedNoticeResult = .success(.cancelled)

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .stopped(.customerCancelledNotice)
        expect(result.shouldProceed) == false
        expect(self.customLink.invokedTokenTypes).to(beEmpty())
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseToken) == false
    }

    /// Requesting a token without having disclosed anything is not an option, so a failing notice stops the
    /// purchase even though the customer did not decline.
    func testStopsWhenTheNoticeCannotBeShown() async {
        self.customLink.stubbedNoticeResult = .failure(ExternalPurchaseError.apiUnavailable)

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .stopped(.noticeFailed)
        expect(result.shouldProceed) == false
        expect(self.customLink.invokedTokenTypes).to(beEmpty())
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseToken) == false
    }

    // MARK: - Registering without a StoreKit token

    /// StoreKit has no token to give where its API is not available yet, and the backend generates one instead,
    /// so the registration still happens and the checkout still gets an identifier.
    func testRegistersWithoutATokenWhenStoreKitHasNone() async throws {
        self.customLink.stubbedTokenResult = .success(nil)

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .registered(tokenID: try XCTUnwrap(self.postedTokenID))
        expect(result.shouldProceed) == true
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseTokenCount) == 1
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseTokenParameters?.token).to(beNil())
    }

    // MARK: - Proceeding without an identifier

    func testProceedsWithoutRegisteringWhenTheTokenRequestFails() async {
        self.customLink.stubbedTokenResult = .failure(ErrorUtils.storeProblemError())

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .unregistered(.tokenRequestFailed)
        expect(result.shouldProceed) == true
        expect(result.tokenID).to(beNil())
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseToken) == false
    }

    /// A failed registration leaves the checkout with nothing to tie the purchase to, which is knowingly accepted
    /// rather than getting in the way of the customer buying.
    func testProceedsWhenRegistrationFails() async {
        self.externalPurchaseTokenAPI.stubbedPostExternalPurchaseTokenError = .networkError(.offlineConnection())

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .unregistered(.registrationFailed)
        expect(result.shouldProceed) == true
        expect(result.tokenID).to(beNil())
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseTokenCount) == 1
    }

    // MARK: - Keeping the registration

    /// Apple expects a report for every token minted, so the registration is kept before the post that may
    /// never land.
    func testKeepsTheRegistrationBeforePostingIt() async throws {
        let store = try XCTUnwrap(self.tokenStore)
        let keptWhilePosting: Atomic<[ExternalPurchaseTokenRegistration]> = .init([])

        self.externalPurchaseTokenAPI.postExternalPurchaseTokenCallback = {
            keptWhilePosting.value = store.storedRegistrations
        }

        _ = await self.manager.prepareExternalPurchase(flow: .linkOut)

        let kept = try XCTUnwrap(keptWhilePosting.value.onlyElement)
        expect(kept.tokenID) == self.postedTokenID
        expect(kept.appUserID) == Self.appUserID
        expect(kept.purchaseType) == .linkOut
        expect(kept.token) == Self.token
    }

    func testDropsTheRegistrationOnceTheBackendAcceptsIt() async {
        _ = await self.manager.prepareExternalPurchase(flow: .linkOut)

        expect(self.tokenStore.storedRegistrations).to(beEmpty())
    }

    /// A registration lost to a connection failure can still land later, which is what keeping it is for.
    func testKeepsTheRegistrationWhenThePostFailsTransiently() async throws {
        self.externalPurchaseTokenAPI.stubbedPostExternalPurchaseTokenError = .networkError(.offlineConnection())

        _ = await self.manager.prepareExternalPurchase(flow: .linkOut)

        let kept = try XCTUnwrap(self.tokenStore.storedRegistrations.onlyElement)
        expect(kept.tokenID) == self.postedTokenID

        self.logger.verifyMessageWasLogged(Strings.externalPurchase.registration_pending_retry(kept.tokenID),
                                           level: .debug)
    }

    /// A rejection is the backend's answer, so posting the same registration again would only be rejected
    /// again.
    func testDropsTheRegistrationWhenTheBackendRejectsIt() async throws {
        self.externalPurchaseTokenAPI.stubbedPostExternalPurchaseTokenError = .networkError(
            .errorResponse(.defaultResponse, .invalidRequest)
        )

        _ = await self.manager.prepareExternalPurchase(flow: .linkOut)

        let tokenID = try XCTUnwrap(self.postedTokenID)
        expect(self.tokenStore.storedRegistrations).to(beEmpty())

        self.logger.verifyMessageWasLogged(Strings.externalPurchase.registration_discarded(tokenID),
                                           level: .debug)
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

        expect(result) == .stopped(.notEligible)
        expect(self.customLink.invokedAvailabilityCount) == 0
        expect(self.customLink.invokedNoticeTypes).to(beEmpty())
        expect(self.customLink.invokedTokenTypes).to(beEmpty())
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseToken) == false
    }

    /// Apps outside the programme did not try to make an external purchase, so telling them they cannot is
    /// noise in their console.
    func testNothingIsLoggedWhileTheSettingIsDisabled() async {
        self.systemInfo = Self.makeSystemInfo(useExternalPurchaseCustomLinks: false)
        self.manager = self.makeManager()

        _ = await self.manager.prepareExternalPurchase(flow: .linkOut)

        self.logger.verifyMessageWasNotLogged(Strings.externalPurchase.cannot_make_external_purchases,
                                              allowNoMessages: true)
    }

    // MARK: - Test Store

    /// A Test Store key has no App Store behind it, so none of the StoreKit steps apply. It reads as ineligible
    /// rather than as a device that cannot pay, so the caller keeps offering its usual way to buy.
    func testTheTestStoreIsNotEligible() async {
        self.systemInfo.stubbedApiKeyValidationResult = .simulatedStore

        let availability = await self.manager.externalPurchaseAvailability()

        expect(availability) == .notEligible
        expect(self.customLink.invokedAvailabilityCount) == 0
    }

    func testTheTestStoreSkipsTheWholeSequence() async {
        self.systemInfo.stubbedApiKeyValidationResult = .simulatedStore

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .stopped(.notEligible)
        expect(self.customLink.invokedNoticeTypes).to(beEmpty())
        expect(self.customLink.invokedTokenTypes).to(beEmpty())
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseToken) == false
    }

    // MARK: - Eligibility

    /// Eligibility can change while the app is running, so every purchase asks for it again.
    func testResolvesEligibilityOnEveryPurchase() async throws {
        self.customLink.stubbedAvailability = .notEligible

        let whileIneligible = await self.manager.prepareExternalPurchase(flow: .inApp)
        expect(whileIneligible) == .stopped(.notEligible)

        self.customLink.stubbedAvailability = .available

        let onceEligible = await self.manager.prepareExternalPurchase(flow: .inApp)
        expect(onceEligible) == .registered(tokenID: try XCTUnwrap(self.postedTokenID))

        expect(self.customLink.invokedAvailabilityCount) == 2
    }

    // MARK: - One preparation at a time

    /// Every token minted is one Apple expects a report for, and a customer who taps twice while the notice is
    /// coming up asked to buy once.
    func testStopsAPreparationAskedForWhileAnotherIsUnderWay() async throws {
        let manager = self.manager!
        let secondResult: Atomic<ExternalPurchasePreparationResult?> = nil

        self.customLink.whileShowingNotice = {
            secondResult.value = await manager.prepareExternalPurchase(flow: .linkOut)
        }

        let firstResult = await manager.prepareExternalPurchase(flow: .linkOut)

        expect(secondResult.value) == .stopped(.alreadyPreparing)
        expect(firstResult) == .registered(tokenID: try XCTUnwrap(self.postedTokenID))
        expect(self.customLink.invokedNoticeTypes) == [.browser]
        expect(self.customLink.invokedTokenTypes) == [.linkOut]
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseTokenCount) == 1
    }

    func testPreparesAgainOnceTheFirstOneIsDone() async {
        let first = await self.manager.prepareExternalPurchase(flow: .linkOut)
        let second = await self.manager.prepareExternalPurchase(flow: .linkOut)

        expect(first.tokenID).toNot(beNil())
        expect(second.tokenID).toNot(beNil())
        expect(first.tokenID) != second.tokenID
        expect(self.customLink.invokedNoticeTypes) == [.browser, .browser]
    }

    // MARK: - Registering the tokens kept from earlier attempts

    /// A token minted in a session that never reached the backend is still one Apple expects a report for.
    func testRegistersTheTokensKeptFromEarlierAttempts() async {
        self.tokenStore.store(Self.makeRegistration(tokenID: "ept00000000000000000000000000000001"))
        self.tokenStore.store(Self.makeRegistration(tokenID: "ept00000000000000000000000000000002"))

        await self.manager.registerPendingTokens()

        expect(self.externalPurchaseTokenAPI.postedTokenIDs) == [
            "ept00000000000000000000000000000001",
            "ept00000000000000000000000000000002"
        ]
        expect(self.tokenStore.storedRegistrations).to(beEmpty())
    }

    /// The registration carries the customer the token was minted for, who may no longer be the current one.
    func testRegistersAKeptTokenAgainstTheCustomerItWasMintedFor() async throws {
        self.tokenStore.store(ExternalPurchaseTokenRegistration(
            tokenID: "ept00000000000000000000000000000001",
            appUserID: "another-app-user-id",
            purchaseType: .inApp,
            token: nil
        ))

        await self.manager.registerPendingTokens()

        let parameters = try XCTUnwrap(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseTokenParameters)
        expect(parameters.appUserID) == "another-app-user-id"
        expect(parameters.purchaseType) == .inApp
        expect(parameters.token).to(beNil())
    }

    func testKeepsATokenWhoseRegistrationFailsTransientlyAgain() async {
        self.externalPurchaseTokenAPI.stubbedPostExternalPurchaseTokenError = .networkError(.offlineConnection())

        let registration = Self.makeRegistration(tokenID: "ept00000000000000000000000000000001")
        self.tokenStore.store(registration)

        await self.manager.registerPendingTokens()

        expect(self.tokenStore.storedRegistrations) == [registration]
    }

    func testDropsAKeptTokenTheBackendRejects() async {
        self.externalPurchaseTokenAPI.stubbedPostExternalPurchaseTokenError = .networkError(
            .errorResponse(.defaultResponse, .invalidRequest)
        )

        self.tokenStore.store(Self.makeRegistration(tokenID: "ept00000000000000000000000000000001"))

        await self.manager.registerPendingTokens()

        expect(self.tokenStore.storedRegistrations).to(beEmpty())
    }

    func testPostsNothingWhenNoTokenIsKept() async {
        await self.manager.registerPendingTokens()

        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseToken) == false
    }

    /// Registering happens on a foreground pass, which must not be held up by it.
    func testRegistersTheKeptTokensOffTheCallersThread() {
        self.tokenStore.store(Self.makeRegistration(tokenID: "ept00000000000000000000000000000001"))

        self.manager.registerPendingTokensIfNeeded()

        expect(self.operationDispatcher.invokedDispatchAsyncOnWorkerThread) == true
        expect(self.externalPurchaseTokenAPI.postedTokenIDs) == ["ept00000000000000000000000000000001"]
    }

    func testRegistersNoKeptTokenWhileTheSettingIsDisabled() {
        self.systemInfo = Self.makeSystemInfo(useExternalPurchaseCustomLinks: false)
        self.manager = self.makeManager()

        self.tokenStore.store(Self.makeRegistration(tokenID: "ept00000000000000000000000000000001"))

        self.manager.registerPendingTokensIfNeeded()

        expect(self.operationDispatcher.invokedDispatchAsyncOnWorkerThread) == false
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseToken) == false
    }

    func testRegistersNoKeptTokenWithATestStoreKey() {
        self.systemInfo.stubbedApiKeyValidationResult = .simulatedStore

        self.tokenStore.store(Self.makeRegistration(tokenID: "ept00000000000000000000000000000001"))

        self.manager.registerPendingTokensIfNeeded()

        expect(self.operationDispatcher.invokedDispatchAsyncOnWorkerThread) == false
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseToken) == false
    }

    // MARK: - Helpers

    /// The identifier the manager generated for the registration it last posted, which is what it is expected
    /// to hand back.
    private var postedTokenID: String? {
        return self.externalPurchaseTokenAPI.invokedPostExternalPurchaseTokenParameters?.tokenID
    }

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
            tokenStore: self.tokenStore,
            currentUserProvider: MockCurrentUserProvider(mockAppUserID: Self.appUserID),
            operationDispatcher: self.operationDispatcher,
            systemInfo: self.systemInfo
        )
    }

    private static func makeRegistration(tokenID: String) -> ExternalPurchaseTokenRegistration {
        return ExternalPurchaseTokenRegistration(
            tokenID: tokenID,
            appUserID: Self.appUserID,
            purchaseType: .linkOut,
            token: Self.token
        )
    }

}
