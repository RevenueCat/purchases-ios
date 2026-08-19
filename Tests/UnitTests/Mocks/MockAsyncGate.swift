//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockAsyncGate.swift
//
//  Created by Antonio Pallares on 8/18/26.

import Foundation

/// A one-shot, thread-safe async gate used to deterministically order concurrent operations in tests.
/// Callers of `wait()` suspend until `open()` is invoked; once open, `wait()` returns immediately.
final class MockAsyncGate: @unchecked Sendable {

    private let lock = NSLock()
    private var isOpen = false
    private var continuations: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        await withCheckedContinuation { continuation in
            self.lock.lock()
            if self.isOpen {
                self.lock.unlock()
                continuation.resume()
            } else {
                self.continuations.append(continuation)
                self.lock.unlock()
            }
        }
    }

    func open() {
        self.lock.lock()
        self.isOpen = true
        let continuations = self.continuations
        self.continuations = []
        self.lock.unlock()

        for continuation in continuations {
            continuation.resume()
        }
    }
}
