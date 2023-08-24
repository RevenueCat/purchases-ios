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

    static func debug(
        _ text: CustomStringConvertible,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        Purchases.verboseLogHandler(
            .debug,
            text.description,
            file,
            function,
            line
        )
    }

    static func warning(
        _ text: CustomStringConvertible,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        Purchases.verboseLogHandler(
            .warn,
            text.description,
            file,
            function,
            line
        )
    }

}
