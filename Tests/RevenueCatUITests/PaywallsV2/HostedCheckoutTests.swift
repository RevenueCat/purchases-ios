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

    // MARK: - Settling on what the backend says

    func testCountsAConfirmedPurchase() {
        expect(HostedCheckout.Settlement(.succeeded)) == .purchased
    }

    func testTellsTheCustomerTheyAlreadyOwnIt() {
        expect(HostedCheckout.Settlement(.alreadyPurchased)) == .tellCustomerTheyAlreadyOwnIt
    }

    /// Either the success page told the customer the purchase went through, or a payment was under way
    /// when they closed the sheet, so anything short of a purchase is an error.
    func testFailsWhenTheBackendDoesNotConfirmThePurchase() {
        expect(HostedCheckout.Settlement(.failed(code: 3, message: "payment_charge_failed")))
            == .failed(.failed(code: 3))
        expect(HostedCheckout.Settlement(.undetermined)) == .failed(.unconfirmed)
    }

    func testCancelsACheckoutTheCustomerDismissedWithoutPaying() {
        expect(HostedCheckout.Settlement(.abandoned)) == .cancelled
    }

    func testAsksAboutTheSessionThatWasPresented() async {
        let sessionsAskedAbout = Recorder<String>()
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutPollBlock = { operationSessionID in
            await sessionsAskedAbout.record(operationSessionID)
            return .succeeded
        }

        _ = await HostedCheckout.settle(Self.session,
                                        after: .successPage,
                                        package: TestData.annualPackage,
                                        purchaseHandler: Self.makeHandler(purchases: purchases))

        let asked = await sessionsAskedAbout.values
        expect(asked) == [Self.session.operationSessionID]
    }

    @MainActor
    func testShowsThePurchaseUnderWayUntilTheBackendAnswers() async {
        let actionsWhilePolling = Recorder<Bool>()
        let purchases = Self.makePurchases()
        let handler = Self.makeHandler(purchases: purchases)
        purchases.hostedCheckoutPollBlock = { _ in
            await actionsWhilePolling.record(await MainActor.run { handler.actionTypeInProgress == .purchase })
            return .succeeded
        }

        _ = await HostedCheckout.settle(Self.session,
                                        after: .successPage,
                                        package: TestData.annualPackage,
                                        purchaseHandler: handler)

        let wasPurchasing = await actionsWhilePolling.values
        expect(wasPurchasing) == [true]
        expect(handler.actionInProgress) == false
    }

    /// Reporting the purchase can close the paywall, so it waits until the customer has been told about it.
    /// Only the backend can say whether the customer paid before closing the sheet, so the dismissed
    /// session is asked about as such.
    func testAsksAboutADismissedSessionAsDismissed() async {
        let sessionsAskedAbout = Recorder<String>()
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutPollBlock = { _ in
            await sessionsAskedAbout.record("polled")
            return .succeeded
        }
        purchases.hostedCheckoutPollDismissedBlock = { operationSessionID in
            await sessionsAskedAbout.record(operationSessionID)
            return .abandoned
        }

        let settlement = await HostedCheckout.settle(Self.session,
                                                     after: .closedSheet,
                                                     package: TestData.annualPackage,
                                                     purchaseHandler: Self.makeHandler(purchases: purchases))

        let asked = await sessionsAskedAbout.values
        expect(asked) == [Self.session.operationSessionID]
        expect(settlement) == .cancelled
    }

    @MainActor
    func testLeavesAConfirmedPurchaseForThePaywallToReport() async {
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutPollDismissedBlock = { _ in .succeeded }
        let handler = Self.makeHandler(purchases: purchases)

        let settlement = await HostedCheckout.settle(Self.session,
                                                     after: .closedSheet,
                                                     package: TestData.annualPackage,
                                                     purchaseHandler: handler)

        expect(settlement) == .purchased
        expect(handler.sessionPurchaseResult).to(beNil())
        expect(handler.purchaseError).to(beNil())
        expect(handler.actionInProgress) == false
    }

    @MainActor
    func testReportsAConfirmedPurchaseAsCompleted() async {
        let handler = Self.makeHandler(purchases: Self.makePurchases())

        await handler.handleHostedCheckoutPurchase()

        expect(handler.sessionPurchaseResult?.userCancelled) == false
        expect(handler.purchaseError).to(beNil())
    }

    @MainActor
    func testReportsAFailureAfterTheSuccessPageAsAPurchaseError() async {
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutPollBlock = { _ in .undetermined }
        let handler = Self.makeHandler(purchases: purchases)

        let settlement = await HostedCheckout.settle(Self.session,
                                                     after: .successPage,
                                                     package: TestData.annualPackage,
                                                     purchaseHandler: handler)

        expect(settlement) == .failed(.unconfirmed)
        expect(handler.purchaseError as? HostedCheckoutError) == .unconfirmed
        expect(handler.sessionPurchaseResult).to(beNil())
    }

    @MainActor
    func testReportsAClosedSheetTheCustomerDidNotPayForAsCancelled() async {
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutPollDismissedBlock = { _ in .abandoned }
        let handler = Self.makeHandler(purchases: purchases)

        let settlement = await HostedCheckout.settle(Self.session,
                                                     after: .closedSheet,
                                                     package: TestData.annualPackage,
                                                     purchaseHandler: handler)

        expect(settlement) == .cancelled
        expect(handler.sessionPurchaseResult?.userCancelled) == true
        expect(handler.purchaseError).to(beNil())
    }

    /// The customer may have paid, so saying they cancelled could hide a purchase that went through.
    @MainActor
    func testReportsAClosedSheetThatCouldNotBeConfirmedAsAPurchaseError() async {
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutPollDismissedBlock = { _ in .undetermined }
        let handler = Self.makeHandler(purchases: purchases)

        let settlement = await HostedCheckout.settle(Self.session,
                                                     after: .closedSheet,
                                                     package: TestData.annualPackage,
                                                     purchaseHandler: handler)

        expect(settlement) == .failed(.unconfirmed)
        expect(handler.purchaseError as? HostedCheckoutError) == .unconfirmed
        expect(handler.sessionPurchaseResult).to(beNil())
    }

    @MainActor
    func testTracksAFailureAfterTheSuccessPageAsAPurchaseError() async {
        let trackedEvents: Atomic<[PaywallEvent]> = .init([])
        let purchases = Self.makePurchases(trackingInto: trackedEvents)
        purchases.hostedCheckoutPollBlock = { _ in .failed(code: 3, message: "payment_charge_failed") }
        let handler = Self.makeHandler(purchases: purchases)
        handler.trackPaywallImpression(Self.impressionData)

        _ = await HostedCheckout.settle(Self.session,
                                        after: .successPage,
                                        package: TestData.annualPackage,
                                        purchaseHandler: handler)

        await expect(trackedEvents.value.contains(where: Self.isPurchaseError))
            .toEventually(beTrue(), timeout: .seconds(2))
        expect(trackedEvents.value.first(where: Self.isPurchaseError)?.data.packageId)
            == TestData.annualPackage.identifier
    }

    /// Settles as when the checkout never opened for this reason: the paywall tells the customer, and reports
    /// neither a purchase nor a cancellation.
    @MainActor
    func testReportsNothingForAProductTheCustomerAlreadyOwned() async {
        let trackedEvents: Atomic<[PaywallEvent]> = .init([])
        let purchases = Self.makePurchases(trackingInto: trackedEvents)
        purchases.hostedCheckoutPollBlock = { _ in .alreadyPurchased }
        let handler = Self.makeHandler(purchases: purchases)
        handler.trackPaywallImpression(Self.impressionData)

        _ = await HostedCheckout.settle(Self.session,
                                        after: .successPage,
                                        package: TestData.annualPackage,
                                        purchaseHandler: handler)

        expect(handler.sessionPurchaseResult).to(beNil())
        expect(handler.purchaseError).to(beNil())
        expect(handler.actionInProgress) == false
        await expect(trackedEvents.value.contains(where: Self.isCancel))
            .toNever(beTrue(), until: .milliseconds(300))
    }

    // MARK: - Errors

    /// Not as a pending payment, which is what `purchases-js` reports: on Apple platforms that means a purchase
    /// awaiting approval.
    func testReportsAFailedChargeAsAPurchaseThatWasNotAllowed() {
        expect((HostedCheckoutError.failed(code: 3) as NSError).code) == ErrorCode.purchaseNotAllowedError.rawValue
    }

    func testReportsAFailedSetupAsAStoreProblem() {
        for code in [1, 2, 4] {
            expect((HostedCheckoutError.failed(code: code) as NSError).code) == ErrorCode.storeProblemError.rawValue
        }
    }

    func testReportsAnyOtherFailureAsUnknown() {
        expect((HostedCheckoutError.failed(code: nil) as NSError).code) == ErrorCode.unknownError.rawValue
        expect((HostedCheckoutError.failed(code: 99) as NSError).code) == ErrorCode.unknownError.rawValue
        expect((HostedCheckoutError.unconfirmed as NSError).code) == ErrorCode.unknownError.rawValue
    }

    func testReportsErrorsInTheSDKsDomain() {
        expect((HostedCheckoutError.unconfirmed as NSError).domain) == ErrorCode.errorDomain
    }

}

@available(iOS 15.0, *)
private extension HostedCheckoutTests {

    static func makePurchases() -> MockPurchases {
        return self.makePurchases(trackingInto: .init([]))
    }

    static func makePurchases(trackingInto trackedEvents: Atomic<[PaywallEvent]>) -> MockPurchases {
        return MockPurchases { _, _, _ in
            return (transaction: nil, customerInfo: TestData.customerInfo, userCancelled: false)
        } restorePurchases: {
            return TestData.customerInfo
        } trackEvent: { event in
            trackedEvents.modify { $0.append(event) }
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

    static func isPurchaseError(_ event: PaywallEvent) -> Bool {
        if case .purchaseError = event { return true }
        return false
    }

    static func isCancel(_ event: PaywallEvent) -> Bool {
        if case .cancel = event { return true }
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
