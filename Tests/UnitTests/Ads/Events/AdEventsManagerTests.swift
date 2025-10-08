//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdEventsManagerTests.swift
//
//  Created by RevenueCat on 1/8/25.

import Foundation
import Nimble

@testable import RevenueCat

import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class AdEventsManagerTests: TestCase {

    private var api: MockInternalAPI!
    private var userProvider: MockCurrentUserProvider!
    private var store: MockAdEventStore!
    private var manager: AdEventsManager!
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
        let event: AdEvent = .displayed(.random(), .random())

        await self.manager.track(featureEvent: event)

        let events = await self.store.storedEvents
        expect(events) == [
            try createStoredEvent(from: event)
        ]
    }

    func testTrackMultipleEvents() async throws {
        let event1: AdEvent = .displayed(.random(), .random())
        let event2: AdEvent = .opened(.random(), .random())

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
        let result = try await self.manager.flushEvents(count: 1)
        expect(result) == 0
        expect(self.api.invokedPostAdEvents) == false
    }

    func testFlushOneEvent() async throws {
        let event = await self.storeRandomEvent()

        let result = try await self.manager.flushEvents(count: 1)
        expect(result) == 1

        expect(self.api.invokedPostAdEvents) == true
        expect(self.api.invokedPostAdEventsParameters) == [[try createStoredEvent(from: event)]]

        await self.verifyEmptyStore()
    }

    func testFlushTwice() async throws {
        let event1 = await self.storeRandomEvent()
        let event2 = await self.storeRandomEvent()

        let result1 = try await self.manager.flushEvents(count: 1)
        let result2 = try await self.manager.flushEvents(count: 1)

        expect(result1) == 1
        expect(result2) == 1

        expect(self.api.invokedPostAdEvents) == true
        expect(self.api.invokedPostAdEventsParameters) == [
            [try createStoredEvent(from: event1)],
            [try createStoredEvent(from: event2)]
        ]

        await self.verifyEmptyStore()
    }

    func testFlushOnlyOneEventPostsFirstOne() async throws {
        let event = await self.storeRandomEvent()
        let storedEvent = try createStoredEvent(from: event)

        _ = await self.storeRandomEvent()
        _ = await self.storeRandomEvent()

        let result = try await self.manager.flushEvents(count: 1)
        expect(result) == 1

        expect(self.api.invokedPostAdEvents) == true
        expect(self.api.invokedPostAdEventsParameters) == [[storedEvent]]

        let events = await self.store.storedEvents
        expect(events).to(haveCount(2))
        expect(events).toNot(contain(storedEvent))
    }

    func testFlushWithUnsuccessfulPostError() async throws {
        let event = await self.storeRandomEvent()
        let storedEvent = try createStoredEvent(from: event)
        let expectedError: NetworkError = .offlineConnection()

        self.api.stubbedPostAdEventsCompletionResult = .networkError(expectedError)
        do {
            _ = try await self.manager.flushEvents(count: 1)
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
        _ = await self.storeRandomEvent()

        self.api.stubbedPostAdEventsCompletionResult = .networkError(
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

        expect(self.api.invokedPostAdEvents) == true

        await self.verifyEmptyStore()
    }

    func testFlushWithSuccessfullySyncedErrorOnlyDeletesPostedEvents() async throws {
        let event1 = await self.storeRandomEvent()
        let event2 = await self.storeRandomEvent()

        self.api.stubbedPostAdEventsCompletionResult = .networkError(
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

        expect(self.api.invokedPostAdEvents) == true
        let expectedEvent = try createStoredEvent(from: event1)
        expect(self.api.invokedPostAdEventsParameters) == [[expectedEvent]]

        await self.verifyEvents([try createStoredEvent(from: event2)])
    }

    #if swift(>=5.9)
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func testCannotFlushMultipleTimesInParallel() async throws {
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        let event1 = await self.storeRandomEvent()
        _ = await self.storeRandomEvent()

        let continuation = AsyncStream<Void>.makeStream()

        self.api.stubbedPostAdEventsCallback = { completion in
            Task {
                await continuation.stream.first { _ in true }
                completion(nil)
            }
        }

        let manager = self.manager!
        async let result1 = manager.flushEvents(count: 1)
        async let result2 = manager.flushEvents(count: 1)

        continuation.continuation.yield()
        continuation.continuation.finish()

        let results = try await [result1, result2]
        expect(Set(results)) == [1, 0]

        expect(self.api.invokedPostAdEvents) == true
        expect(self.api.invokedPostAdEventsParameters).to(haveCount(1))
        expect(self.api.invokedPostAdEventsParameters.onlyElement) == [
            try createStoredEvent(from: event1)
        ]

        self.logger.verifyMessageWasLogged(
            Strings.ads.event_flush_already_in_progress,
            level: .debug,
            expectedCount: 1
        )
    }
    #endif

    // MARK: -

    private static let userID = "test-user"

}

// MARK: - Private

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension AdEventsManagerTests {

    func storeRandomEvent() async -> AdEvent {
        let event: AdEvent = .displayed(.random(), .random())
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

    func createStoredEvent(from event: AdEvent) throws -> StoredEvent {
        return try XCTUnwrap(.init(event: event,
                                   userID: Self.userID,
                                   feature: .ads,
                                   appSessionID: self.appSessionID,
                                   eventDiscriminator: nil))
    }

}

// MARK: - MockAdEventStore

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private actor MockAdEventStore: AdEventStoreType {

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
