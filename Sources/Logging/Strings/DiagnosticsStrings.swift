//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DiagnosticsStrings.swift
//
//  Created by Nacho Soto on 6/8/23.

import Foundation

// swiftlint:disable identifier_name

enum DiagnosticsStrings {

    case timing_message(message: String, duration: TimeInterval)

}

extension DiagnosticsStrings: LogMessage {

    var description: String {
        switch self {
        case let .timing_message(message, duration):
            let roundedDuration = (duration * 100).rounded(.down) / 100
            return String(format: "%@ (%.2f seconds)", message.description, roundedDuration)
        }
    }

    var category: String { return "diagnostics" }

}
