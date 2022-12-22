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

/// A type that can receive logs of different levels.
protocol LoggerType {

    func verbose(_ message: @autoclosure () -> CustomStringConvertible,
                 fileName: String?,
                 functionName: String?,
                 line: UInt)
    func debug(_ message: @autoclosure () -> CustomStringConvertible,
               fileName: String?,
               functionName: String?,
               line: UInt)
    func info(_ message: @autoclosure () -> CustomStringConvertible,
              fileName: String?,
              functionName: String?,
              line: UInt)
    func warn(_ message: @autoclosure () -> CustomStringConvertible,
              fileName: String?,
              functionName: String?,
              line: UInt)
    func error(_ message: @autoclosure () -> CustomStringConvertible,
               fileName: String,
               functionName: String,
               line: UInt)

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

// swiftlint:disable:next function_parameter_count
func defaultLogHandler(
    framework: String,
    verbose: Bool,
    level: LogLevel,
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

    NSLog("%@", "[\(framework)] - \(level.description)\(fileContext): \(message)")
}

// MARK: -

/// Default overloads to allow implicit values
extension LoggerType {

    func verbose(_ message: @autoclosure () -> CustomStringConvertible,
                 _ fileName: String? = #fileID,
                 _ functionName: String? = #function,
                 _ line: UInt = #line) {
        self.verbose(message(), fileName: fileName, functionName: functionName, line: line)
    }

    func debug(_ message: @autoclosure () -> CustomStringConvertible,
               _ fileName: String? = #fileID,
               _ functionName: String? = #function,
               _ line: UInt = #line) {
        self.debug(message(), fileName: fileName, functionName: functionName, line: line)
    }

    func info(_ message: @autoclosure () -> CustomStringConvertible,
              _ fileName: String? = #fileID,
              _ functionName: String? = #function,
              _ line: UInt = #line) {
        self.info(message(), fileName: fileName, functionName: functionName, line: line)
    }

    func warn(_ message: @autoclosure () -> CustomStringConvertible,
              _ fileName: String? = #fileID,
              _ functionName: String? = #function,
              _ line: UInt = #line) {
        self.warn(message(), fileName: fileName, functionName: functionName, line: line)
    }

    func error(_ message: @autoclosure () -> CustomStringConvertible,
               _ fileName: String = #fileID,
               _ functionName: String = #function,
               _ line: UInt = #line) {
        self.error(message(), fileName: fileName, functionName: functionName, line: line)
    }

}
