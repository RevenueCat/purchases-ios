//
//  Logger.swift
//  PurchasesCoreSwift
//
//  Created by Andrés Boedo on 11/13/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

// NOTE: this must exactly match the enum in RCLogging.h
@objc(RCInternalLogLevel) public enum LogLevel: Int {
    case debug, info, warn, error

    func description() -> String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warn: return "WARN"
        case .error: return "ERROR"
        }
    }
}

@objc(RCLog) public class Logger: NSObject {
    @objc public static var logLevel: LogLevel = .info
    @objc public static var logHandler: (LogLevel, String) -> Void = { level, message in
        NSLog("[\(frameworkDescription)] - \(level.description()): \(message)")
    }

    private static let frameworkDescription = "Purchases"

    @objc public static func log(level: LogLevel, message: String) {
        guard self.logLevel.rawValue <= level.rawValue else { return }
        logHandler(level, message)
    }

    @objc public static func log(level: LogLevel, intent: LogIntent, message: String) {
        let messageWithPrefix = "\(intent.suffix) \(message)"
        Logger.log(level: level, message: messageWithPrefix)
    }

    @objc public static func debug(_ message: String) {
        log(level: .debug, intent: .info, message: message)
    }

    @objc public static func info(_ message: String) {
        log(level: .info, intent: .info, message: message)
    }

    @objc public static func warn(_ message: String) {
        log(level: .warn, intent: .warning, message: message)
    }

    @objc public static func error(_ message: String) {
        log(level: .error, intent: .rcError, message: message)
    }
}

@objc public extension Logger {
    static func appleError(_ message: String) {
        log(level: .error, intent: .appleError, message: message)
    }

    static func appleWarning(_ message: String) {
        log(level: .warn, intent: .appleError, message: message)
    }

    static func purchase(_ message: String) {
        log(level: .debug, intent: .purchase, message: message)
    }

    static func rcPurchaseSuccess(_ message: String) {
        log(level: .info, intent: .rcPurchaseSuccess, message: message)
    }

    static func rcSuccess(_ message: String) {
        log(level: .debug, intent: .rcSuccess, message: message)
    }

    static func user(_ message: String) {
        log(level: .debug, intent: .user, message: message)
    }
}
