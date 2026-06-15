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
            Logger.debug(AdsStrings.poll_start(
                transactionID: clientTransactionID,
                maxAttempts: self.maxAttempts
            ))

            for attempt in 0..<self.maxAttempts {
                Logger.verbose(AdsStrings.poll_attempt(
                    attempt: attempt + 1,
                    maxAttempts: self.maxAttempts,
                    transactionID: clientTransactionID
                ))

                if Task.isCancelled {
                    Logger.debug(AdsStrings.poll_cancelled(transactionID: clientTransactionID))
                    return .failed(.unknown)
                }
                if attempt > 0 {
                    try? await self.sleeper.sleep(seconds: self.jitter.sample())
                }

                do {
                    let status = try await self.statusPoller.pollStatus(
                        clientTransactionID: clientTransactionID
                    )
                    Logger.debug(AdsStrings.poll_status(
                        status: status.logDescription,
                        transactionID: clientTransactionID
                    ))
                    switch status {
                    case .verified(let reward): return .verified(reward)
                    case .failed: return .failed(.backendError)
                    case .pending, .unknown: continue
                    }
                } catch where Self.isTransientPollingError(error) {
                    Logger.debug(AdsStrings.poll_transient_error(
                        error: error,
                        transactionID: clientTransactionID
                    ))
                    continue
                } catch {
                    Logger.error(AdsStrings.poll_terminal_error(
                        error: error,
                        transactionID: clientTransactionID
                    ))
                    return .failed(error is ErrorCode ? .backendError : .unknown)
                }
            }

            Logger.warn(AdsStrings.poll_exhausted(
                maxAttempts: self.maxAttempts,
                transactionID: clientTransactionID
            ))
            return .failed(.timeout)
        }

        /// Retries network/offline transport errors and any HTTP 5xx, keying on the status code
        /// rather than the mapped `ErrorCode` so empty/unparseable 5xx retry and 4xx fail fast.
        static func isTransientPollingError(_ error: Error) -> Bool {
            switch error as? ErrorCode {
            case .networkError, .offlineConnectionError:
                return true
            default:
                let statusCode = (error as NSError).userInfo[ErrorDetails.statusCodeKey] as? Int
                return statusCode.map { HTTPStatusCode(rawValue: $0).isServerError } ?? false
            }
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
