//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AsyncConcurrencyLimiter.swift
//
//  Created by Rick van der Linden on 11/4/26.

/// Limits concurrent asynchronous operations, admitting waiters in first-in, first-out order.
actor AsyncConcurrencyLimiter {

    private var availablePermits: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(maxConcurrentOperations: Int) {
        self.availablePermits = max(1, maxConcurrentOperations)
    }

    /// Runs an operation after acquiring a permit and always releases it when the operation completes.
    func perform<Value: Sendable>(
        _ operation: @Sendable () async -> Value
    ) async -> Value {
        await self.acquire()
        let value = await operation()
        self.release()
        return value
    }

    /// Runs a non-returning operation unless its task was canceled while waiting for a permit.
    func perform(_ operation: @Sendable () async -> Void) async {
        await self.acquire()
        if !Task.isCancelled {
            await operation()
        }
        self.release()
    }

    private func acquire() async {
        guard self.availablePermits == 0 else {
            self.availablePermits -= 1
            return
        }

        await withCheckedContinuation { continuation in
            self.waiters.append(continuation)
        }
    }

    private func release() {
        guard !self.waiters.isEmpty else {
            self.availablePermits += 1
            return
        }

        self.waiters.removeFirst().resume()
    }

}
