//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LoggerType.swift
//
//  Created by Nacho Soto on 11/29/22.

import Foundation
import os

// swiftlint:disable force_unwrapping

/// A type that can receive logs of different levels.
protocol LoggerType {

    func verbose(_ message: @autoclosure () -> LogMessage,
                 fileName: String?,
                 functionName: String?,
                 line: UInt)
    func debug(_ message: @autoclosure () -> LogMessage,
               fileName: String?,
               functionName: String?,
               line: UInt)
    func info(_ message: @autoclosure () -> LogMessage,
              fileName: String?,
              functionName: String?,
              line: UInt)
    func warn(_ message: @autoclosure () -> LogMessage,
              fileName: String?,
              functionName: String?,
              line: UInt)
    func error(_ message: @autoclosure () -> LogMessage,
               fileName: String,
               functionName: String,
               line: UInt)

}

/// Contains a message that can be output by ``os.Logger``.
protocol LogMessage: CustomStringConvertible {

    var description: String { get }
    var category: String { get }

}

/// Enumeration of the different verbosity levels.
///
/// #### Related Symbols
/// - ``Purchases/logLevel``
@objc(RCLogLevel) public enum LogLevel: Int, CustomStringConvertible, CaseIterable, Sendable {

    // swiftlint:disable missing_docs

    case verbose = 4
    case debug = 0
    case info = 1
    case warn = 2
    case error = 3

    public var description: String {
        switch self {
        case .verbose: return "VERBOSE"
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warn: return "WARN"
        case .error: return "ERROR"
        }
    }

    // swiftlint:enable missing_docs
}

/// An in-memory cache of ``os.Logger`` instances based on their category.
@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
final class LoggerStore {

    private var loggersByCategory: [String: os.Logger] = [:]

    func logger(for category: String) -> os.Logger {
        return self.loggersByCategory[category, default: Self.create(for: category)]
    }

    private static func create(for category: String) -> os.Logger {
        return .init(subsystem: Self.subsystem, category: category)
    }

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.revenuecat.Purchases"

}

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
private let store = LoggerStore()

// swiftlint:disable:next function_parameter_count
func defaultLogHandler(
    framework: String,
    verbose: Bool,
    level: LogLevel,
    category: String,
    message: String,
    file: String?,
    function: String?,
    line: UInt
) {
    let fileContext: String
    if verbose, let file = file, let function = function {
        let fileName = (file as NSString)
            .lastPathComponent
            .replacingOccurrences(of: ".swift", with: "")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        fileContext = "\t\(fileName).\(function):\(line)"
    } else {
        fileContext = ""
    }

    if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
        store
            .logger(for: category)
            .log(
                level: level.logType,
                "\(level.description, privacy: .public)\(fileContext, privacy: .public): \(message, privacy: .public)"
            )
    } else {
        NSLog("%@", "[\(framework)] - \(level.description)\(fileContext): \(message)")
    }
}

// MARK: -

/// Default overloads to allow implicit values
extension LoggerType {

    func verbose(_ message: @autoclosure () -> LogMessage,
                 _ fileName: String? = #fileID,
                 _ functionName: String? = #function,
                 _ line: UInt = #line) {
        self.verbose(message(), fileName: fileName, functionName: functionName, line: line)
    }

    func debug(_ message: @autoclosure () -> LogMessage,
               _ fileName: String? = #fileID,
               _ functionName: String? = #function,
               _ line: UInt = #line) {
        self.debug(message(), fileName: fileName, functionName: functionName, line: line)
    }

    func info(_ message: @autoclosure () -> LogMessage,
              _ fileName: String? = #fileID,
              _ functionName: String? = #function,
              _ line: UInt = #line) {
        self.info(message(), fileName: fileName, functionName: functionName, line: line)
    }

    func warn(_ message: @autoclosure () -> LogMessage,
              _ fileName: String? = #fileID,
              _ functionName: String? = #function,
              _ line: UInt = #line) {
        self.warn(message(), fileName: fileName, functionName: functionName, line: line)
    }

    func error(_ message: @autoclosure () -> LogMessage,
               _ fileName: String = #fileID,
               _ functionName: String = #function,
               _ line: UInt = #line) {
        self.error(message(), fileName: fileName, functionName: functionName, line: line)
    }

}

private extension LogLevel {

    var logType: OSLogType {
        return Self.logTypes[self]!
    }

    private func calculateLogType() -> OSLogType {
        switch self {
        case .verbose, .debug:
            #if DEBUG
            if ProcessInfo.isRunningIntegrationTests {
                // See https://github.com/RevenueCat/purchases-ios/pull/3108
                // With `.debug` we'd lose these logs when running integration tests on CI.
                return .info
            } else {
                return .debug
            }
            #else
            return .debug
            #endif

        case .info: return .info
        case .warn: return .error
        case .error: return .error
        }
    }

    private static let logTypes: [Self: OSLogType] =
        .init(uniqueKeysWithValues: Self.allCases.lazy.map {
            ($0, $0.calculateLogType())
        })

}
