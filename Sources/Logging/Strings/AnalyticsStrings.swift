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
}

extension AnalyticsStrings: LogMessage {
    var category: String { return "analytics" }

    var description: String {
        switch self {
        case .flush_events_success:
            return "Events flush succeeded"
        }
    }
}
