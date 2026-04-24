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

    /// Bounded polling loop. Surfaces only `Outcome.verified` (when the backend confirms) or
    /// `Outcome.failed` (when the backend rejects, or when the attempt budget is exhausted —
    /// whether on `pending`/`unknown` or on repeated transient errors). Cancellation is the only
    /// thing that escapes via `throws`; everything else is absorbed inside the budget.
    ///
    /// Transient errors (network blips, sleeper failures) are treated as non-answers, exactly
    /// like `pending`: log, sleep + jitter, retry — count against the budget. This mirrors how
    /// real mobile clients actually behave (spotty connections, brief 5xx, etc.) and keeps the
    /// consumer-facing outcome stable: either we got a verdict, or we didn't.
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
                    do {
                        try await self.sleeper.sleep(seconds: self.jitter.sample())
                    } catch is CancellationError {
                        throw CancellationError()
                    } catch {
                        // Sleeper failed transiently — treat like `pending` and try the next
                        // attempt anyway. In production `TaskSleeper` only throws `CancellationError`,
                        // so this branch only fires for unusual custom sleepers (mainly tests).
                        // Pending: warn-log when adapter logging is wired in (transient sleeper
                        // error on attempt \(attempt): \(error), retrying).
                        continue
                    }
                }

                do {
                    let status = try await self.statusPoller.pollStatus(clientTransactionID: clientTransactionID)
                    switch status {
                    case .verified(let reward):
                        return .verified(reward)
                    case .failed:
                        return .failed
                    case .pending, .unknown:
                        // Treat `unknown` like `pending`; persistent unknowns surface as `.failed`
                        // via the bounded retry budget.
                        continue
                    }
                } catch is CancellationError {
                    throw CancellationError()
                } catch {
                    // Transient throw (URLError, transient backend 5xx, etc.) — treat like
                    // `pending`. The next iteration will sleep + retry; if every attempt blips,
                    // we exhaust the budget and surface `.failed`. Mobile clients are spotty by
                    // nature; one blip is not a verdict.
                    // Pending: warn-log when adapter logging is wired in (transient SSV poll
                    // error on attempt \(attempt): \(error), retrying).
                    continue
                }
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

#endif
