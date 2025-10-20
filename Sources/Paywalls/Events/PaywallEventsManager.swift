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

        do {
            try await self.internalAPI.postPaywallEvents(events: events)
            Logger.debug(Strings.analytics.flush_events_success)

            await self.store.clear(count)

            return events.count
        } catch {
            Logger.error(Strings.paywalls.event_sync_failed(error))

            if let backendError = error as? BackendError,
               backendError.successfullySynced {
                await self.store.clear(count)
            }

            throw error
        }
    }

    static let defaultEventFlushCount = 50

}
