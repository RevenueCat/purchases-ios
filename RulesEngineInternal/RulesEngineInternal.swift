//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RulesEngineInternal.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Namespace for the RevenueCat rules engine.
public enum RulesEngine {}

extension RulesEngine {

    /// Per-task override used by tests and scoped diagnostic callers.
    /// When `nil`, logging falls through to the module default.
    @TaskLocal static var scopedLogger: RulesEngineLogger?

    static var logger: RulesEngineLogger {
        scopedLogger ?? loggerStorage.value
    }

    /// Host-SDK wiring entry point. Idempotent; intended to be called once during configure.
    @_spi(Internal)
    public static func setDefaultLogger(_ logger: RulesEngineLogger) {
        loggerStorage.value = logger
    }

    private static let loggerStorage = LoggerStorage()
}

/// Locked storage for the module default logger. A reference type so the enclosing
/// namespace's `static let loggerStorage` can be a stored property.
private final class LoggerStorage {

    private let lock = NSLock()
    private var current: RulesEngineLogger = PrintLogger()

    var value: RulesEngineLogger {
        get {
            lock.lock()
            defer { lock.unlock() }
            return current
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            current = newValue
        }
    }
}
