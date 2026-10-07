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
        let fetcher = StubStatusFetcher(results: [.status(.succeeded(nil))])
        let sleeper = RecordingHostedCheckoutSleeper()

        let result = await self.makePoller(fetcher: fetcher, sleeper: sleeper).poll(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.appUserID
        )

        expect(result) == .succeeded(nil)
        expect(fetcher.receivedIDs) == [Self.operationSessionID]
        expect(sleeper.delays).to(beEmpty())
    }

    func testSucceedsWithTheTransactionTheSessionMade() async {
        let fetcher = StubStatusFetcher(results: [.status(.succeeded(Self.purchase(isSandbox: true)))])

        let result = await self.makePoller(fetcher: fetcher, sleeper: RecordingHostedCheckoutSleeper()).poll(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.appUserID
        )

        guard case let .succeeded(transaction?) = result else {
            return XCTFail("Expected a transaction, got \(result)")
        }
        expect(transaction.transactionIdentifier) == "txn_123"
        expect(transaction.productIdentifier) == "monthly"
        expect(transaction.purchaseDate) == Date(timeIntervalSince1970: 1609459200)
        expect(transaction.quantity) == 1
        expect(transaction.environment) == .sandbox
    }

    func testReportsAPurchaseOutsideSandboxAsProduction() async {
        let fetcher = StubStatusFetcher(results: [.status(.succeeded(Self.purchase(isSandbox: false)))])

        let result = await self.makePoller(fetcher: fetcher, sleeper: RecordingHostedCheckoutSleeper()).poll(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.appUserID
        )

        guard case let .succeeded(transaction?) = result else {
            return XCTFail("Expected a transaction, got \(result)")
        }
        expect(transaction.environment) == .production
    }

    func testKeepsAskingWhileTheSessionIsUnderWay() async {
        let fetcher = StubStatusFetcher(results: [.status(.pending), .status(.pending), .status(.succeeded(nil))])
        let sleeper = RecordingHostedCheckoutSleeper()

        let result = await self.makePoller(fetcher: fetcher, sleeper: sleeper).poll(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.appUserID
        )

        expect(result) == .succeeded(nil)
        expect(fetcher.callCount) == 3
        expect(sleeper.delays) == [1, 1]
    }

    /// Every attempt asks about the customer the session belongs to. The backend answers for no one else,
    /// so a poll that followed a customer who changed would stop answering.
    func testAsksAboutTheSameCustomerOnEveryAttempt() async {
        let fetcher = StubStatusFetcher(results: [.status(.pending), .status(.pending), .status(.succeeded(nil))])

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

    func testGivesNoAnswerWhenARequestOutlastsTheTimeout() async {
        let fetcher = UnansweredStatusFetcher()
        let poller = HostedCheckoutPoller(statusFetcher: fetcher,
                                          sleeper: RecordingHostedCheckoutSleeper(),
                                          dateProvider: DateProvider(),
                                          interval: 1,
                                          maxAttempts: 30,
                                          timeout: 0.1)

        let result = await poller.poll(operationSessionID: Self.operationSessionID, appUserID: Self.appUserID)

        expect(result) == .undetermined
        expect(fetcher.callCount.value) == 1
    }

    func testKeepsAskingThroughAnErrorThatTendsToPass() async {
        let fetcher = StubStatusFetcher(results: [.failure(.networkError(.serverDown())), .status(.succeeded(nil))])

        let result = await self.makePoller(fetcher: fetcher, sleeper: RecordingHostedCheckoutSleeper()).poll(
            operationSessionID: Self.operationSessionID,
            appUserID: Self.appUserID
        )

        expect(result) == .succeeded(nil)
        expect(fetcher.callCount) == 2
    }

    /// The session cannot be asked about at all, which says nothing about whether the customer paid.
    func testGivesNoAnswerWhenTheSessionIsNotFoundForThisCustomer() async {
        let fetcher = StubStatusFetcher(results: [.failure(Self.sessionNotFoundError), .status(.succeeded(nil))])

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

    /// The request cannot be cancelled, but whoever is waiting on it no longer has to.
    func testAnswersRightAwayWhenCancelledWhileARequestIsOut() async {
        let fetcher = UnansweredStatusFetcher()
        let poller = HostedCheckoutPoller(statusFetcher: fetcher,
                                          sleeper: RecordingHostedCheckoutSleeper(),
                                          dateProvider: DateProvider(),
                                          interval: 1,
                                          maxAttempts: 30,
                                          timeout: 45)

        let task = Task<HostedCheckoutPollResult, Never> {
            await poller.poll(operationSessionID: Self.operationSessionID, appUserID: Self.appUserID)
        }
        await expect(fetcher.callCount.value).toEventually(equal(1))
        let cancelledAt = Date()
        task.cancel()

        let result = await task.value

        expect(result) == .undetermined
        expect(Date().timeIntervalSince(cancelledAt)) < 5
    }

    func testAsksNothingMoreWhenCancelledBetweenAttempts() async {
        let fetcher = StubStatusFetcher(results: [.status(.pending)])
        let sleeper = RecordingHostedCheckoutSleeper()
        sleeper.whileSleeping = { withUnsafeCurrentTask { $0?.cancel() } }
        let poller = self.makePoller(fetcher: fetcher, sleeper: sleeper)

        let result = await Task<HostedCheckoutPollResult, Never> {
            await poller.poll(operationSessionID: Self.operationSessionID, appUserID: Self.appUserID)
        }.value

        expect(result) == .undetermined
        expect(fetcher.callCount) == 1
    }

}

private extension HostedCheckoutPollerTests {

    static let sessionNotFoundError: BackendError = .networkError(
        .errorResponse(.init(code: .unknownBackendError,
                             originalCode: 7877,
                             message: "The operation session is invalid."),
                       .notFoundError)
    )

    static func purchase(isSandbox: Bool) -> HostedCheckoutStatusResponse.Purchase {
        return .init(storeTransactionIdentifier: "txn_123",
                     productIdentifier: "monthly",
                     purchaseDate: Date(timeIntervalSince1970: 1609459200),
                     isSandbox: isSandbox)
    }

    func makePoller(fetcher: HostedCheckoutStatusFetching,
                    sleeper: AsyncSleeper) -> HostedCheckoutPoller {
        return self.makePoller(fetcher: fetcher, sleeper: sleeper, maxAttempts: 30)
    }

    func makePoller(fetcher: HostedCheckoutStatusFetching,
                    sleeper: AsyncSleeper,
                    maxAttempts: Int) -> HostedCheckoutPoller {
        return self.makePoller(fetcher: fetcher, sleeper: sleeper, clock: ManualClock(), maxAttempts: maxAttempts)
    }

    func makePoller(fetcher: HostedCheckoutStatusFetching,
                    sleeper: AsyncSleeper,
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

    private let answers: [Answer]
    private(set) var receivedIDs: [String] = []
    private(set) var receivedAppUserIDs: [String] = []
    /// Runs while each request is out, standing in for the time it takes.
    var whileRequesting: () -> Void = {}

    var callCount: Int { return self.receivedIDs.count }

    init(results: [Answer]) {
        self.answers = results
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

/// A request that is still out long after any test using it has finished.
private final class UnansweredStatusFetcher: HostedCheckoutStatusFetching {

    let callCount: Atomic<Int> = .init(0)

    func fetchStatus(operationSessionID: String,
                     appUserID: String) async -> Result<HostedCheckoutStatusResponse, BackendError> {
        self.callCount.modify { $0 += 1 }
        try? await Task.sleep(nanoseconds: 10_000_000_000)
        return .success(.init(status: .succeeded(nil)))
    }

}

/// Records what the loop would have waited, so a poll of any length runs instantly.
private final class RecordingHostedCheckoutSleeper: AsyncSleeper, @unchecked Sendable {

    private(set) var delays: [TimeInterval] = []
    var clock: ManualClock?
    /// Runs on the polling task during each wait.
    var whileSleeping: () -> Void = {}

    func sleep(seconds: TimeInterval) async throws {
        self.delays.append(seconds)
        self.clock?.advance(by: seconds)
        self.whileSleeping()
    }

}
