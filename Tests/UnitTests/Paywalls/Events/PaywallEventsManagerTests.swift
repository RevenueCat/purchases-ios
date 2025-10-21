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
    private var appSessionID = UUID()

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.api = .init()
        self.userProvider = .init(mockAppUserID: Self.userID)
        self.store = .init()
        self.manager = .init(
            internalAPI: self.api,
            userProvider: self.userProvider,
            store: self.store,
            appSessionID: self.appSessionID
        )
    }

    // MARK: - trackEvent

    func testTrackEvent() async throws {
        let event: PaywallEvent = .impression(.random(), .random())

        await self.manager.track(featureEvent: event)

        let events = await self.store.storedEvents
        expect(events) == [
            try createStoredEvent(from: event)
        ]
    }

    func testTrackMultipleEvents() async throws {
        let event1: PaywallEvent = .impression(.random(), .random())
        let event2: PaywallEvent = .close(.random(), .random())

        await self.manager.track(featureEvent: event1)
        await self.manager.track(featureEvent: event2)

        let events = await self.store.storedEvents
        expect(events) == [
            try createStoredEvent(from: event1),
            try createStoredEvent(from: event2)
        ]
    }

    // MARK: - flushEvents

    func testFlushEmptyStore() async throws {
        let result = try await self.manager.flushEvents(batchSize: 1)
        expect(result) == 0
        expect(self.api.invokedPostPaywallEvents) == false
    }

    func testFlushOneEvent() async throws {
        let event = await self.storeRandomEvent()

        let result = try await self.manager.flushEvents(batchSize: 1)
        expect(result) == 1

        expect(self.api.invokedPostPaywallEvents) == true
        expect(self.api.invokedPostPaywallEventsParameters) == [[try createStoredEvent(from: event)]]

        await self.verifyEmptyStore()
    }

    func testFlushTwice() async throws {
        let event1 = await self.storeRandomEvent()
        let event2 = await self.storeRandomEvent()

        let result1 = try await self.manager.flushEvents(batchSize: 1)
        let result2 = try await self.manager.flushEvents(batchSize: 1)

        expect(result1) == 2
        expect(result2) == 0

        expect(self.api.invokedPostPaywallEvents) == true
        expect(self.api.invokedPostPaywallEventsParameters) == [
            [try createStoredEvent(from: event1)],
            [try createStoredEvent(from: event2)]
        ]

        await self.verifyEmptyStore()
    }

    func testFlushAllEventsInBatches() async throws {
        let event1 = await self.storeRandomEvent()
        let event2 = await self.storeRandomEvent()
        let event3 = await self.storeRandomEvent()

        let result = try await self.manager.flushEvents(batchSize: 1)
        expect(result) == 3

        expect(self.api.invokedPostPaywallEvents) == true
        expect(self.api.invokedPostPaywallEventsParameters) == [
            [try createStoredEvent(from: event1)],
            [try createStoredEvent(from: event2)],
            [try createStoredEvent(from: event3)]
        ]

        await self.verifyEmptyStore()
    }

    func testFlushMultipleEventsInLargerBatches() async throws {
        let event1 = await self.storeRandomEvent()
        let event2 = await self.storeRandomEvent()
        let event3 = await self.storeRandomEvent()
        let event4 = await self.storeRandomEvent()
        let event5 = await self.storeRandomEvent()

        let result = try await self.manager.flushEvents(batchSize: 2)
        expect(result) == 5

        expect(self.api.invokedPostPaywallEvents) == true
        expect(self.api.invokedPostPaywallEventsParameters) == [
            [try createStoredEvent(from: event1), try createStoredEvent(from: event2)],
            [try createStoredEvent(from: event3), try createStoredEvent(from: event4)],
            [try createStoredEvent(from: event5)]
        ]

        await self.verifyEmptyStore()
    }

    func testFlushWithUnsuccessfulPostError() async throws {
        let event = await self.storeRandomEvent()
        let storedEvent = try createStoredEvent(from: event)
        let expectedError: NetworkError = .offlineConnection()

        self.api.stubbedPostPaywallEventsCompletionResult = .networkError(expectedError)
        do {
            _ = try await self.manager.flushEvents(batchSize: 1)
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

        let result = try await self.manager.flushEvents(batchSize: 1)

        expect(result) == 1
        expect(self.api.invokedPostPaywallEvents) == true

        await self.verifyEmptyStore()
    }

    func testFlushWithSuccessfullySyncedErrorContinuesToNextBatch() async throws {
        let event1 = await self.storeRandomEvent()
        let event2 = await self.storeRandomEvent()

        self.api.stubbedPostPaywallEventsCompletionResult = .networkError(
            .errorResponse(.defaultResponse, .invalidRequest)
        )

        let result = try await self.manager.flushEvents(batchSize: 1)

        expect(result) == 2
        expect(self.api.invokedPostPaywallEvents) == true
        expect(self.api.invokedPostPaywallEventsParameters) == [
            [try createStoredEvent(from: event1)],
            [try createStoredEvent(from: event2)]
        ]

        await self.verifyEmptyStore()
    }

    func testFlushWithUnsuccessfulPostErrorStopsAfterFirstBatch() async throws {
        let event1 = await self.storeRandomEvent()
        let event2 = await self.storeRandomEvent()
        let expectedError: NetworkError = .offlineConnection()

        self.api.stubbedPostPaywallEventsCompletionResult = .networkError(expectedError)

        do {
            _ = try await self.manager.flushEvents(batchSize: 1)
            fail("Expected error")
        } catch BackendError.networkError(expectedError) {
            // Expected
        } catch {
            throw error
        }

        expect(self.api.invokedPostPaywallEvents) == true
        expect(self.api.invokedPostPaywallEventsParameters) == [
            [try createStoredEvent(from: event1)]
        ]

        // Both events should still be in the store since the first batch failed
        await self.verifyEvents([
            try createStoredEvent(from: event1),
            try createStoredEvent(from: event2)
        ])
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
        async let result1 = manager.flushEvents(batchSize: 1)
        async let result2 = manager.flushEvents(batchSize: 1)

        // Signal the API call to complete
        continuation.continuation.yield()
        continuation.continuation.finish()

        // Wait for both results
        let results = try await [result1, result2]
        expect(Set(results)) == [2, 0]

        expect(self.api.invokedPostPaywallEvents) == true
        expect(self.api.invokedPostPaywallEventsParameters).to(haveCount(2))
        expect(self.api.invokedPostPaywallEventsParameters.first) == [
            try createStoredEvent(from: event1)
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
        await self.manager.track(featureEvent: event)

        return event
    }

    func verifyEmptyStore(file: FileString = #filePath, line: UInt = #line) async {
        let events = await self.store.storedEvents
        expect(file: file, line: line, events).to(beEmpty())
    }

    func verifyEvents(
        _ expected: [StoredEvent],
        file: FileString = #filePath,
        line: UInt = #line
    ) async {
        let events = await self.store.storedEvents
        expect(file: file, line: line, events) == expected
    }

    func createStoredEvent(from event: PaywallEvent) throws -> StoredEvent {
        return try XCTUnwrap(.init(event: event,
                                   userID: Self.userID,
                                   feature: .paywalls,
                                   appSessionID: self.appSessionID,
                                   eventDiscriminator: nil))
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
