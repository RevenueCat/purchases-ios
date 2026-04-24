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

    func testVerifiedReturnsImmediatelyOnFirstAttemptForwardingPayload() async throws {
        let reward = VirtualCurrencyReward(code: "coins", amount: 3)
        let statusPoller = StubStatusPoller(statuses: [.verified(.virtualCurrency(reward))])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = try await sut.run(clientTransactionID: "tx-1")

        guard case .verified(.virtualCurrency(let earnedReward)) = outcome else {
            return XCTFail("Expected .verified(.virtualCurrency), got \(outcome)")
        }
        XCTAssertEqual(earnedReward, reward)
        XCTAssertEqual(statusPoller.receivedIDs, ["tx-1"])
        XCTAssertTrue(sleeper.delays.isEmpty)
    }

    func testFailedReturnsAfterFirstAttempt() async throws {
        let statusPoller = StubStatusPoller(statuses: [.failed])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = try await sut.run(clientTransactionID: "tx-1")

        guard case .failed = outcome else {
            return XCTFail("Expected .failed, got \(outcome)")
        }
        XCTAssertEqual(statusPoller.receivedIDs, ["tx-1"])
        XCTAssertTrue(sleeper.delays.isEmpty)
    }

    func testPendingThenVerifiedSleepsBetweenAttempts() async throws {
        let statusPoller = StubStatusPoller(statuses: [.pending, .pending, .verified(.noReward)])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = try await sut.run(clientTransactionID: "tx-1")

        guard case .verified(.noReward) = outcome else {
            return XCTFail("Expected .verified(.noReward), got \(outcome)")
        }
        XCTAssertEqual(statusPoller.receivedIDs, ["tx-1", "tx-1", "tx-1"])
        XCTAssertEqual(sleeper.delays, [1.0, 1.0])
    }

    func testAllPendingReturnsFailedAfterMaxAttempts() async throws {
        let statusPoller = StubStatusPoller(statuses: Array(repeating: .pending, count: 10))
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper, maxAttempts: 10)

        let outcome = try await sut.run(clientTransactionID: "tx-1")

        guard case .failed = outcome else {
            return XCTFail("Expected .failed, got \(outcome)")
        }
        XCTAssertEqual(statusPoller.receivedIDs.count, 10)
        XCTAssertEqual(sleeper.delays.count, 9)
    }

    func testVerifiedOnLastAttemptReturnsVerified() async throws {
        let statusPoller = StubStatusPoller(
            statuses: Array(repeating: .pending, count: 9) + [.verified(.noReward)]
        )
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper, maxAttempts: 10)

        let outcome = try await sut.run(clientTransactionID: "tx-1")

        guard case .verified(.noReward) = outcome else {
            return XCTFail("Expected .verified(.noReward), got \(outcome)")
        }
        XCTAssertEqual(statusPoller.receivedIDs.count, 10)
        XCTAssertEqual(sleeper.delays.count, 9)
    }

    func testFailedOnLaterAttemptReturnsFailedWithoutAdditionalPolls() async throws {
        let statusPoller = StubStatusPoller(statuses: [.pending, .pending, .failed])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper, maxAttempts: 10)

        let outcome = try await sut.run(clientTransactionID: "tx-1")

        guard case .failed = outcome else {
            return XCTFail("Expected .failed, got \(outcome)")
        }
        XCTAssertEqual(statusPoller.receivedIDs.count, 3)
        XCTAssertEqual(sleeper.delays.count, 2)
    }

    func testUnknownIsTreatedLikePendingAndKeepsPolling() async throws {
        let statusPoller = StubStatusPoller(statuses: [.unknown, .unknown, .verified(.noReward)])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = try await sut.run(clientTransactionID: "tx-1")

        guard case .verified(.noReward) = outcome else {
            return XCTFail("Expected .verified(.noReward), got \(outcome)")
        }
        XCTAssertEqual(statusPoller.receivedIDs.count, 3)
        XCTAssertEqual(sleeper.delays.count, 2)
    }

    // MARK: - Transient `ErrorCode` retry path

    func testTransientErrorCodeOnFirstAttemptIsRetried() async throws {
        let statusPoller = ScriptedStatusPoller(steps: [
            .throwError(ErrorCode.networkError),
            .status(.verified(.noReward))
        ])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = try await sut.run(clientTransactionID: "tx-1")

        guard case .verified(.noReward) = outcome else {
            return XCTFail("Expected .verified(.noReward), got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 2)
        XCTAssertEqual(sleeper.delays.count, 1, "A transient throw should still consume an inter-attempt sleep")
    }

    func testTransientErrorCodeAfterPendingIsRetried() async throws {
        let statusPoller = ScriptedStatusPoller(steps: [
            .status(.pending),
            .throwError(ErrorCode.offlineConnectionError),
            .status(.verified(.noReward))
        ])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = try await sut.run(clientTransactionID: "tx-1")

        guard case .verified(.noReward) = outcome else {
            return XCTFail("Expected .verified(.noReward), got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 3)
        XCTAssertEqual(sleeper.delays.count, 2)
    }

    func testEveryAttemptThrowingTransientExhaustsBudgetAndReturnsFailed() async throws {
        let statusPoller = ThrowingStatusPoller(error: ErrorCode.unknownBackendError)
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper, maxAttempts: 5)

        let outcome = try await sut.run(clientTransactionID: "tx-1")

        guard case .failed = outcome else {
            return XCTFail("Expected .failed after exhausting the budget on transient throws, got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 5,
                       "Every attempt should have been tried; transient throws are not terminal")
        XCTAssertEqual(sleeper.delays.count, 4)
    }

    func testMixedPendingAndTransientThrowsExhaustsBudgetAndReturnsFailed() async throws {
        let statusPoller = ScriptedStatusPoller(steps: [
            .status(.pending),
            .throwError(ErrorCode.networkError),
            .status(.pending),
            .throwError(ErrorCode.offlineConnectionError),
            .status(.pending)
        ])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper, maxAttempts: 5)

        let outcome = try await sut.run(clientTransactionID: "tx-1")

        guard case .failed = outcome else {
            return XCTFail("Expected .failed, got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 5)
        XCTAssertEqual(sleeper.delays.count, 4)
    }

    func testEachTransientErrorCodeIsRetried() async throws {
        let transient: [ErrorCode] = [.networkError, .offlineConnectionError, .unknownBackendError]
        for code in transient {
            let statusPoller = ScriptedStatusPoller(steps: [
                .throwError(code),
                .status(.verified(.noReward))
            ])
            let sut = makePoller(statusPoller: statusPoller, sleeper: RecordingSleeper())

            let outcome = try await sut.run(clientTransactionID: "tx-1")

            guard case .verified(.noReward) = outcome else {
                return XCTFail("Expected .verified for transient code \(code), got \(outcome)")
            }
            XCTAssertEqual(statusPoller.callCount, 2, "Transient code \(code) should have been retried once")
        }
    }

    // MARK: - Terminal `ErrorCode` path

    func testSignatureVerificationFailedReturnsFailedWithoutRetrying() async throws {
        let statusPoller = ThrowingStatusPoller(error: ErrorCode.signatureVerificationFailed)
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = try await sut.run(clientTransactionID: "tx-1")

        guard case .failed = outcome else {
            return XCTFail("Expected .failed, got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 1, "Terminal ErrorCode must not be retried")
        XCTAssertTrue(sleeper.delays.isEmpty)
    }

    func testUnexpectedBackendResponseErrorReturnsFailedWithoutRetrying() async throws {
        let statusPoller = ThrowingStatusPoller(error: ErrorCode.unexpectedBackendResponseError)
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = try await sut.run(clientTransactionID: "tx-1")

        guard case .failed = outcome else {
            return XCTFail("Expected .failed, got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 1)
    }

    func testApiEndpointBlockedErrorReturnsFailedWithoutRetrying() async throws {
        // DNS blocking — retrying within ~10s won't unblock the user; surface `.failed` immediately.
        let statusPoller = ThrowingStatusPoller(error: ErrorCode.apiEndpointBlockedError)
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = try await sut.run(clientTransactionID: "tx-1")

        guard case .failed = outcome else {
            return XCTFail("Expected .failed, got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 1)
    }

    func testPendingThenTerminalErrorCodeReturnsFailedWithoutAdditionalPolls() async throws {
        let statusPoller = ScriptedStatusPoller(steps: [
            .status(.pending),
            .throwError(ErrorCode.signatureVerificationFailed)
        ])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let outcome = try await sut.run(clientTransactionID: "tx-1")

        guard case .failed = outcome else {
            return XCTFail("Expected .failed, got \(outcome)")
        }
        XCTAssertEqual(statusPoller.callCount, 2)
    }

    // MARK: - Propagating throws (not handled by Poller)

    func testCancellationErrorFromPollStatusPropagates() async {
        let statusPoller = ThrowingStatusPoller(error: CancellationError())
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        do {
            _ = try await sut.run(clientTransactionID: "tx-1")
            XCTFail("Expected CancellationError to propagate")
        } catch is CancellationError {
            // expected
        } catch {
            XCTFail("Expected CancellationError, got \(error)")
        }
        XCTAssertEqual(statusPoller.callCount, 1)
        XCTAssertTrue(sleeper.delays.isEmpty)
    }

    func testCancellationErrorFromSleeperPropagates() async {
        let statusPoller = StubStatusPoller(statuses: [.pending, .verified(.noReward)])
        let sleeper = ThrowingSleeper(error: CancellationError())
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        do {
            _ = try await sut.run(clientTransactionID: "tx-1")
            XCTFail("Expected CancellationError to propagate")
        } catch is CancellationError {
            // expected
        } catch {
            XCTFail("Expected CancellationError, got \(error)")
        }
        XCTAssertEqual(statusPoller.callCount, 1)
        XCTAssertEqual(sleeper.callCount, 1)
    }

    func testUnrecognisedErrorTypeFromPollStatusPropagates() async {
        // An error type that isn't `ErrorCode` and isn't `CancellationError` shouldn't reach
        // the loop in production, but if it does the Poller surfaces it to the caller (which
        // owns the safety net). Verifies we do NOT swallow unknown throws as a transient retry.
        let sentinel = SentinelError()
        let statusPoller = ThrowingStatusPoller(error: sentinel)
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        do {
            _ = try await sut.run(clientTransactionID: "tx-1")
            XCTFail("Expected SentinelError to propagate")
        } catch let error as SentinelError {
            XCTAssertIdentical(error, sentinel)
        } catch {
            XCTFail("Expected SentinelError, got \(error)")
        }
        XCTAssertEqual(statusPoller.callCount, 1, "Unrecognised throws are not retried")
    }

    func testUnrecognisedErrorTypeFromSleeperPropagates() async {
        let sentinel = SentinelError()
        let statusPoller = StubStatusPoller(statuses: [.pending, .verified(.noReward)])
        let sleeper = ThrowingSleeper(error: sentinel)
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        do {
            _ = try await sut.run(clientTransactionID: "tx-1")
            XCTFail("Expected SentinelError from sleeper to propagate")
        } catch let error as SentinelError {
            XCTAssertIdentical(error, sentinel)
        } catch {
            XCTFail("Expected SentinelError, got \(error)")
        }
        XCTAssertEqual(statusPoller.callCount, 1, "First poll succeeded; sleep failure aborted the run")
        XCTAssertEqual(sleeper.callCount, 1)
    }

    // MARK: - Boundaries

    func testMaxAttemptsZeroReturnsFailedWithoutAnyPollOrSleep() async throws {
        let statusPoller = StubStatusPoller(statuses: [])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper, maxAttempts: 0)

        let outcome = try await sut.run(clientTransactionID: "tx-1")

        guard case .failed = outcome else {
            return XCTFail("Expected .failed, got \(outcome)")
        }
        XCTAssertTrue(statusPoller.receivedIDs.isEmpty)
        XCTAssertTrue(sleeper.delays.isEmpty)
    }

    func testMaxAttemptsOnePollsOnceWithoutSleeping() async throws {
        let statusPoller = StubStatusPoller(statuses: [.pending])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper, maxAttempts: 1)

        let outcome = try await sut.run(clientTransactionID: "tx-1")

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

    func testEachJitteredDelayUsedByLoopIsWithinDefaultBounds() async throws {
        let statusPoller = StubStatusPoller(statuses: Array(repeating: .pending, count: 10))
        let sleeper = RecordingSleeper()
        let sut = RewardVerification.Poller(
            statusPoller: statusPoller,
            sleeper: sleeper,
            jitter: .default,
            maxAttempts: 10
        )

        _ = try await sut.run(clientTransactionID: "tx-1")

        XCTAssertEqual(sleeper.delays.count, 9)
        for delay in sleeper.delays {
            XCTAssertGreaterThanOrEqual(delay, RewardVerification.Jitter.defaultLowerBound)
            XCTAssertLessThanOrEqual(delay, RewardVerification.Jitter.defaultUpperBound)
        }
    }

    func testJitterIsSampledOncePerInterAttemptSleep() async throws {
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

        _ = try await sut.run(clientTransactionID: "tx-1")

        XCTAssertEqual(counter.value, 4)
        XCTAssertEqual(sleeper.delays.count, 4)
    }
}

// swiftlint:enable type_body_length

#endif
