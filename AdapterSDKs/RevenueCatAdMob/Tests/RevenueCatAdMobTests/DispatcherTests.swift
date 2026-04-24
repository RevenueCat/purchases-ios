import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Internal) import RevenueCat
@testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class DispatcherTests: AdapterTestCase {

    // MARK: - run(...) outcomes

    func testRunFiresVerifiedOutcomeWithVirtualCurrencyReward() async {
        let reward = VirtualCurrencyReward(code: "coins", amount: 5)
        let state = RewardVerification.State(clientTransactionID: "tx-verified")
        let poller = self.makePoller(statuses: [.verified(.virtualCurrency(reward))])
        let recorder = OutcomeRecorder()

        await RewardVerification.Dispatcher.run(
            clientTransactionID: state.clientTransactionID,
            state: state,
            poller: poller,
            outcomeHandler: { recorder.append($0) }
        )

        let outcomes = recorder.snapshot()
        XCTAssertEqual(outcomes.count, 1)
        guard case .verified(.virtualCurrency(let earnedReward)) = outcomes.first else {
            return XCTFail("Expected .verified(.virtualCurrency), got \(String(describing: outcomes.first))")
        }
        XCTAssertEqual(earnedReward, reward)
    }

    func testRunFiresFailedOutcomeWhenPollerReportsFailed() async {
        let state = RewardVerification.State(clientTransactionID: "tx-failed")
        let poller = self.makePoller(statuses: [.failed])
        let recorder = OutcomeRecorder()

        await RewardVerification.Dispatcher.run(
            clientTransactionID: state.clientTransactionID,
            state: state,
            poller: poller,
            outcomeHandler: { recorder.append($0) }
        )

        let outcomes = recorder.snapshot()
        guard case .failed = outcomes.first else {
            return XCTFail("Expected .failed, got \(String(describing: outcomes.first))")
        }
    }

    func testRunFiresFailedOutcomeWhenAllAttemptsRemainPending() async {
        let state = RewardVerification.State(clientTransactionID: "tx-pending-budget")
        let poller = self.makePoller(statuses: Array(repeating: .pending, count: 3), maxAttempts: 3)
        let recorder = OutcomeRecorder()

        await RewardVerification.Dispatcher.run(
            clientTransactionID: state.clientTransactionID,
            state: state,
            poller: poller,
            outcomeHandler: { recorder.append($0) }
        )

        guard case .failed = recorder.snapshot().first else {
            return XCTFail("Expected .failed, got \(String(describing: recorder.snapshot().first))")
        }
    }

    func testRunFiresFailedOutcomeWhenAllAttemptsThrowTransiently() async {
        let state = RewardVerification.State(clientTransactionID: "tx-transient")
        let throwingPoller = ThrowingStatusPoller(error: SentinelError())
        let poller = RewardVerification.Poller(
            statusPoller: throwingPoller, sleeper: RecordingSleeper(), maxAttempts: 3
        )
        let recorder = OutcomeRecorder()

        await RewardVerification.Dispatcher.run(
            clientTransactionID: state.clientTransactionID,
            state: state,
            poller: poller,
            outcomeHandler: { recorder.append($0) }
        )

        let outcomes = recorder.snapshot()
        guard case .failed = outcomes.first else {
            return XCTFail("Expected .failed for transient-only attempts, got \(String(describing: outcomes.first))")
        }
        XCTAssertEqual(throwingPoller.callCount, 3,
                       "Transient throws should be retried up to the attempt budget")
    }

    func testRunForwardsNoRewardCaseUnchangedThroughVerifiedOutcome() async {
        let state = RewardVerification.State(clientTransactionID: "tx-no-reward")
        let poller = self.makePoller(statuses: [.verified(.noReward)])
        let recorder = OutcomeRecorder()

        await RewardVerification.Dispatcher.run(
            clientTransactionID: state.clientTransactionID,
            state: state,
            poller: poller,
            outcomeHandler: { recorder.append($0) }
        )

        guard case .verified(.noReward) = recorder.snapshot().first else {
            return XCTFail("Expected .verified(.noReward), got \(String(describing: recorder.snapshot().first))")
        }
    }

    func testRunForwardsUnsupportedRewardCaseUnchangedThroughVerifiedOutcome() async {
        let state = RewardVerification.State(clientTransactionID: "tx-unsupported-reward")
        let poller = self.makePoller(statuses: [.verified(.unsupportedReward)])
        let recorder = OutcomeRecorder()

        await RewardVerification.Dispatcher.run(
            clientTransactionID: state.clientTransactionID,
            state: state,
            poller: poller,
            outcomeHandler: { recorder.append($0) }
        )

        guard case .verified(.unsupportedReward) = recorder.snapshot().first else {
            return XCTFail(
                "Expected .verified(.unsupportedReward), got \(String(describing: recorder.snapshot().first))"
            )
        }
    }

    // MARK: - Cancellation

    func testRunSwallowsCancellationAndDoesNotFireHandler() async {
        let state = RewardVerification.State(clientTransactionID: "tx-cancel")
        let throwingPoller = ThrowingStatusPoller(error: CancellationError())
        let poller = RewardVerification.Poller(statusPoller: throwingPoller, sleeper: RecordingSleeper())
        let recorder = OutcomeRecorder()

        await RewardVerification.Dispatcher.run(
            clientTransactionID: state.clientTransactionID,
            state: state,
            poller: poller,
            outcomeHandler: { recorder.append($0) }
        )

        XCTAssertTrue(recorder.snapshot().isEmpty,
                      "Cancellation must not surface as an outcome to the handler")
        XCTAssertTrue(state.consumeFireToken(),
                      "Cancellation must leave the one-shot guard intact for a later attempt")
    }

    // MARK: - One-shot guard

    func testRunDoesNotFireWhenStateGuardAlreadyConsumed() async {
        let state = RewardVerification.State(clientTransactionID: "tx-already-fired")
        XCTAssertTrue(state.consumeFireToken(), "Pre-consume the guard before invoking the dispatcher")
        let poller = self.makePoller(statuses: [.verified(.noReward)])
        let recorder = OutcomeRecorder()

        await RewardVerification.Dispatcher.run(
            clientTransactionID: state.clientTransactionID,
            state: state,
            poller: poller,
            outcomeHandler: { recorder.append($0) }
        )

        XCTAssertTrue(recorder.snapshot().isEmpty,
                      "Handler must not be invoked when the one-shot guard has already been consumed")
    }

    func testRunFiresHandlerAtMostOnceForBackToBackCalls() async {
        let state = RewardVerification.State(clientTransactionID: "tx-once")
        let recorder = OutcomeRecorder()

        await RewardVerification.Dispatcher.run(
            clientTransactionID: state.clientTransactionID,
            state: state,
            poller: self.makePoller(statuses: [.verified(.noReward)]),
            outcomeHandler: { recorder.append($0) }
        )
        await RewardVerification.Dispatcher.run(
            clientTransactionID: state.clientTransactionID,
            state: state,
            poller: self.makePoller(statuses: [.verified(.noReward)]),
            outcomeHandler: { recorder.append($0) }
        )

        XCTAssertEqual(recorder.snapshot().count, 1,
                       "Outcome handler must fire at most once across repeated dispatcher invocations")
    }

    // MARK: - dispatch

    func testDispatchCompletesAndForwardsVerifiedOutcome() async {
        let reward = VirtualCurrencyReward(code: "coins", amount: 7)
        let state = RewardVerification.State(clientTransactionID: "tx-dispatch")
        let poller = self.makePoller(statuses: [.verified(.virtualCurrency(reward))])
        let recorder = OutcomeRecorder()

        let task = RewardVerification.Dispatcher.dispatch(
            clientTransactionID: state.clientTransactionID,
            state: state,
            poller: poller,
            outcomeHandler: { recorder.append($0) }
        )

        await task.value

        guard case .verified(.virtualCurrency(let earnedReward)) = recorder.snapshot().first else {
            return XCTFail("Expected .verified(.virtualCurrency) from dispatched task")
        }
        XCTAssertEqual(earnedReward, reward)
    }

    func testDispatchCancellationDoesNotFireHandlerAndPreservesGuard() async {
        let state = RewardVerification.State(clientTransactionID: "tx-dispatch-cancel")
        let hangingPoller = HangingStatusPoller()
        let poller = RewardVerification.Poller(
            statusPoller: hangingPoller,
            sleeper: RecordingSleeper()
        )
        let recorder = OutcomeRecorder()

        let task = RewardVerification.Dispatcher.dispatch(
            clientTransactionID: state.clientTransactionID,
            state: state,
            poller: poller,
            outcomeHandler: { recorder.append($0) }
        )

        // Yield once so the dispatched Task starts and is parked inside the hanging poller's
        // `Task.sleep` before we cancel it.
        await Task.yield()
        task.cancel()
        await task.value

        XCTAssertTrue(recorder.snapshot().isEmpty,
                      "Cancelling the dispatched task must not deliver an outcome")
        XCTAssertTrue(state.consumeFireToken(),
                      "Cancellation must leave the one-shot guard intact for a later attempt")
    }

    // MARK: - Threading

    func testRunDeliversOutcomeOnMainActor() async {
        let state = RewardVerification.State(clientTransactionID: "tx-main-actor")
        let poller = self.makePoller(statuses: [.verified(.noReward)])
        let mainActorAssertion = MainActorAssertionRecorder()

        await RewardVerification.Dispatcher.run(
            clientTransactionID: state.clientTransactionID,
            state: state,
            poller: poller,
            outcomeHandler: { _ in
                MainActor.assertIsolated("Outcome handler must be invoked on the main actor")
                mainActorAssertion.markFired()
            }
        )

        XCTAssertTrue(mainActorAssertion.didFire,
                      "Outcome handler should have run; without it the MainActor assertion would never be reached")
    }

    // MARK: - Helpers

    private func makePoller(
        statuses: [RewardVerificationPollStatus],
        maxAttempts: Int = RewardVerification.Poller.defaultMaxAttempts
    ) -> RewardVerification.Poller {
        RewardVerification.Poller(
            statusPoller: StubStatusPoller(statuses: statuses),
            sleeper: RecordingSleeper(),
            jitter: RewardVerification.Jitter { 0 },
            maxAttempts: maxAttempts
        )
    }
}

// MARK: - Test doubles

/// Captures handler invocations across actor hops for assertions.
final class OutcomeRecorder: @unchecked Sendable {

    private let lock = NSLock()
    private var outcomes: [RewardVerification.Outcome] = []

    func append(_ outcome: RewardVerification.Outcome) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.outcomes.append(outcome)
    }

    func snapshot() -> [RewardVerification.Outcome] {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.outcomes
    }
}

/// Captures whether the outcome handler ran. Cross-actor mutation lives behind a lock so the
/// recorder is safe to share with the `@Sendable @MainActor` handler.
final class MainActorAssertionRecorder: @unchecked Sendable {

    private let lock = NSLock()
    private var fired = false

    var didFire: Bool {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.fired
    }

    func markFired() {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.fired = true
    }
}

#endif
