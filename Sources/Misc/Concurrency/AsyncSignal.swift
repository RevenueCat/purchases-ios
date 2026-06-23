//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AsyncSignal.swift
//
//  Created by Antonio Pallares on 23/6/26.

import Foundation

/// A one-shot, thread-safe asynchronous signal.
///
/// Callers of ``wait()`` suspend until ``signal()`` is invoked. Once signaled, the signal stays
/// signaled: any subsequent (or already suspended) `wait()` returns immediately.
final class AsyncSignal: Sendable {

    private struct State {
        var isSignaled = false
        var continuations: [CheckedContinuation<Void, Never>] = []
    }

    private let state: Atomic<State> = .init(.init())

    /// Suspends until ``signal()`` has been called. Returns immediately if already signaled.
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

    /// Signals, resuming every current and future ``wait()`` caller. Subsequent calls are no-ops.
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
