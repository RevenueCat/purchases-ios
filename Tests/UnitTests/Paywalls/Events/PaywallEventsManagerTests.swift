//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallEventsManagerTests.swift
//
//  Created by Nacho Soto on 9/6/23.

import Foundation
import Nimble

@testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class PaywallEventsManagerTests: TestCase {

    private var api: MockInternalAPI!
    private var userProvider: MockCurrentUserProvider!
    private var store: MockPaywallEventStore!
    private var manager: PaywallEventsManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.api = .init()
        self.userProvider = .init(mockAppUserID: Self.userID)
        self.store = .init()
        self.manager = .init(
            internalAPI: self.api,
            userProvider: self.userProvider,
            store: self.store
        )
    }

    // MARK: - trackEvent

    func testTrackEvent() async {
        let event: PaywallEvent = .view(.random())

        await self.manager.track(paywallEvent: event)

        let events = await self.store.storedEvents
        expect(events) == [
            .init(event: event, userID: Self.userID)
        ]
    }

    func testTrackMultipleEvents() async {
        let event1: PaywallEvent = .view(.random())
        let event2: PaywallEvent = .close(.random())

        await self.manager.track(paywallEvent: event1)
        await self.manager.track(paywallEvent: event2)

        let events = await self.store.storedEvents
        expect(events) == [
            .init(event: event1, userID: Self.userID),
            .init(event: event2, userID: Self.userID)
        ]
    }

    // MARK: - flushEvents

    func testFlushEmptyStore() async throws {
        let result = try await self.manager.flushEvents(count: 1)
        expect(result) == 0
        expect(self.api.invokedPostPaywallEvents) == false
    }

    func testFlushOneEvent() async throws {
        let event = await self.storeRandomEvent()

        let result = try await self.manager.flushEvents(count: 1)
        expect(result) == 1

        expect(self.api.invokedPostPaywallEvents) == true
        expect(self.api.invokedPostPaywallEventsParameters) == [[.init(event: event, userID: Self.userID)]]

        await self.verifyEmptyStore()
    }

    func testFlushTwice() async throws {
        let event1 = await self.storeRandomEvent()
        let event2 = await self.storeRandomEvent()

        let result1 = try await self.manager.flushEvents(count: 1)
        let result2 = try await self.manager.flushEvents(count: 1)

        expect(result1) == 1
        expect(result2) == 1

        expect(self.api.invokedPostPaywallEvents) == true
        expect(self.api.invokedPostPaywallEventsParameters) == [
            [.init(event: event1, userID: Self.userID)],
            [.init(event: event2, userID: Self.userID)]
        ]

        await self.verifyEmptyStore()
    }

    func testFlushOnlyOneEventPostsFirstOne() async throws {
        let event = await self.storeRandomEvent()
        let storedEvent: PaywallStoredEvent = .init(event: event, userID: Self.userID)

        _ = await self.storeRandomEvent()
        _ = await self.storeRandomEvent()

        let result = try await self.manager.flushEvents(count: 1)
        expect(result) == 1

        expect(self.api.invokedPostPaywallEvents) == true
        expect(self.api.invokedPostPaywallEventsParameters) == [[storedEvent]]

        let events = await self.store.storedEvents
        expect(events).to(haveCount(2))
        expect(events).toNot(contain(storedEvent))
    }

    func testFlushWithUnsuccessfulPostError() async throws {
        let event = await self.storeRandomEvent()
        let storedEvent: PaywallStoredEvent = .init(event: event, userID: Self.userID)

        self.api.stubbedPostPaywallEventsCompletionResult = .networkError(.offlineConnection())
        do {
            _ = try await self.manager.flushEvents(count: 1)
            fail("Expected error")
        } catch BackendError.networkError(.offlineConnection) {
            // Expected
        } catch {
            throw error
        }

        expect(self.api.invokedPostPaywallEvents) == true
        expect(self.api.invokedPostPaywallEventsParameters) == [[storedEvent]]

        await self.verifyEvents([storedEvent])
    }

    func testFlushWithSuccessfullySyncedError() async throws {
        _ = await self.storeRandomEvent()

        self.api.stubbedPostPaywallEventsCompletionResult = .networkError(
            .errorResponse(.defaultResponse, .invalidRequest)
        )

        do {
            _ = try await self.manager.flushEvents(count: 1)
            fail("Expected error")
        } catch BackendError.networkError(.errorResponse) {
            // Expected
        } catch {
            throw error
        }

        expect(self.api.invokedPostPaywallEvents) == true

        await self.verifyEmptyStore()
    }

    func testFlushWithSuccessfullySyncedErrorOnlyDeletesPostedEvents() async throws {
        let event1 = await self.storeRandomEvent()
        let event2 = await self.storeRandomEvent()

        self.api.stubbedPostPaywallEventsCompletionResult = .networkError(
            .errorResponse(.defaultResponse, .invalidRequest)
        )

        do {
            _ = try await self.manager.flushEvents(count: 1)
            fail("Expected error")
        } catch BackendError.networkError(.errorResponse) {
            // Expected
        } catch {
            throw error
        }

        expect(self.api.invokedPostPaywallEvents) == true
        expect(self.api.invokedPostPaywallEventsParameters) == [[.init(event: event1, userID: Self.userID)]]

        await self.verifyEvents([.init(event: event2, userID: Self.userID)])
    }

    // MARK: -

    private static let userID = "nacho"

}

// MARK: - Private

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension PaywallEventsManagerTests {

    func storeRandomEvent() async -> PaywallEvent {
        let event: PaywallEvent = .view(.random())
        await self.manager.track(paywallEvent: event)

        return event
    }

    func verifyEmptyStore(file: StaticString = #file, line: UInt = #line) async {
        let events = await self.store.storedEvents
        expect(file: file, line: line, events).to(beEmpty())
    }

    func verifyEvents(
        _ expected: [PaywallStoredEvent],
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let events = await self.store.storedEvents
        expect(file: file, line: line, events) == expected
    }

}

// MARK: - MockPaywallEventStore

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private actor MockPaywallEventStore: PaywallEventStoreType {

    var storedEvents: [PaywallStoredEvent] = []

    func store(_ storedEvent: PaywallStoredEvent) {
        self.storedEvents.append(storedEvent)
    }

    func fetch(_ count: Int) -> [PaywallStoredEvent] {
        return Array(self.storedEvents.prefix(count))
    }

    func clear(_ count: Int) {
        self.storedEvents.removeFirst(min(count, self.storedEvents.count))
    }

}
