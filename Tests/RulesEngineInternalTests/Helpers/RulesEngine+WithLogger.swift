//
//  RulesEngine+WithLogger.swift
//
//  Created by Antonio Pallares.
//

import Foundation

@testable import RulesEngineInternal

/// Test-only convenience for scoping a `RulesEngine.logger` override to a single
/// expression. Tests that install a logger globally via `setUp` /
/// `tearDown` don't need this; it exists for the one-off case (e.g.
/// asserting that a specific evaluation emits a warning) where wiring
/// the lifecycle through XCTest would be overkill.
extension RulesEngine {

    /// Install `logger` as the module logger for the duration of `body`,
    /// restoring the previous logger on exit (including when `body`
    /// throws). Not designed for concurrent use across tasks — XCTest
    /// runs test methods serially within a class, which is the only
    /// contract we lean on.
    static func withLogger<T>(
        _ logger: RulesEngineLogger,
        _ body: () throws -> T
    ) rethrows -> T {
        let previous = self.logger
        self.logger = logger
        defer { self.logger = previous }
        return try body()
    }
}
