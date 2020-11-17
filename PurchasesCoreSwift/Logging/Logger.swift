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

    static func debug(_ message: String) {
        log(level: .debug, message: message)
    }

    static func info(_ message: String) {
        log(level: .debug, message: message)
    }

    static func warn(_ message: String) {
        log(level: .debug, message: message)
    }

    static func error(_ message: String) {
        log(level: .debug, message: message)
    }
}
