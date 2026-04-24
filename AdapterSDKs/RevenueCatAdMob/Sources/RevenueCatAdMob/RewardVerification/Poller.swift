//
//  Poller.swift
//
//  Created by RevenueCat.
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds)
@_spi(Internal) import RevenueCat

@available(iOS 15.0, *)
internal extension RewardVerification {

    /// Production wiring: `Purchases.shared.pollRewardVerificationStatus(clientTransactionID:)`.
    protocol StatusPolling: Sendable {
        func pollStatus(clientTransactionID: String) async throws -> RewardVerificationPollStatus
    }

    /// Async sleep abstraction used by the polling loop. Production wiring is `TaskSleeper`.
    protocol AsyncSleeper: Sendable {
        func sleep(seconds: TimeInterval) async throws
    }

    /// Per-attempt jitter sampler. Defaults to a uniform draw in `[0.75s, 1.25s]`.
    struct Jitter: Sendable {

        static let defaultLowerBound: TimeInterval = 0.75
        static let defaultUpperBound: TimeInterval = 1.25

        static let `default` = Jitter {
            TimeInterval.random(in: defaultLowerBound...defaultUpperBound)
        }

        let sample: @Sendable () -> TimeInterval
    }

    /// Bounded polling loop. Returns an `Outcome` for any terminal verdict (verified, backend
    /// `failed`, exhausted budget, or terminal `ErrorCode` from the SPI). Cancellation and
    /// truly unexpected throws propagate to the caller, which owns the cancellation policy
    /// and the safety net (see `Dispatcher.run`).
    ///
    /// Retry policy: `pending`/`unknown` and `ErrorCode` cases in the transient allowlist
    /// (`networkError`, `offlineConnectionError`, `unknownBackendError`) consume one attempt
    /// slot. Anything else is terminal — non-transient `ErrorCode`s map to `.failed`; other
    /// throws (CancellationError, unrecognised error types) propagate.
    struct Poller: Sendable {

        static let defaultMaxAttempts = 10

        private let statusPoller: StatusPolling
        private let sleeper: AsyncSleeper
        private let jitter: Jitter
        let maxAttempts: Int

        init(
            statusPoller: StatusPolling,
            sleeper: AsyncSleeper,
            jitter: Jitter = .default,
            maxAttempts: Int = Poller.defaultMaxAttempts
        ) {
            self.statusPoller = statusPoller
            self.sleeper = sleeper
            self.jitter = jitter
            self.maxAttempts = maxAttempts
        }

        /// Production poller wired to `Purchases.shared.pollRewardVerificationStatus(...)` and
        /// `Task.sleep`.
        static func makeDefault() -> Poller {
            Poller(
                statusPoller: PurchasesStatusPoller(),
                sleeper: TaskSleeper()
            )
        }

        func run(clientTransactionID: String) async throws -> Outcome {
            for attempt in 0..<self.maxAttempts {
                if attempt > 0 {
                    // Sleeper failures (in production: only `CancellationError`) propagate.
                    try await self.sleeper.sleep(seconds: self.jitter.sample())
                }

                do {
                    let status = try await self.statusPoller.pollStatus(clientTransactionID: clientTransactionID)
                    switch status {
                    case .verified(let reward):
                        return .verified(reward)
                    case .failed:
                        return .failed
                    case .pending, .unknown:
                        // `unknown` is treated like `pending`; persistent unknowns surface as `.failed` via the budget.
                        continue
                    }
                } catch let code as ErrorCode where code.isTransientPolling {
                    // Expected transient backend/network error from the SDK SPI — consume an
                    // attempt slot and retry within the budget.
                    continue
                } catch is ErrorCode {
                    // Known but terminal `ErrorCode` (e.g. signatureVerificationFailed,
                    // unexpectedBackendResponseError, 4xx-mapped codes). Retrying won't change
                    // the outcome; surface as `.failed` immediately.
                    return .failed
                }
                // Any other throw (CancellationError, unrecognised error type) propagates.
            }

            return .failed
        }
    }

    // MARK: - Production seam impls

    struct PurchasesStatusPoller: StatusPolling {

        func pollStatus(clientTransactionID: String) async throws -> RewardVerificationPollStatus {
            try await Purchases.shared.pollRewardVerificationStatus(clientTransactionID: clientTransactionID)
        }
    }

    struct TaskSleeper: AsyncSleeper {

        func sleep(seconds: TimeInterval) async throws {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        }
    }
}

// MARK: - ErrorCode classification

/// Allowlist of `ErrorCode` cases the polling loop treats as transient (worth retrying within
/// the attempt budget). Kept narrow on purpose — anything not listed here is either terminal
/// (returns `.failed` from the loop) or unrecognised (propagates to the caller).
fileprivate extension ErrorCode {

    var isTransientPolling: Bool {
        switch self {
        case .networkError,
             .offlineConnectionError,
             .unknownBackendError:
            return true
        default:
            return false
        }
    }
}

#endif
