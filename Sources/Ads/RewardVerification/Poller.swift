//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Poller.swift
//

import Foundation

/// Production wiring: `Purchases.shared.fetchRewardVerificationStatus(clientTransactionID:)`,
/// which throws a structured ``BackendError`` so the poller can reuse the SDK's retry
/// classification (``BackendError/isTransient``).
internal protocol RewardVerificationStatusPolling: Sendable {
    func pollStatus(clientTransactionID: String) async throws -> RewardVerificationPollStatus
}

/// Async sleep abstraction used by the polling loop. Production wiring is `RewardVerification.TaskSleeper`.
internal protocol RewardVerificationAsyncSleeper: Sendable {
    func sleep(seconds: TimeInterval) async throws
}

internal extension RewardVerification {

    /// Per-attempt jitter sampler. Defaults to a uniform draw in `[0.75s, 1.25s]`.
    struct Jitter: Sendable {

        static let defaultLowerBound: TimeInterval = 0.75
        static let defaultUpperBound: TimeInterval = 1.25

        static let `default` = Jitter {
            TimeInterval.random(in: defaultLowerBound...defaultUpperBound)
        }

        let sample: @Sendable () -> TimeInterval
    }

    /// Bounded polling loop. Retries `pending`/`unknown` statuses and transient `BackendError`
    /// throws within an attempt budget; everything else (terminal `BackendError`, sleeper failure,
    /// any unrecognised throw) collapses to `.failed`. Honors `Task.isCancelled` between attempts
    /// and after each attempt completes, mapping cancellation to `.failed(.cancelled)` and exiting
    /// early without further polling.
    struct Poller: Sendable {

        static let defaultMaxAttempts = 10

        private let statusPoller: RewardVerificationStatusPolling
        private let sleeper: RewardVerificationAsyncSleeper
        private let jitter: Jitter
        let maxAttempts: Int

        init(
            statusPoller: RewardVerificationStatusPolling,
            sleeper: RewardVerificationAsyncSleeper,
            jitter: Jitter = .default,
            maxAttempts: Int = Poller.defaultMaxAttempts
        ) {
            self.statusPoller = statusPoller
            self.sleeper = sleeper
            self.jitter = jitter
            self.maxAttempts = maxAttempts
        }

        /// Production poller wired to `Purchases.shared.fetchRewardVerificationStatus(...)` and
        /// `Task.sleep`.
        static func makeDefault() -> Poller {
            Poller(
                statusPoller: PurchasesStatusPoller(),
                sleeper: TaskSleeper()
            )
        }

        func run(clientTransactionID: String) async -> Outcome {
            Logger.debug(AdsStrings.poll_start(
                transactionID: clientTransactionID,
                maxAttempts: self.maxAttempts
            ))

            var lastDisposition: PollDisposition = .pending

            for attempt in 0..<self.maxAttempts {
                Logger.verbose(AdsStrings.poll_attempt(
                    attempt: attempt + 1,
                    maxAttempts: self.maxAttempts,
                    transactionID: clientTransactionID
                ))

                if Task.isCancelled {
                    Logger.warn(AdsStrings.poll_cancelled(transactionID: clientTransactionID))
                    return .failed(.cancelled)
                }
                if attempt > 0 {
                    try? await self.sleeper.sleep(seconds: self.jitter.sample())
                }

                switch await self.pollOnce(clientTransactionID: clientTransactionID) {
                case .finished(let outcome):
                    return outcome
                case .retry(let disposition):
                    lastDisposition = disposition
                }
            }

            return .failed(self.exhaustionReason(
                for: lastDisposition,
                clientTransactionID: clientTransactionID
            ))
        }

        /// Runs a single poll attempt: either a terminal `Outcome` or a `retry` carrying the
        /// disposition to remember for exhaustion classification.
        private func pollOnce(clientTransactionID: String) async -> PollAttemptResult {
            do {
                let status = try await self.statusPoller.pollStatus(
                    clientTransactionID: clientTransactionID
                )
                // A cancellation that lands while the status request is in flight won't surface as a
                // `CancellationError` if the request resolves successfully. Re-check before logging or
                // acting on the status, so a late cancellation maps to `.failed(.cancelled)` instead of
                // emitting a stale outcome (e.g. a backend-rejection warning the caller never receives).
                if Task.isCancelled {
                    Logger.warn(AdsStrings.poll_cancelled(transactionID: clientTransactionID))
                    return .finished(.failed(.cancelled))
                }
                Logger.debug(AdsStrings.poll_status(
                    status: status.logDescription,
                    transactionID: clientTransactionID
                ))
                switch status {
                case .verified(let reward):
                    return .finished(.verified(reward))
                case let .failed(reason, message):
                    Logger.warn(AdsStrings.poll_backend_rejected(
                        reason: reason,
                        message: message,
                        transactionID: clientTransactionID
                    ))
                    return .finished(.failed(.backendRejected(reason: reason, message: message)))
                case .pending:
                    return .retry(.pending)
                case .unknown:
                    return .retry(.unknownStatus)
                }
            } catch let error as BackendError where error.isTransient {
                Logger.debug(AdsStrings.poll_transient_error(
                    error: error,
                    transactionID: clientTransactionID
                ))
                return .retry(.transient)
            } catch is CancellationError {
                Logger.warn(AdsStrings.poll_cancelled(transactionID: clientTransactionID))
                return .finished(.failed(.cancelled))
            } catch {
                // A non-retryable transport/HTTP failure or a decoding error stopped the poll.
                Logger.error(AdsStrings.poll_terminal_error(
                    error: error,
                    transactionID: clientTransactionID
                ))
                return .finished(.failed(.terminalError(error: "\(error)")))
            }
        }

        /// Logs the diagnostic for an exhausted poll and returns the matching ``FailureReason``.
        private func exhaustionReason(
            for disposition: PollDisposition,
            clientTransactionID: String
        ) -> FailureReason {
            switch disposition {
            case .pending:
                Logger.warn(AdsStrings.poll_exhausted_pending(transactionID: clientTransactionID))
                return .exhaustedPending
            case .transient:
                Logger.warn(AdsStrings.poll_exhausted_transient(transactionID: clientTransactionID))
                return .exhaustedTransient
            case .unknownStatus:
                Logger.warn(AdsStrings.poll_unexpected_response(transactionID: clientTransactionID))
                return .unexpectedResponse
            }
        }
    }

    /// The most recent non-terminal result of a poll attempt, used to classify *why* the attempt
    /// budget was exhausted (last-observed disposition wins).
    enum PollDisposition {
        case pending
        case transient
        case unknownStatus
    }

    /// Outcome of a single ``Poller`` attempt: a terminal result, or a retry carrying the
    /// disposition to remember.
    enum PollAttemptResult {
        case finished(Outcome)
        case retry(PollDisposition)
    }

    // MARK: - Production seam impls

    struct PurchasesStatusPoller: RewardVerificationStatusPolling {

        func pollStatus(clientTransactionID: String) async throws -> RewardVerificationPollStatus {
            try await Purchases.shared.fetchRewardVerificationStatus(clientTransactionID: clientTransactionID)
        }
    }

    struct TaskSleeper: RewardVerificationAsyncSleeper {

        func sleep(seconds: TimeInterval) async throws {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        }
    }
}

// MARK: - Helpers

private extension RewardVerificationPollStatus {

    var logDescription: String {
        switch self {
        case .verified: return "verified"
        case .pending: return "pending"
        case .failed: return "failed"
        case .unknown: return "unknown"
        }
    }
}
