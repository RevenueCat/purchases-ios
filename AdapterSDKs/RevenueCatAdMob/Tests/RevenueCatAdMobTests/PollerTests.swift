// swiftlint:disable file_length

import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Internal) import RevenueCat
@testable import RevenueCatAdMob

// swiftlint:disable type_body_length

@available(iOS 15.0, *)
final class PollerTests: AdapterTestCase {

    // MARK: - Terminal statuses

    func testVerifiedReturnsImmediatelyOnFirstAttemptForwardingPayload() async {
        let reward = VirtualCurrencyReward(code: "coins", amount: 3)
        let statusPoller = StubStatusPoller(statuses: [.verified(.virtualCurrency(reward))])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .verified(.virtualCurrency(let earnedReward)) = outcome else {
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

        guard case .failed = outcome else {
            return XCTFail("Expected .failed, got \(outcome)")
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

        guard case .failed = outcome else {
            return XCTFail("Expected .failed, got \(outcome)")
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

        guard case .failed = outcome else {
            return XCTFail("Expected .failed, got \(outcome)")
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

    // MARK: - Transient `ErrorCode` retry path

    func testTransientErrorCodeOnFirstAttemptIsRetried() async {
        let statusPoller = ScriptedStatusPoller(steps: [
            .throwError(ErrorCode.networkError),
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

    func testTransientErrorCodeAfterPendingIsRetried() async {
        let statusPoller = ScriptedStatusPoller(steps: [
            .status(.pending),
            .throwError(ErrorCode.offlineConnectionError),
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
        let statusPoller = ThrowingStatusPoller(error: ErrorCode.unknownBackendError)
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper, maxAttempts: 5)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .failed = outcome else {
            return XCTFail("Expected .failed after exhausting the budget on transient throws, got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 5,
                       "Every attempt should have been tried; transient throws are not terminal")
        XCTAssertEqual(sleeper.delays.count, 4)
    }

    func testMixedPendingAndTransientThrowsExhaustsBudgetAndReturnsFailed() async {
        let statusPoller = ScriptedStatusPoller(steps: [
            .status(.pending),
            .throwError(ErrorCode.networkError),
            .status(.pending),
            .throwError(ErrorCode.offlineConnectionError),
            .status(.pending)
        ])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper, maxAttempts: 5)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .failed = outcome else {
            return XCTFail("Expected .failed, got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 5)
        XCTAssertEqual(sleeper.delays.count, 4)
    }

    func testEachTransientErrorCodeIsRetried() async {
        let transient: [ErrorCode] = [.networkError, .offlineConnectionError, .unknownBackendError]
        for code in transient {
            let statusPoller = ScriptedStatusPoller(steps: [
                .throwError(code),
                .status(.verified(.noReward))
            ])
            let sut = makePoller(statusPoller: statusPoller, sleeper: RecordingSleeper())

            let outcome = await sut.run(clientTransactionID: "tx-1")

            guard case .verified(.noReward) = outcome else {
                return XCTFail("Expected .verified for transient code \(code), got \(outcome)")
            }
            XCTAssertEqual(statusPoller.callCount, 2, "Transient code \(code) should have been retried once")
        }
    }

    // MARK: - Terminal `ErrorCode` path

    func testSignatureVerificationFailedReturnsFailedWithoutRetrying() async {
        let statusPoller = ThrowingStatusPoller(error: ErrorCode.signatureVerificationFailed)
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .failed = outcome else {
            return XCTFail("Expected .failed, got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 1, "Terminal ErrorCode must not be retried")
        XCTAssertTrue(sleeper.delays.isEmpty)
    }

    func testUnexpectedBackendResponseErrorReturnsFailedWithoutRetrying() async {
        let statusPoller = ThrowingStatusPoller(error: ErrorCode.unexpectedBackendResponseError)
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .failed = outcome else {
            return XCTFail("Expected .failed, got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 1)
    }

    func testApiEndpointBlockedErrorReturnsFailedWithoutRetrying() async {
        // DNS blocking — retrying within ~10s won't unblock the user; surface `.failed` immediately.
        let statusPoller = ThrowingStatusPoller(error: ErrorCode.apiEndpointBlockedError)
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .failed = outcome else {
            return XCTFail("Expected .failed, got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 1)
    }

    func testPendingThenTerminalErrorCodeReturnsFailedWithoutAdditionalPolls() async {
        let statusPoller = ScriptedStatusPoller(steps: [
            .status(.pending),
            .throwError(ErrorCode.signatureVerificationFailed)
        ])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .failed = outcome else {
            return XCTFail("Expected .failed, got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 2)
    }

    // MARK: - Catch-all behaviour

    func testCancellationErrorFromPollStatusReturnsFailedWithoutRetrying() async {
        // `Poller` does not distinguish `CancellationError` from any other non-transient throw —
        // both collapse to `.failed`. `Dispatcher` is what swallows the delivery when the
        // surrounding `Task` is actually cancelled.
        let statusPoller = ThrowingStatusPoller(error: CancellationError())
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .failed = outcome else {
            return XCTFail("Expected .failed, got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 1, "Cancellation throws are not retried")
        XCTAssertTrue(sleeper.delays.isEmpty)
    }

    func testUnrecognisedErrorTypeFromPollStatusReturnsFailedWithoutRetrying() async {
        let statusPoller = ThrowingStatusPoller(error: SentinelError())
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .failed = outcome else {
            return XCTFail("Expected .failed, got \(outcome)")
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

        guard case .failed = outcome else {
            return XCTFail("Expected .failed after cancellation, got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 0,
                       "Cancellation must short-circuit before any pollStatus call")
        XCTAssertTrue(sleeper.delays.isEmpty)
    }

    func testSleeperFailureIsSwallowedAndLoopContinuesToNextAttempt() async {
        // Inter-attempt sleeps use `try?`, so a throwing sleeper does not abort the run.
        let statusPoller = StubStatusPoller(statuses: [.pending, .verified(.noReward)])
        let sleeper = ThrowingSleeper(error: SentinelError())
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

        guard case .failed = outcome else {
            return XCTFail("Expected .failed, got \(outcome)")
        }
        XCTAssertTrue(statusPoller.receivedIDs.isEmpty)
        XCTAssertTrue(sleeper.delays.isEmpty)
    }

    func testMaxAttemptsOnePollsOnceWithoutSleeping() async {
        let statusPoller = StubStatusPoller(statuses: [.pending])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper, maxAttempts: 1)

        let outcome = await sut.run(clientTransactionID: "tx-1")

        guard case .failed = outcome else {
            return XCTFail("Expected .failed, got \(outcome)")
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
        let counter = Counter()
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

// swiftlint:enable type_body_length

#endif
