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

    case event_sync_already_in_progress
    case event_sync_with_empty_store
    case event_sync_starting(count: Int)

    case error_fetching_events(error: Error)

    case could_not_synchronize_diagnostics(error: Error)

    case invalid_sent_diagnostics_count(count: Int)
    case failed_to_clean_sent_diagnostics(error: Error)
    case failed_to_empty_diagnostics_file(error: Error)
    case failed_check_diagnostics_size(error: Error)

    case failed_diagnostics_sync_more_than_max_retries

}

extension DiagnosticsStrings: LogMessage {

    var description: String {
        switch self {
        case let .timing_message(message, duration):
            let roundedDuration = (duration * 100).rounded(.down) / 100
            return String(format: "%@ (%.2f seconds)", message.description, roundedDuration)

        case .could_not_create_diagnostics_tracker:
            return "Could not create DiagnosticsTracker"

        case .event_sync_already_in_progress:
            return "Diagnostics event flushing already in progress. Skipping."

        case .event_sync_with_empty_store:
            return "Diagnostics event flushing requested with empty store."

        case let .event_sync_starting(count):
            return "Diagnostics event flush: posting \(count) events."

        case let .error_fetching_events(error):
            return "Failed to read lines from file: \(error.localizedDescription)"

        case let .could_not_synchronize_diagnostics(error):
            return "Failed to synchronize diagnostics: \(error.localizedDescription)"

        case let .invalid_sent_diagnostics_count(count):
            return "Invalid sent diagnostics count: \(count)"

        case let .failed_to_clean_sent_diagnostics(error):
            return "Failed to clean sent diagnostics: \(error.localizedDescription)"

        case let .failed_to_empty_diagnostics_file(error):
            return "Failed to empty diagnostics file: \(error.localizedDescription)"

        case let .failed_check_diagnostics_size(error):
            return "Failed to check whether diagnostics file is too big: \(error.localizedDescription)"

        case .failed_diagnostics_sync_more_than_max_retries:
            return "Failed to sync diagnostics more than max retries. Clearing entire diagnostics file."

        }
    }

    var category: String { return "diagnostics" }

}
