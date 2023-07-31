//
//  Logger.swift
//  
//
//  Created by Nacho Soto on 7/12/23.
//

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
