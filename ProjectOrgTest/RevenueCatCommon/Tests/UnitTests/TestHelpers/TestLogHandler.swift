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

#if ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
@testable import RevenueCat_CustomEntitlementComputation
#else
@testable import RevenueCat
#endif

import Foundation
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
/// matches that of the test, and the observed logged messages are those that happen during the test.
/// This is already defined in every subclass of `TestCase`.
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
final class TestLogHandler {

    typealias MessageData = (level: LogLevel, message: String)

    var messages: [MessageData] { return self.loggedMessages.value }
    private let capacity: Int

    init(
        capacity: Int = TestLogHandler.defaultMessageLimit,
        file: String = #fileID,
        line: UInt = #line
    ) {
        self.capacity = capacity
        self.creationContext = .init(file: file, line: line)
        Self.sharedHandler.add(observer: self)
    }

    deinit { Self.sharedHandler.remove(observer: self) }

    /// If a test overrides `Purchases.verboseLogHandler` or `Logger.internalLogHandler`
    /// this needs to be called to re-install the test handler.
    static func restore() {
        Self.sharedHandler.install()
    }

    private let loggedMessages: Atomic<[MessageData]> = .init([])
    private let creationContext: Context

    private static let sharedHandler: SharedTestLogHandler = {
        let handler = SharedTestLogHandler()
        handler.install()

        return handler
    }()

}

extension TestLogHandler: Sendable {}

extension TestLogHandler {

    private typealias EntryCondition = @Sendable (MessageData) -> Bool

    /// Useful if you want to ignore messages logged so far.
    func clearMessages() {
        self.loggedMessages.value.removeAll(keepingCapacity: false)
    }

    func verifyMessageWasLogged(
        _ message: CustomStringConvertible,
        level: LogLevel? = nil,
        expectedCount: Int? = nil,
        file: FileString = #file,
        line: UInt = #line
    ) {
        precondition(expectedCount == nil || expectedCount! > 0)

        let condition = Self.entryCondition(message: message, level: level)

        expect(
            file: file,
            line: line,
            self.messages
        )
        .to(
            containElementSatisfying(condition),
            description: "Message '\(message)' not found. Logged messages: \(self.messages)"
        )

        if let expectedCount = expectedCount {
            expect(
                file: file,
                line: line,
                self.messagesMatching(condition)
            )
            .to(
                equal(expectedCount),
                description: "Message '\(message)' expected \(expectedCount) times"
            )
        }
    }

    @available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
    func verifyMessageIsEventuallyLogged(
        _ message: String,
        level: LogLevel? = nil,
        expectedCount: Int? = nil,
        timeout: DispatchTimeInterval = AsyncDefaults.timeout,
        pollInterval: DispatchTimeInterval = AsyncDefaults.pollInterval,
        file: FileString = #file,
        line: UInt = #line
    ) async throws {
        let condition = Self.entryCondition(message: message, level: level)

        try await asyncWait(
            description: "Message '\(message)' not found. Logged messages: \(self.messages)",
            timeout: timeout,
            pollInterval: pollInterval,
            file: file,
            line: line
        ) {
            self.messages.contains(where: condition)
        }

        if let expectedCount = expectedCount {
            try await asyncWait(
                description: "Message '\(message)' expected \(expectedCount) times",
                timeout: timeout,
                pollInterval: pollInterval,
                file: file,
                line: line
            ) {
                self.messagesMatching(condition) == expectedCount
            }
        }
    }

    /// - Parameter allowNoMessages: by default, this method requires logs to not be empty
    /// to eliminate the possibility of false positives due to log handler not being installed properly.
    func verifyMessageWasNotLogged(
        _ message: CustomStringConvertible,
        level: LogLevel? = nil,
        allowNoMessages: Bool = false,
        file: FileString = #file,
        line: UInt = #line
    ) {
        if !allowNoMessages {
            expect(
                file: file,
                line: line,
                self.messages
            )
            .toNot(
                beEmpty(),
                description: "Tried to verify message was not logged, but found no messages. " +
                "This is likely a false positive."
            )
        }

        expect(
            file: file,
            line: line,
            self.messages
        )
        .toNot(
            containElementSatisfying(Self.entryCondition(message: message, level: level)),
            description: "Message '\(message)' should not have been logged"
        )
    }

    private func messagesMatching(_ condition: EntryCondition) -> Int {
        return self
            .messages
            .lazy
            .filter(condition)
            .count
    }

    private static func entryCondition(
        message: CustomStringConvertible, level: LogLevel?
    ) -> EntryCondition {
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

private extension TestLogHandler {

    struct Context {
        let file: String
        let line: UInt
    }

}

extension TestLogHandler: LogMessageObserver {

    func didReceive(message: String, with level: LogLevel) {
        self.loggedMessages.modify {
            $0.append((level, message))

            let count = $0.count

            expect(count).to(
                beLessThan(self.capacity),
                description: "\(count) messages have been stored. " +
                "This is likely a programming error and \(self) " +
                "(created in \(self.creationContext.file):\(self.creationContext.line) has leaked."
            )
        }
    }

    private static let defaultMessageLimit = 200

}

private final class SharedTestLogHandler {

    private let observers: Atomic<[WeakBox<LogMessageObserver>]>
    private let logHandler: InternalLogHandler

    init() {
        self.observers = .init([])
        self.logHandler = { [observers] level, message, category, file, function, line in
            Logger.defaultLogHandler(level, message, category, file, function, line)

            Self.notify(observers: observers.value, message: message, level: level)
        }
    }

    func install() {
        Logger.internalLogHandler = self.logHandler
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
