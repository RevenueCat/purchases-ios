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
        return HostedCheckoutPoller(statusFetcher: fetcher,
                                    sleeper: sleeper,
                                    interval: 1,
                                    maxAttempts: maxAttempts)
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

    var callCount: Int { return self.receivedIDs.count }

    init(results: [Answer]) {
        self.answers = results
    }

    func fetchStatus(operationSessionID: String,
                     appUserID: String) async -> Result<HostedCheckoutStatusResponse, BackendError> {
        let index = min(self.receivedIDs.count, self.answers.count - 1)
        self.receivedIDs.append(operationSessionID)
        self.receivedAppUserIDs.append(appUserID)

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

    func sleep(seconds: TimeInterval) async throws {
        self.delays.append(seconds)
    }

}
