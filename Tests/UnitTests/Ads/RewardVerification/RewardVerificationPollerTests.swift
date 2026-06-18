//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RewardVerificationPollerTests.swift
//

// swiftlint:disable file_length type_body_length

import XCTest

@_spi(Internal) @_spi(Experimental) @testable import RevenueCat

final class RewardVerificationPollerTests: TestCase {

    // MARK: - Terminal statuses

    func testVerifiedReturnsImmediatelyOnFirstAttemptForwardingPayload() async throws {
        let reward = try XCTUnwrap(VirtualCurrencyReward(code: "coins", amount: 3))
        let statusPoller = StubStatusPoller(statuses: [.verified(.virtualCurrency(reward))])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .verified(let adReward) = outcome, let earnedReward = adReward.virtualCurrency else {
            return XCTFail("Expected .verified(.virtualCurrency), got \(outcome)")
        }
        XCTAssertEqual(earnedReward, reward)
        XCTAssertEqual(statusPoller.receivedIDs, ["tx-1"])
        XCTAssertTrue(sleeper.delays.isEmpty)
    }

    func testFailedReturnsAfterFirstAttempt() async {
        let statusPoller = StubStatusPoller(statuses: [.failed])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .failed(.backendError) = outcome else {
            return XCTFail("Expected .failed(.backendError), got \(outcome)")
        }
        XCTAssertEqual(statusPoller.receivedIDs, ["tx-1"])
        XCTAssertTrue(sleeper.delays.isEmpty)
    }

    func testPendingThenVerifiedSleepsBetweenAttempts() async {
        let statusPoller = StubStatusPoller(statuses: [.pending, .pending, .verified(.noReward)])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .verified(.noReward) = outcome else {
            return XCTFail("Expected .verified(.noReward), got \(outcome)")
        }
        XCTAssertEqual(statusPoller.receivedIDs, ["tx-1", "tx-1", "tx-1"])
        XCTAssertEqual(sleeper.delays, [1.0, 1.0])
    }

