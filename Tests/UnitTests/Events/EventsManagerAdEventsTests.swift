//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EventsManagerAdEventsTests.swift
//
//  Created by RevenueCat on 1/21/25.

#if ENABLE_AD_EVENTS_TRACKING

import Foundation
import Nimble

@_spi(Experimental) @testable import RevenueCat

import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class EventsManagerAdEventsTests: TestCase {

    private var api: MockInternalAPI!
    private var userProvider: MockCurrentUserProvider!
    private var featureEventStore: MockEventStore!
    private var adEventStore: MockAdEventStore!
    private var manager: EventsManager!
    private var appSessionID = UUID()

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.api = .init()
        self.userProvider = .init(mockAppUserID: Self.userID)
        self.featureEventStore = .init()
        self.adEventStore = .init()
        self.manager = .init(
            internalAPI: self.api,
            userProvider: self.userProvider,
            store: self.featureEventStore,
            systemInfo: MockSystemInfo(finishTransactions: true),
            appSessionID: self.appSessionID,
            adEventStore: self.adEventStore
        )
    }

    // MARK: - flushEvents (combined)

    func testFlushEventsFlushesFeatureAndAdEvents() async throws {
        // Store feature events
        let featureEvent1: PaywallEvent = .impression(.random(), .random())
        let featureEvent2: PaywallEvent = .close(.random(), .random())
        await self.manager.track(featureEvent: featureEvent1)
        await self.manager.track(featureEvent: featureEvent2)

        // Store ad events
        let adEvent1 = await self.storeRandomAdEvent()
        let adEvent2 = await self.storeRandomAdEvent()

        let result = try await self.manager.flushEvents(batchSize: 10)

        // Should have flushed both types
        expect(result) == 4

        // Both stores should be empty
        await self.verifyEmptyStore()
        let featureEvents = await self.featureEventStore.storedEvents
        expect(featureEvents).to(beEmpty())
    }

    func testFlushEventsReturnsZeroWhenBothStoresEmpty() async throws {
        let result = try await self.manager.flushEvents(batchSize: 1)
        expect(result) == 0
    }

    func testFlushEventsOnlyFlushesFeatureEventsWhenAdStoreEmpty() async throws {
        let featureEvent: PaywallEvent = .impression(.random(), .random())
        await self.manager.track(featureEvent: featureEvent)

        let result = try await self.manager.flushEvents(batchSize: 10)

        expect(result) == 1

        let featureEvents = await self.featureEventStore.storedEvents
        expect(featureEvents).to(beEmpty())
    }

    func testFlushEventsOnlyFlushesAdEventsWhenFeatureStoreEmpty() async throws {
        _ = await self.storeRandomAdEvent()
        _ = await self.storeRandomAdEvent()

        let result = try await self.manager.flushEvents(batchSize: 10)

        expect(result) == 2

        await self.verifyEmptyStore()
    }

    func testFlushEventsThrowsIfFeatureEventsFlushFails() async throws {
        let featureEvent: PaywallEvent = .impression(.random(), .random())
        await self.manager.track(featureEvent: featureEvent)
        _ = await self.storeRandomAdEvent()

        let expectedError: NetworkError = .offlineConnection()
        self.api.stubbedPostPaywallEventsCompletionResult = .networkError(expectedError)

        do {
            _ = try await self.manager.flushEvents(batchSize: 10)
            fail("Expected error")
        } catch BackendError.networkError(expectedError) {
            // Expected
        } catch {
            throw error
        }

        // Feature event should still be in store
        let featureEvents = await self.featureEventStore.storedEvents
        expect(featureEvents).to(haveCount(1))

        // Ad event should still be in store (not flushed if feature flush failed)
        let adEvents = await self.adEventStore.storedEvents
        expect(adEvents).to(haveCount(1))
    }

    func testFlushEventsThrowsIfAdEventsFlushFails() async throws {
        let featureEvent: PaywallEvent = .impression(.random(), .random())
        await self.manager.track(featureEvent: featureEvent)
        _ = await self.storeRandomAdEvent()

        let expectedError: NetworkError = .offlineConnection()
        self.api.stubbedPostAdEventsCompletionResult = .networkError(expectedError)

        do {
            _ = try await self.manager.flushEvents(batchSize: 10)
            fail("Expected error")
        } catch BackendError.networkError(expectedError) {
            // Expected
        } catch {
            throw error
        }

        // Feature event should be flushed (succeeded first)
        let featureEvents = await self.featureEventStore.storedEvents
        expect(featureEvents).to(beEmpty())

        // Ad event should still be in store
        let adEvents = await self.adEventStore.storedEvents
        expect(adEvents).to(haveCount(1))
    }

    // MARK: - trackAdEvent

    func testTrackAdEvent() async throws {
        let event: AdEvent = .randomDisplayedEvent()

        await self.manager.track(adEvent: event)

        let events = await self.adEventStore.storedEvents
        expect(events) == [
            try createStoredAdEvent(from: event)
        ]
    }

    func testTrackMultipleAdEvents() async throws {
        let event1: AdEvent = .randomDisplayedEvent()
        let event2: AdEvent = .randomDisplayedEvent()

        await self.manager.track(adEvent: event1)
        await self.manager.track(adEvent: event2)

        let events = await self.adEventStore.storedEvents
        expect(events) == [
            try createStoredAdEvent(from: event1),
            try createStoredAdEvent(from: event2)
        ]
    }

    // MARK: - flushAdEvents

    func testFlushEmptyStore() async throws {
        let result = try await self.manager.flushAdEvents(count: 1)
        expect(result) == 0
        expect(self.api.invokedPostAdEvents) == false
    }

    func testFlushOneAdEvent() async throws {
        let event = await self.storeRandomAdEvent()

        let result = try await self.manager.flushAdEvents(count: 1)
        expect(result) == 1

        expect(self.api.invokedPostAdEvents) == true
        expect(self.api.invokedPostAdEventsParameters) == [[try createStoredAdEvent(from: event)]]

        await self.verifyEmptyStore()
    }

    func testFlushTwice() async throws {
        let event1 = await self.storeRandomAdEvent()
        let event2 = await self.storeRandomAdEvent()

        let result1 = try await self.manager.flushAdEvents(count: 1)
        let result2 = try await self.manager.flushAdEvents(count: 1)

        expect(result1) == 1
        expect(result2) == 1

        expect(self.api.invokedPostAdEvents) == true
        expect(self.api.invokedPostAdEventsParameters) == [
            [try createStoredAdEvent(from: event1)],
            [try createStoredAdEvent(from: event2)]
        ]

        await self.verifyEmptyStore()
    }

    func testFlushOnlyOneEventPostsFirstOne() async throws {
        let event = await self.storeRandomAdEvent()
        let storedEvent = try createStoredAdEvent(from: event)

        _ = await self.storeRandomAdEvent()
        _ = await self.storeRandomAdEvent()

        let result = try await self.manager.flushAdEvents(count: 1)
        expect(result) == 1

        expect(self.api.invokedPostAdEvents) == true
        expect(self.api.invokedPostAdEventsParameters) == [[storedEvent]]

        let events = await self.adEventStore.storedEvents
        expect(events).to(haveCount(2))
        expect(events).toNot(contain(storedEvent))
    }

    func testFlushWithUnsuccessfulPostError() async throws {
        let event = await self.storeRandomAdEvent()
        let storedEvent = try createStoredAdEvent(from: event)
        let expectedError: NetworkError = .offlineConnection()

        self.api.stubbedPostAdEventsCompletionResult = .networkError(expectedError)
        do {
            _ = try await self.manager.flushAdEvents(count: 1)
            fail("Expected error")
        } catch BackendError.networkError(expectedError) {
            // Expected
        } catch {
            throw error
        }

        expect(self.api.invokedPostAdEvents) == true
        expect(self.api.invokedPostAdEventsParameters) == [[storedEvent]]

        await self.verifyEvents([storedEvent])
    }

    func testFlushWithSuccessfullySyncedError() async throws {
        _ = await self.storeRandomAdEvent()

        self.api.stubbedPostAdEventsCompletionResult = .networkError(
            .errorResponse(.defaultResponse, .invalidRequest)
        )

        do {
            _ = try await self.manager.flushAdEvents(count: 1)
            fail("Expected error")
        } catch BackendError.networkError(.errorResponse) {
            // Expected
        } catch {
            throw error
        }

        expect(self.api.invokedPostAdEvents) == true

        await self.verifyEmptyStore()
    }

    func testFlushWithSuccessfullySyncedErrorOnlyDeletesPostedEvents() async throws {
        let event1 = await self.storeRandomAdEvent()
        let event2 = await self.storeRandomAdEvent()

        self.api.stubbedPostAdEventsCompletionResult = .networkError(
            .errorResponse(.defaultResponse, .invalidRequest)
        )

        do {
            _ = try await self.manager.flushAdEvents(count: 1)
            fail("Expected error")
        } catch BackendError.networkError(.errorResponse) {
            // Expected
        } catch {
            throw error
        }

        expect(self.api.invokedPostAdEvents) == true
        let expectedEvent = try createStoredAdEvent(from: event1)
        expect(self.api.invokedPostAdEventsParameters) == [[expectedEvent]]

        await self.verifyEvents([try createStoredAdEvent(from: event2)])
    }

    #if swift(>=5.9)
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func testCannotFlushMultipleTimesInParallel() async throws {
        // The way this test is written does not work in iOS 15.
        // The second Task does not start until the first one is done.
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        let event1 = await self.storeRandomAdEvent()
        _ = await self.storeRandomAdEvent()

        // Creates a stream and its continuation
        let continuation = AsyncStream<Void>.makeStream()

        // Set up the mock to wait for our signal
        self.api.stubbedPostAdEventsCallback = { completion in
            Task {
                // This waits until something is sent through the stream
                await continuation.stream.first { _ in true }
                // Once we receive the signal, call completion
                completion(nil)
            }
        }

        let manager = self.manager!
        async let result1 = manager.flushAdEvents(count: 1)
        async let result2 = manager.flushAdEvents(count: 1)

        // Signal the API call to complete
        continuation.continuation.yield()
        continuation.continuation.finish()

        // Wait for both results
        let results = try await [result1, result2]
        expect(Set(results)) == [1, 0]

        expect(self.api.invokedPostAdEvents) == true
        expect(self.api.invokedPostAdEventsParameters).to(haveCount(1))
        expect(self.api.invokedPostAdEventsParameters.onlyElement) == [
            try createStoredAdEvent(from: event1)
        ]
    }
    #endif

    // MARK: -

    private static let userID = "test-user"

}

