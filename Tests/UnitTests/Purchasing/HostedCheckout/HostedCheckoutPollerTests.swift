//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HostedCheckoutPollerTests.swift
//
//  Created by Antonio Pallares on 22/9/26.

import Foundation
import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

class HostedCheckoutPollerTests: TestCase {

    private static let operationSessionID = "opsession_123"
    private static let appUserID = "user_123"

    // MARK: - Terminal answers

    func testSucceedsOnTheFirstAttemptWithoutWaiting() async {
        let fetcher = StubStatusFetcher(results: [.status(.succeeded)])
        let sleeper = RecordingHostedCheckoutSleeper()

        let result = await self.makePoller(fetcher: fetcher, sleeper: sleeper).poll(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.appUserID
        )

        expect(result) == .succeeded
        expect(fetcher.receivedIDs) == [Self.operationSessionID]
        expect(sleeper.delays).to(beEmpty())
    }

    func testKeepsAskingWhileTheSessionIsUnderWay() async {
        let fetcher = StubStatusFetcher(results: [.status(.pending), .status(.pending), .status(.succeeded)])
        let sleeper = RecordingHostedCheckoutSleeper()

        let result = await self.makePoller(fetcher: fetcher, sleeper: sleeper).poll(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.appUserID
        )

        expect(result) == .succeeded
        expect(fetcher.callCount) == 3
        expect(sleeper.delays) == [1, 1]
    }

    /// Every attempt asks about the customer the session belongs to. The backend answers for no one else,
    /// so a poll that followed a customer who changed would stop answering.
    func testAsksAboutTheSameCustomerOnEveryAttempt() async {
        let fetcher = StubStatusFetcher(results: [.status(.pending), .status(.pending), .status(.succeeded)])

        _ = await self.makePoller(fetcher: fetcher, sleeper: RecordingHostedCheckoutSleeper()).poll(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.appUserID
        )

        expect(fetcher.receivedAppUserIDs) == Array(repeating: Self.appUserID, count: 3)
    }

    /// The reason comes back with the failure: a payment the bank turned down is not the same thing to say
    /// to a customer as a checkout that never got going.
    func testFailsWithTheReasonTheBackendGaveForTheSession() async {
        let fetcher = StubStatusFetcher(results: [.status(.failed(.init(code: 3,
                                                                        message: "payment_charge_failed")))])

        let result = await self.makePoller(fetcher: fetcher, sleeper: RecordingHostedCheckoutSleeper()).poll(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.appUserID
        )

        expect(result) == .failed(code: 3, message: "payment_charge_failed")
    }

    /// Told apart from any other failure: there is something to say to the customer rather than
    /// something that went wrong.
    func testSaysTheProductIsAlreadyOwnedWhenThatIsWhyTheSessionFailed() async {
        let fetcher = StubStatusFetcher(results: [.status(.failed(.init(code: 5,
                                                                        message: "already_purchased")))])

        let result = await self.makePoller(fetcher: fetcher, sleeper: RecordingHostedCheckoutSleeper()).poll(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.appUserID
        )

        expect(result) == .alreadyPurchased
    }

    func testFailsOnAFailedSessionTheBackendGivesNoReasonFor() async {
        let fetcher = StubStatusFetcher(results: [.status(.failed(nil))])

        let result = await self.makePoller(fetcher: fetcher, sleeper: RecordingHostedCheckoutSleeper()).poll(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.appUserID
        )

        expect(result) == .failed(code: nil, message: nil)
    }

    // MARK: - Answers the SDK does not have

    /// A session still under way when the attempts run out is not a purchase that did not happen.
    func testGivesNoAnswerWhenTheAttemptsRunOut() async {
        let fetcher = StubStatusFetcher(results: Array(repeating: .status(.pending), count: 4))
        let sleeper = RecordingHostedCheckoutSleeper()

        let result = await self.makePoller(fetcher: fetcher, sleeper: sleeper, maxAttempts: 4).poll(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.appUserID
        )

        expect(result) == .undetermined
        expect(fetcher.callCount) == 4
        expect(sleeper.delays) == [1, 1, 1]
    }

