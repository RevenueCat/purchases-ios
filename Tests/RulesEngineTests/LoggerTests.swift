//
//  LoggerTests.swift
//
//  Created by Antonio Pallares.
//

import XCTest

@testable import RulesEngine

final class LoggerTests: XCTestCase {

    func testCapturingLoggerRecordsWarningsInOrder() {
        let logger = CapturingLogger()
        logger.warn("first")
        logger.warn("second")
        XCTAssertEqual(logger.warnings, ["first", "second"])
    }

    func testPrintLoggerDoesNotCrash() {
        // Smoke test: just make sure the default logger is callable. We
        // can't easily intercept stderr, but the goal here is to catch
        // crashes / mis-typed format strings rather than verify content.
        let logger = PrintLogger()
        logger.warn("smoke")
    }
}
