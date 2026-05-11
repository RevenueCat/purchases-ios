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

    /// Bounded polling loop. Retries `pending`/`unknown` statuses and transient `ErrorCode`
    /// throws within an attempt budget; everything else (terminal `ErrorCode`, sleeper failure,
    /// any unrecognised throw) collapses to `.failed`. Honors `Task.isCancelled` between
    /// attempts and exits early without further polling.
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

        func run(clientTransactionID: String) async -> Outcome {
            Logger.debug(RewardVerificationStrings.poll_start(
                transactionID: clientTransactionID,
                maxAttempts: self.maxAttempts
            ))

            for attempt in 0..<self.maxAttempts {
                Logger.verbose(RewardVerificationStrings.poll_attempt(
                    attempt: attempt + 1,
                    maxAttempts: self.maxAttempts,
                    transactionID: clientTransactionID
                ))

                if Task.isCancelled {
                    Logger.debug(RewardVerificationStrings.poll_cancelled(transactionID: clientTransactionID))
                    return .failed
                }
                if attempt > 0 {
                    try? await self.sleeper.sleep(seconds: self.jitter.sample())
                }

                do {
                    let status = try await self.statusPoller.pollStatus(clientTransactionID: clientTransactionID)
                    Logger.debug(RewardVerificationStrings.poll_status(
                        status: status.logDescription,
                        transactionID: clientTransactionID
                    ))
                    switch status {
                    case .verified(let reward): return .verified(reward)
                    case .failed: return .failed
                    case .pending, .unknown: continue
                    }
                } catch let code as ErrorCode where code.isTransientPolling {
                    Logger.debug(RewardVerificationStrings.poll_transient_error(
                        error: code,
                        transactionID: clientTransactionID
                    ))
                    continue
                } catch {
                    Logger.error(RewardVerificationStrings.poll_terminal_error(
                        error: error,
                        transactionID: clientTransactionID
                    ))
                    return .failed
                }
            }

            Logger.warn(RewardVerificationStrings.poll_exhausted(
                maxAttempts: self.maxAttempts,
                transactionID: clientTransactionID
            ))
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

// MARK: - Helpers

fileprivate extension RewardVerificationPollStatus {

    var logDescription: String {
        switch self {
        case .verified: return "verified"
        case .pending: return "pending"
        case .failed: return "failed"
        case .unknown: return "unknown"
        }
    }
}

// MARK: - ErrorCode classification

/// Allowlist of `ErrorCode` cases the polling loop retries instead of surfacing as `.failed`.
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
