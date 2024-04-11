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
    case could_not_create_diagnostics_tracker

    case event_flush_already_in_progress
    case event_flush_with_empty_store
    case event_flush_starting(count: Int)

    case error_fetching_events(error: Error)

}

extension DiagnosticsStrings: LogMessage {

    var description: String {
        switch self {
        case let .timing_message(message, duration):
            let roundedDuration = (duration * 100).rounded(.down) / 100
            return String(format: "%@ (%.2f seconds)", message.description, roundedDuration)

        case .could_not_create_diagnostics_tracker:
            return "Could not create DiagnosticsTracker"

        case .event_flush_already_in_progress:
            return "Diagnostics event flushing already in progress. Skipping."

        case .event_flush_with_empty_store:
            return "Diagnostics event flushing requested with empty store."

        case let .event_flush_starting(count):
            return "Diagnostics event flush: posting \(count) events."

        case let .error_fetching_events(error):
            return "Failed to read lines from file: \(error.localizedDescription)"
        }
    }

    var category: String { return "diagnostics" }

}
