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

import XCTest

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

    func testTrackEvent() async throws {
        let event: PaywallEvent = .impression(.random(), .random())

        await self.manager.track(paywallEvent: event)

        let events = await self.store.storedEvents
        expect(events) == [
            try XCTUnwrap(.init(event: event, userID: Self.userID, feature: .paywalls))
        ]
    }

    func testTrackMultipleEvents() async throws {
        let event1: PaywallEvent = .impression(.random(), .random())
        let event2: PaywallEvent = .close(.random(), .random())

        await self.manager.track(paywallEvent: event1)
        await self.manager.track(paywallEvent: event2)

        let events = await self.store.storedEvents
        expect(events) == [
            try XCTUnwrap(.init(event: event1, userID: Self.userID, feature: .paywalls)),
            try XCTUnwrap(.init(event: event2, userID: Self.userID, feature: .paywalls))
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
        expect(self.api.invokedPostPaywallEventsParameters) == [[try XCTUnwrap(.init(event: event,
                                                                                     userID: Self.userID,
                                                                                     feature: .paywalls))]]

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
            [try XCTUnwrap(.init(event: event1, userID: Self.userID, feature: .paywalls))],
            [try XCTUnwrap(.init(event: event2, userID: Self.userID, feature: .paywalls))]
        ]

        await self.verifyEmptyStore()
    }

    func testFlushOnlyOneEventPostsFirstOne() async throws {
        let event = await self.storeRandomEvent()
        let storedEvent: StoredEvent = try XCTUnwrap(.init(event: event, userID: Self.userID, feature: .paywalls))

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
        let storedEvent: StoredEvent = try XCTUnwrap(.init(event: event, userID: Self.userID, feature: .paywalls))
        let expectedError: NetworkError = .offlineConnection()

        self.api.stubbedPostPaywallEventsCompletionResult = .networkError(expectedError)
        do {
            _ = try await self.manager.flushEvents(count: 1)
            fail("Expected error")
        } catch BackendError.networkError(expectedError) {
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
        let expectedEvent: StoredEvent = try XCTUnwrap(.init(event: event1,
                                                             userID: Self.userID,
                                                             feature: .paywalls))
        expect(self.api.invokedPostPaywallEventsParameters) == [[expectedEvent]]

        await self.verifyEvents([try XCTUnwrap(.init(event: event2, userID: Self.userID, feature: .paywalls))])
    }

    #if swift(>=5.9)
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func testCannotFlushMultipleTimesInParallel() async throws {
        // The way this test is written does not work in iOS 15.
        // The second Task does not start until the first one is done.
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        let event1 = await self.storeRandomEvent()
        _ = await self.storeRandomEvent()

        // Creates a stream and its continuation
        let continuation = AsyncStream<Void>.makeStream()

        // Set up the mock to wait for our signal
        self.api.stubbedPostPaywallEventsCallback = { completion in
            Task {
                // This waits until something is sent through the stream
                await continuation.stream.first { _ in true }
                // Once we receive the signal, call completion
                completion(nil)
            }
        }

        let manager = self.manager!
        async let result1 = manager.flushEvents(count: 1)
        async let result2 = manager.flushEvents(count: 1)

        // Signal the API call to complete
        continuation.continuation.yield()
        continuation.continuation.finish()

        // Wait for both results
        let results = try await [result1, result2]
        expect(Set(results)) == [1, 0]

        expect(self.api.invokedPostPaywallEvents) == true
        expect(self.api.invokedPostPaywallEventsParameters).to(haveCount(1))
        expect(self.api.invokedPostPaywallEventsParameters.onlyElement) == [
            try XCTUnwrap(.init(event: event1, userID: Self.userID, feature: .paywalls))
        ]

        self.logger.verifyMessageWasLogged(
            Strings.paywalls.event_flush_already_in_progress,
            level: .debug,
            expectedCount: 1
        )
    }
    #endif

    // MARK: -

    private static let userID = "nacho"

}

// MARK: - Private

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension PaywallEventsManagerTests {

    func storeRandomEvent() async -> PaywallEvent {
        let event: PaywallEvent = .impression(.random(), .random())
        await self.manager.track(paywallEvent: event)

        return event
    }

    func verifyEmptyStore(file: StaticString = #file, line: UInt = #line) async {
        let events = await self.store.storedEvents
        expect(file: file, line: line, events).to(beEmpty())
    }

    func verifyEvents(
        _ expected: [StoredEvent],
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

    var storedEvents: [StoredEvent] = []

    func store(_ storedEvent: StoredEvent) {
        self.storedEvents.append(storedEvent)
    }

    func fetch(_ count: Int) -> [StoredEvent] {
        return Array(self.storedEvents.prefix(count))
    }

    func clear(_ count: Int) {
        self.storedEvents.removeFirst(min(count, self.storedEvents.count))
    }

}
