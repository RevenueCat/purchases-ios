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

    /// Bounded polling loop. Returns a `PollerResult`: `.outcome(...)` for a terminal verdict
    /// (or `.failed` once the attempt budget is exhausted), `.cancelled` if the underlying
    /// task is cancelled. Transient throws and `pending`/`unknown` consume retry slots and
    /// are absorbed within the budget; only `CancellationError` short-circuits the loop.
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
                        // Transient sleeper failure — treat like `pending`. In production
                        // `TaskSleeper` only throws `CancellationError`; this branch only
                        // fires for test doubles.
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
                        // `unknown` is treated like `pending`; persistent unknowns surface as `.failed` via the budget.
                        continue
                    }
                } catch is CancellationError {
                    return .cancelled
                } catch {
                    // Transient throw (URLError, transient backend 5xx, unknown future error
                    // types) — treat like `pending`. The broad catch is the policy: the retry
                    // budget is the only place transient errors surface as a verdict, so
                    // narrowing this would risk silently bypassing the loop on an unexpected
                    // throw type. Pending: warn-log when adapter logging is wired in.
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
