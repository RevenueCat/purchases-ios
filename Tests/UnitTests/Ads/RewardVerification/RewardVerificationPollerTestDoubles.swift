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

final class StubStatusPoller: RewardVerificationStatusPolling, @unchecked Sendable {

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

final class ThrowingStatusPoller: RewardVerificationStatusPolling, @unchecked Sendable {

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
final class HangingStatusPoller: RewardVerificationStatusPolling, @unchecked Sendable {

    private(set) var callCount = 0

    func pollStatus(clientTransactionID: String) async throws -> RewardVerificationPollStatus {
        self.callCount += 1
        try await Task.sleep(nanoseconds: UInt64.max)
        return .pending
    }
}

/// Signals that the in-flight `pollStatus` call has started, observes cancellation cooperatively
/// (without throwing), then resolves to a successful status. Models the race where a status request
/// completes successfully at the same moment the surrounding task is cancelled — the poller must
/// still collapse that to `.failed(.cancelled)`.
final class CancelThenSucceedStatusPoller: RewardVerificationStatusPolling, @unchecked Sendable {

    private let started: Atomic<Bool>
    private let successStatus: RewardVerificationPollStatus
    private(set) var callCount = 0

    var didStart: Bool { self.started.value }

    init(started: Atomic<Bool>, successStatus: RewardVerificationPollStatus) {
        self.started = started
        self.successStatus = successStatus
    }

    func pollStatus(clientTransactionID: String) async throws -> RewardVerificationPollStatus {
        self.callCount += 1
        self.started.value = true
        // Wait for cancellation cooperatively *without* throwing, then resolve successfully.
        while !Task.isCancelled {
            await Task.yield()
        }
        return self.successStatus
    }
}

final class ScriptedStatusPoller: RewardVerificationStatusPolling, @unchecked Sendable {

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

final class RecordingSleeper: RewardVerificationAsyncSleeper, @unchecked Sendable {

    private(set) var delays: [TimeInterval] = []

    var callCount: Int { self.delays.count }

    func sleep(seconds: TimeInterval) async throws {
        self.delays.append(seconds)
    }
}

final class ThrowingSleeper: RewardVerificationAsyncSleeper, @unchecked Sendable {

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
    statusPoller: RewardVerificationStatusPolling,
    sleeper: RewardVerificationAsyncSleeper,
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
    .networkError(
        .errorResponse(
            ErrorResponse(code: backendCode, originalCode: backendCode.rawValue, message: nil),
            HTTPStatusCode(rawValue: statusCode)
        )
    )
}

/// A connection-level (transport) failure with no HTTP status: transient, retried by the poller.
func makeConnectivityError() -> BackendError {
    .networkError(.networkError(URLError(.timedOut) as NSError))
}

/// A terminal `BackendError` that is not worth retrying (no transient signal).
func makeTerminalBackendError() -> BackendError {
    .networkError(.signatureVerificationFailed(path: HTTPRequest.Path.health, code: .success))
}
