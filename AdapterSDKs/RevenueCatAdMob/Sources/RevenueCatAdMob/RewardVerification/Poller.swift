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

    /// Bounded polling loop. Surfaces either `PollerResult.outcome(...)` (a terminal verdict
    /// from the backend, or `.failed` when the attempt budget is exhausted on repeated
    /// `pending`/`unknown` or transient errors) or `PollerResult.cancelled` (the caller asked
    /// to stop).
    ///
    /// `run` is intentionally non-throwing: cancellation is encoded in the return type so
    /// callers don't need a broad catch, and the type system enforces that no other error
    /// type can escape this layer.
    ///
    /// Transient errors (network blips, sleeper failures) are treated as non-answers, exactly
    /// like `pending`: sleep + jitter, retry — count against the budget. This mirrors how real
    /// mobile clients actually behave (spotty connections, brief 5xx, etc.) and keeps the
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

        func run(clientTransactionID: String) async -> PollerResult {
            for attempt in 0..<self.maxAttempts {
                if attempt > 0 {
                    do {
                        try await self.sleeper.sleep(seconds: self.jitter.sample())
                    } catch is CancellationError {
                        return .cancelled
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
                        return .outcome(.verified(reward))
                    case .failed:
                        return .outcome(.failed)
                    case .pending, .unknown:
                        // Treat `unknown` like `pending`; persistent unknowns surface as `.failed`
                        // via the bounded retry budget.
                        continue
                    }
                } catch is CancellationError {
                    return .cancelled
                } catch {
                    // Transient throw (URLError, transient backend 5xx, etc.) — treat like
                    // `pending`. This broad catch IS the product policy: spotty mobile
                    // connections are not a verdict; retry within budget. Any unknown throw
                    // type from the SDK polling endpoint should also be absorbed here rather
                    // than silently bypassing the retry loop.
                    // Pending: warn-log when adapter logging is wired in (transient SSV poll
                    // error on attempt \(attempt): \(error), retrying).
                    continue
                }
            }

            return .outcome(.failed)
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
