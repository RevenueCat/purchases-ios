//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TimingUtil.swift
//
//  Created by Nacho Soto on 11/15/22.

import Foundation

internal enum TimingUtil {

    typealias Duration = TimeInterval

}

// MARK: - async API

extension TimingUtil {

    /// Measures the time to execute `work` and returns the result and the duration.
    /// Example:
    /// ```swift
    /// let (result, duration) = try await TimingUtil.measure {
    ///    return try await asyncMethod()
    /// }
    /// ```
    static func measure<Value>(
        _ clock: ClockType = Clock.default,
        _ work: @Sendable () async throws -> Value
    ) async rethrows -> (result: Value, duration: Duration) {
        let start = clock.currentTime
        let result = try await work()

        return (
            result: result,
            duration: clock.durationSince(start)
        )
    }

    /// Measures the time to execute `work`, returns the result,
    /// and logs `message` if duration exceeded `threshold`.
    /// Example:
    /// ```swift
    /// let result = try await TimingUtil.measureAndLogIfTooSlow(
    ///     threshold: 2,
    ///     message: "Computation too slow",
    ///     level: .warn,
    ///     intent: .appleWarning
    /// ) {
    ///    try await asyncMethod()
    /// }
    /// ```
    static func measureAndLogIfTooSlow<Value>(
        threshold: Duration,
        message: CustomStringConvertible,
        level: LogLevel = .warn,
        intent: LogIntent = .appleWarning,
        clock: ClockType = Clock.default,
        work: @Sendable () async throws -> Value
    ) async rethrows -> Value {
        precondition(threshold > 0, "Invalid threshold: \(threshold)")

        let (result, duration) = try await self.measure(clock, work)

        Self.logIfRequired(duration: duration,
                           threshold: threshold,
                           message: message,
                           level: level,
                           intent: intent)

        return result
    }

    /// Measures the time to execute `work`, returns the result,
    /// and logs `message` if duration exceeded `threshold`.
    /// Example:
    /// ```swift
    /// let result = try await TimingUtil.measureAndLogIfTooSlow(
    ///     threshold: .productRequest,
    ///     message: "Computation too slow",
    ///     level: .warn,
    ///     intent: .appleWarning
    /// ) {
    ///    try await asyncMethod()
    /// }
    /// ```
    static func measureAndLogIfTooSlow<Value, Message: CustomStringConvertible & Sendable>(
        threshold: Configuration.TimingThreshold,
        message: Message,
        level: LogLevel = .warn,
        intent: LogIntent = .appleWarning,
        clock: ClockType = Clock.default,
        _ work: @Sendable () async throws -> Value
    ) async rethrows -> Value {
        return try await self.measureAndLogIfTooSlow(
            threshold: threshold.rawValue,
            message: message,
            level: level,
            intent: intent,
            work: work
        )
    }

}

// MARK: - Synchronous API

extension TimingUtil {

    /// Measures the time to execute `work` and returns the result and the duration.
    /// Example:
    /// ```swift
    /// let (result, duration) = try TimingUtil.measure {
    ///    return try method()
    /// }
    /// ```
    static func measureSync<Value>(
        _ clock: ClockType = Clock.default,
        _ work: () throws -> Value
    ) rethrows -> (result: Value, duration: Duration) {
        let start = clock.currentTime
        let result = try work()

        return (
            result: result,
            duration: clock.durationSince(start)
        )
    }

    /// Measures the time to execute `work`, returns the result,
    /// and logs `message` if duration exceeded `threshold`.
    /// Example:
    /// ```swift
    /// let result = try TimingUtil.measureAndLogIfTooSlow(
    ///     threshold: .productRequest,
    ///     message: "Computation too slow",
    ///     level: .warn,
    ///     intent: .appleWarning
    /// ) {
    ///    try method()
    /// }
    /// ```
    static func measureSyncAndLogIfTooSlow<Value, Message: CustomStringConvertible & Sendable>(
        threshold: Configuration.TimingThreshold,
        message: Message,
        level: LogLevel = .warn,
        intent: LogIntent = .appleWarning,
        clock: ClockType = Clock.default,
        _ work: () throws -> Value
    ) rethrows -> Value {
        return try self.measureSyncAndLogIfTooSlow(
            threshold: threshold.rawValue,
            message: message,
            level: level,
            intent: intent,
            work)
    }

