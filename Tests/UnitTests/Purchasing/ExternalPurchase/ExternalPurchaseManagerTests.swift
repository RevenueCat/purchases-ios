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

@testable import RevenueCat

class ExternalPurchaseManagerTests: TestCase {

    private static let appUserID = "test-app-user-id"
    private static let token = "test-external-purchase-token"
    private static let tokenID = "ept13dcbc01adaa44db9b1691a6be2f9929"

    private var customLink: MockExternalPurchaseCustomLink!
    private var externalPurchaseTokenAPI: MockExternalPurchaseTokenAPI!
    private var systemInfo: MockSystemInfo!
    private var manager: ExternalPurchaseManager!

    override func setUp() {
        super.setUp()

        self.customLink = MockExternalPurchaseCustomLink()
        self.customLink.stubbedTokenResult = .success(Self.token)

        self.externalPurchaseTokenAPI = MockExternalPurchaseTokenAPI()
        self.externalPurchaseTokenAPI.stubbedPostExternalPurchaseTokenResult = .success(.init(id: Self.tokenID))

        self.systemInfo = MockSystemInfo(finishTransactions: true)

        self.manager = ExternalPurchaseManager(
            customLink: self.customLink,
            externalPurchaseTokenAPI: self.externalPurchaseTokenAPI,
            currentUserProvider: MockCurrentUserProvider(mockAppUserID: Self.appUserID),
            systemInfo: self.systemInfo
        )
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

    // MARK: - Stopping

    func testMintsNothingWhenTheCustomerCannotMakeExternalPurchases() async {
        self.customLink.stubbedCanMakeExternalPurchases = false

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .stopped(.cannotMakeExternalPurchases)
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

    // MARK: - Proceeding without an identifier

    func testProceedsWithoutRegisteringWhenStoreKitHasNoToken() async {
        self.customLink.stubbedTokenResult = .success(nil)

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .unreportable(.noTokenAvailable)
        expect(result.shouldProceed) == true
        expect(result.tokenID).to(beNil())
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseToken) == false
    }

    func testProceedsWithoutRegisteringWhenTheTokenRequestFails() async {
        self.customLink.stubbedTokenResult = .failure(ErrorUtils.storeProblemError())

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .unreportable(.tokenRequestFailed)
        expect(result.shouldProceed) == true
        expect(result.tokenID).to(beNil())
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseToken) == false
    }

    /// A failed registration means the purchase is not reportable, which is knowingly accepted rather than
    /// getting in the way of the customer buying.
    func testProceedsWhenRegistrationFails() async {
        self.externalPurchaseTokenAPI.stubbedPostExternalPurchaseTokenResult = .failure(
            .networkError(.offlineConnection())
        )

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .unreportable(.registrationFailed)
        expect(result.shouldProceed) == true
        expect(result.tokenID).to(beNil())
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseTokenCount) == 1
    }

    // MARK: - Test Store

    /// A Test Store key has no App Store behind it, so none of the StoreKit steps apply.
    func testTheTestStoreCannotMakeExternalPurchases() async {
        self.systemInfo.stubbedApiKeyValidationResult = .simulatedStore

        let canMakeExternalPurchases = await self.manager.canMakeExternalPurchases()

        expect(canMakeExternalPurchases) == false
        expect(self.customLink.invokedCanMakeExternalPurchasesCount) == 0
    }

    func testTheTestStoreSkipsTheWholeSequence() async {
        self.systemInfo.stubbedApiKeyValidationResult = .simulatedStore

        let result = await self.manager.prepareExternalPurchase(flow: .inApp)

        expect(result) == .stopped(.cannotMakeExternalPurchases)
        expect(self.customLink.invokedNoticeTypes).to(beEmpty())
        expect(self.customLink.invokedTokenTypes).to(beEmpty())
        expect(self.externalPurchaseTokenAPI.invokedPostExternalPurchaseToken) == false
    }

    // MARK: - Eligibility

    /// Eligibility can change while the app is running, so every purchase asks for it again.
    func testResolvesEligibilityOnEveryPurchase() async {
        self.customLink.stubbedCanMakeExternalPurchases = false

        let whileIneligible = await self.manager.prepareExternalPurchase(flow: .inApp)
        expect(whileIneligible) == .stopped(.cannotMakeExternalPurchases)

        self.customLink.stubbedCanMakeExternalPurchases = true

        let onceEligible = await self.manager.prepareExternalPurchase(flow: .inApp)
        expect(onceEligible) == .registered(tokenID: Self.tokenID)

        expect(self.customLink.invokedCanMakeExternalPurchasesCount) == 2
    }

}
