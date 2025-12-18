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

#if os(iOS) || os(tvOS) || VISION_OS
import UIKit
#endif

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
    func flushAllEvents(batchSize: Int) async throws -> Int

    /// - Throws: if posting feature events fails
    /// - Returns: the number of feature events posted
    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func flushFeatureEvents(batchSize: Int) async throws -> Int

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
actor EventsManager: EventsManagerType {

    static let defaultEventBatchSize = 50
    static let maxBatchesPerFlush = 10

    private let internalAPI: InternalAPI
    private let userProvider: CurrentUserProvider
    private let store: FeatureEventStoreType
    private var appSessionID: UUID
    private let systemInfo: SystemInfo

    #if ENABLE_AD_EVENTS_TRACKING
    private let adEventStore: AdEventStoreType?
    private var adFlushInProgress = false
    #endif

    private var flushInProgress = false

    #if ENABLE_AD_EVENTS_TRACKING
    init(
        internalAPI: InternalAPI,
        userProvider: CurrentUserProvider,
        store: FeatureEventStoreType,
        systemInfo: SystemInfo,
        appSessionID: UUID = SystemInfo.appSessionID,
        adEventStore: AdEventStoreType? = nil
    ) {
        self.internalAPI = internalAPI
        self.userProvider = userProvider
        self.store = store
        self.systemInfo = systemInfo
        self.appSessionID = appSessionID
        self.adEventStore = adEventStore
    }
    #else
    init(
        internalAPI: InternalAPI,
        userProvider: CurrentUserProvider,
        store: FeatureEventStoreType,
        systemInfo: SystemInfo,
        appSessionID: UUID = SystemInfo.appSessionID
    ) {
        self.internalAPI = internalAPI
        self.userProvider = userProvider
        self.store = store
        self.systemInfo = systemInfo
        self.appSessionID = appSessionID
    }
    #endif

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
        guard let store = self.adEventStore else {
            Logger.warn(EventsManagerStrings.ad_event_tracking_disabled)
            return
        }

        guard let event: StoredAdEvent = .init(event: adEvent,
                                               userID: self.userProvider.currentAppUserID,
                                               appSessionID: self.appSessionID) else {
            Logger.error(EventsManagerStrings.ad_event_cannot_serialize)
            return
        }
        await store.store(event)
    }
    #endif

    func flushAllEvents(batchSize: Int) async throws -> Int {
        #if os(iOS) || os(tvOS) || VISION_OS
        let endBackgroundTask: (() -> Void)?
        if !self.systemInfo.isAppExtension {
            endBackgroundTask = await self.beginBackgroundTask(named: "com.revenuecat.flushAllEvents")
        } else {
            endBackgroundTask = nil
        }
        defer {
            endBackgroundTask?()
        }
        #endif

        let featureEventsFlushed = try await self.flushFeatureEventsInternal(batchSize: batchSize)

        #if ENABLE_AD_EVENTS_TRACKING
        let adEventsFlushed = try await self.flushAdEvents(count: batchSize)
        return featureEventsFlushed + adEventsFlushed
        #else
        return featureEventsFlushed
        #endif
    }

    func flushFeatureEvents(batchSize: Int) async throws -> Int {
        #if os(iOS) || os(tvOS) || VISION_OS
        let endBackgroundTask: (() -> Void)?
        if !self.systemInfo.isAppExtension {
            endBackgroundTask = await self.beginBackgroundTask(named: "com.revenuecat.flushFeatureEvents")
        } else {
            endBackgroundTask = nil
        }
        defer {
            endBackgroundTask?()
        }
        #endif

        return try await self.flushFeatureEventsInternal(batchSize: batchSize)
    }

}

