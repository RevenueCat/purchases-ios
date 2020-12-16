//
//  Logger.swift
//  PurchasesCoreSwift
//
//  Created by Andrés Boedo on 11/13/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCLogLevel) public enum LogLevel: Int {
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

@objc(RCLogger) public class Logger: NSObject {
    @objc public static var shouldShowDebugLogs = false
    private static let frameworkDescription = "Purchases"

    @objc public static func log(level: LogLevel, message: String) {
        guard level != .debug || shouldShowDebugLogs else { return }
        NSLog("[\(frameworkDescription)] - \(level.description()): \(message)")
    }
    
    @objc public static func log(level: LogLevel, intent: LogIntent, message: String) {
        #if V2_LOGS_ENABLED
            let messageWithPrefix = "\(intent.suffix) \(message)"
            Logger.log(level: level, message: messageWithPrefix)
        #else
            Logger.log(level: level, message: message)
        #endif
    }

    static func debug(_ message: String) {
        log(level: .debug, intent: .info, message: message)
    }

    static func info(_ message: String) {
        log(level: .info, intent: .info, message: message)
    }

    static func warn(_ message: String) {
        log(level: .warn, intent: .warning, message: message)
    }

    static func error(_ message: String) {
        log(level: .error, message: message)
    }
}

extension Logger {
    @objc public static func appleError(_ message: String) {
        log(level: .error, intent: .appleError, message: message)
    }
    
    @objc public static func appleWarning(_ message: String) {
        log(level: .warn, intent: .appleError, message: message)
    }
    
    @objc public static func purchase(_ message: String) {
        log(level: .debug, intent: .purchase, message: message)
    }
    
    @objc public static func rcError(_ message: String) {
        log(level: .error, intent: .rcError, message: message)
    }
    
    @objc public static func rcPurchaseSuccess(_ message: String) {
        log(level: .info, intent: .rcPurchaseSuccess, message: message)
    }
    
    @objc public static func rcSuccess(_ message: String) {
        log(level: .debug, intent: .rcSuccess, message: message)
    }
    
    @objc public static func user(_ message: String) {
        log(level: .debug, intent: .user, message: message)
    }
}
