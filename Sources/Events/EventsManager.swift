//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EventsManager.swift
//
//  Created by Nacho Soto on 9/6/23.

import Foundation

protocol EventsManagerType {

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func track(featureEvent: FeatureEvent) async

    #if ENABLE_AD_EVENTS_TRACKING
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func track(adEvent: AdEvent) async
    #endif

    /// - Throws: if posting events fails
    /// - Returns: the number of events posted
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func flushEvents(batchSize: Int) async throws -> Int

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
actor EventsManager: EventsManagerType {

    private let internalAPI: InternalAPI
    private let userProvider: CurrentUserProvider
    private let store: FeatureEventStoreType
    private var appSessionID: UUID

    private var flushInProgress = false

    init(
        internalAPI: InternalAPI,
        userProvider: CurrentUserProvider,
        store: FeatureEventStoreType,
        appSessionID: UUID = SystemInfo.appSessionID
    ) {
        self.internalAPI = internalAPI
        self.userProvider = userProvider
        self.store = store
        self.appSessionID = appSessionID
    }

    func track(featureEvent: FeatureEvent) async {
        guard let event: StoredFeatureEvent = .init(event: featureEvent,
                                                    userID: self.userProvider.currentAppUserID,
                                                    feature: featureEvent.feature,
                                                    appSessionID: self.appSessionID,
                                                    eventDiscriminator: featureEvent.eventDiscriminator) else {
            Logger.error(Strings.paywalls.event_cannot_serialize)
            return
        }
        await self.store.store(event)
    }

    #if ENABLE_AD_EVENTS_TRACKING
    func track(adEvent: AdEvent) async {
        // Ad events are not yet implemented.
        // They should not be sent through the feature events system.
        // They require their own StoredAdEvent, AdEventStore, and
        // InternalAPI.postAdEvents() using HTTPRequest.AdPath.postEvents
    }
    #endif

    func flushEvents(batchSize: Int) async throws -> Int {
        guard !self.flushInProgress else {
            Logger.debug(Strings.paywalls.event_flush_already_in_progress)
            return 0
        }
        self.flushInProgress = true
        defer { self.flushInProgress = false }

        var totalFlushed = 0
        var batchesSent = 0

        while batchesSent < Self.maxBatchesPerFlush {
            let events = await self.store.fetch(batchSize)

            guard !events.isEmpty else {
                if totalFlushed == 0 {
                    Logger.verbose(Strings.paywalls.event_flush_with_empty_store)
                }
                return totalFlushed
            }

            Logger.verbose(Strings.paywalls.event_flush_starting(count: events.count))

            do {
                try await self.internalAPI.postFeatureEvents(events: events)
                Logger.debug(Strings.analytics.flush_events_success)

                await self.store.clear(events.count)
                totalFlushed += events.count
                batchesSent += 1
            } catch {
                Logger.error(Strings.paywalls.event_sync_failed(error))

                if let backendError = error as? BackendError,
                   backendError.successfullySynced {
                    await self.store.clear(events.count)
                    totalFlushed += events.count
                    batchesSent += 1
                } else {
                    throw error
                }
            }
        }

        return totalFlushed
    }

    static let defaultEventBatchSize = 50
    static let maxBatchesPerFlush = 10

}
