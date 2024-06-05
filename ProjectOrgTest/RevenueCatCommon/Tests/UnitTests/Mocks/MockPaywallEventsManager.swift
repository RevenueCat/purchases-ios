//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockPaywallEventsManager.swift
//
//  Created by Nacho Soto on 9/6/23.

import Foundation
@testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
actor MockPaywallEventsManager: PaywallEventsManagerType {

    var trackedEvents: [PaywallEvent] = []

    func track(paywallEvent: PaywallEvent) async {
        self.trackedEvents.append(paywallEvent)
    }

    var invokedFlushEvents = false
    var invokedFlushEventsCount = 0

    func flushEvents(count: Int) async -> Int {
        self.invokedFlushEvents = true
        self.invokedFlushEventsCount += 1

        return 0
    }

}
