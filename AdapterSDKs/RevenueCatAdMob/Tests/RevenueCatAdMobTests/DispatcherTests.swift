import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Internal) @_spi(Experimental) import RevenueCat
@testable import RevenueCatAdMob

@MainActor
@available(iOS 15.0, *)
final class DispatcherTests: AdapterTestCase {

    // MARK: - run(...) outcomes

    func testRunFiresVerifiedResult() async {
        let state = RewardVerification.State(clientTransactionID: "tx-verified")
        let recorder = ResultRecorder()

        await RewardVerification.Dispatcher.run(
            transactionID: state.clientTransactionID,
            state: state,
            pollRewardVerification: { _ in .verified(.unsupportedReward) },
            resultHandler: { recorder.append($0) }
        )

        let results = recorder.snapshot()
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.verifiedReward, .unsupportedReward)
    }

    func testRunFiresFailedResult() async {
        let state = RewardVerification.State(clientTransactionID: "tx-failed")
        let recorder = ResultRecorder()

        await RewardVerification.Dispatcher.run(
            transactionID: state.clientTransactionID,
            state: state,
            pollRewardVerification: { _ in .failed },
            resultHandler: { recorder.append($0) }
        )

        XCTAssertEqual(recorder.snapshot().first, .failed)
    }

    func testRunForwardsTransactionIDToPoll() async {
        let state = RewardVerification.State(clientTransactionID: "tx-forward")
        let recorder = ResultRecorder()
        let receivedID = TransactionIDRecorder()

        await RewardVerification.Dispatcher.run(
            transactionID: state.clientTransactionID,
            state: state,
            pollRewardVerification: { id in
                receivedID.set(id)
                return .failed
            },
            resultHandler: { recorder.append($0) }
        )

        XCTAssertEqual(receivedID.value, "tx-forward")
    }

    // MARK: - One-shot guard

    func testRunDoesNotFireWhenStateGuardAlreadyConsumed() async {
        let state = RewardVerification.State(clientTransactionID: "tx-already-fired")
        XCTAssertTrue(state.consumeFireToken(), "Pre-consume the guard before invoking the dispatcher")
        let recorder = ResultRecorder()

        await RewardVerification.Dispatcher.run(
            transactionID: state.clientTransactionID,
            state: state,
            pollRewardVerification: { _ in .verified(.noReward) },
            resultHandler: { recorder.append($0) }
        )

        XCTAssertTrue(recorder.snapshot().isEmpty,
                      "Handler must not be invoked when the one-shot guard has already been consumed")
    }

    func testRunFiresHandlerAtMostOnceForBackToBackCalls() async {
        let state = RewardVerification.State(clientTransactionID: "tx-once")
        let recorder = ResultRecorder()

        await RewardVerification.Dispatcher.run(
            transactionID: state.clientTransactionID,
            state: state,
            pollRewardVerification: { _ in .verified(.noReward) },
            resultHandler: { recorder.append($0) }
        )
        await RewardVerification.Dispatcher.run(
            transactionID: state.clientTransactionID,
            state: state,
            pollRewardVerification: { _ in .verified(.noReward) },
            resultHandler: { recorder.append($0) }
        )

        XCTAssertEqual(recorder.snapshot().count, 1,
                       "Result handler must fire at most once across repeated dispatcher invocations")
    }

    // MARK: - dispatch

    func testDispatchCompletesAndForwardsResult() async {
        let state = RewardVerification.State(clientTransactionID: "tx-dispatch")
        let recorder = ResultRecorder()

        let task = RewardVerification.Dispatcher.dispatch(
            transactionID: state.clientTransactionID,
            state: state,
            pollRewardVerification: { _ in .verified(.unsupportedReward) },
            resultHandler: { recorder.append($0) }
        )

        await task.value

        XCTAssertEqual(recorder.snapshot().first?.verifiedReward, .unsupportedReward)
    }

    func testDispatchCancellationDoesNotFireHandlerAndPreservesGuard() async {
        let state = RewardVerification.State(clientTransactionID: "tx-dispatch-cancel")
        let recorder = ResultRecorder()

        let task = RewardVerification.Dispatcher.dispatch(
            transactionID: state.clientTransactionID,
            state: state,
            pollRewardVerification: { _ in
                try? await Task.sleep(nanoseconds: UInt64.max)
                return .failed
            },
            resultHandler: { recorder.append($0) }
        )

        // Yield once so the dispatched Task starts and is parked inside the hanging poll before cancel.
        await Task.yield()
        task.cancel()
        await task.value

        XCTAssertTrue(recorder.snapshot().isEmpty,
                      "Cancelling the dispatched task must not deliver a result")
        XCTAssertTrue(state.consumeFireToken(),
                      "Cancellation must leave the one-shot guard intact for a later attempt")
    }

    // MARK: - Threading

    func testRunDeliversResultOnMainActor() async {
        let state = RewardVerification.State(clientTransactionID: "tx-main-actor")
        let mainActorAssertion = MainActorAssertionRecorder()

        await RewardVerification.Dispatcher.run(
            transactionID: state.clientTransactionID,
            state: state,
            pollRewardVerification: { _ in .verified(.noReward) },
            resultHandler: { _ in
                MainActor.assertIsolated("Result handler must be invoked on the main actor")
                mainActorAssertion.markFired()
            }
        )

        XCTAssertTrue(mainActorAssertion.didFire,
                      "Result handler should have run; without it the MainActor assertion would never be reached")
    }
}

// MARK: - Test doubles

/// Captures handler invocations across actor hops for assertions.
final class ResultRecorder: @unchecked Sendable {

    private let lock = NSLock()
    private var results: [RewardVerificationResult] = []

    func append(_ result: RewardVerificationResult) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.results.append(result)
    }

    func snapshot() -> [RewardVerificationResult] {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.results
    }
}

final class TransactionIDRecorder: @unchecked Sendable {

    private let lock = NSLock()
    private var stored: String?

    var value: String? {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.stored
    }

    func set(_ value: String) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.stored = value
    }
}

/// Captures whether the result handler ran. Cross-actor mutation lives behind a lock.
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
