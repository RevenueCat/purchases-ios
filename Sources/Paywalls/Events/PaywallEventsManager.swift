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
    func track(paywallEvent: PaywallEvent) async

    @available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
    func flushEvents(count: Int) async

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
actor PaywallEventsManager: PaywallEventsManagerType {

    private let internalAPI: InternalAPI
    private let userProvider: CurrentUserProvider
    private let store: PaywallEventStoreType

    private var flushInProgress = false

    init(
        internalAPI: InternalAPI,
        userProvider: CurrentUserProvider,
        store: PaywallEventStoreType
    ) {
        self.internalAPI = internalAPI
        self.userProvider = userProvider
        self.store = store
    }

    func track(paywallEvent: PaywallEvent) async {
        await self.store.store(.init(event: paywallEvent, userID: self.userProvider.currentAppUserID))
    }

    func flushEvents(count: Int) async {
        guard !self.flushInProgress else {
            Logger.debug(Strings.paywalls.event_flush_already_in_progress)
            return
        }
        self.flushInProgress = true
        defer { self.flushInProgress = false }

        let events = await self.store.fetch(count)

        guard !events.isEmpty else {
            Logger.verbose(Strings.paywalls.event_flush_with_empty_store)
            return
        }

        Logger.verbose(Strings.paywalls.event_flush_starting(count: events.count))

        let error = await self.internalAPI.postPaywallEvents(events: events)

        if let error {
            Logger.error(Strings.paywalls.event_flush_failed(error))

            if error.successfullySynced {
                await self.store.clear(count)
            }
        } else {
            await self.store.clear(count)
        }
    }

}
