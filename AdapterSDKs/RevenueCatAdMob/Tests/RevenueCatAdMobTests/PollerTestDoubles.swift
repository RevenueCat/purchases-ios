import XCTest

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds
@_spi(Internal) import RevenueCat
@testable import RevenueCatAdMob

@available(iOS 15.0, *)
final class StubStatusPoller: RewardVerification.StatusPolling, @unchecked Sendable {

    private var statuses: [RewardVerificationPollStatus]
    private(set) var receivedIDs: [String] = []

    var callCount: Int { self.receivedIDs.count }

    init(statuses: [RewardVerificationPollStatus]) {
        self.statuses = statuses
    }

    func pollStatus(clientTransactionID: String) async throws -> RewardVerificationPollStatus {
        self.receivedIDs.append(clientTransactionID)
        guard !self.statuses.isEmpty else {
            XCTFail("Unexpected extra pollStatus call for id=\(clientTransactionID)")
            return .pending
        }
        return self.statuses.removeFirst()
    }
}

@available(iOS 15.0, *)
final class ThrowingStatusPoller: RewardVerification.StatusPolling, @unchecked Sendable {

    let error: any Error
    private(set) var callCount = 0

    init(error: any Error) {
        self.error = error
    }

    func pollStatus(clientTransactionID: String) async throws -> RewardVerificationPollStatus {
        self.callCount += 1
        throw self.error
    }
}

/// Suspends the calling task indefinitely on each `pollStatus` call. Used to test cancellation
/// of an in-flight `Dispatcher.dispatch(...)` Task: cancelling the task wakes the underlying
/// `Task.sleep` and the call throws `CancellationError`, exactly as a real GMA/network poll would
/// when its enclosing task is cancelled.
@available(iOS 15.0, *)
final class HangingStatusPoller: RewardVerification.StatusPolling, @unchecked Sendable {

    private(set) var callCount = 0

    func pollStatus(clientTransactionID: String) async throws -> RewardVerificationPollStatus {
        self.callCount += 1
        try await Task.sleep(nanoseconds: UInt64.max)
        return .pending
    }
}

@available(iOS 15.0, *)
final class ScriptedStatusPoller: RewardVerification.StatusPolling, @unchecked Sendable {

    enum Step {
        case status(RewardVerificationPollStatus)
        case throwError(any Error)
    }

    private var steps: [Step]
    private(set) var callCount = 0

    init(steps: [Step]) {
        self.steps = steps
    }

    func pollStatus(clientTransactionID: String) async throws -> RewardVerificationPollStatus {
        self.callCount += 1
        guard !self.steps.isEmpty else {
            XCTFail("Unexpected extra pollStatus call for id=\(clientTransactionID)")
            return .pending
        }
        switch self.steps.removeFirst() {
        case .status(let status):
            return status
        case .throwError(let error):
            throw error
        }
    }
}

@available(iOS 15.0, *)
final class RecordingSleeper: RewardVerification.AsyncSleeper, @unchecked Sendable {

    private(set) var delays: [TimeInterval] = []

    var callCount: Int { self.delays.count }

    func sleep(seconds: TimeInterval) async throws {
        self.delays.append(seconds)
    }
}

@available(iOS 15.0, *)
final class ThrowingSleeper: RewardVerification.AsyncSleeper, @unchecked Sendable {

    let error: any Error
    private(set) var callCount = 0

    init(error: any Error) {
        self.error = error
    }

    func sleep(seconds: TimeInterval) async throws {
        self.callCount += 1
        throw self.error
    }
}

final class Counter: @unchecked Sendable {

    private(set) var value = 0

    func increment() {
        self.value += 1
    }
}

/// Class-based so tests can assert thrown-error identity via `XCTAssertIdentical`.
final class SentinelError: Error {}

// MARK: - Factories

/// Builds a `RewardVerification.Poller` with deterministic 1.0s jitter for tests that don't care
/// about the random delay distribution (those that do should construct the poller directly).
@available(iOS 15.0, *)
func makePoller(
    statusPoller: RewardVerification.StatusPolling,
    sleeper: RewardVerification.AsyncSleeper,
    maxAttempts: Int = 10
) -> RewardVerification.Poller {
    RewardVerification.Poller(
        statusPoller: statusPoller,
        sleeper: sleeper,
        jitter: RewardVerification.Jitter { 1.0 },
        maxAttempts: maxAttempts
    )
}

#endif
