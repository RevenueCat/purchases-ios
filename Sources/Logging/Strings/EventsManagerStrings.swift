//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EventsManagerStrings.swift
//

import Foundation

// swiftlint:disable identifier_name
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum EventsManagerStrings {

    case background_task_unavailable
    case background_task_expired(String)
    case background_task_failed(String)
    case background_task_started(String)

    case priority_flush_starting
    case priority_flush_queued
    case priority_flush_draining
    case priority_flush_rate_limited(maxCalls: Int, period: Int)

    case ad_event_tracking_disabled
    case ad_event_cannot_serialize
    case ad_event_flush_already_in_progress
    case ad_event_flush_with_empty_store
    case ad_event_flush_starting(Int)
    case ad_events_flushed_successfully
    case ad_event_sync_failed(Error)

}
// swiftlint:enable identifier_name

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EventsManagerStrings: LogMessage {

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

        case .priority_flush_starting:
            return "Priority event tracked, triggering immediate flush"

        case .priority_flush_queued:
            return "Priority event tracked while flush in progress, queuing priority flush"

        case .priority_flush_draining:
            return "Draining pending priority flush"

        case let .priority_flush_rate_limited(maxCalls, period):
            return "Priority flush rate-limited (max \(maxCalls) calls per \(period)s). " +
                "Event stored; will be uploaded on next scheduled flush."

        case .ad_event_tracking_disabled:
            return "Ad event tracking is disabled - no ad event store configured"

        case .ad_event_cannot_serialize:
            return "Cannot serialize ad event"

        case .ad_event_flush_already_in_progress:
            return "Ad event flush already in progress"

        case .ad_event_flush_with_empty_store:
            return "Ad event flush with empty store"

        case let .ad_event_flush_starting(count):
            return "Ad event flush starting with \(count) event(s)"

        case .ad_events_flushed_successfully:
            return "Ad events flushed successfully"

        case let .ad_event_sync_failed(error):
            return "Ad event sync failed: \(error)"
        }
    }

    var category: String { return "events_manager" }

}
