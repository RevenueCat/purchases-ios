//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdsStrings.swift
//
//  Created by RevenueCat on 1/8/25.

import Foundation

// swiftlint:disable identifier_name

enum AdsStrings {

    // MARK: - Events

    case event_flush_already_in_progress
    case event_flush_with_empty_store
    case event_flush_starting(count: Int)
    case event_sync_failed(Error)
    case event_cannot_serialize
    case event_cannot_get_encoded_event
    case event_cannot_deserialize(Error)

}

extension AdsStrings: LogMessage {

    var description: String {
        switch self {
        // MARK: - Events

        case .event_flush_already_in_progress:
            return "Ad event flushing already in progress. Skipping."

        case .event_flush_with_empty_store:
            return "Ad event flushing requested with empty store."

        case let .event_flush_starting(count):
            return "Ad event flush: posting \(count) events."

        case let .event_sync_failed(error):
            return "Ad event flushing failed, will retry. Error: \((error as NSError).localizedDescription)"

        case .event_cannot_serialize:
            return "Couldn't serialize AdEvent to storage."

        case .event_cannot_get_encoded_event:
            return "Couldn't get encoded event from storage."

        case let .event_cannot_deserialize(error):
            return "Couldn't deserialize AdEvent from storage. Error: \((error as NSError).description)"
        }
    }

    var category: String { return "ads" }

}
