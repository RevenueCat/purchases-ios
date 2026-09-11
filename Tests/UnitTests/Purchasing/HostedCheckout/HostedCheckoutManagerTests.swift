//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HostedCheckoutManagerTests.swift
//
//  Created by Antonio Pallares on 8/9/26.

import Foundation
import Nimble
import XCTest

@_spi(Experimental) @_spi(Internal) @testable import RevenueCat

class HostedCheckoutManagerTests: TestCase {

    private static let appUserID = "test-app-user-id"
    private static let tokenID = "ept13dcbc01adaa44db9b1691a6be2f9929"
    private static let paywallSessionID = UUID()

    private var customLink: MockExternalPurchaseCustomLink!
    private var externalPurchaseTokenAPI: MockExternalPurchaseTokenAPI!
    private var webBillingAPI: MockWebBillingAPI!
    private var systemInfo: MockSystemInfo!
    private var manager: HostedCheckoutManager!

    override func setUp() {
        super.setUp()

        self.customLink = MockExternalPurchaseCustomLink()

        self.externalPurchaseTokenAPI = MockExternalPurchaseTokenAPI()
        self.externalPurchaseTokenAPI.stubbedPostExternalPurchaseTokenResult = .success(.init(id: Self.tokenID))

        self.webBillingAPI = MockWebBillingAPI(backendConfig: MockBackendConfiguration())
        self.webBillingAPI.stubbedPostHostedCheckoutCompletionResult = .success(Self.response)

        self.systemInfo = Self.makeSystemInfo(useExternalPurchaseCustomLinks: true)
        self.manager = self.makeManager()
    }

    // MARK: - Starting

    func testRegistersATokenAndCreatesTheSessionForIt() async {
        let result = await self.manager.startCheckout(package: Self.package, paywall: nil)

        expect(result) == .started(Self.session)
        expect(self.customLink.invokedNoticeTypes) == [.withinApp]
        expect(self.customLink.invokedTokenTypes) == [.inApp]

        let parameters = self.webBillingAPI.invokedPostHostedCheckoutParameters
        expect(parameters?.appUserID) == Self.appUserID
        expect(parameters?.packageID) == Self.package.identifier
        expect(parameters?.presentedOfferingContext) == Self.package.presentedOfferingContext
        expect(parameters?.externalPurchaseTokenID) == Self.tokenID
        expect(parameters?.paywall).to(beNil())
    }

    func testAttributesTheCheckoutToThePaywallItWasStartedFrom() async {
        _ = await self.manager.startCheckout(package: Self.package,
                                             paywall: Self.paywall(identifier: "test-paywall-id"))

        let paywall = self.webBillingAPI.invokedPostHostedCheckoutParameters?.paywall
        expect(paywall?.paywallID) == "test-paywall-id"
        expect(paywall?.sessionID) == Self.paywallSessionID.uuidString
        expect(paywall?.workflowID) == "test-workflow-id"
        expect(paywall?.stepID) == "test-step-id"
    }

    /// The backend attributes the checkout by paywall identifier, so there is nothing to attribute without one.
    func testSendsNoAttributionForAPaywallWithoutAnIdentifier() async {
        _ = await self.manager.startCheckout(package: Self.package, paywall: Self.paywall(identifier: nil))

        expect(self.webBillingAPI.invokedPostHostedCheckout) == true
        expect(self.webBillingAPI.invokedPostHostedCheckoutParameters?.paywall).to(beNil())
    }

    // MARK: - Not starting

    /// A checkout with no token behind it is a purchase Apple is never told about.
    func testCreatesNoSessionWhenTheTokenCouldNotBeRegistered() async {
        self.externalPurchaseTokenAPI.stubbedPostExternalPurchaseTokenResult =
            .failure(.networkError(.serverDown()))

        let result = await self.manager.startCheckout(package: Self.package, paywall: nil)

        expect(result) == .failed
        expect(self.webBillingAPI.invokedPostHostedCheckout) == false
    }

    func testCreatesNoSessionWhenStoreKitCouldNotProvideAToken() async {
        self.customLink.stubbedTokenResult = .failure(NSError(domain: "test", code: 1))

        let result = await self.manager.startCheckout(package: Self.package, paywall: nil)

        expect(result) == .failed
        expect(self.webBillingAPI.invokedPostHostedCheckout) == false
    }

    func testMintsNothingAndCreatesNoSessionWhenExternalPurchasesAreUnavailable() async {
        self.customLink.stubbedAvailability = .notEligible

        let result = await self.manager.startCheckout(package: Self.package, paywall: nil)

        expect(result) == .externalPurchaseUnavailable
        expect(self.customLink.invokedTokenTypes).to(beEmpty())
        expect(self.webBillingAPI.invokedPostHostedCheckout) == false
    }

    /// Apple asks that a device which cannot authorize payments be offered no purchase at all, so unlike
    /// ``HostedCheckoutStartResult/externalPurchaseUnavailable`` there is nothing to fall back to either.
    func testCreatesNoSessionWhenTheDeviceDoesNotAuthorizePayments() async {
        self.customLink.stubbedAvailability = .paymentsNotAuthorized

        let result = await self.manager.startCheckout(package: Self.package, paywall: nil)

        expect(result) == .paymentsNotAuthorized
        expect(self.customLink.invokedNoticeTypes).to(beEmpty())
        expect(self.customLink.invokedTokenTypes).to(beEmpty())
        expect(self.webBillingAPI.invokedPostHostedCheckout) == false
    }