    /// Slow requests would otherwise keep the customer waiting for as long as thirty of them take.
    func testGivesNoAnswerOnceTheTimeoutPasses() async {
        let clock = ManualClock()
        let fetcher = StubStatusFetcher(results: [.status(.pending)])
        fetcher.whileRequesting = { clock.advance(by: 10) }
        let sleeper = RecordingHostedCheckoutSleeper()
        sleeper.clock = clock

        let result = await self.makePoller(fetcher: fetcher, sleeper: sleeper, clock: clock, maxAttempts: 30).poll(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.appUserID
        )

        expect(result) == .undetermined
        // Asked at 0, 11, 22, 33 and 44 seconds in; at 55 the 45 seconds are up.
        expect(fetcher.callCount) == 5
    }

    func testTakesAnAnswerThatArrivesAfterTheTimeout() async {
        let clock = ManualClock()
        let fetcher = StubStatusFetcher(results: [.status(.pending), .status(.pending), .status(.pending),
                                                  .status(.pending), .status(.succeeded)])
        fetcher.whileRequesting = { clock.advance(by: 10) }
        let sleeper = RecordingHostedCheckoutSleeper()
        sleeper.clock = clock

        let result = await self.makePoller(fetcher: fetcher, sleeper: sleeper, clock: clock, maxAttempts: 30).poll(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.appUserID
        )

        expect(result) == .succeeded
        expect(fetcher.callCount) == 5
    }

    /// A status this version does not know is likelier to be a step along the way than an outcome, so it
    /// keeps asking and ends up with no answer rather than a wrong one.
    func testKeepsAskingThroughAStatusItDoesNotKnow() async {
        let fetcher = StubStatusFetcher(results: [.status(.unknown), .status(.succeeded)])

        let result = await self.makePoller(fetcher: fetcher, sleeper: RecordingHostedCheckoutSleeper()).poll(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.appUserID
        )

        expect(result) == .succeeded
        expect(fetcher.callCount) == 2
    }

    func testKeepsAskingThroughAnErrorThatTendsToPass() async {
        let fetcher = StubStatusFetcher(results: [.failure(.networkError(.serverDown())), .status(.succeeded)])

        let result = await self.makePoller(fetcher: fetcher, sleeper: RecordingHostedCheckoutSleeper()).poll(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.appUserID
        )

        expect(result) == .succeeded
        expect(fetcher.callCount) == 2
    }

    /// The session cannot be asked about at all, which says nothing about whether the customer paid.
    func testGivesNoAnswerWhenTheSessionIsNotFoundForThisCustomer() async {
        let fetcher = StubStatusFetcher(results: [.failure(Self.sessionNotFoundError), .status(.succeeded)])

        let result = await self.makePoller(fetcher: fetcher, sleeper: RecordingHostedCheckoutSleeper()).poll(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.appUserID
        )

        expect(result) == .undetermined
        expect(fetcher.callCount) == 1
    }

    func testGivesNoAnswerWhenTheAppUserIDIsMissing() async {
        let fetcher = StubStatusFetcher(results: [.failure(.missingAppUserID())])

        let result = await self.makePoller(fetcher: fetcher, sleeper: RecordingHostedCheckoutSleeper()).poll(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.appUserID
        )

        expect(result) == .undetermined
    }

    // MARK: - Cancellation

    func testAsksNothingOnceCancelled() async {
        let fetcher = StubStatusFetcher(results: Array(repeating: .status(.pending), count: 30))
        let sleeper = RecordingHostedCheckoutSleeper()
        let poller = self.makePoller(fetcher: fetcher, sleeper: sleeper)

        let task = Task<HostedCheckoutPollResult, Never> {
            await poller.poll(operationSessionID: Self.operationSessionID, appUserID: Self.appUserID)
        }
        task.cancel()

        let result = await task.value

        expect(result) == .undetermined
        expect(fetcher.callCount) == 0
        expect(sleeper.delays).to(beEmpty())
    }

    // MARK: - A dismissed checkout

    /// Nothing to wait for, so the session itself is never asked about.
    func testAbandonsADismissedCheckoutTheCustomerDidNotPayFor() async {
        let fetcher = StubStatusFetcher(paymentStatuses: [.paymentStatus(.open)], results: [.status(.succeeded)])
        let sleeper = RecordingHostedCheckoutSleeper()

        let result = await self.makePoller(fetcher: fetcher, sleeper: sleeper).pollDismissed(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.appUserID
        )

        expect(result) == .abandoned
        expect(fetcher.receivedPaymentStatusIDs) == [Self.operationSessionID]
        expect(fetcher.receivedPaymentStatusAppUserIDs) == [Self.appUserID]
        expect(fetcher.callCount) == 0
        expect(sleeper.delays).to(beEmpty())
    }