    func testAllPendingReturnsFailedAfterMaxAttempts() async {
        let statusPoller = StubStatusPoller(statuses: Array(repeating: .pending, count: 10))
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper, maxAttempts: 10)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .failed(.timeout) = outcome else {
            return XCTFail("Expected .failed(.timeout), got \(outcome)")
        }
        XCTAssertEqual(statusPoller.receivedIDs.count, 10)
        XCTAssertEqual(sleeper.delays.count, 9)
    }

    func testVerifiedOnLastAttemptReturnsVerified() async {
        let statusPoller = StubStatusPoller(
            statuses: Array(repeating: .pending, count: 9) + [.verified(.noReward)]
        )
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper, maxAttempts: 10)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .verified(.noReward) = outcome else {
            return XCTFail("Expected .verified(.noReward), got \(outcome)")
        }
        XCTAssertEqual(statusPoller.receivedIDs.count, 10)
        XCTAssertEqual(sleeper.delays.count, 9)
    }

    func testFailedOnLaterAttemptReturnsFailedWithoutAdditionalPolls() async {
        let statusPoller = StubStatusPoller(statuses: [.pending, .pending, .failed])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper, maxAttempts: 10)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .failed(.backendError) = outcome else {
            return XCTFail("Expected .failed(.backendError), got \(outcome)")
        }
        XCTAssertEqual(statusPoller.receivedIDs.count, 3)
        XCTAssertEqual(sleeper.delays.count, 2)
    }

    func testUnknownIsTreatedLikePendingAndKeepsPolling() async {
        let statusPoller = StubStatusPoller(statuses: [.unknown, .unknown, .verified(.noReward)])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .verified(.noReward) = outcome else {
            return XCTFail("Expected .verified(.noReward), got \(outcome)")
        }
        XCTAssertEqual(statusPoller.receivedIDs.count, 3)
        XCTAssertEqual(sleeper.delays.count, 2)
    }

    // MARK: - Transient connection-level retry path

    func testTransientNetworkErrorOnFirstAttemptIsRetried() async {
        let statusPoller = ScriptedStatusPoller(steps: [
            .throwError(makeConnectivityError()),
            .status(.verified(.noReward))
        ])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .verified(.noReward) = outcome else {
            return XCTFail("Expected .verified(.noReward), got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 2)
        XCTAssertEqual(sleeper.delays.count, 1, "A transient throw should still consume an inter-attempt sleep")
    }

    func testTransientNetworkErrorAfterPendingIsRetried() async {
        let statusPoller = ScriptedStatusPoller(steps: [
            .status(.pending),
            .throwError(makeConnectivityError()),
            .status(.verified(.noReward))
        ])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .verified(.noReward) = outcome else {
            return XCTFail("Expected .verified(.noReward), got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 3)
        XCTAssertEqual(sleeper.delays.count, 2)
    }

    func testEveryAttemptThrowingTransientExhaustsBudgetAndReturnsFailed() async {
        let statusPoller = ThrowingStatusPoller(
            error: makePollingError(statusCode: 500, backendCode: .internalServerError)
        )
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper, maxAttempts: 5)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .failed(.timeout) = outcome else {
            return XCTFail(
                "Expected .failed(.timeout) after exhausting the budget on transient throws, got \(outcome)"
            )
        }
        XCTAssertEqual(statusPoller.callCount, 5,
                       "Every attempt should have been tried; transient throws are not terminal")
        XCTAssertEqual(sleeper.delays.count, 4)
    }

    func testMixedPendingAndTransientThrowsExhaustsBudgetAndReturnsFailed() async {
        let statusPoller = ScriptedStatusPoller(steps: [
            .status(.pending),
            .throwError(makeConnectivityError()),
            .status(.pending),
            .throwError(makeConnectivityError()),
            .status(.pending)
        ])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper, maxAttempts: 5)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .failed(.timeout) = outcome else {
            return XCTFail("Expected .failed(.timeout), got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 5)
        XCTAssertEqual(sleeper.delays.count, 4)
    }

    func testTransientErrorsAreRetried() async {
        // Connection-level failure (no HTTP status) and 5xx server responses are both transient.
        let transient: [BackendError] = [
            makeConnectivityError(),
            makePollingError(statusCode: 500, backendCode: .internalServerError)
        ]
        for error in transient {
            let statusPoller = ScriptedStatusPoller(steps: [
                .throwError(error),
                .status(.verified(.noReward))
            ])
            let sut = makePoller(statusPoller: statusPoller, sleeper: RecordingSleeper())

            let outcome = await sut.run(clientTransactionID: "tx-1")

            guard case .verified(.noReward) = outcome else {
                return XCTFail("Expected .verified for transient error \(error), got \(outcome)")
            }
            XCTAssertEqual(statusPoller.callCount, 2, "Transient error \(error) should have been retried once")
        }
    }

    // MARK: - HTTP-status-keyed retry (5xx transient, 4xx terminal)

    func testParseableServerErrorIsRetried() async {
        let statusPoller = ScriptedStatusPoller(steps: [
            .throwError(makePollingError(statusCode: 500, backendCode: .internalServerError)),
            .status(.verified(.noReward))
        ])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .verified(.noReward) = outcome else {
            return XCTFail("Expected .verified(.noReward), got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 2, "A 5xx should be retried")
    }

    func testUnparseableServerErrorIsRetried() async {
        // Empty 5xx maps to `.unknownError` (not a transient code) but must still be retried on the 5xx status.
        let statusPoller = ScriptedStatusPoller(steps: [
            .throwError(makePollingError(statusCode: 503, backendCode: .unknownError)),
            .status(.verified(.noReward))
        ])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .verified(.noReward) = outcome else {
            return XCTFail("Expected .verified(.noReward), got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 2, "An unparseable 5xx should still be retried")
    }

    func testClientErrorIsNotRetriedAndFailsFastAsBackendError() async {
        // A 4xx must fail fast as `.backendError`, not be retried to a misleading `.timeout`.
        let statusPoller = ThrowingStatusPoller(
            error: makePollingError(statusCode: 400, backendCode: .badRequest)
        )
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .failed(.backendError) = outcome else {
            return XCTFail("Expected .failed(.backendError), got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 1, "A 4xx must not be retried")
        XCTAssertTrue(sleeper.delays.isEmpty)
    }

    func testServerErrorAfterPendingIsRetried() async {
        let statusPoller = ScriptedStatusPoller(steps: [
            .status(.pending),
            .throwError(makePollingError(statusCode: 502, backendCode: .unknownError)),
            .status(.verified(.noReward))
        ])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .verified(.noReward) = outcome else {
            return XCTFail("Expected .verified(.noReward), got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 3)
    }

    // MARK: - Terminal `BackendError` path

    func testTerminalBackendErrorReturnsFailedWithoutRetrying() async {
        let statusPoller = ThrowingStatusPoller(error: makeTerminalBackendError())
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .failed(.backendError) = outcome else {
            return XCTFail("Expected .failed(.backendError), got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 1, "A terminal BackendError must not be retried")
        XCTAssertTrue(sleeper.delays.isEmpty)
    }

    func testNonNetworkBackendErrorReturnsFailedWithoutRetrying() async {
        // A BackendError without an underlying NetworkError carries no transient signal.
        let statusPoller = ThrowingStatusPoller(error: BackendError.unexpectedBackendResponse(.customerInfoNil))
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .failed(.backendError) = outcome else {
            return XCTFail("Expected .failed(.backendError), got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 1)
    }

    func testPendingThenTerminalBackendErrorReturnsFailedWithoutAdditionalPolls() async {
        let statusPoller = ScriptedStatusPoller(steps: [
            .status(.pending),
            .throwError(makeTerminalBackendError())
        ])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .failed(.backendError) = outcome else {
            return XCTFail("Expected .failed(.backendError), got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 2)
    }

    // MARK: - Catch-all behaviour

    func testCancellationErrorFromPollStatusReturnsFailedWithoutRetrying() async {
        let statusPoller = ThrowingStatusPoller(error: CancellationError())
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .failed(.unknown) = outcome else {
            return XCTFail("Expected .failed(.unknown), got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 1, "Cancellation throws are not retried")
        XCTAssertTrue(sleeper.delays.isEmpty)
    }

    func testUnrecognisedErrorTypeFromPollStatusReturnsFailedWithoutRetrying() async {
        let statusPoller = ThrowingStatusPoller(error: PollerSentinelError())
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .failed(.unknown) = outcome else {
            return XCTFail("Expected .failed(.unknown), got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 1, "Unrecognised throws are not retried")
    }

    func testCancellationBeforeFirstAttemptShortCircuitsLoopWithoutPolling() async {
        let statusPoller = StubStatusPoller(statuses: Array(repeating: .pending, count: 10))
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper, maxAttempts: 10)

        let task = Task<RewardVerification.Outcome, Never> {
            await sut.run(clientTransactionID: "tx-1")
        }
        task.cancel()
        let outcome = await task.value

        guard case .failed(.unknown) = outcome else {
            return XCTFail("Expected .failed(.unknown) after cancellation, got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 0,
                       "Cancellation must short-circuit before any pollStatus call")
        XCTAssertTrue(sleeper.delays.isEmpty)
    }

    func testSleeperFailureIsSwallowedAndLoopContinuesToNextAttempt() async {
        let statusPoller = StubStatusPoller(statuses: [.pending, .verified(.noReward)])
        let sleeper = ThrowingSleeper(error: PollerSentinelError())
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .verified(.noReward) = outcome else {
            return XCTFail("Expected .verified(.noReward) after sleeper failure was swallowed, got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 2)
        XCTAssertEqual(sleeper.callCount, 1)
    }

    // MARK: - Boundaries

    func testMaxAttemptsZeroReturnsFailedWithoutAnyPollOrSleep() async {
        let statusPoller = StubStatusPoller(statuses: [])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper, maxAttempts: 0)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .failed(.timeout) = outcome else {
            return XCTFail("Expected .failed(.timeout), got \(outcome)")
        }
        XCTAssertTrue(statusPoller.receivedIDs.isEmpty)
        XCTAssertTrue(sleeper.delays.isEmpty)
    }

    func testMaxAttemptsOnePollsOnceWithoutSleeping() async {
        let statusPoller = StubStatusPoller(statuses: [.pending])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper, maxAttempts: 1)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .failed(.timeout) = outcome else {
            return XCTFail("Expected .failed(.timeout), got \(outcome)")
        }
        XCTAssertEqual(statusPoller.receivedIDs, ["tx-1"])
        XCTAssertTrue(sleeper.delays.isEmpty)
    }

    // MARK: - Defaults

    func testDefaultMaxAttemptsIsTen() {
        let sut = RewardVerification.Poller(
            statusPoller: StubStatusPoller(statuses: []),
            sleeper: RecordingSleeper()
        )
        XCTAssertEqual(sut.maxAttempts, 10)
    }

    func testDefaultJitterAlwaysWithinExpectedBounds() {
        let jitter = RewardVerification.Jitter.default
        for _ in 0..<2000 {
            let delay = jitter.sample()
            XCTAssertGreaterThanOrEqual(delay, RewardVerification.Jitter.defaultLowerBound)
            XCTAssertLessThanOrEqual(delay, RewardVerification.Jitter.defaultUpperBound)
        }
    }

    func testEachJitteredDelayUsedByLoopIsWithinDefaultBounds() async {
        let statusPoller = StubStatusPoller(statuses: Array(repeating: .pending, count: 10))
        let sleeper = RecordingSleeper()
        let sut = RewardVerification.Poller(
            statusPoller: statusPoller,
            sleeper: sleeper,
            jitter: .default,
            maxAttempts: 10
        )

        _ = await sut.run(clientTransactionID: "tx-1")

        XCTAssertEqual(sleeper.delays.count, 9)
        for delay in sleeper.delays {
            XCTAssertGreaterThanOrEqual(delay, RewardVerification.Jitter.defaultLowerBound)
            XCTAssertLessThanOrEqual(delay, RewardVerification.Jitter.defaultUpperBound)
        }
    }

    func testJitterIsSampledOncePerInterAttemptSleep() async {
        let statusPoller = StubStatusPoller(statuses: Array(repeating: .pending, count: 5))
        let sleeper = RecordingSleeper()
        let counter = PollerJitterCounter()
        let jitter = RewardVerification.Jitter {
            counter.increment()
            return 1.0
        }
        let sut = RewardVerification.Poller(
            statusPoller: statusPoller,
            sleeper: sleeper,
            jitter: jitter,
            maxAttempts: 5
        )

        _ = await sut.run(clientTransactionID: "tx-1")

        XCTAssertEqual(counter.value, 4)
        XCTAssertEqual(sleeper.delays.count, 4)
    }
}