    /// A customer who taps twice while the notice is coming up asked to buy once, and it is the first tap that
    /// carries the purchase.
    func testStopsACheckoutAskedForWhileAnotherIsStarting() async {
        let manager = self.manager!
        let secondResult: Atomic<HostedCheckoutStartResult?> = nil

        self.customLink.whileShowingNotice = {
            secondResult.value = await manager.startCheckout(package: Self.package, paywall: nil)
        }

        let firstResult = await manager.startCheckout(package: Self.package, paywall: nil)

        expect(secondResult.value) == .alreadyStarting
        expect(firstResult) == .started(Self.session)
        expect(self.webBillingAPI.invokedPostHostedCheckoutCount) == 1
    }

    /// The setting stands for the app taking part in Apple's programme at all, and there is no checkout to open
    /// outside it, so the caller is left to buy through StoreKit.
    func testCreatesNoSessionWhileTheExternalPurchaseSettingIsDisabled() async {
        self.systemInfo = Self.makeSystemInfo(useExternalPurchaseCustomLinks: false)
        self.manager = self.makeManager()

        let result = await self.manager.startCheckout(package: Self.package, paywall: nil)

        expect(result) == .externalPurchaseUnavailable
        expect(self.customLink.invokedAvailabilityCount) == 0
        expect(self.webBillingAPI.invokedPostHostedCheckout) == false
    }

    func testCreatesNoSessionWhenTheCustomerDeclinesTheNotice() async {
        self.customLink.stubbedNoticeResult = .success(.cancelled)

        let result = await self.manager.startCheckout(package: Self.package, paywall: nil)

        expect(result) == .declinedByCustomer
        expect(self.customLink.invokedTokenTypes).to(beEmpty())
        expect(self.webBillingAPI.invokedPostHostedCheckout) == false
    }

    /// Continuing without the notice would breach what StoreKit asks for.
    func testCreatesNoSessionWhenTheNoticeCannotBeShown() async {
        self.customLink.stubbedNoticeResult = .failure(NSError(domain: "test", code: 1))

        let result = await self.manager.startCheckout(package: Self.package, paywall: nil)

        expect(result) == .failed
        expect(self.webBillingAPI.invokedPostHostedCheckout) == false
    }

    func testFailsWhenTheSessionCannotBeCreated() async {
        self.webBillingAPI.stubbedPostHostedCheckoutCompletionResult = .failure(.networkError(.serverDown()))

        let result = await self.manager.startCheckout(package: Self.package, paywall: nil)

        expect(result) == .failed
    }

    /// The Test Store is not supported for now, so a `test_` key leaves the caller to buy through StoreKit.
    func testCreatesNoSessionWithATestStoreKey() async {
        self.systemInfo.stubbedApiKeyValidationResult = .simulatedStore

        let result = await self.manager.startCheckout(package: Self.package, paywall: nil)

        expect(result) == .externalPurchaseUnavailable
        expect(self.customLink.invokedAvailabilityCount) == 0
        expect(self.customLink.invokedTokenTypes).to(beEmpty())
        expect(self.webBillingAPI.invokedPostHostedCheckout) == false
    }

}

private extension HostedCheckoutManagerTests {

    static func makeSystemInfo(useExternalPurchaseCustomLinks: Bool) -> MockSystemInfo {
        return MockSystemInfo(
            finishTransactions: true,
            dangerousSettings: DangerousSettings(
                autoSyncPurchases: true,
                useExternalPurchaseCustomLinks: useExternalPurchaseCustomLinks
            )
        )
    }

    func makeManager() -> HostedCheckoutManager {
        return HostedCheckoutManager(
            externalPurchaseManager: ExternalPurchaseManager(
                customLink: self.customLink,
                externalPurchaseTokenAPI: self.externalPurchaseTokenAPI,
                currentUserProvider: MockCurrentUserProvider(mockAppUserID: Self.appUserID),
                systemInfo: self.systemInfo
            ),
            webBillingAPI: self.webBillingAPI,
            currentUserProvider: MockCurrentUserProvider(mockAppUserID: Self.appUserID)
        )
    }

    static let operationSessionID = "opse4e63d6a8a2c4"
    static let checkoutURL = URL(string: "https://pay.example.com/session")!
    static let successURL = URL(string: "https://api.revenuecat.com/checkout-return?status=success")!
    static let cancelURL = URL(string: "https://api.revenuecat.com/checkout-return?status=cancel")!

    static let response = HostedCheckoutResponse(operationSessionID: operationSessionID,
                                                 checkoutURL: checkoutURL,
                                                 successURL: successURL,
                                                 cancelURL: cancelURL)

    static let session = HostedCheckoutSession(operationSessionID: operationSessionID,
                                               checkoutURL: checkoutURL,
                                               successURL: successURL,
                                               cancelURL: cancelURL)

    static let package = Package(
        identifier: "$rc_monthly",
        packageType: .monthly,
        storeProduct: StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.test.monthly")),
        presentedOfferingContext: .init(offeringIdentifier: "default",
                                        placementIdentifier: "home",
                                        targetingContext: .init(revision: 3, ruleId: "test-rule-id")),
        webCheckoutUrl: nil
    )

    static func paywall(identifier: String?) -> PaywallEvent.Data {
        return .init(paywallIdentifier: identifier,
                     offeringIdentifier: "default",
                     paywallRevision: 4,
                     sessionID: Self.paywallSessionID,
                     displayMode: .fullScreen,
                     localeIdentifier: "en_US",
                     darkMode: false,
                     workflowId: "test-workflow-id",
                     stepId: "test-step-id")
    }

}