    func testPollsADismissedCheckoutWithAPaymentUnderWay() async {
        let fetcher = StubStatusFetcher(paymentStatuses: [.paymentStatus(.processing)],
                                        results: [.status(.pending), .status(.succeeded)])

        let result = await self.makePoller(fetcher: fetcher, sleeper: RecordingHostedCheckoutSleeper()).pollDismissed(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.appUserID
        )

        expect(result) == .succeeded
        expect(fetcher.paymentStatusCallCount) == 1
        expect(fetcher.receivedAppUserIDs) == [Self.appUserID, Self.appUserID]
    }

    /// A payment under way is not a purchase that did not happen, however long it takes to land.
    func testGivesNoAnswerWhenAPaymentUnderWayDoesNotLandInTime() async {
        let fetcher = StubStatusFetcher(paymentStatuses: [.paymentStatus(.processing)],
                                        results: [.status(.pending)])

        let result = await self.makePoller(fetcher: fetcher,
                                           sleeper: RecordingHostedCheckoutSleeper(),
                                           maxAttempts: 3).pollDismissed(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.appUserID
        )

        expect(result) == .undetermined
        expect(fetcher.callCount) == 3
    }

    func testAsksOnceMoreWhenTheBackendCannotSayWhetherTheCustomerPaid() async {
        let fetcher = StubStatusFetcher(paymentStatuses: [.paymentStatus(.unknown), .paymentStatus(.open)],
                                        results: [.status(.succeeded)])
        let sleeper = RecordingHostedCheckoutSleeper()

        let result = await self.makePoller(fetcher: fetcher, sleeper: sleeper).pollDismissed(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.appUserID
        )

        expect(result) == .abandoned
        expect(fetcher.paymentStatusCallCount) == 2
        expect(sleeper.delays) == [1]
    }

    func testAsksOnceMoreThroughAnErrorThatTendsToPass() async {
        let fetcher = StubStatusFetcher(paymentStatuses: [.failure(.networkError(.serverDown())),
                                                          .paymentStatus(.processing)],
                                        results: [.status(.succeeded)])

        let result = await self.makePoller(fetcher: fetcher, sleeper: RecordingHostedCheckoutSleeper()).pollDismissed(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.appUserID
        )

        expect(result) == .succeeded
        expect(fetcher.paymentStatusCallCount) == 2
    }

    /// The customer may have paid, so this is not taken for a checkout they walked away from.
    func testGivesNoAnswerWhenTheBackendStillCannotSayWhetherTheCustomerPaid() async {
        let fetcher = StubStatusFetcher(paymentStatuses: [.paymentStatus(.unknown)], results: [.status(.succeeded)])

        let result = await self.makePoller(fetcher: fetcher, sleeper: RecordingHostedCheckoutSleeper()).pollDismissed(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.appUserID
        )

        expect(result) == .undetermined
        expect(fetcher.paymentStatusCallCount) == 2
        expect(fetcher.callCount) == 0
    }

    func testGivesNoAnswerWhenTheDismissedSessionIsNotFoundForThisCustomer() async {
        let fetcher = StubStatusFetcher(paymentStatuses: [.failure(Self.sessionNotFoundError),
                                                          .paymentStatus(.open)],
                                        results: [.status(.succeeded)])

        let result = await self.makePoller(fetcher: fetcher, sleeper: RecordingHostedCheckoutSleeper()).pollDismissed(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.appUserID
        )

        expect(result) == .undetermined
        expect(fetcher.paymentStatusCallCount) == 1
        expect(fetcher.callCount) == 0
    }

}

private extension HostedCheckoutPollerTests {

    static let sessionNotFoundError: BackendError = .networkError(
        .errorResponse(.init(code: .unknownBackendError,
                             originalCode: 7877,
                             message: "The operation session is invalid."),
                       .notFoundError)
    )

