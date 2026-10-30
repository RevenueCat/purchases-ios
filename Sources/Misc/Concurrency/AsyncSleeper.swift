//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AsyncSleeper.swift
//
//  Created by Antonio Pallares on 28/9/26.

import Foundation

/// Waits between attempts of something that is retried or polled, so tests can decide how long a wait
/// really takes. Production wiring is ``TaskSleeper``.
internal protocol AsyncSleeper: Sendable {

    /// Throws if the calling task is cancelled while it waits.
    func sleep(seconds: TimeInterval) async throws

}

internal struct TaskSleeper: AsyncSleeper {

    func sleep(seconds: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

}
