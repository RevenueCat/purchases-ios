//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RulesEngine.swift
//
//  Created by Antonio Pallares.
//

import Foundation

/// Namespace for the RevenueCat rules engine.
public enum RulesEngine {}

extension RulesEngine {

    static var logger: RulesEngineLogger {
        loggerStorage.value
    }

    static func setLogger(_ logger: RulesEngineLogger) {
        loggerStorage.value = logger
    }

    private static let loggerStorage = LoggerStorage()
}

/// Locked storage for `RulesEngine.logger`. A reference type so the enclosing
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
