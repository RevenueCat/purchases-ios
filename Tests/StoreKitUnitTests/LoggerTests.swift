//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LoggerTests.swift
//
//  Created by Nacho Soto on 11/29/22.

import Nimble
import XCTest

@testable import RevenueCat

// Note: this is in `StoreKitUnitTests` because it modifies the global `Logger.logLevel`
// which means it would interfere with other tests if ran concurrently.
class LoggerTests: TestCase {

    private var logger: TestLogHandler!
    private var previousLogLevel: LogLevel!

    override func setUp() {
        super.setUp()

        self.logger = .init()
        self.previousLogLevel = Logger.logLevel
    }

    override func tearDown() {
        Logger.logLevel = self.previousLogLevel

        super.tearDown()
    }

    func testLogLevelOrderContainsAllLevels() {
        expect(Set(LogLevel.order.keys)) == Set(LogLevel.allCases)
    }

    func testLogLevelOrdering() {
        let levels: [LogLevel] = LogLevel.allCases.shuffled()

        expect(levels.sorted()) == [
            .verbose,
            .debug,
            .info,
            .warn,
            .error
        ]
    }

    func testLoggerLogsMessagesWithHigherLevel() {
        Logger.logLevel = .info
        Logger.warn(Self.logMessage)

        self.logger.verifyMessageWasLogged(Self.logMessage, level: .warn)
    }

    func testLoggerLogsMessagesWithHigherLevelThanVerbose() {
        Logger.logLevel = .verbose
        Logger.info(Self.logMessage)

        self.logger.verifyMessageWasLogged(Self.logMessage, level: .info)
    }

    func testLoggerLogsMessagesWithSameLevel() {
        Logger.logLevel = .info
        Logger.info(Self.logMessage)

        self.logger.verifyMessageWasLogged(Self.logMessage, level: .info)
    }

    func testLoggerDoesNotLogMessagesWithLowerLevel() {
        Logger.logLevel = .info
        Logger.debug(Self.logMessage)

        self.logger.verifyMessageWasNotLogged(Self.logMessage)
    }

}

private extension LoggerTests {

    static let logMessage = "Log message"

}
