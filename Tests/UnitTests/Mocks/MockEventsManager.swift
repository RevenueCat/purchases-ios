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

    var trackedEvents: [FeatureEvent] = []

    func track(featureEvent: FeatureEvent) async {
        self.trackedEvents.append(featureEvent)
    }

    var invokedFlushEventsWithBackgroundTask = false
    var invokedFlushEventsWithBackgroundTaskCount = 0

    func flushEventsWithBackgroundTask() async {
        self.invokedFlushEventsWithBackgroundTask = true
        self.invokedFlushEventsWithBackgroundTaskCount += 1
    }

    var invokedFlushFeatureEventsWithBackgroundTask = false
    var invokedFlushFeatureEventsWithBackgroundTaskCount = 0

    func flushFeatureEventsWithBackgroundTask() async {
        self.invokedFlushFeatureEventsWithBackgroundTask = true
        self.invokedFlushFeatureEventsWithBackgroundTaskCount += 1
    }

    #if ENABLE_AD_EVENTS_TRACKING
    var trackedAdEvents: [AdEvent] = []

    func track(adEvent: AdEvent) async {
        self.trackedAdEvents.append(adEvent)
    }
    #endif

}