    /// Measures the time to execute `work`, returns the result,
    /// and logs `message` if duration exceeded `threshold`.
    /// Example:
    /// ```swift
    /// let result = try TimingUtil.measureAndLogIfTooSlow(
    ///     threshold: .productRequest,
    ///     message: "Computation too slow",
    ///     level: .warn,
    ///     intent: .appleWarning
    /// ) {
    ///    try asyncMethod()
    /// }
    /// ```
    static func measureSyncAndLogIfTooSlow<Value, Message: CustomStringConvertible & Sendable>(
        threshold: Duration,
        message: Message,
        level: LogLevel = .warn,
        intent: LogIntent = .appleWarning,
        clock: ClockType = Clock.default,
        _ work: () throws -> Value
    ) rethrows -> Value {
        let (result, duration) = try self.measureSync(clock, work)

        Self.logIfRequired(duration: duration,
                           threshold: threshold,
                           message: message,
                           level: level,
                           intent: intent)

        return result
    }

}

// MARK: - completion-block API

extension TimingUtil {

    /// Measures the time to execute `work` and returns the `Result` and the duration.
    /// Example:
    /// ```swift
    /// TimingUtil.measure { completion in
    ///     work { completion($0) }
    /// } result: { result, duration in
    ///     print("Result: \(result) calculated in \(duration) seconds")
    /// }
    /// ```
    static func measure<Value>(
        _ clock: ClockType = Clock.default,
        _ work: (@escaping @Sendable (Value) -> Void) -> Void,
        result: @escaping (Value, Duration) -> Void
    ) {
        let start = clock.currentTime

        work { value in
            result(value, clock.durationSince(start))
        }
    }

    /// Measures the time to execute `work`, returns the result,
    /// and logs `message` if duration exceeded `threshold`.
    /// Example:
    /// ```swift
    /// TimingUtil.measureAndLogIfTooSlow(
    ///     threshold: 2,
    ///     message: "Computation too slow",
    ///     level: .warn,
    ///     intent: .appleWarning
    /// ) { completion in
    ///     work { completion($0) }
    /// } result: { result in
    ///     print("Finished computing: \(result)")
    /// }
    /// ```
    static func measureAndLogIfTooSlow<Value>(
        threshold: Duration,
        message: CustomStringConvertible,
        level: LogLevel = .warn,
        intent: LogIntent = .appleWarning,
        clock: ClockType = Clock.default,
        work: (@escaping @Sendable (Value) -> Void) -> Void,
        result: @escaping (Value) -> Void
    ) {
        Self.measure(clock, work) { value, duration in
            Self.logIfRequired(duration: duration,
                               threshold: threshold,
                               message: message,
                               level: level,
                               intent: intent)

            result(value)
        }
    }

    /// Measures the time to execute `work`, returns the result,
    /// and logs `message` if duration exceeded `threshold`.
    /// Example:
    /// ```swift
    /// TimingUtil.measureAndLogIfTooSlow(
    ///     threshold: .productRequest,
    ///     message: "Computation too slow",
    ///     level: .warn,
    ///     intent: .appleWarning
    /// ) { completion in
    ///     work { completion($0) }
    /// } result: { result in
    ///     print("Finished computing: \(result)")
    /// }
    /// ```
    static func measureAndLogIfTooSlow<Value>(
        threshold: Configuration.TimingThreshold,
        message: CustomStringConvertible,
        level: LogLevel = .warn,
        intent: LogIntent = .appleWarning,
        clock: ClockType = Clock.default,
        work: (@escaping @Sendable (Value) -> Void) -> Void,
        result: @escaping (Value) -> Void
    ) {
        Self.measureAndLogIfTooSlow(threshold: threshold.rawValue,
                                    message: message,
                                    level: level,
                                    intent: intent,
                                    clock: clock,
                                    work: work,
                                    result: result)
    }

}

// MARK: - Private

private extension TimingUtil {

    static func logIfRequired(
        duration: Duration,
        threshold: Duration,
        message: CustomStringConvertible,
        level: LogLevel,
        intent: LogIntent
    ) {
        if duration >= threshold {
            Logger.log(
                level: level,
                intent: intent,
                message: Strings.diagnostics.timing_message(message: message.description,
                                                            duration: duration)
            )
        }
    }

}
