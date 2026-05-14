//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
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
