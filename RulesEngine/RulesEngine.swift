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

/// Namespace for the RevenueCat rules engine. Named `Rules` rather than
/// `RulesEngine` to avoid colliding with the module name — from the test
/// target's perspective (`@testable import RulesEngine`) the bare
/// identifier `RulesEngine` resolves to the module, which would force
/// callers to write `RulesEngine.RulesEngine.something` to reach the
/// namespace.
@_spi(Internal) public enum Rules {}

extension Rules {

    /// Logger used by the evaluator and operator implementations for
    /// diagnostic warnings (e.g. missing variables, unknown operators,
    /// malformed args). Defaults to `PrintLogger` during development; the
    /// SDK integration point will replace this with an adapter into the
    /// host SDK's logging system.
    ///
    /// Threading the logger through every operator call would be pure
    /// boilerplate (only `AccessorOperators` actually emits warnings
    /// today), so we make it module state. Access is `NSLock`-synchronized
    /// through `loggerStorage` so a concurrent reader during a write
    /// can't observe a half-assigned value.
    static var logger: RulesEngineLogger {
        get { loggerStorage.value }
        set { loggerStorage.value = newValue }
    }

    private static let loggerStorage = LoggerStorage()
}

/// Locked storage for `Rules.logger`. A reference type so the enclosing
/// namespace's `static let loggerStorage` can be a stored property
/// (Swift forbids stored properties on enums, but `static let` of a
/// class instance is fine).
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
