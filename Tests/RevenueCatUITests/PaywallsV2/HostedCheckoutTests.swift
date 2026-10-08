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
        purchases.hostedCheckoutBlock = { _, _, _ in .started(Self.session) }

        let action = await HostedCheckout.start(for: TestData.annualPackage,
                                                purchaseHandler: Self.makeHandler(purchases: purchases),
                                                purchaseInitiatedAction: nil)

        guard case let .present(session) = action else { return fail("Unexpected \(action)") }
        expect(session) == Self.session
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
        purchases.hostedCheckoutBlock = { _, paywallEvent, _ in
            eventsSentWithTheCheckout.modify { $0.append(paywallEvent) }
            return .started(Self.session)
        }
        let handler = Self.makeHandler(purchases: purchases)
        handler.trackPaywallImpression(Self.impressionData)

        _ = await handler.startHostedCheckout(package: TestData.annualPackage, previousSession: nil)

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
        purchases.hostedCheckoutBlock = { package, _, _ in
            await checkoutsStarted.record(package.identifier)
            return .started(Self.session)
        }

        let action = await HostedCheckout.start(for: TestData.annualPackage,
                                                purchaseHandler: Self.makeHandler(purchases: purchases),
                                                purchaseInitiatedAction: Self.interceptor(proceeding: false,
                                                                                          recordingInto: .init()))

        let packagesCheckedOut = await checkoutsStarted.values
        guard case .nothing = action else { return fail("Unexpected \(action)") }
        expect(packagesCheckedOut).to(beEmpty())
    }

    func testStartsTheCheckoutOnceTheAppLetsThePurchaseThrough() async {
        let packagesIntercepted = Recorder<String>()
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutBlock = { _, _, _ in .started(Self.session) }

        let action = await HostedCheckout.start(
            for: TestData.annualPackage,
            purchaseHandler: Self.makeHandler(purchases: purchases),
            purchaseInitiatedAction: Self.interceptor(proceeding: true, recordingInto: packagesIntercepted)
        )

        let packagesAskedAbout = await packagesIntercepted.values
        guard case let .present(session) = action else { return fail("Unexpected \(action)") }
        expect(session) == Self.session
        expect(packagesAskedAbout) == [TestData.annualPackage.identifier]
    }

    func testPresentsTheCheckoutThatWasCreated() {
        let action = HostedCheckout.Action(.started(Self.session), keptCheckout: nil)

        guard case let .present(session) = action else { return fail("Unexpected \(action)") }
        expect(session) == Self.session
    }

    func testPresentsTheCheckoutThatWasResumed() {
        let action = HostedCheckout.Action(.resumed(Self.session), keptCheckout: nil)

        guard case let .present(session) = action else { return fail("Unexpected \(action)") }
        expect(session) == Self.session
    }

    /// There is nothing left to pay for, but the purchase still has to be confirmed and reported.
    @MainActor
    func testConfirmsACheckoutTheCustomerAlreadyPaidFor() {
        let kept = Self.makeKeptCheckout(for: Self.session)

        let action = HostedCheckout.Action(.completed(Self.session.id), keptCheckout: kept)

        guard case let .confirm(sessionID, settling) = action else { return fail("Unexpected \(action)") }
        expect(sessionID) == Self.session.id
        expect(settling) === kept
    }

    /// There is no checkout to open for something the customer already has, and they are told so rather than
    /// left with a button that appears to do nothing.
    func testTellsTheCustomerWhenTheyAlreadyOwnTheProduct() {
        let action = HostedCheckout.Action(.alreadyPurchased, keptCheckout: nil)

        guard case .tellCustomerTheyAlreadyOwnIt = action else { return fail("Unexpected \(action)") }
    }

    /// A customer who said no to Apple's notice said no to the purchase.
    func testOffersNothingWhenTheCustomerDeclinedTheNotice() {
        let action = HostedCheckout.Action(.declinedByCustomer, keptCheckout: nil)

        guard case .nothing = action else { return fail("Unexpected \(action)") }
    }

    /// Apple asks that a device that does not authorize payments be offered no purchase at all, not even
    /// through StoreKit.
    func testOffersNothingWhenTheDeviceDoesNotAuthorizePayments() {
        let action = HostedCheckout.Action(.paymentsNotAuthorized, keptCheckout: nil)

        guard case .nothing = action else { return fail("Unexpected \(action)") }
    }

    /// A customer who is not eligible to buy outside the App Store is told the purchase is unavailable rather
    /// than left with a button that appears to do nothing.
    func testTellsAnIneligibleCustomerThePurchaseIsUnavailable() {
        let action = HostedCheckout.Action(.notEligible, keptCheckout: nil)

        guard case .tellCustomerThePurchaseIsUnavailable = action else { return fail("Unexpected \(action)") }
    }

    /// The checkout already under way carries the purchase.
    func testOffersNothingWhileAnotherCheckoutIsStarting() {
        let action = HostedCheckout.Action(.alreadyStarting, keptCheckout: nil)

        guard case .nothing = action else { return fail("Unexpected \(action)") }
    }

    /// Falling back to StoreKit here would charge a customer who is midway through a checkout that may yet
    /// be resolved, so a failure offers nothing but telling them.
    func testTellsTheCustomerWhenTheCheckoutCouldNotBeCreated() {
        let action = HostedCheckout.Action(.failed, keptCheckout: nil)

        guard case let .failed(error) = action else { return fail("Unexpected \(action)") }
        expect(error) == .notStarted
    }

    @MainActor
    func testReportsACheckoutThatCouldNotBeCreatedAsAPurchaseError() async {
        let trackedEvents: Atomic<[PaywallEvent]> = .init([])
        let purchases = Self.makePurchases(trackingInto: trackedEvents)
        purchases.hostedCheckoutBlock = { _, _, _ in .failed }
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

    /// Saying no to Apple's notice is the hosted checkout's counterpart to dismissing StoreKit's sheet, so the app
    /// hears of it as a cancellation too.
    @MainActor
    func testReportsADeclinedNoticeAsACancellation() async {
        let trackedEvents: Atomic<[PaywallEvent]> = .init([])
        let purchases = Self.makePurchases(trackingInto: trackedEvents)
        purchases.hostedCheckoutBlock = { _, _, _ in .declinedByCustomer }
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
        expect(handler.sessionPurchaseResult) == .cancelled
        expect(handler.purchaseResult) == .cancelled
    }

    /// The customer is told they already own it or that it is unavailable, or nothing at all, but the purchase still
    /// fails, as one StoreKit refuses does.
    @MainActor
    func testReportsARefusedPurchaseAsAPurchaseError() async {
        let cases: [(HostedCheckoutStartResult, HostedCheckout.Refusal)] = [
            (.alreadyPurchased, .alreadyPurchased),
            (.notEligible, .notEligible),
            (.paymentsNotAuthorized, .paymentsNotAuthorized)
        ]

        for (result, expectedError) in cases {
            let (handler, trackedEvents) = await Self.startCheckout(endingIn: result)

            Self.expectASinglePurchaseError(expectedError, in: trackedEvents)
            expect(handler.purchaseError as? HostedCheckout.Refusal).to(equal(expectedError), description: "\(result)")
        }
    }

    /// The checkout already starting reports how the purchase ends, which may yet be a purchase.
    @MainActor
    func testOnlyTracksATapWhileAnotherCheckoutIsStarting() async {
        let (handler, trackedEvents) = await Self.startCheckout(endingIn: .alreadyStarting)

        Self.expectASinglePurchaseError(HostedCheckout.Refusal.alreadyStarting, in: trackedEvents)
        expect(handler.purchaseError).to(beNil())
    }

    // MARK: - Keeping the checkout

    @MainActor
    func testAsksToCarryOnWithTheKeptCheckout() async {
        let previousSessions = Recorder<HostedCheckoutSession?>()
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutBlock = { _, _, previousSession in
            await previousSessions.record(previousSession)
            return .resumed(Self.session)
        }
        let handler = Self.makeHandler(purchases: purchases)
        handler.keptHostedCheckout = Self.makeKeptCheckout(for: Self.session)

        _ = await HostedCheckout.start(for: TestData.annualPackage,
                                       purchaseHandler: handler,
                                       purchaseInitiatedAction: nil)

        let sent = await previousSessions.values
        expect(sent) == [Self.session]
    }

    @MainActor
    func testAsksForANewCheckoutWhenNoneIsKept() async {
        let previousSessions = Recorder<HostedCheckoutSession?>()
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutBlock = { _, _, previousSession in
            await previousSessions.record(previousSession)
            return .started(Self.session)
        }

        _ = await HostedCheckout.start(for: TestData.annualPackage,
                                       purchaseHandler: Self.makeHandler(purchases: purchases),
                                       purchaseInitiatedAction: nil)

        let sent = await previousSessions.values
        expect(sent) == [nil]
    }

    /// Confirming the payment can still fail, and tapping buy again should then retry it.
    @MainActor
    func testKeepsACheckoutThatWasAlreadyPaidForUntilItIsConfirmed() async {
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutBlock = { _, _, _ in .completed(Self.session.id) }
        let handler = Self.makeHandler(purchases: purchases)
        let kept = Self.makeKeptCheckout(for: Self.session)
        handler.keptHostedCheckout = kept

        let action = await HostedCheckout.start(for: TestData.annualPackage,
                                                purchaseHandler: handler,
                                                purchaseInitiatedAction: nil)

        guard case let .confirm(sessionID, settling) = action else { return fail("Unexpected \(action)") }
        expect(sessionID) == Self.session.id
        expect(settling) === kept
        expect(handler.keptHostedCheckout) === kept
    }

    /// The backend may say another session was the one paid for, and confirming that still settles the kept one.
    @MainActor
    func testConfirmsTheSessionTheBackendSaysWasPaidForInsteadOfTheKeptOne() async {
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutBlock = { _, _, _ in .completed(Self.otherSession.id) }
        let handler = Self.makeHandler(purchases: purchases)
        let kept = Self.makeKeptCheckout(for: Self.session)
        handler.keptHostedCheckout = kept

        let action = await HostedCheckout.start(for: TestData.annualPackage,
                                                purchaseHandler: handler,
                                                purchaseInitiatedAction: nil)

        guard case let .confirm(sessionID, settling) = action else { return fail("Unexpected \(action)") }
        expect(sessionID) == Self.otherSession.id
        expect(settling) === kept
    }

    @MainActor
    func testReleasesTheKeptCheckoutOnceItsPurchaseIsConfirmed() async {
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutPollBlock = { _ in .succeeded }
        let handler = Self.makeHandler(purchases: purchases)
        let kept = Self.makeKeptCheckout(for: Self.session)
        handler.keptHostedCheckout = kept

        _ = await HostedCheckout.resolve(Self.session.id,
                                         settling: kept,
                                         package: TestData.annualPackage,
                                         purchaseHandler: handler)

        expect(handler.keptHostedCheckout).to(beNil())
    }

    /// Otherwise every tap on buy would hand the backend the same settled checkout and confirm it again.
    @MainActor
    func testReleasesTheKeptCheckoutWhenThePurchaseConfirmedForItIsUnderAnotherSession() async {
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutPollBlock = { _ in .succeeded }
        let handler = Self.makeHandler(purchases: purchases)
        let kept = Self.makeKeptCheckout(for: Self.session)
        handler.keptHostedCheckout = kept

        _ = await HostedCheckout.resolve(Self.otherSession.id,
                                         settling: kept,
                                         package: TestData.annualPackage,
                                         purchaseHandler: handler)

        expect(handler.keptHostedCheckout).to(beNil())
    }

    @MainActor
    func testReleasesTheKeptCheckoutForAProductTheCustomerAlreadyOwned() async {
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutPollBlock = { _ in .alreadyPurchased }
        let handler = Self.makeHandler(purchases: purchases)
        let kept = Self.makeKeptCheckout(for: Self.session)
        handler.keptHostedCheckout = kept

        _ = await HostedCheckout.resolve(Self.otherSession.id,
                                         settling: kept,
                                         package: TestData.annualPackage,
                                         purchaseHandler: handler)

        expect(handler.keptHostedCheckout).to(beNil())
    }

    /// Otherwise tapping buy again would start a second checkout while this payment may still be landing.
    @MainActor
    func testKeepsTheCheckoutWhenItsPurchaseCouldNotBeConfirmed() async {
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutPollBlock = { _ in .undetermined }
        let handler = Self.makeHandler(purchases: purchases)
        let kept = Self.makeKeptCheckout(for: Self.session)
        handler.keptHostedCheckout = kept

        _ = await HostedCheckout.resolve(Self.otherSession.id,
                                         settling: kept,
                                         package: TestData.annualPackage,
                                         purchaseHandler: handler)

        expect(handler.keptHostedCheckout) === kept
    }

    @MainActor
    func testLeavesACheckoutThatReplacedTheOneBeingConfirmed() async {
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutPollBlock = { _ in .succeeded }
        let handler = Self.makeHandler(purchases: purchases)
        let replacement = Self.makeKeptCheckout(for: Self.otherSession)
        handler.keptHostedCheckout = replacement

        _ = await HostedCheckout.resolve(Self.session.id,
                                         settling: Self.makeKeptCheckout(for: Self.session),
                                         package: TestData.annualPackage,
                                         purchaseHandler: handler)

        expect(handler.keptHostedCheckout) === replacement
    }

    /// The customer comes back to the page as they left it, rather than to one loading afresh.
    @MainActor
    func testPresentsTheKeptCheckoutAgainForTheSameSession() {
        let handler = Self.makeHandler(purchases: Self.makePurchases())
        let kept = Self.makeKeptCheckout(for: Self.session)
        handler.keptHostedCheckout = kept

        let checkout = HostedCheckout.checkoutToPresent(Self.session,
                                                        package: TestData.annualPackage,
                                                        purchaseHandler: handler)

        expect(checkout) === kept
    }

    @MainActor
    func testReplacesTheKeptCheckoutWithADifferentSession() {
        let handler = Self.makeHandler(purchases: Self.makePurchases())
        let kept = Self.makeKeptCheckout(for: Self.session)
        handler.keptHostedCheckout = kept

        let checkout = HostedCheckout.checkoutToPresent(Self.otherSession,
                                                        package: TestData.monthlyPackage,
                                                        purchaseHandler: handler)

        expect(checkout) !== kept
        expect(checkout.session) == Self.otherSession
        expect(checkout.package.identifier) == TestData.monthlyPackage.identifier
        expect(handler.keptHostedCheckout) === checkout
    }

    @MainActor
    func testKeepsTheCheckoutItPresents() {
        let handler = Self.makeHandler(purchases: Self.makePurchases())

        let checkout = HostedCheckout.checkoutToPresent(Self.session,
                                                        package: TestData.annualPackage,
                                                        purchaseHandler: handler)

        expect(handler.keptHostedCheckout) === checkout
    }

    /// A customer who comes back to the paywall later starts afresh.
    @MainActor
    func testReleasesTheKeptCheckoutWithThePaywallSession() {
        let handler = Self.makeHandler(purchases: Self.makePurchases())
        handler.keptHostedCheckout = Self.makeKeptCheckout(for: Self.session)

        handler.resetForNewSession()

        expect(handler.keptHostedCheckout).to(beNil())
    }

    // MARK: - Returning while hidden

    /// The provider redirects once a payment the customer made moments before closing the sheet goes through.
    @MainActor
    func testConfirmsTheKeptCheckoutWhenItsPageReachesTheSuccessURLWhileHidden() {
        let handler = Self.makeHandler(purchases: Self.makePurchases())
        let kept = Self.makeKeptCheckout(for: Self.session)
        handler.keptHostedCheckout = kept
        var confirmed: [HostedCheckout.KeptCheckout] = []

        HostedCheckout.onSuccessAfterDismissal(of: kept, purchaseHandler: handler) { confirmed.append($0) }
        Self.navigate(kept.viewModel, to: Self.session.successURL)

        expect(confirmed).to(haveCount(1))
        expect(confirmed.first) === kept
        expect(handler.keptHostedCheckout) === kept
    }

    @MainActor
    func testLeavesTheKeptCheckoutWhenItsPageReturnsWithoutSucceedingWhileHidden() {
        let handler = Self.makeHandler(purchases: Self.makePurchases())
        let kept = Self.makeKeptCheckout(for: Self.session)
        handler.keptHostedCheckout = kept
        var confirmed = 0

        HostedCheckout.onSuccessAfterDismissal(of: kept, purchaseHandler: handler) { _ in confirmed += 1 }
        Self.navigate(kept.viewModel,
                      to: URL(string: "https://api.revenuecat.com/rcbilling/v1/hosted-checkout-return?status=cancel")!)

        expect(confirmed) == 0
        expect(handler.keptHostedCheckout) === kept
    }

    /// The customer moved on to another checkout, which is the one that carries their purchase now.
    @MainActor
    func testDoesNotConfirmACheckoutThatIsNoLongerKept() {
        let handler = Self.makeHandler(purchases: Self.makePurchases())
        let kept = Self.makeKeptCheckout(for: Self.session)
        handler.keptHostedCheckout = kept
        var confirmed = 0

        HostedCheckout.onSuccessAfterDismissal(of: kept, purchaseHandler: handler) { _ in confirmed += 1 }
        let replacement = HostedCheckout.checkoutToPresent(Self.otherSession,
                                                           package: TestData.monthlyPackage,
                                                           purchaseHandler: handler)
        Self.navigate(kept.viewModel, to: Self.session.successURL)

        expect(confirmed) == 0
        expect(handler.keptHostedCheckout) === replacement
    }

    /// Taking over the paywall's busy state would end whatever the customer is doing in the meantime.
    @MainActor
    func testConfirmsWithoutShowingItWhileAnotherActionIsUnderWay() async {
        let actionsWhilePolling = Recorder<PurchaseHandler.ActionType?>()
        let purchases = Self.makePurchases()
        let handler = Self.makeHandler(purchases: purchases)
        purchases.hostedCheckoutPollBlock = { _ in
            await actionsWhilePolling.record(await MainActor.run { handler.actionTypeInProgress })
            return .succeeded
        }
        handler.actionTypeInProgress = .restore

        let resolution = await HostedCheckout.resolve(Self.session.id,
                                                      settling: nil,
                                                      package: TestData.annualPackage,
                                                      purchaseHandler: handler)

        let actions = await actionsWhilePolling.values
        expect(resolution) == .purchased(TestData.customerInfo)
        expect(actions) == [.restore]
        expect(handler.actionTypeInProgress) == .restore
    }

    // MARK: - Confirming once

    /// The page can reach the success URL after the sheet was closed while tapping buy again confirms the same
    /// checkout, and the customer should be told about their purchase once.
    @MainActor
    func testDoesNotConfirmACheckoutAlreadyBeingConfirmed() async {
        let pollStarted = Gate()
        let pollAnswer = Gate()
        let sessionsAskedAbout = Recorder<HostedCheckoutSessionID>()
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutPollBlock = { sessionID in
            await sessionsAskedAbout.record(sessionID)
            await pollStarted.open()
            await pollAnswer.wait()
            return .succeeded
        }
        let handler = Self.makeHandler(purchases: purchases)
        let kept = Self.makeKeptCheckout(for: Self.session)
        handler.keptHostedCheckout = kept

        let first = Task { @MainActor in
            await HostedCheckout.resolve(Self.session.id,
                                         settling: kept,
                                         package: TestData.annualPackage,
                                         purchaseHandler: handler)
        }
        await pollStarted.wait()
        let second = await HostedCheckout.resolve(Self.session.id,
                                                  settling: kept,
                                                  package: TestData.annualPackage,
                                                  purchaseHandler: handler)
        await pollAnswer.open()

        let firstResolution = await first.value
        let asked = await sessionsAskedAbout.values
        expect(second).to(beNil())
        expect(firstResolution) == .purchased(TestData.customerInfo)
        expect(asked) == [Self.session.id]
    }

    @MainActor
    func testDoesNotConfirmACheckoutThatAlreadySettled() async {
        let sessionsAskedAbout = Recorder<HostedCheckoutSessionID>()
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutPollBlock = { sessionID in
            await sessionsAskedAbout.record(sessionID)
            return .succeeded
        }
        let handler = Self.makeHandler(purchases: purchases)
        let kept = Self.makeKeptCheckout(for: Self.session)
        handler.keptHostedCheckout = kept

        _ = await HostedCheckout.resolve(Self.session.id,
                                         settling: kept,
                                         package: TestData.annualPackage,
                                         purchaseHandler: handler)
        let again = await HostedCheckout.resolve(Self.session.id,
                                                 settling: kept,
                                                 package: TestData.annualPackage,
                                                 purchaseHandler: handler)

        let asked = await sessionsAskedAbout.values
        expect(again).to(beNil())
        expect(asked) == [Self.session.id]
    }

    /// Tapping buy again retries it.
    @MainActor
    func testConfirmsAgainACheckoutWhoseConfirmationFailed() async {
        let sessionsAskedAbout = Recorder<HostedCheckoutSessionID>()
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutPollBlock = { sessionID in
            await sessionsAskedAbout.record(sessionID)
            return .undetermined
        }
        let handler = Self.makeHandler(purchases: purchases)
        let kept = Self.makeKeptCheckout(for: Self.session)
        handler.keptHostedCheckout = kept

        _ = await HostedCheckout.resolve(Self.session.id,
                                         settling: kept,
                                         package: TestData.annualPackage,
                                         purchaseHandler: handler)
        let again = await HostedCheckout.resolve(Self.session.id,
                                                 settling: kept,
                                                 package: TestData.annualPackage,
                                                 purchaseHandler: handler)

        let asked = await sessionsAskedAbout.values
        expect(again) == .failed(.unconfirmed)
        expect(asked) == [Self.session.id, Self.session.id]
    }

    /// The page reached the success URL after the sheet was closed while the backend answered the customer's tap on
    /// buy. That confirmation tells the customer, and the paywall shows it under way until it does.
    @MainActor
    func testWaitsForAConfirmationThatBeganWhileTheCheckoutStarted() async {
        let pollStarted = Gate()
        let pollAnswer = Gate()
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutPollBlock = { _ in
            await pollStarted.open()
            await pollAnswer.wait()
            return .succeeded
        }
        let handler = Self.makeHandler(purchases: purchases)
        let kept = Self.makeKeptCheckout(for: Self.session)
        handler.keptHostedCheckout = kept
        let confirmation: Atomic<Task<HostedCheckout.Resolution?, Never>?> = .init(nil)
        purchases.hostedCheckoutBlock = { _, _, _ in
            confirmation.value = Task { @MainActor in
                await HostedCheckout.resolve(Self.session.id,
                                             settling: kept,
                                             package: TestData.annualPackage,
                                             purchaseHandler: handler)
            }
            await pollStarted.wait()
            return .resumed(Self.session)
        }

        let tap = Task { @MainActor in
            await HostedCheckout.start(for: TestData.annualPackage,
                                       purchaseHandler: handler,
                                       purchaseInitiatedAction: nil)
        }
        await expect(handler.actionTypeInProgress).toEventually(equal(.purchase), timeout: .seconds(2))
        await pollAnswer.open()
        let action = await tap.value

        let resolution = await confirmation.value?.value
        guard case .nothing = action else { return fail("Unexpected \(action)") }
        expect(resolution) == .purchased(TestData.customerInfo)
        expect(handler.keptHostedCheckout).to(beNil())
        expect(handler.actionInProgress) == false
    }

    /// The confirmation already told the customer how the checkout settled.
    @MainActor
    func testOpensNothingForAKeptCheckoutThatSettledWhileTheCheckoutStarted() async {
        let sessionsAskedAbout = Recorder<HostedCheckoutSessionID>()
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutPollBlock = { sessionID in
            await sessionsAskedAbout.record(sessionID)
            return .succeeded
        }
        let handler = Self.makeHandler(purchases: purchases)
        let kept = Self.makeKeptCheckout(for: Self.session)
        handler.keptHostedCheckout = kept
        purchases.hostedCheckoutBlock = { _, _, _ in
            _ = await HostedCheckout.resolve(Self.session.id,
                                             settling: kept,
                                             package: TestData.annualPackage,
                                             purchaseHandler: handler)
            return .completed(Self.session.id)
        }

        let action = await HostedCheckout.start(for: TestData.annualPackage,
                                                purchaseHandler: handler,
                                                purchaseInitiatedAction: nil)

        let asked = await sessionsAskedAbout.values
        guard case .nothing = action else { return fail("Unexpected \(action)") }
        expect(asked) == [Self.session.id]
    }

    /// The app's purchase interceptor can take its time, and the page the customer closed can reach the success URL
    /// meanwhile. The confirmation released the kept checkout, and starting another would let them pay again.
    @MainActor
    func testOpensNothingForAKeptCheckoutThatSettledWhileTheInterceptorDecided() async {
        let checkoutsStarted = Recorder<String>()
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutPollBlock = { _ in .succeeded }
        purchases.hostedCheckoutBlock = { package, _, _ in
            await checkoutsStarted.record(package.identifier)
            return .started(Self.otherSession)
        }
        let handler = Self.makeHandler(purchases: purchases)
        let kept = Self.makeKeptCheckout(for: Self.session)
        handler.keptHostedCheckout = kept
        let interceptor = PurchaseInitiatedAction { _, resume in
            Task { @MainActor in
                _ = await HostedCheckout.resolve(Self.session.id,
                                                 settling: kept,
                                                 package: TestData.annualPackage,
                                                 purchaseHandler: handler)
                resume(shouldProceed: true)
            }
        }

        let action = await HostedCheckout.start(for: TestData.annualPackage,
                                                purchaseHandler: handler,
                                                purchaseInitiatedAction: interceptor)

        let started = await checkoutsStarted.values
        guard case .nothing = action else { return fail("Unexpected \(action)") }
        expect(started).to(beEmpty())
        expect(handler.keptHostedCheckout).to(beNil())
    }

    /// Starting the checkout would show Apple's notice to a customer who already paid.
    @MainActor
    func testWaitsForAConfirmationThatBeganWhileTheInterceptorDecidedWithoutStartingACheckout() async {
        let pollStarted = Gate()
        let pollAnswer = Gate()
        let checkoutsStarted = Recorder<String>()
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutPollBlock = { _ in
            await pollStarted.open()
            await pollAnswer.wait()
            return .succeeded
        }
        purchases.hostedCheckoutBlock = { package, _, _ in
            await checkoutsStarted.record(package.identifier)
            return .resumed(Self.session)
        }
        let handler = Self.makeHandler(purchases: purchases)
        let kept = Self.makeKeptCheckout(for: Self.session)
        handler.keptHostedCheckout = kept
        let confirmation: Atomic<Task<HostedCheckout.Resolution?, Never>?> = .init(nil)
        let interceptor = PurchaseInitiatedAction { _, resume in
            Task { @MainActor in
                confirmation.value = Task { @MainActor in
                    await HostedCheckout.resolve(Self.session.id,
                                                 settling: kept,
                                                 package: TestData.annualPackage,
                                                 purchaseHandler: handler)
                }
                await pollStarted.wait()
                resume(shouldProceed: true)
            }
        }

        let tap = Task { @MainActor in
            await HostedCheckout.start(for: TestData.annualPackage,
                                       purchaseHandler: handler,
                                       purchaseInitiatedAction: interceptor)
        }
        await expect(handler.actionTypeInProgress).toEventually(equal(.purchase), timeout: .seconds(2))
        await pollAnswer.open()
        let action = await tap.value

        let resolution = await confirmation.value?.value
        let started = await checkoutsStarted.values
        guard case .nothing = action else { return fail("Unexpected \(action)") }
        expect(resolution) == .purchased(TestData.customerInfo)
        expect(started).to(beEmpty())
        expect(handler.actionInProgress) == false
    }

    /// The page says the customer paid, whatever the backend has seen so far, and another page would let them pay
    /// again.
    @MainActor
    func testConfirmsAKeptCheckoutWhosePageSucceededInsteadOfPresentingAnother() async {
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutBlock = { _, _, _ in .started(Self.otherSession) }
        let handler = Self.makeHandler(purchases: purchases)
        let kept = Self.makeKeptCheckout(for: Self.session)
        handler.keptHostedCheckout = kept
        Self.navigate(kept.viewModel, to: Self.session.successURL)

        let action = await HostedCheckout.start(for: TestData.monthlyPackage,
                                                purchaseHandler: handler,
                                                purchaseInitiatedAction: nil)

        guard case let .confirm(sessionID, settling) = action else { return fail("Unexpected \(action)") }
        expect(sessionID) == Self.session.id
        expect(settling) === kept
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
        let sessionsAskedAbout = Recorder<HostedCheckoutSessionID>()
        let purchases = Self.makePurchases()
        purchases.hostedCheckoutPollBlock = { sessionID in
            await sessionsAskedAbout.record(sessionID)
            return .succeeded
        }

        _ = await HostedCheckout.resolve(Self.session.id,
                                         settling: nil,
                                         package: TestData.annualPackage,
                                         purchaseHandler: Self.makeHandler(purchases: purchases))

        let asked = await sessionsAskedAbout.values
        expect(asked) == [Self.session.id]
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

        _ = await HostedCheckout.resolve(Self.session.id,
                                         settling: nil,
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

        let resolution = await HostedCheckout.resolve(Self.session.id,
                                                      settling: nil,
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

        let resolution = await HostedCheckout.resolve(Self.session.id,
                                                      settling: nil,
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

        let resolution = await HostedCheckout.resolve(Self.session.id,
                                                      settling: nil,
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

        _ = await HostedCheckout.resolve(Self.session.id,
                                         settling: nil,
                                         package: TestData.annualPackage,
                                         purchaseHandler: handler)

        await expect(trackedEvents.value.contains(where: Self.isPurchaseError))
            .toEventually(beTrue(), timeout: .seconds(2))
        expect(trackedEvents.value.first(where: Self.isPurchaseError)?.data.packageId)
            == TestData.annualPackage.identifier
    }

    /// Settles as when the checkout never opened for this reason: the paywall tells the customer, and the purchase
    /// fails with the error StoreKit refuses it with.
    @MainActor
    func testReportsAProductTheCustomerAlreadyOwnedAsAPurchaseError() async {
        let trackedEvents: Atomic<[PaywallEvent]> = .init([])
        let purchases = Self.makePurchases(trackingInto: trackedEvents)
        purchases.hostedCheckoutPollBlock = { _ in .alreadyPurchased }
        let handler = Self.makeHandler(purchases: purchases)
        handler.trackPaywallImpression(Self.impressionData)

        _ = await HostedCheckout.resolve(Self.session.id,
                                         settling: nil,
                                         package: TestData.annualPackage,
                                         purchaseHandler: handler)
        await Self.waitForEventsTrackedSoFar(by: handler, into: trackedEvents)

        expect(handler.sessionPurchaseResult).to(beNil())
        expect(handler.purchaseError as? HostedCheckout.Refusal) == .alreadyPurchased
        expect(handler.actionInProgress) == false
        Self.expectASinglePurchaseError(HostedCheckout.Refusal.alreadyPurchased, in: trackedEvents)
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

    static let otherSession = HostedCheckoutSession(
        operationSessionID: "oper_2",
        appUserID: "app_user_1",
        checkoutURL: URL(string: "https://checkout.stripe.com/c/pay/session_2")!,
        successURL: session.successURL
    )

    /// Has the page navigate to `url`, as the provider's redirect does.
    @MainActor
    static func navigate(_ viewModel: WebCheckoutViewModel, to url: URL) {
        viewModel.webView(viewModel.webView,
                          decidePolicyFor: MainFrameNavigationAction(url: url),
                          decisionHandler: { _ in })
    }

    @MainActor
    static func makeKeptCheckout(for session: HostedCheckoutSession) -> HostedCheckout.KeptCheckout {
        return .init(session: session,
                     package: TestData.annualPackage,
                     viewModel: WebCheckoutViewModel(checkoutURL: session.checkoutURL,
                                                     successURL: session.successURL,
                                                     dataStoreIdentifierStore: .init()))
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

    /// Starts a checkout that ends in `result`, once every event it tracked has been tracked.
    @MainActor
    static func startCheckout(
        endingIn result: HostedCheckoutStartResult
    ) async -> (handler: PurchaseHandler, trackedEvents: Atomic<[PaywallEvent]>) {
        let trackedEvents: Atomic<[PaywallEvent]> = .init([])
        let purchases = Self.makePurchases(trackingInto: trackedEvents)
        purchases.hostedCheckoutBlock = { _, _, _ in result }
        let handler = Self.makeHandler(purchases: purchases)
        handler.trackPaywallImpression(Self.impressionData)

        _ = await HostedCheckout.start(for: TestData.annualPackage,
                                       purchaseHandler: handler,
                                       purchaseInitiatedAction: nil)
        await Self.waitForEventsTrackedSoFar(by: handler, into: trackedEvents)

        return (handler, trackedEvents)
    }

    static func expectASinglePurchaseError(_ refusal: HostedCheckout.Refusal,
                                           in trackedEvents: Atomic<[PaywallEvent]>) {
        let errors = trackedEvents.value.filter(Self.isPurchaseError)
        expect(errors).to(haveCount(1), description: "\(refusal)")
        expect(errors.first?.data.packageId).to(equal(TestData.annualPackage.identifier), description: "\(refusal)")
        expect(errors.first?.data.errorCode).to(equal((refusal as NSError).code), description: "\(refusal)")
        expect(errors.first?.data.errorMessage)
            .to(equal((refusal as NSError).localizedDescription), description: "\(refusal)")
        expect(trackedEvents.value.contains(where: Self.isCancel)).to(beFalse(), description: "\(refusal)")
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

/// Holds whoever waits on it until it is opened.
private actor Gate {

    private var isOpen = false
    private var continuations: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        guard !self.isOpen else { return }

        await withCheckedContinuation { continuation in
            self.continuations.append(continuation)
        }
    }

    func open() {
        self.isOpen = true
        let continuations = self.continuations
        self.continuations = []
        continuations.forEach { $0.resume() }
    }

}

#endif
