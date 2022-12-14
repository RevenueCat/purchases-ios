//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ReceiptParserLogger.swift
//
//  Created by Nacho Soto on 12/5/22.

import Foundation

final class ReceiptParserLogger: LoggerType {

    func verbose(
        _ message: @autoclosure () -> CustomStringConvertible,
        fileName: String?,
        functionName: String?,
        line: UInt
    ) {
        Self.log(
            level: .verbose,
            message: message(),
            fileName: fileName,
            functionName: functionName,
            line: line
        )
    }

    func debug(
        _ message: @autoclosure () -> CustomStringConvertible,
        fileName: String?,
        functionName: String?,
        line: UInt
    ) {
        Self.log(
            level: .debug,
            message: message(),
            fileName: fileName,
            functionName: functionName,
            line: line
        )
    }

    func info(
        _ message: @autoclosure () -> CustomStringConvertible,
        fileName: String?,
        functionName: String?,
        line: UInt
    ) {
        Self.log(
            level: .info,
            message: message(),
            fileName: fileName,
            functionName: functionName,
            line: line
        )
    }

    func warn(
        _ message: @autoclosure () -> CustomStringConvertible,
        fileName: String?,
        functionName: String?,
        line: UInt
    ) {
        Self.log(
            level: .warn,
            message: message(),
            fileName: fileName,
            functionName: functionName,
            line: line
        )
    }

    func error(
        _ message: @autoclosure () -> CustomStringConvertible,
        fileName: String,
        functionName: String,
        line: UInt
    ) {
        Self.log(
            level: .error,
            message: message(),
            fileName: fileName,
            functionName: functionName,
            line: line
        )
    }

    private static func log(level: LogLevel,
                            message: @autoclosure () -> CustomStringConvertible,
                            fileName: String? = #fileID,
                            functionName: String? = #function,
                            line: UInt = #line) {
        defaultLogHandler(
            framework: Self.framework,
            verbose: false,
            level: level,
            message: message().description,
            file: fileName,
            function: functionName,
            line: line
        )
    }

    private static let framework = "ReceiptParser"

}
