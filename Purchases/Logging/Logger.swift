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

class Logger {

    static var logLevel: LogLevel = .info
    static var logHandler: (LogLevel, String) -> Void = { level, message in
        NSLog("[\(frameworkDescription)] - \(level.description): \(message)")
    }

    private static let frameworkDescription = "Purchases"

    static func debug(_ message: CustomStringConvertible) {
        log(level: .debug, intent: .info, message: message.description)
    }

    static func info(_ message: CustomStringConvertible) {
        log(level: .info, intent: .info, message: message.description)
    }

    static func warn(_ message: CustomStringConvertible) {
        log(level: .warn, intent: .warning, message: message.description)
    }

    static func error(_ message: CustomStringConvertible) {
        log(level: .error, intent: .rcError, message: message.description)
    }

}

extension Logger {

    static func appleError(_ message: CustomStringConvertible) {
        log(level: .error, intent: .appleError, message: message.description)
    }

    static func appleWarning(_ message: CustomStringConvertible) {
        log(level: .warn, intent: .appleError, message: message.description)
    }

    static func purchase(_ message: CustomStringConvertible) {
        log(level: .debug, intent: .purchase, message: message.description)
    }

    static func rcPurchaseSuccess(_ message: CustomStringConvertible) {
        log(level: .info, intent: .rcPurchaseSuccess, message: message.description)
    }

    static func rcSuccess(_ message: CustomStringConvertible) {
        log(level: .debug, intent: .rcSuccess, message: message.description)
    }

    static func user(_ message: CustomStringConvertible) {
        log(level: .debug, intent: .user, message: message.description)
    }

}

private extension Logger {

    static func log(level: LogLevel, message: String) {
        guard self.logLevel.rawValue <= level.rawValue else { return }
        logHandler(level, message)
    }

    static func log(level: LogLevel, intent: LogIntent, message: String) {
        let messageWithPrefix = "\(intent.prefix) \(message)"
        Logger.log(level: level, message: messageWithPrefix)
    }

}
