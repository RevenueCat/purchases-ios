//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Analytics.swift
//
//  Created by Facundo Menzella on 27/2/25.

import Foundation

// swiftlint:disable identifier_name
enum AnalyticsStrings {

    case flush_events_success
    case background_task_started
    case background_task_expired
    case background_task_failed_to_start
    case background_task_unavailable
}

extension AnalyticsStrings: LogMessage {
    var category: String { return "analytics" }

    var description: String {
        switch self {
        case .flush_events_success:
            return "Events flush succeeded"
        case .background_task_started:
            return "Background task started for event flush"
        case .background_task_expired:
            return "Background task expired before event flush completed"
        case .background_task_failed_to_start:
            return "Background task failed to start for event flush"
        case .background_task_unavailable:
            return "Background task unavailable for event flush"
        }
    }
}
