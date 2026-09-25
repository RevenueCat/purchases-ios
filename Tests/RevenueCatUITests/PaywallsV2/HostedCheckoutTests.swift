//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HostedCheckoutTests.swift
//
//  Created by Antonio Pallares on 11/9/26.

import Nimble
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if os(iOS) && canImport(WebKit)

@available(iOS 15.0, *)
final class HostedCheckoutTests: TestCase {

    private static let session = HostedCheckoutSession(
        operationSessionID: "oper_1",
        checkoutURL: URL(string: "https://checkout.stripe.com/c/pay/session_1")!,
        successURL: URL(string: "https://api.revenuecat.com/rcbilling/v1/hosted-checkout-return?status=success")!,
        cancelURL: URL(string: "https://api.revenuecat.com/rcbilling/v1/hosted-checkout-return?status=cancel")!
    )

    /// The checkout is asked for through the handler, which is the paywall's only way to the SDK.
    func testAsksTheHandlerForTheCheckout() async {
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutBlock = { _, _ in .started(Self.session) }

        let action = await HostedCheckout.start(for: TestData.annualPackage,
                                                purchaseHandler: Self.makeHandler(purchases: purchases),
                                                purchaseInitiatedAction: nil)

        expect(action) == .present(Self.session)
    }

    /// The same event is tracked and sent with the checkout, so the purchase made on the page is attributed
    /// to the initiation the paywall reported.
    func testTracksThePurchaseAsInitiated() async throws {
        let trackedEvents: Atomic<[PaywallEvent]> = .init([])
        let eventsSentWithTheCheckout: Atomic<[PaywallEvent?]> = .init([])

        let purchases = MockPurchases { _, _, _ in
            return (transaction: nil, customerInfo: TestData.customerInfo, userCancelled: false)
        } restorePurchases: {
            return TestData.customerInfo
        } trackEvent: { event in
            trackedEvents.modify { $0.append(event) }
        } customerInfo: {
            return TestData.customerInfo
        }
        purchases.hostedCheckoutBlock = { _, paywallEvent in
            eventsSentWithTheCheckout.modify { $0.append(paywallEvent) }
            return .started(Self.session)
        }
        let handler = Self.makeHandler(purchases: purchases)
        handler.trackPaywallImpression(Self.impressionData)

        _ = await handler.startHostedCheckout(package: TestData.annualPackage)

        await expect(trackedEvents.value.contains(where: Self.isPurchaseInitiated))
            .toEventually(beTrue(), timeout: .seconds(2))

        let initiated = try XCTUnwrap(trackedEvents.value.first(where: Self.isPurchaseInitiated))
        expect(initiated.data.packageId) == TestData.annualPackage.identifier
        expect(eventsSentWithTheCheckout.value) == [initiated]
    }

    /// An app that gates purchases, e.g. behind sign in, gets to stop this one before Apple's flow runs.
    func testStartsNoCheckoutWhenTheAppStopsThePurchase() async {
        let checkoutsStarted = Recorder<String>()
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutBlock = { package, _ in
            await checkoutsStarted.record(package.identifier)
            return .started(Self.session)
        }

        let action = await HostedCheckout.start(for: TestData.annualPackage,
                                                purchaseHandler: Self.makeHandler(purchases: purchases),
                                                purchaseInitiatedAction: Self.interceptor(proceeding: false,
                                                                                          recordingInto: .init()))

        let packagesCheckedOut = await checkoutsStarted.values
        expect(action) == .nothing
        expect(packagesCheckedOut).to(beEmpty())
    }

    func testStartsTheCheckoutOnceTheAppLetsThePurchaseThrough() async {
        let packagesIntercepted = Recorder<String>()
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutBlock = { _, _ in .started(Self.session) }

        let action = await HostedCheckout.start(
            for: TestData.annualPackage,
            purchaseHandler: Self.makeHandler(purchases: purchases),
            purchaseInitiatedAction: Self.interceptor(proceeding: true, recordingInto: packagesIntercepted)
        )

        let packagesAskedAbout = await packagesIntercepted.values
        expect(action) == .present(Self.session)
        expect(packagesAskedAbout) == [TestData.annualPackage.identifier]
    }

    func testPresentsTheCheckoutThatWasCreated() {
        expect(HostedCheckout.Action(.started(Self.session))) == .present(Self.session)
    }

    /// There is no checkout to open for something the customer already has, and they are told so rather than
    /// left with a button that appears to do nothing.
    func testTellsTheCustomerWhenTheyAlreadyOwnTheProduct() {
        expect(HostedCheckout.Action(.alreadyPurchased)) == .tellCustomerTheyAlreadyOwnIt
    }

    /// A customer who said no to Apple's notice said no to the purchase.
    func testOffersNothingWhenTheCustomerDeclinedTheNotice() {
        expect(HostedCheckout.Action(.declinedByCustomer)) == .nothing
    }

    /// Apple asks that a device that does not authorize payments be offered no purchase at all, not even
    /// through StoreKit.
    func testOffersNothingWhenTheDeviceDoesNotAuthorizePayments() {
        expect(HostedCheckout.Action(.paymentsNotAuthorized)) == .nothing
    }

    /// The checkout already under way carries the purchase.
    func testOffersNothingWhileAnotherCheckoutIsStarting() {
        expect(HostedCheckout.Action(.alreadyStarting)) == .nothing
    }

    /// Falling back to StoreKit here would charge a customer who is midway through a checkout that may yet
    /// be resolved, so a failure offers nothing.
    func testOffersNothingWhenTheCheckoutCouldNotBeCreated() {
        expect(HostedCheckout.Action(.failed)) == .nothing
    }

}

@available(iOS 15.0, *)
private extension HostedCheckoutTests {

    static func makePurchases() -> MockPurchases {
        return MockPurchases { _, _, _ in
            return (transaction: nil, customerInfo: TestData.customerInfo, userCancelled: false)
        } restorePurchases: {
            return TestData.customerInfo
        } trackEvent: { _ in
        } customerInfo: {
            return TestData.customerInfo
        }
    }

    static func makeHandler(purchases: MockPurchases) -> PurchaseHandler {
        return PurchaseHandler(
            purchases: purchases,
            eventTracker: .init(purchases: purchases,
                                eventDispatcher: PaywallEventTrackerTestDispatcher.value)
        )
    }

    static let impressionData = PaywallEvent.Data(
        paywallIdentifier: TestData.paywallWithIntroOffer.id,
        offeringIdentifier: TestData.offeringWithIntroOffer.identifier,
        paywallRevision: TestData.paywallWithIntroOffer.revision,
        sessionID: .init(),
        displayMode: .fullScreen,
        localeIdentifier: "en_US",
        darkMode: false,
        source: nil
    )

    static func isPurchaseInitiated(_ event: PaywallEvent) -> Bool {
        if case .purchaseInitiated = event { return true }
        return false
    }

    static func interceptor(proceeding: Bool,
                            recordingInto recorder: Recorder<String>) -> PurchaseInitiatedAction {
        return PurchaseInitiatedAction { package, resume in
            Task { @MainActor in
                await recorder.record(package.identifier)
                resume(shouldProceed: proceeding)
            }
        }
    }

}

private actor Recorder<Value: Sendable> {

    private(set) var values: [Value] = []

    func record(_ value: Value) {
        self.values.append(value)
    }

}

#endif
