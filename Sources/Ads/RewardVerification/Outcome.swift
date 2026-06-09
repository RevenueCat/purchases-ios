//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Outcome.swift
//

import Foundation

internal extension RewardVerification {

    /// Terminal SSV verdict from the polling loop.
    enum Outcome: Sendable {
        case verified(AdReward)
        case failed(FailureReason)

        var logDescription: String {
            switch self {
            case .verified: return "verified"
            case .failed(let reason): return "failed(\(reason))"
            }
        }
    }

    /// Internal classification of *why* verification failed. Not exposed publicly — every case
    /// maps to the binary public `RewardVerificationResult.failed`; it only drives the diagnostic
    /// logged by ``Poller`` so the cause is visible without leaking new public surface.
    enum FailureReason: Sendable, Equatable {

        /// The backend definitively rejected the reward. `message` is the backend-provided,
        /// human-readable cause (logged verbatim) and `reason` the raw `failure_reason` code
        /// (e.g. `no_access`); either may be `nil`, but both are carried so the cause survives
        /// when the backend supplies only one of them.
        case backendRejected(reason: String?, message: String?)

        /// Attempt budget exhausted while the status was still `pending` — the SSV callback
        /// was never received in time.
        case exhaustedPending

        /// Attempt budget exhausted while repeatedly hitting transient errors (network / brief
        /// backend unavailability).
        case exhaustedTransient

        /// Attempt budget exhausted after the backend returned a status this SDK doesn't recognize.
        case unexpectedResponse

        /// Polling stopped on an unrecoverable, non-retryable error (terminal transport/HTTP
        /// failure or a decoding error). `error` is that error's description.
        case terminalError(error: String)

        /// The polling task was cancelled before completion.
        case cancelled
    }
}
