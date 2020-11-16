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
}

@objc(RCLogger) public class Logger: NSObject {
    public static var shouldShowLogs = false

    @objc public static func log(level: LogLevel, message: String) {
        let fullFormat = String(format: "NEW [Purchases] - DEBUG: %@ ", message)
        NSLog(fullFormat)
    }

    public static func log(level: LogLevel, _ args: CVarArg...) {
        withVaList(args) {
            let fullFormat = String(format: "NEW [Purchases] - DEBUG: %@ ", args)
            NSLogv(fullFormat, $0)
        }
    }
}