// MARK: - Private

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension EventsManagerAdEventsTests {

    func storeRandomAdEvent() async -> AdEvent {
        let event: AdEvent = .randomDisplayedEvent()
        await self.manager.track(adEvent: event)

        return event
    }

    func verifyEmptyStore(file: FileString = #filePath, line: UInt = #line) async {
        let events = await self.adEventStore.storedEvents
        expect(file: file, line: line, events).to(beEmpty())
    }

    func verifyEvents(
        _ expected: [StoredAdEvent],
        file: FileString = #filePath,
        line: UInt = #line
    ) async {
        let events = await self.adEventStore.storedEvents
        expect(file: file, line: line, events) == expected
    }

    func createStoredAdEvent(from event: AdEvent) throws -> StoredAdEvent {
        return try XCTUnwrap(.init(event: event,
                                   userID: Self.userID,
                                   appSessionID: self.appSessionID))
    }

}

// MARK: - MockAdEventStore

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private actor MockAdEventStore: AdEventStoreType {

    var storedEvents: [StoredAdEvent] = []

    func store(_ storedEvent: StoredAdEvent) {
        self.storedEvents.append(storedEvent)
    }

    func fetch(_ count: Int) -> [StoredAdEvent] {
        return Array(self.storedEvents.prefix(count))
    }

    func clear(_ count: Int) {
        self.storedEvents.removeFirst(min(count, self.storedEvents.count))
    }

}

// MARK: - MockEventStore

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private actor MockEventStore: FeatureEventStoreType {

    var storedEvents: [StoredFeatureEvent] = []

    func store(_ storedEvent: StoredFeatureEvent) {
        self.storedEvents.append(storedEvent)
    }

    func fetch(_ count: Int) -> [StoredFeatureEvent] {
        return Array(self.storedEvents.prefix(count))
    }

    func clear(_ count: Int) {
        self.storedEvents.removeFirst(min(count, self.storedEvents.count))
    }

}

#endif
