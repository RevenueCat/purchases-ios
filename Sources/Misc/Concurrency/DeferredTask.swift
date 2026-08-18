//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DeferredTask.swift
//
//  Created by Antonio Pallares on 8/18/26.

import Foundation

/// A task whose operation doesn't begin until ``start()`` is called.
///
/// `Task` starts running as soon as it's created, so anything the operation depends on must already
/// be in place by then. Deferring the start allows storing the handle where the operation (or code
/// racing with it) can find it, and only then letting the work begin.
///
/// - Warning: the operation never runs if ``start()`` isn't called, leaving anything awaiting
/// ``value`` or ``result`` suspended indefinitely.
final class DeferredTask<Success: Sendable>: Sendable {

    private let started: AsyncSignal
    private let task: Task<Success, Error>

    init(operation: @escaping @Sendable () async throws -> Success) {
        let started = AsyncSignal()

        self.started = started
        self.task = Task {
            await started.wait()
            return try await operation()
        }
    }

    /// Allows the operation to begin. Subsequent calls are no-ops.
    func start() {
        self.started.signal()
    }

    /// The result of the operation, suspending until it completes.
    var value: Success {
        get async throws { try await self.task.value }
    }

    /// The result of the operation, suspending until it completes.
    var result: Result<Success, Error> {
        get async { await self.task.result }
    }

    /// Cancels the underlying task. An operation that hasn't started yet still runs once
    /// ``start()`` is called, with its cancellation flag already set.
    func cancel() {
        self.task.cancel()
    }
}

/// A one-shot, thread-safe asynchronous signal.
///
/// Callers of ``wait()`` suspend until ``signal()`` is invoked. Once signaled, the signal stays
/// signaled: any subsequent (or already suspended) `wait()` returns immediately.
private final class AsyncSignal: Sendable {

    private struct State {
        var isSignaled = false
        var continuations: [CheckedContinuation<Void, Never>] = []
    }

    private let state: Atomic<State> = .init(.init())

    func wait() async {
        await withCheckedContinuation { continuation in
            let alreadySignaled = self.state.modify { state -> Bool in
                guard !state.isSignaled else { return true }
                state.continuations.append(continuation)
                return false
            }

            if alreadySignaled {
                continuation.resume()
            }
        }
    }

    func signal() {
        let continuations = self.state.modify { state -> [CheckedContinuation<Void, Never>] in
            state.isSignaled = true
            defer { state.continuations = [] }
            return state.continuations
        }

        for continuation in continuations {
            continuation.resume()
        }
    }
}
