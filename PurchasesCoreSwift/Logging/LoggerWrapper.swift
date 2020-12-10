//
//  LoggerWrapper.swift
//  PurchasesCoreSwift
//
//  Created by Tina Nguyen on 12/08/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCLogIntent) public enum LogIntent: Int {
    case appleError
    case info
    case purchase
    case rcError
    case rcPurchaseSuccess
    case rcSuccess
    case user
    case warning
    
    func emojis() -> String {
        switch self {
        case .appleError: return Emojis.appleError.rawValue + Emojis.doubleExclamation.rawValue
        case .info: return Emojis.info.rawValue
        case .purchase: return Emojis.purchase.rawValue
        case .rcError: return Emojis.rcError.rawValue + Emojis.doubleExclamation.rawValue
        case .rcPurchaseSuccess: return Emojis.rcSuccess.rawValue + Emojis.purchase.rawValue
        case .rcSuccess: return Emojis.rcSuccess.rawValue
        case .user: return Emojis.appUserID.rawValue
        case .warning: return Emojis.warning.rawValue
        }
    }
}

@objc(RCLoggerWrapper) public class LoggerWrapper: NSObject {
    @objc public static func log(level: LogLevel, intent: LogIntent, message: String) {
        let emojifiedMessage = "\(intent.emojis()) \(message)"
        Logger.log(level: level, message: emojifiedMessage)
    }
    @objc public static func appleError(_ message: String) {
        log(level: .error, intent: .appleError, message: message)
    }
    
    @objc public static func appleInfo(_ message: String) {
        log(level: .info, intent: .appleError, message: message)
    }
    
    @objc public static func debugInfo(_ message: String) {
        log(level: .debug, intent: .info, message: message)
    }
    
    @objc public static func info(_ message: String) {
        log(level: .info, intent: .info, message: message)
    }
    
    @objc public static func purchase(_ message: String) {
        log(level: .debug, intent: .purchase, message: message)
    }
    
    @objc public static func rcError(_ message: String) {
        log(level: .error, intent: .rcError, message: message)
    }
    
    @objc public static func rcPurchaseSuccess(_ message: String) {
        log(level: .debug, intent: .rcPurchaseSuccess, message: message)
    }
    
    @objc public static func rcSuccess(_ message: String) {
        log(level: .debug, intent: .rcSuccess, message: message)
    }
    
    @objc public static func user(_ message: String) {
        log(level: .debug, intent: .user, message: message)
    }
    
    @objc public static func warning(_ message: String) {
        log(level: .warn, intent: .warning, message: message)
    }
}
