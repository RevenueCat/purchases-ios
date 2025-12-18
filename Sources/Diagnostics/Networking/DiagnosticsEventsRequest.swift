//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DiagnosticsEventsRequest.swift
//
//  Created by Cesar de la Vega on 11/4/24.

import Foundation

/// The content of a request to the events endpoints.
struct DiagnosticsEventsRequest {

    var entries: [DiagnosticsEvent]

    init(events: [DiagnosticsEvent]) {
        self.entries = events
    }
}

extension DiagnosticsEventsRequest: HTTPRequestBody {}
