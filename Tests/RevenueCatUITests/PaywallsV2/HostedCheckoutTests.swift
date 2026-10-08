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
import SwiftUI
import XCTest

#if os(iOS) && canImport(WebKit)

@available(iOS 15.0, *)
final class HostedCheckoutTests: TestCase {

    private static let session = HostedCheckoutSession(
        operationSessionID: "oper_1",
        appUserID: "app_user_1",
        checkoutURL: URL(string: "https://checkout.stripe.com/c/pay/session_1")!,
        successURL: URL(string: "https://api.revenuecat.com/rcbilling/v1/hosted-checkout-return?status=success")!
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

    /// A customer who is not eligible to buy outside the App Store is told the purchase is unavailable rather
    /// than left with a button that appears to do nothing.
    func testTellsAnIneligibleCustomerThePurchaseIsUnavailable() {
        expect(HostedCheckout.Action(.notEligible)) == .tellCustomerThePurchaseIsUnavailable
    }

    /// The checkout already under way carries the purchase.
    func testOffersNothingWhileAnotherCheckoutIsStarting() {
        expect(HostedCheckout.Action(.alreadyStarting)) == .nothing
    }

    /// Falling back to StoreKit here would charge a customer who is midway through a checkout that may yet
    /// be resolved, so a failure offers nothing but telling them.
    func testTellsTheCustomerWhenTheCheckoutCouldNotBeCreated() {
        expect(HostedCheckout.Action(.failed)) == .failed(.notStarted)
    }

    @MainActor
    func testReportsACheckoutThatCouldNotBeCreatedAsAPurchaseError() async {
        let trackedEvents: Atomic<[PaywallEvent]> = .init([])
        let purchases = Self.makePurchases(trackingInto: trackedEvents)
        purchases.hostedCheckoutBlock = { _, _ in .failed }
        let handler = Self.makeHandler(purchases: purchases)
        handler.trackPaywallImpression(Self.impressionData)

        _ = await HostedCheckout.start(for: TestData.annualPackage,
                                       purchaseHandler: handler,
                                       purchaseInitiatedAction: nil)
        await Self.waitForEventsTrackedSoFar(by: handler, into: trackedEvents)

        expect(handler.purchaseError as? HostedCheckoutError) == .notStarted
        expect(trackedEvents.value.filter(Self.isPurchaseError)).to(haveCount(1))
        expect(trackedEvents.value.contains(where: Self.isCancel)) == false
    }

    /// Saying no to Apple's notice is the hosted checkout's counterpart to dismissing StoreKit's sheet.
    @MainActor
    func testTracksADeclinedNoticeAsACancellation() async {
        let trackedEvents: Atomic<[PaywallEvent]> = .init([])
        let purchases = Self.makePurchases(trackingInto: trackedEvents)
        purchases.hostedCheckoutBlock = { _, _ in .declinedByCustomer }
        let handler = Self.makeHandler(purchases: purchases)
        handler.trackPaywallImpression(Self.impressionData)

        _ = await HostedCheckout.start(for: TestData.annualPackage,
                                       purchaseHandler: handler,
                                       purchaseInitiatedAction: nil)
        await Self.waitForEventsTrackedSoFar(by: handler, into: trackedEvents)

        let cancellations = trackedEvents.value.filter(Self.isCancel)
        expect(cancellations).to(haveCount(1))
        expect(cancellations.first?.data.packageId) == TestData.annualPackage.identifier
        expect(trackedEvents.value.contains(where: Self.isPurchaseError)) == false
        expect(handler.purchaseError).to(beNil())
        expect(handler.sessionPurchaseResult).to(beNil())
    }

    /// The customer is told they already own it or that it is unavailable, or nothing at all, but the initiated
    /// purchase still ends in an error, as one StoreKit refuses does.
    @MainActor
    func testTracksARefusedPurchaseAsAPurchaseError() async throws {
        let cases: [(HostedCheckoutStartResult, HostedCheckout.Refusal)] = [
            (.alreadyPurchased, .alreadyPurchased),
            (.notEligible, .notEligible),
            (.paymentsNotAuthorized, .paymentsNotAuthorized),
            (.alreadyStarting, .alreadyStarting)
        ]

        for (result, expectedError) in cases {
            let trackedEvents: Atomic<[PaywallEvent]> = .init([])
            let purchases = Self.makePurchases(trackingInto: trackedEvents)
            purchases.hostedCheckoutBlock = { _, _ in result }
            let handler = Self.makeHandler(purchases: purchases)
            handler.trackPaywallImpression(Self.impressionData)

            _ = await HostedCheckout.start(for: TestData.annualPackage,
                                           purchaseHandler: handler,
                                           purchaseInitiatedAction: nil)
            await Self.waitForEventsTrackedSoFar(by: handler, into: trackedEvents)

            let errors = trackedEvents.value.filter(Self.isPurchaseError)
            expect(errors).to(haveCount(1), description: "\(result)")
            expect(errors.first?.data.packageId) == TestData.annualPackage.identifier
            expect(errors.first?.data.errorCode).to(equal((expectedError as NSError).code), description: "\(result)")
            expect(errors.first?.data.errorMessage) == (expectedError as NSError).localizedDescription
            expect(trackedEvents.value.contains(where: Self.isCancel)).to(beFalse(), description: "\(result)")
            expect(handler.purchaseError).to(beNil(), description: "\(result)")
        }
    }

    // MARK: - Settling on what the backend says

    func testCountsAConfirmedPurchase() {
        expect(HostedCheckout.Resolution(.succeeded, customerInfo: TestData.customerInfo))
            == .purchased(TestData.customerInfo)
    }

    func testTreatsAConfirmedPurchaseWithoutItsCustomerInfoAsUnconfirmed() {
        expect(HostedCheckout.Resolution(.succeeded, customerInfo: nil)) == .failed(.unconfirmed)
    }

    func testTellsTheCustomerTheyAlreadyOwnIt() {
        expect(HostedCheckout.Resolution(.alreadyPurchased, customerInfo: nil)) == .tellCustomerTheyAlreadyOwnIt
    }

    /// The success page always tells the customer the purchase went through, so anything short of it is an error.
    func testFailsWhenTheBackendDoesNotConfirmWhatTheSuccessPageSaid() {
        expect(HostedCheckout.Resolution(.failed(code: 3, message: "payment_charge_failed"), customerInfo: nil))
            == .failed(.failed(code: 3))
        expect(HostedCheckout.Resolution(.undetermined, customerInfo: nil)) == .failed(.unconfirmed)
    }

    func testAsksAboutTheSessionThatWasPresented() async {
        let sessionsAskedAbout = Recorder<HostedCheckoutSession>()
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutPollBlock = { session in
            await sessionsAskedAbout.record(session)
            return .succeeded
        }

        _ = await HostedCheckout.resolve(Self.session,
                                         package: TestData.annualPackage,
                                         purchaseHandler: Self.makeHandler(purchases: purchases))

        let asked = await sessionsAskedAbout.values
        expect(asked) == [Self.session]
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

        _ = await HostedCheckout.resolve(Self.session,
                                         package: TestData.annualPackage,
                                         purchaseHandler: handler)

        let wasPurchasing = await actionsWhilePolling.values
        expect(wasPurchasing) == [true]
        expect(handler.actionInProgress) == false
    }

    /// Reporting the purchase can close the paywall, so it waits until the customer has been told about it.
    @MainActor
    func testLeavesAConfirmedPurchaseForThePaywallToReport() async {
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutPollBlock = { _ in .succeeded }
        let handler = Self.makeHandler(purchases: purchases)

        let resolution = await HostedCheckout.resolve(Self.session,
                                                      package: TestData.annualPackage,
                                                      purchaseHandler: handler)

        expect(resolution) == .purchased(TestData.customerInfo)
        expect(handler.sessionPurchaseResult).to(beNil())
        expect(handler.purchaseError).to(beNil())
        expect(handler.actionInProgress) == false
    }

    /// Reporting happens as the customer dismisses the alert, so it uses the `CustomerInfo` fetched while the
    /// paywall still showed the purchase under way rather than fetching it again.
    @MainActor
    func testReportsAConfirmedPurchaseAsCompletedWithoutFetchingItsCustomerInfoAgain() {
        let purchases = MockPurchases { _, _, _ in
            return (transaction: nil, customerInfo: TestData.customerInfo, userCancelled: false)
        } restorePurchases: {
            return TestData.customerInfo
        } trackEvent: { _ in
        } customerInfo: {
            throw ErrorCode.networkError
        }
        let handler = Self.makeHandler(purchases: purchases)

        handler.handleHostedCheckoutPurchase(customerInfo: TestData.customerInfo)

        expect(handler.sessionPurchaseResult) == .purchased(transaction: nil, customerInfo: TestData.customerInfo)
        expect(handler.purchaseError).to(beNil())
    }

    /// The SDK fetches the `CustomerInfo` showing the purchase while confirming it, but that fetch can fail.
    @MainActor
    func testTellsTheCustomerAConfirmedPurchaseIsStillProcessingWithoutItsCustomerInfo() async {
        let purchases = MockPurchases { _, _, _ in
            return (transaction: nil, customerInfo: TestData.customerInfo, userCancelled: false)
        } restorePurchases: {
            return TestData.customerInfo
        } trackEvent: { _ in
        } customerInfo: {
            throw ErrorCode.networkError
        }
        purchases.hostedCheckoutPollBlock = { _ in .succeeded }
        let handler = Self.makeHandler(purchases: purchases)

        let resolution = await HostedCheckout.resolve(Self.session,
                                                      package: TestData.annualPackage,
                                                      purchaseHandler: handler)

        expect(resolution) == .failed(.unconfirmed)
        expect(handler.purchaseError as? HostedCheckoutError) == .unconfirmed
        expect(handler.sessionPurchaseResult).to(beNil())
        expect(handler.actionInProgress) == false
    }

    @MainActor
    func testReportsAFailureAfterTheSuccessPageAsAPurchaseError() async {
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutPollBlock = { _ in .undetermined }
        let handler = Self.makeHandler(purchases: purchases)

        let resolution = await HostedCheckout.resolve(Self.session,
                                                      package: TestData.annualPackage,
                                                      purchaseHandler: handler)

        expect(resolution) == .failed(.unconfirmed)
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

        _ = await HostedCheckout.resolve(Self.session,
                                         package: TestData.annualPackage,
                                         purchaseHandler: handler)

        await expect(trackedEvents.value.contains(where: Self.isPurchaseError))
            .toEventually(beTrue(), timeout: .seconds(2))
        expect(trackedEvents.value.first(where: Self.isPurchaseError)?.data.packageId)
            == TestData.annualPackage.identifier
    }

    /// Settles as when the checkout never opened for this reason: the paywall only tells the customer, and the
    /// initiated purchase ends in the error StoreKit refuses it with.
    @MainActor
    func testTracksAProductTheCustomerAlreadyOwnedAsAPurchaseError() async {
        let trackedEvents: Atomic<[PaywallEvent]> = .init([])
        let purchases = Self.makePurchases(trackingInto: trackedEvents)
        purchases.hostedCheckoutPollBlock = { _ in .alreadyPurchased }
        let handler = Self.makeHandler(purchases: purchases)
        handler.trackPaywallImpression(Self.impressionData)

        _ = await HostedCheckout.resolve(Self.session,
                                         package: TestData.annualPackage,
                                         purchaseHandler: handler)
        await Self.waitForEventsTrackedSoFar(by: handler, into: trackedEvents)

        expect(handler.sessionPurchaseResult).to(beNil())
        expect(handler.purchaseError).to(beNil())
        expect(handler.actionInProgress) == false
        let errors = trackedEvents.value.filter(Self.isPurchaseError)
        expect(errors).to(haveCount(1))
        expect(errors.first?.data.errorCode) == ErrorCode.productAlreadyPurchasedError.rawValue
        expect(trackedEvents.value.contains(where: Self.isCancel)) == false
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

    func testReportsACheckoutThatCouldNotBeStartedAsAStoreProblem() {
        expect((HostedCheckoutError.notStarted as NSError).code) == ErrorCode.storeProblemError.rawValue
    }

    /// The codes StoreKit refuses the same purchases with, so these end like their StoreKit counterparts.
    func testReportsARefusedPurchaseWithStoreKitsCode() {
        let expectedCodes: [(HostedCheckout.Refusal, ErrorCode)] = [
            (.alreadyPurchased, .productAlreadyPurchasedError),
            (.notEligible, .productNotAvailableForPurchaseError),
            (.paymentsNotAuthorized, .purchaseNotAllowedError),
            (.alreadyStarting, .operationAlreadyInProgressForProductError)
        ]

        for (refusal, code) in expectedCodes {
            expect((refusal as NSError).code).to(equal(code.rawValue), description: "\(refusal)")
            expect((refusal as NSError).domain) == ErrorCode.errorDomain
        }
    }

    func testReportsAnyOtherFailureAsUnknown() {
        expect((HostedCheckoutError.failed(code: nil) as NSError).code) == ErrorCode.unknownError.rawValue
        expect((HostedCheckoutError.failed(code: 99) as NSError).code) == ErrorCode.unknownError.rawValue
        expect((HostedCheckoutError.unconfirmed as NSError).code) == ErrorCode.unknownError.rawValue
    }

    func testTellsTheCustomerAFailedChargeFailed() {
        expect(HostedCheckoutError.failed(code: 3).message(bundle: .main)) == Text("Payment failed.", bundle: .main)
    }

    /// Which step failed is nothing the customer can act on.
    func testTellsTheCustomerSomethingWentWrongForAnyOtherFailure() {
        for code in [nil, 1, 2, 4, 99] {
            expect(HostedCheckoutError.failed(code: code).message(bundle: .main))
                == Text("Something went wrong", bundle: .main)
        }
        expect(HostedCheckoutError.notStarted.message(bundle: .main)) == Text("Something went wrong", bundle: .main)
    }

    /// The customer most likely paid, and the purchase may yet land.
    func testTellsTheCustomerAnUnconfirmedPurchaseIsStillProcessing() {
        expect(HostedCheckoutError.unconfirmed.message(bundle: .main))
            == Text("Your purchase is still processing.", bundle: .main)
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

    static func isClose(_ event: PaywallEvent) -> Bool {
        if case .close = event { return true }
        return false
    }

    /// Events are tracked in the order they are submitted, so once a close submitted now is tracked, so is every
    /// event submitted before it.
    @MainActor
    static func waitForEventsTrackedSoFar(by handler: PurchaseHandler,
                                          into trackedEvents: Atomic<[PaywallEvent]>) async {
        handler.trackPaywallClose()
        await expect(trackedEvents.value.contains(where: Self.isClose))
            .toEventually(beTrue(), timeout: .seconds(2))
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
