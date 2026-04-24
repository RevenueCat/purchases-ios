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

        let result = await sut.run(clientTransactionID: "tx-1")

        guard case .outcome(.verified(.virtualCurrency(let earnedReward))) = result else {
            return XCTFail("Expected .outcome(.verified(.virtualCurrency)), got \(result)")
        }
        XCTAssertEqual(earnedReward, reward)
        XCTAssertEqual(statusPoller.receivedIDs, ["tx-1"])
        XCTAssertTrue(sleeper.delays.isEmpty)
    }

    func testFailedReturnsAfterFirstAttempt() async {
        let statusPoller = StubStatusPoller(statuses: [.failed])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let result = await sut.run(clientTransactionID: "tx-1")

        guard case .outcome(.failed) = result else {
            return XCTFail("Expected .outcome(.failed), got \(result)")
        }
        XCTAssertEqual(statusPoller.receivedIDs, ["tx-1"])
        XCTAssertTrue(sleeper.delays.isEmpty)
    }

    func testPendingThenVerifiedSleepsBetweenAttempts() async {
        let statusPoller = StubStatusPoller(statuses: [.pending, .pending, .verified(.noReward)])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let result = await sut.run(clientTransactionID: "tx-1")

        guard case .outcome(.verified(.noReward)) = result else {
            return XCTFail("Expected .outcome(.verified(.noReward)), got \(result)")
        }
        XCTAssertEqual(statusPoller.receivedIDs, ["tx-1", "tx-1", "tx-1"])
        XCTAssertEqual(sleeper.delays, [1.0, 1.0])
    }

    func testAllPendingReturnsFailedAfterMaxAttempts() async {
        let statusPoller = StubStatusPoller(statuses: Array(repeating: .pending, count: 10))
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper, maxAttempts: 10)

        let result = await sut.run(clientTransactionID: "tx-1")

        guard case .outcome(.failed) = result else {
            return XCTFail("Expected .outcome(.failed), got \(result)")
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

        let result = await sut.run(clientTransactionID: "tx-1")

        guard case .outcome(.verified(.noReward)) = result else {
            return XCTFail("Expected .outcome(.verified(.noReward)), got \(result)")
        }
        XCTAssertEqual(statusPoller.receivedIDs.count, 10)
        XCTAssertEqual(sleeper.delays.count, 9)
    }

    func testFailedOnLaterAttemptReturnsFailedWithoutAdditionalPolls() async {
        let statusPoller = StubStatusPoller(statuses: [.pending, .pending, .failed])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper, maxAttempts: 10)

        let result = await sut.run(clientTransactionID: "tx-1")

        guard case .outcome(.failed) = result else {
            return XCTFail("Expected .outcome(.failed), got \(result)")
        }
        XCTAssertEqual(statusPoller.receivedIDs.count, 3)
        XCTAssertEqual(sleeper.delays.count, 2)
    }

    func testUnknownIsTreatedLikePendingAndKeepsPolling() async {
        let statusPoller = StubStatusPoller(statuses: [.unknown, .unknown, .verified(.noReward)])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let result = await sut.run(clientTransactionID: "tx-1")

        guard case .outcome(.verified(.noReward)) = result else {
            return XCTFail("Expected .outcome(.verified(.noReward)), got \(result)")
        }
        XCTAssertEqual(statusPoller.receivedIDs.count, 3)
        XCTAssertEqual(sleeper.delays.count, 2)
    }

    // MARK: - Transient error path

    func testThrownErrorOnFirstAttemptIsTreatedAsTransientAndRetried() async {
        let statusPoller = ScriptedStatusPoller(steps: [
            .throwError(SentinelError()),
            .status(.verified(.noReward))
        ])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let result = await sut.run(clientTransactionID: "tx-1")

        guard case .outcome(.verified(.noReward)) = result else {
            return XCTFail("Expected .outcome(.verified(.noReward)), got \(result)")
        }
        XCTAssertEqual(statusPoller.callCount, 2)
        XCTAssertEqual(sleeper.delays.count, 1, "A transient throw should still consume an inter-attempt sleep")
    }

    func testThrownErrorAfterPendingIsTreatedAsTransientAndRetried() async {
        let statusPoller = ScriptedStatusPoller(steps: [
            .status(.pending),
            .throwError(SentinelError()),
            .status(.verified(.noReward))
        ])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let result = await sut.run(clientTransactionID: "tx-1")

        guard case .outcome(.verified(.noReward)) = result else {
            return XCTFail("Expected .outcome(.verified(.noReward)), got \(result)")
        }
        XCTAssertEqual(statusPoller.callCount, 3)
        XCTAssertEqual(sleeper.delays.count, 2)
    }

    func testEveryAttemptThrowingExhaustsBudgetAndReturnsFailed() async {
        let statusPoller = ThrowingStatusPoller(error: SentinelError())
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper, maxAttempts: 5)

        let result = await sut.run(clientTransactionID: "tx-1")

        guard case .outcome(.failed) = result else {
            return XCTFail("Expected .outcome(.failed) after exhausting the budget on transient throws, got \(result)")
        }
        XCTAssertEqual(statusPoller.callCount, 5,
                       "Every attempt should have been tried; transient throws are not terminal")
        XCTAssertEqual(sleeper.delays.count, 4)
    }

    func testMixedPendingAndThrowsExhaustsBudgetAndReturnsFailed() async {
        let statusPoller = ScriptedStatusPoller(steps: [
            .status(.pending),
            .throwError(SentinelError()),
            .status(.pending),
            .throwError(SentinelError()),
            .status(.pending)
        ])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper, maxAttempts: 5)

        let result = await sut.run(clientTransactionID: "tx-1")

        guard case .outcome(.failed) = result else {
            return XCTFail("Expected .outcome(.failed), got \(result)")
        }
        XCTAssertEqual(statusPoller.callCount, 5)
        XCTAssertEqual(sleeper.delays.count, 4)
    }

    func testTransientSleeperErrorBetweenAttemptsIsAbsorbedAndPollContinues() async {
        // Custom sleeper that throws on the first sleep and succeeds on subsequent ones, to
        // verify the loop doesn't bail out on a non-cancellation sleeper failure.
        // When a sleep throws, the loop skips that attempt's poll (a slot is consumed against
        // the budget) and tries again next iteration.
        let sleeper = FlakySleeper(throwsOnAttempts: [1])
        let statusPoller = StubStatusPoller(statuses: [.pending, .verified(.noReward)])
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let result = await sut.run(clientTransactionID: "tx-1")

        guard case .outcome(.verified(.noReward)) = result else {
            return XCTFail("Expected .outcome(.verified(.noReward)), got \(result)")
        }
        XCTAssertEqual(statusPoller.callCount, 2,
                       // First attempt polled (.pending); second attempt's sleep failed so its
                       // poll was skipped; third attempt polled (.verified).
                       "Skipped poll after sleep failure; second successful poll completes the run")
        XCTAssertEqual(sleeper.callCount, 2,
                       "Sleeper called once and threw, called again next attempt and succeeded")
    }

    func testURLErrorCancelledIsTreatedAsTransientAndRetried() async {
        // URLError(.cancelled) is *not* Swift's CancellationError — it's a domain-specific
        // URLSession code. We treat it as a transient blip, not as task cancellation, so the
        // loop keeps going.
        let statusPoller = ScriptedStatusPoller(steps: [
            .throwError(URLError(.cancelled)),
            .status(.verified(.noReward))
        ])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let result = await sut.run(clientTransactionID: "tx-1")

        guard case .outcome(.verified(.noReward)) = result else {
            return XCTFail("Expected URLError(.cancelled) to be retried, got \(result)")
        }
        XCTAssertEqual(statusPoller.callCount, 2)
    }

    func testNSErrorWithURLErrorCancelledCodeIsTreatedAsTransientAndRetried() async {
        let nsCancel = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled, userInfo: nil)
        let statusPoller = ScriptedStatusPoller(steps: [
            .throwError(nsCancel),
            .status(.verified(.noReward))
        ])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let result = await sut.run(clientTransactionID: "tx-1")

        guard case .outcome(.verified(.noReward)) = result else {
            return XCTFail(
                "Expected NSURLErrorCancelled to be retried, got \(result)"
            )
        }
        XCTAssertEqual(statusPoller.callCount, 2)
    }

    // MARK: - Cancellation

    func testCancellationErrorFromPollerReturnsCancelledResult() async {
        let statusPoller = ThrowingStatusPoller(error: CancellationError())
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let result = await sut.run(clientTransactionID: "tx-1")

        XCTAssertEqual(result, .cancelled)
        XCTAssertEqual(statusPoller.callCount, 1)
        XCTAssertTrue(sleeper.delays.isEmpty)
    }

    func testCancellationErrorFromSleeperReturnsCancelledResult() async {
        let statusPoller = StubStatusPoller(statuses: [.pending, .verified(.noReward)])
        let sleeper = ThrowingSleeper(error: CancellationError())
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper)

        let result = await sut.run(clientTransactionID: "tx-1")

        XCTAssertEqual(result, .cancelled)
        XCTAssertEqual(statusPoller.callCount, 1)
        XCTAssertEqual(sleeper.callCount, 1)
    }

    // MARK: - Boundaries

    func testMaxAttemptsZeroReturnsFailedWithoutAnyPollOrSleep() async {
        let statusPoller = StubStatusPoller(statuses: [])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper, maxAttempts: 0)

        let result = await sut.run(clientTransactionID: "tx-1")

        guard case .outcome(.failed) = result else {
            return XCTFail("Expected .outcome(.failed), got \(result)")
        }
        XCTAssertTrue(statusPoller.receivedIDs.isEmpty)
        XCTAssertTrue(sleeper.delays.isEmpty)
    }

    func testMaxAttemptsOnePollsOnceWithoutSleeping() async {
        let statusPoller = StubStatusPoller(statuses: [.pending])
        let sleeper = RecordingSleeper()
        let sut = makePoller(statusPoller: statusPoller, sleeper: sleeper, maxAttempts: 1)

        let result = await sut.run(clientTransactionID: "tx-1")

        guard case .outcome(.failed) = result else {
            return XCTFail("Expected .outcome(.failed), got \(result)")
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
