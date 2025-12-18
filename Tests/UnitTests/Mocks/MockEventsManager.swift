//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockEventsManager.swift
//
//  Created by Nacho Soto on 9/6/23.

import Foundation
@testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
actor MockEventsManager: EventsManagerType {
    nonisolated func flushAllEventsWithBackgroundTask(batchSize: Int) {
        Task {
            _ = try? await flushAllEvents(batchSize: batchSize)
        }
    }

    nonisolated func flushFeatureEventsWithBackgroundTask(batchSize: Int) {
        Task {
            _ = try? await flushFeatureEvents(batchSize: batchSize)
        }
    }

    var trackedEvents: [FeatureEvent] = []

    func track(featureEvent: FeatureEvent) async {
        self.trackedEvents.append(featureEvent)
    }

    var invokedFlushEvents = false
    var invokedFlushEventsCount = 0

    func flushAllEvents(batchSize: Int) async throws -> Int {
        self.invokedFlushEvents = true
        self.invokedFlushEventsCount += 1
        return 0
    }

    var invokedFlushFeatureEvents = false
    var invokedFlushFeatureEventsCount = 0

    func flushFeatureEvents(batchSize: Int) async throws -> Int {
        self.invokedFlushFeatureEvents = true
        self.invokedFlushFeatureEventsCount += 1
        return 0
    }

    #if ENABLE_AD_EVENTS_TRACKING
    var trackedAdEvents: [AdEvent] = []

    func track(adEvent: AdEvent) async {
        self.trackedAdEvents.append(adEvent)
    }
    #endif

}