// MARK: - Private Helpers

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension EventsManager {

    func flushFeatureEventsInternal(batchSize: Int) async throws -> Int {
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

    #if ENABLE_AD_EVENTS_TRACKING
    func flushAdEvents(count: Int) async throws -> Int {
        guard let store = self.adEventStore else {
            Logger.warn(EventsManagerStrings.ad_event_tracking_disabled)
            return 0
        }

        guard !self.adFlushInProgress else {
            Logger.debug(EventsManagerStrings.ad_event_flush_already_in_progress)
            return 0
        }
        self.adFlushInProgress = true
        defer { self.adFlushInProgress = false }

        let events = await store.fetch(count)

        guard !events.isEmpty else {
            Logger.verbose(EventsManagerStrings.ad_event_flush_with_empty_store)
            return 0
        }

        Logger.verbose(EventsManagerStrings.ad_event_flush_starting(events.count))

        do {
            try await self.internalAPI.postAdEvents(events: events)
            Logger.debug(EventsManagerStrings.ad_events_flushed_successfully)

            await store.clear(count)

            return events.count
        } catch {
            Logger.error(EventsManagerStrings.ad_event_sync_failed(error))

            if let backendError = error as? BackendError,
               backendError.successfullySynced {
                await store.clear(count)
            }

            throw error
        }
    }
    #endif

}

// MARK: - Private Helpers

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension EventsManager {

    #if os(iOS) || os(tvOS) || VISION_OS
    @MainActor
    func beginBackgroundTask(named taskName: String) -> (() -> Void)? {
        guard let application = SystemInfo.sharedUIApplication else {
            Logger.warn(EventsManagerStrings.background_task_unavailable)
            return nil
        }

        var backgroundTaskID: UIBackgroundTaskIdentifier?
        backgroundTaskID = application.beginBackgroundTask(withName: taskName) {
            Logger.warn(EventsManagerStrings.background_task_expired(taskName))
            if let taskID = backgroundTaskID {
                application.endBackgroundTask(taskID)
                backgroundTaskID = .invalid
            }
        }

        if backgroundTaskID == .invalid {
            Logger.warn(EventsManagerStrings.background_task_failed(taskName))
            return nil
        }

        Logger.debug(EventsManagerStrings.background_task_started(taskName))
        return {
            if let taskID = backgroundTaskID {
                application.endBackgroundTask(taskID)
            }
        }
    }
    #endif

}

// MARK: - Messages

// swiftlint:disable identifier_name
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private enum EventsManagerStrings {

    case background_task_unavailable
    case background_task_expired(String)
    case background_task_failed(String)
    case background_task_started(String)

    #if ENABLE_AD_EVENTS_TRACKING
    case ad_event_tracking_disabled
    case ad_event_cannot_serialize
    case ad_event_flush_already_in_progress
    case ad_event_flush_with_empty_store
    case ad_event_flush_starting(Int)
    case ad_events_flushed_successfully
    case ad_event_sync_failed(Error)
    #endif

}
// swiftlint:enable identifier_name

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension EventsManagerStrings: LogMessage {

    var description: String {
        switch self {
        case .background_task_unavailable:
            return "Background task unavailable"

        case .background_task_expired(let taskName):
            return "Background task expired: \(taskName)"

        case .background_task_failed(let taskName):
            return "Background task failed to start: \(taskName)"

        case .background_task_started(let taskName):
            return "Background task started: \(taskName)"

        #if ENABLE_AD_EVENTS_TRACKING
        case .ad_event_tracking_disabled:
            return "Ad event tracking is disabled - no ad event store configured"

        case .ad_event_cannot_serialize:
            return "Cannot serialize ad event"

        case .ad_event_flush_already_in_progress:
            return "Ad event flush already in progress"

        case .ad_event_flush_with_empty_store:
            return "Ad event flush with empty store"

        case let .ad_event_flush_starting(count):
            return "Ad event flush starting with \(count) event(s)"

        case .ad_events_flushed_successfully:
            return "Ad events flushed successfully"

        case let .ad_event_sync_failed(error):
            return "Ad event sync failed: \(error)"
        #endif
        }
    }

    var category: String { return "events_manager" }

}
