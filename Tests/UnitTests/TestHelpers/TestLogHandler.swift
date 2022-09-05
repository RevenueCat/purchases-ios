//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TestLogHandler.swift
//
//  Created by Nacho Soto on 8/19/22.

@testable import RevenueCat

import Nimble

/// Provides a `Logger.VerboseLogHandler` that wraps the default implementation
/// and allows introspecting logged messages.
///
/// - Warning: this will implicitly override `Purchases.verboseLogHandler`.
/// - Note: this only _wraps_ the original implementation, so messages are still logged to the console.
///
/// This type can be used with the RAII pattern.
///
/// ### Examples:
/// - Initialize `TestLogHandler` for every test. This ensures that the lifetime
/// matches that of the test, and the observed logged messages are those that happen during the test:
///
/// ```swift
/// private var testLogHandler: TestLogHandler!
/// override func setUp() {
///     super.setUp()
///     self.testLogHandler = TestLogHandler()
/// }
///
/// override func tearDown() {
///     self.testLogHandler = nil
///     super.tearDown()
/// }
/// ```
///
/// - Alternatively, `TestLogHandler` can be used locally within a single test:
///
/// ```swift
/// func testExample() {
///     let logHandler = TestLogHandler()
///
///     // Run some code
///
///     expect(logHandler.loggedMessages.onlyElement?.message) == "Expected log"
/// }
/// ```
final class TestLogHandler {

    typealias MessageData = (level: LogLevel, message: String)

    var messages: [MessageData] { return self.loggedMessages.value }

    init() { Self.sharedHandler.add(observer: self) }

    deinit { Self.sharedHandler.remove(observer: self) }

    private let loggedMessages: Atomic<[MessageData]> = .init([])

    private static let sharedHandler: SharedTestLogHandler = {
        let handler = SharedTestLogHandler()
        handler.install()

        return handler
    }()

}

extension TestLogHandler: Sendable {}

extension TestLogHandler {

    func verifyMessageWasLogged(
        _ message: CustomStringConvertible,
        level: LogLevel? = nil,
        file: FileString = #file,
        line: UInt = #line
    ) {
        expect(
            file: file,
            line: line,
            self.messages
        )
        .to(containElementSatisfying(Self.entryCondition(message: message, level: level)))
    }

    func verifyMessageWasNotLogged(
        _ message: CustomStringConvertible,
        level: LogLevel? = nil,
        file: FileString = #file,
        line: UInt = #line
    ) {
        expect(
            file: file,
            line: line,
            self.messages
        )
        .toNot(containElementSatisfying(Self.entryCondition(message: message, level: level)))
    }

    private static func entryCondition(message: CustomStringConvertible, level: LogLevel?) -> (MessageData) -> Bool {
        return { entry in
            guard entry.message.contains(message.description) else {
                return false
            }

            if let level = level, entry.level != level {
                return false
            }

            return true
        }
    }

}

// MARK: - Private

extension TestLogHandler: LogMessageObserver {

    func didReceive(message: String, with level: LogLevel) {
        self.loggedMessages.modify {
            $0.append((level, message))

            precondition(
                $0.count < Self.messageLimit,
                "\(Self.messageLimit) messages have been stored.\n" +
                "This is likely a programming error and \(self) has leaked."
            )
        }
    }

    private static let messageLimit = 100

}

private final class SharedTestLogHandler {

    private let observers: Atomic<[WeakBox<LogMessageObserver>]>
    private let logHandler: VerboseLogHandler

    init() {
        self.observers = .init([])
        self.logHandler = { [observers] level, message, file, function, line in
            Logger.defaultLogHandler(level, message, file, function, line)

            Self.notify(observers: observers.value, message: message, level: level)
        }
    }

    func install() {
        Purchases.verboseLogHandler = self.logHandler
    }

    func add(observer: LogMessageObserver) {
        self.observers.modify { $0.append(.init(observer)) }
    }

    func remove(observer: LogMessageObserver) {
        self.observers.modify { $0.removeAll { $0.value === observer } }
    }

    private static func notify(observers: [WeakBox<LogMessageObserver>], message: String, level: LogLevel) {
        for observer in observers {
            observer.value?.didReceive(message: message, with: level)
        }
    }

}

@objc protocol LogMessageObserver: AnyObject {

    func didReceive(message: String, with level: LogLevel)

}