    func makePoller(fetcher: HostedCheckoutStatusFetching,
                    sleeper: HostedCheckoutAsyncSleeper) -> HostedCheckoutPoller {
        return self.makePoller(fetcher: fetcher, sleeper: sleeper, maxAttempts: 30)
    }

    func makePoller(fetcher: HostedCheckoutStatusFetching,
                    sleeper: HostedCheckoutAsyncSleeper,
                    maxAttempts: Int) -> HostedCheckoutPoller {
        return self.makePoller(fetcher: fetcher, sleeper: sleeper, clock: ManualClock(), maxAttempts: maxAttempts)
    }

    func makePoller(fetcher: HostedCheckoutStatusFetching,
                    sleeper: HostedCheckoutAsyncSleeper,
                    clock: DateProvider,
                    maxAttempts: Int) -> HostedCheckoutPoller {
        return HostedCheckoutPoller(statusFetcher: fetcher,
                                    sleeper: sleeper,
                                    dateProvider: clock,
                                    interval: 1,
                                    maxAttempts: maxAttempts,
                                    timeout: 45)
    }

}

/// Stands still unless a test moves it, so time passes only where a test says it does.
private final class ManualClock: DateProvider, @unchecked Sendable {

    private let current: Atomic<Date> = .init(Date(timeIntervalSince1970: 1_700_000_000))

    override func now() -> Date {
        return self.current.value
    }

    func advance(by seconds: TimeInterval) {
        self.current.modify { $0.addTimeInterval(seconds) }
    }

}

/// Answers each attempt from a script, repeating the last answer once the script runs out.
private final class StubStatusFetcher: HostedCheckoutStatusFetching, @unchecked Sendable {

    enum Answer {
        case status(HostedCheckoutStatusResponse.Status)
        case failure(BackendError)
    }

    enum PaymentAnswer {
        case paymentStatus(HostedCheckoutPaymentStatusResponse.PaymentStatus)
        case failure(BackendError)
    }

    private let answers: [Answer]
    private let paymentAnswers: [PaymentAnswer]
    private(set) var receivedIDs: [String] = []
    private(set) var receivedAppUserIDs: [String] = []
    private(set) var receivedPaymentStatusIDs: [String] = []
    private(set) var receivedPaymentStatusAppUserIDs: [String] = []
    /// Runs while each request is out, standing in for the time it takes.
    var whileRequesting: () -> Void = {}

    var callCount: Int { return self.receivedIDs.count }
    var paymentStatusCallCount: Int { return self.receivedPaymentStatusIDs.count }

    convenience init(results: [Answer]) {
        self.init(paymentStatuses: [], results: results)
    }

    init(paymentStatuses: [PaymentAnswer], results: [Answer]) {
        self.paymentAnswers = paymentStatuses
        self.answers = results
    }

    func fetchPaymentStatus(
        operationSessionID: String,
        appUserID: String
    ) async -> Result<HostedCheckoutPaymentStatusResponse, BackendError> {
        let index = min(self.receivedPaymentStatusIDs.count, self.paymentAnswers.count - 1)
        self.receivedPaymentStatusIDs.append(operationSessionID)
        self.receivedPaymentStatusAppUserIDs.append(appUserID)

        switch self.paymentAnswers[index] {
        case let .paymentStatus(paymentStatus):
            return .success(.init(paymentStatus: paymentStatus))
        case let .failure(error):
            return .failure(error)
        }
    }

    func fetchStatus(operationSessionID: String,
                     appUserID: String) async -> Result<HostedCheckoutStatusResponse, BackendError> {
        let index = min(self.receivedIDs.count, self.answers.count - 1)
        self.receivedIDs.append(operationSessionID)
        self.receivedAppUserIDs.append(appUserID)
        self.whileRequesting()

        switch self.answers[index] {
        case let .status(status):
            return .success(.init(status: status))
        case let .failure(error):
            return .failure(error)
        }
    }

}

/// Records what the loop would have waited, so a poll of any length runs instantly.
private final class RecordingHostedCheckoutSleeper: HostedCheckoutAsyncSleeper, @unchecked Sendable {

    private(set) var delays: [TimeInterval] = []
    var clock: ManualClock?

    func sleep(seconds: TimeInterval) async throws {
        self.delays.append(seconds)
        self.clock?.advance(by: seconds)
    }

}
