//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Logger.swift
//
//  Created by Andrés Boedo on 11/13/20.
//

import Foundation

@objc(RCLogLevel) public enum LogLevel: Int, CustomStringConvertible {

    case debug, info, warn, error

    public var description: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warn: return "WARN"
        case .error: return "ERROR"
        }
    }

}

/// A function that can handle a log message
public typealias LogHandler = (_ level: LogLevel,
                               _ message: String,
                               _ file: String?,
                               _ function: String?,
                               _ line: UInt
) -> Void

class Logger {
    static var logLevel: LogLevel = .info
    static var logHandler: LogHandler = { level, message, file, functionName, line in
        let fileContext: String
        if let file = file, let functionName = functionName {
            let fileName = (file as NSString)
                .lastPathComponent
                .replacingOccurrences(of: ".swift", with: "")
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

            fileContext = "\t\(fileName).\(functionName):\(line)"
        } else {
            fileContext = ""
        }

        NSLog("%@", "[\(frameworkDescription)] - \(level.description)\(fileContext): \(message)")
    }

    private static let frameworkDescription = "Purchases"

    static func debug(_ message: CustomStringConvertible,
                      fileName: String? = #fileID,
                      functionName: String? = #function,
                      line: UInt = #line) {
        log(level: .debug, intent: .info, message: message.description,
            fileName: fileName, functionName: functionName, line: line)
    }

    static func info(_ message: CustomStringConvertible,
                     fileName: String? = #fileID,
                     functionName: String? = #function,
                     line: UInt = #line) {
        log(level: .info, intent: .info, message: message.description,
            fileName: fileName, functionName: functionName, line: line)
    }

    static func warn(_ message: CustomStringConvertible,
                     fileName: String? = #fileID,
                     functionName: String? = #function,
                     line: UInt = #line) {
        log(level: .warn, intent: .warning, message: message.description,
            fileName: fileName, functionName: functionName, line: line)
    }

    static func error(_ message: CustomStringConvertible,
                      fileName: String = #fileID,
                      functionName: String = #function,
                      line: UInt = #line) {
        log(level: .error, intent: .rcError, message: message.description,
            fileName: fileName, functionName: functionName, line: line)
    }

}

extension Logger {

    static func appleError(_ message: CustomStringConvertible,
                           fileName: String = #fileID,
                           functionName: String = #function,
                           line: UInt = #line) {
        log(level: .error, intent: .appleError, message: message.description,
            fileName: fileName,
            functionName: functionName,
            line: line)
    }

    static func appleWarning(_ message: CustomStringConvertible,
                             fileName: String = #fileID,
                             functionName: String = #function,
                             line: UInt = #line) {
        log(level: .warn, intent: .appleError, message: message.description,
            fileName: fileName, functionName: functionName, line: line)
    }

    static func purchase(_ message: CustomStringConvertible,
                         fileName: String = #fileID,
                         functionName: String = #function,
                         line: UInt = #line) {
        log(level: .debug, intent: .purchase, message: message.description,
            fileName: fileName, functionName: functionName, line: line)
    }

    static func rcPurchaseSuccess(_ message: CustomStringConvertible,
                                  fileName: String = #fileID,
                                  functionName: String = #function,
                                  line: UInt = #line) {
        log(level: .info, intent: .rcPurchaseSuccess, message: message.description,
            fileName: fileName, functionName: functionName, line: line)
    }

    static func rcSuccess(_ message: CustomStringConvertible,
                          fileName: String = #fileID,
                          functionName: String = #function,
                          line: UInt = #line) {
        log(level: .debug, intent: .rcSuccess, message: message.description,
            fileName: fileName, functionName: functionName, line: line)
    }

    static func user(_ message: CustomStringConvertible,
                     fileName: String? = #fileID,
                     functionName: String? = #function,
                     line: UInt = #line) {
        log(level: .debug, intent: .user, message: message.description,
            fileName: fileName, functionName: functionName, line: line)
    }

}

private extension Logger {

    static func log(level: LogLevel,
                    message: String,
                    fileName: String? = #fileID,
                    functionName: String? = #function,
                    line: UInt = #line) {
        guard self.logLevel.rawValue <= level.rawValue else { return }
        logHandler(level, message, fileName, functionName, line)
    }

    static func log(level: LogLevel,
                    intent: LogIntent,
                    message: String,
                    fileName: String? = #fileID,
                    functionName: String? = #function,
                    line: UInt = #line) {
        let messageWithPrefix = "\(intent.prefix) \(message)"
        Logger.log(level: level,
                   message: messageWithPrefix,
                   fileName: fileName,
                   functionName: functionName,
                   line: line)
    }

}
