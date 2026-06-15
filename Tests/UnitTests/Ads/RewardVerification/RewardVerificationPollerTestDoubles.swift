//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RewardVerificationPollerTestDoubles.swift
//

import XCTest

@_spi(Internal) @testable import RevenueCat

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

/// Suspends indefinitely so tests can exercise cancellation of an in-flight polling task.
final class HangingStatusPoller: RewardVerification.StatusPolling, @unchecked Sendable {

    private(set) var callCount = 0

    func pollStatus(clientTransactionID: String) async throws -> RewardVerificationPollStatus {
        self.callCount += 1
        try await Task.sleep(nanoseconds: UInt64.max)
        return .pending
    }
}

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

final class RecordingSleeper: RewardVerification.AsyncSleeper, @unchecked Sendable {

    private(set) var delays: [TimeInterval] = []

    var callCount: Int { self.delays.count }

    func sleep(seconds: TimeInterval) async throws {
        self.delays.append(seconds)
    }
}

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

final class PollerJitterCounter: @unchecked Sendable {

    private(set) var value = 0

    func increment() {
        self.value += 1
    }
}

/// Class-based so tests can assert thrown-error identity.
final class PollerSentinelError: Error {}

// MARK: - Factories

/// Builds a `RewardVerification.Poller` with deterministic 1.0s jitter for tests that don't care
/// about the random delay distribution (those that do should construct the poller directly).
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

/// Builds a `BackendError` carrying an HTTP status, mirroring what the backend produces. The poller
/// reuses the SDK's `BackendError.isTransient` classification (5xx transient, 4xx terminal).
func makePollingError(statusCode: Int, backendCode: BackendErrorCode) -> BackendError {
    ErrorResponse(code: backendCode, originalCode: backendCode.rawValue, message: nil)
        .asBackendError(with: HTTPStatusCode(rawValue: statusCode))
}

/// A connection-level (transport) failure with no HTTP status: transient, retried by the poller.
func makeConnectivityError() -> BackendError {
    .networkError(.networkError(URLError(.timedOut) as NSError))
}

/// A terminal `BackendError` that is not worth retrying (no transient signal).
func makeTerminalBackendError() -> BackendError {
    .networkError(.signatureVerificationFailed(path: HTTPRequest.Path.health, code: .success))
}
