//
//  RulesEngineTests.swift
//
//  Created by Antonio Pallares.
//

import XCTest

@_spi(Internal) @testable import RulesEngine

final class RulesEngineTests: XCTestCase {

    /// Smoke test: confirms the module is wired up and the test runner
    /// picks it up. Real evaluation tests will land alongside the JSON
    /// Logic implementation.
    func testRulesEngineNamespaceIsReachable() {
        _ = RulesEngine.self
    }
}
