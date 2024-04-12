//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockDiagnosticsTracker.swift
//
//  Created by Cesar de la Vega on 8/4/24.

import Foundation
@testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class MockDiagnosticsTracker: DiagnosticsTrackerType {

    private(set) var trackedEvents: [DiagnosticsEvent] = []

    func track(_ event: DiagnosticsEvent) async {
        trackedEvents.append(event)
    }

}
