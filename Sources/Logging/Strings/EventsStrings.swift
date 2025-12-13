//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EventsStrings.swift
//
//  Created by RevenueCat.

import Foundation

// swiftlint:disable identifier_name

enum EventsStrings {

    case background_task_unavailable
    case background_task_expired(String)
    case background_task_failed(String)
    case background_task_started(String)

}

extension EventsStrings: LogMessage {

    var description: String {
        switch self {
        case .background_task_unavailable:
            return "Background task unavailable"

        case .background_task_expired(let taskName):
            return "Background task expired: \(taskName)"

        case .background_task_failed(let taskName):
            return "Background task failed to start: \(taskName)"

        case .background_task_started(let taskName):
            return "Background task started: \(taskName)"
        }
    }

    var category: String { return "events" }

}
