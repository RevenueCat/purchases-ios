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
//  Created by Nacho Soto on 7/12/23.

import RevenueCat

// Note: this isn't ideal.
// Once we can use the `package` keyword it can use the internal `Logger`.
enum Logger {

    static func verbose(
        _ text: CustomStringConvertible,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        Self.log(
            text,
            .verbose,
            file: file,
            function: function,
            line: line
        )

    }

    static func debug(
        _ text: CustomStringConvertible,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        Self.log(
            text,
            .debug,
            file: file,
            function: function,
            line: line
        )
    }

    static func warning(
        _ text: CustomStringConvertible,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        Self.log(
            text,
            .warn,
            file: file,
            function: function,
            line: line
        )
    }

    private static func log(
        _ text: CustomStringConvertible,
        _ level: LogLevel,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        guard Purchases.logLevel <= level else { return }

        Purchases.verboseLogHandler(
            level,
            text.description,
            file,
            function,
            line
        )
    }

}
