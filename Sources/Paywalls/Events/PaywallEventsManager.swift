//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallEventsManager.swift
//
//  Created by Nacho Soto on 9/6/23.

import Foundation

protocol PaywallEventsManagerType {

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func track(featureEvent: FeatureEvent) async

    /// - Throws: if posting events fails
    /// - Returns: the number of events posted
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func flushEvents(count: Int) async throws -> Int

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
actor PaywallEventsManager: PaywallEventsManagerType {

    private let internalAPI: InternalAPI
    private let userProvider: CurrentUserProvider
    private let store: PaywallEventStoreType
    private var appSessionID: UUID

    private var flushInProgress = false

    init(
        internalAPI: InternalAPI,
        userProvider: CurrentUserProvider,
        store: PaywallEventStoreType,
        appSessionID: UUID = SystemInfo.appSessionID
    ) {
        self.internalAPI = internalAPI
        self.userProvider = userProvider
        self.store = store
        self.appSessionID = appSessionID
    }

    func track(featureEvent: FeatureEvent) async {
        guard let event: StoredEvent = .init(event: featureEvent,
                                             userID: self.userProvider.currentAppUserID,
                                             feature: featureEvent.feature,
                                             appSessionID: self.appSessionID,
                                             eventDiscriminator: featureEvent.eventDiscriminator) else {
            Logger.error(Strings.paywalls.event_cannot_serialize)
            return
        }
        await self.store.store(event)
    }

    func flushEvents(count: Int) async throws -> Int {
        guard !self.flushInProgress else {
            Logger.debug(Strings.paywalls.event_flush_already_in_progress)
            return 0
        }
        self.flushInProgress = true
        defer { self.flushInProgress = false }

        let events = await self.store.fetch(count)

        guard !events.isEmpty else {
            Logger.verbose(Strings.paywalls.event_flush_with_empty_store)
            return 0
        }

        Logger.verbose(Strings.paywalls.event_flush_starting(count: events.count))

        let (allSucceeded, shouldClearEvents, lastError) = await self.postEventsByFeature(events)

        if allSucceeded || shouldClearEvents {
            await self.store.clear(count)
        }

        if let error = lastError {
            throw error
        }

        return events.count
    }

    private func postEventsByFeature(_ events: [StoredEvent]) async -> (
        allSucceeded: Bool,
        shouldClearEvents: Bool,
        lastError: Error?
    ) {
        let adEvents = events.filter { $0.feature == .ads }
        let nonAdEvents = events.filter { $0.feature != .ads }

        var allSucceeded = true
        var shouldClearEvents = false
        var lastError: Error?

        if !adEvents.isEmpty {
            let result = await self.postEvents(adEvents, using: self.internalAPI.postAdEvents)
            allSucceeded = allSucceeded && result.succeeded
            shouldClearEvents = shouldClearEvents || result.shouldClear
            lastError = lastError ?? result.error
        }

        if !nonAdEvents.isEmpty {
            let result = await self.postEvents(nonAdEvents, using: self.internalAPI.postPaywallEvents)
            allSucceeded = allSucceeded && result.succeeded
            shouldClearEvents = shouldClearEvents || result.shouldClear
            lastError = lastError ?? result.error
        }

        return (allSucceeded, shouldClearEvents, lastError)
    }

    private func postEvents(
        _ events: [StoredEvent],
        using poster: ([StoredEvent]) async throws -> Void
    ) async -> (succeeded: Bool, shouldClear: Bool, error: Error?) {
        do {
            try await poster(events)
            Logger.debug(Strings.analytics.flush_events_success)
            return (true, false, nil)
        } catch {
            Logger.error(Strings.paywalls.event_sync_failed(error))
            let shouldClear = (error as? BackendError)?.successfullySynced ?? false
            return (false, shouldClear, error)
        }
    }

    static let defaultEventFlushCount = 50

}
