//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallEventStoreTests.swift
//
//  Created by Nacho Soto on 9/5/23.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class PaywallEventStoreTests: TestCase {

    private var handler: MockFileHandler!
    private var store: PaywallEventStore!

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.handler = .init()
        self.store = .init(handler: self.handler)
    }

    // - MARK: -

    func testCreateDefaultDoesNotThrow() throws {
        _ = try PaywallEventStore.createDefault(applicationSupportDirectory: nil)
    }

    func testPersistsEventsAcrossInitialization() async throws {
        let container = Self.temporaryFolder()

        var store = try PaywallEventStore.createDefault(
            applicationSupportDirectory: container
        )

        await store.store(.randomImpressionEvent())
        await self.verifyEventsInStore(store, expectedCount: 1)

        store = try PaywallEventStore.createDefault(
            applicationSupportDirectory: container
        )
        await self.verifyEventsInStore(store, expectedCount: 1)
    }

    func testCreateDefaultRemovesDocumentsContainer() async throws {
        let applicationSupport = Self.temporaryFolder()
        let documents = Self.temporaryFolder()

        // 1. Initialize store with documents directory:
        var store = try PaywallEventStore.createDefault(applicationSupportDirectory: documents)

        // 2. Store event
        await store.store(.randomImpressionEvent())
        await self.verifyEventsInStore(store, expectedCount: 1)

        // 3. Initialize store with new directories
        store = try PaywallEventStore.createDefault(
            applicationSupportDirectory: applicationSupport,
            documentsDirectory: documents
        )
        await self.verifyEventsInStore(store, expectedCount: 0)

        // 4. Verify events were removed
        store = try PaywallEventStore.createDefault(applicationSupportDirectory: documents)
        await self.verifyEventsInStore(store, expectedCount: 0)
    }

    // - MARK: store and fetch

    func testFetchWithEmptyStore() async {
        let events = await self.store.fetch(1)
        expect(events).to(beEmpty())
    }

    func testFetchingLineWithError() async {
        await self.handler.append(line: "this is not an event")

        let events = await self.store.fetch(1)
        expect(events).to(beEmpty())
    }

    func testStoreOneEvent() async throws {
        let eventToStore: StoredEvent = .randomImpressionEvent()
        await self.store.store(eventToStore)

        let events = await self.store.fetch(1)
        try verifyEvents(events, equalTo: [eventToStore])
    }

    func testFetchEventsDoesNotRemoveEvents() async {
        await self.store.store(.randomImpressionEvent())

        let eventsBeforeFetching = await self.store.fetch(1)
        let eventsAfterFetching = await self.store.fetch(1)

        expect(eventsBeforeFetching).toNot(beEmpty())
        expect(eventsAfterFetching).toNot(beEmpty())
    }

    func testStoreMultipleEvents() async throws {
        let eventToStore1: StoredEvent = .randomImpressionEvent()
        let eventToStore2: StoredEvent = .randomImpressionEvent()

        await self.store.store(eventToStore1)
        await self.store.store(eventToStore2)

        let events = await self.store.fetch(2)
        try verifyEvents(events, equalTo: [eventToStore1, eventToStore2])
    }

    func testFetchOnlySomeEvents() async throws {
        let event: StoredEvent = .randomImpressionEvent()

        await self.store.store(event)
        await self.store.store(.randomImpressionEvent())
        await self.store.store(.randomImpressionEvent())

        let events = await self.store.fetch(1)
        try verifyEvents(events, equalTo: [event])
    }

    func testFetchEventsWithUnrecognizedLines() async throws {
        let event: StoredEvent = .randomImpressionEvent()

        await self.store.store(event)
        await self.handler.append(line: "not an event")
        await self.store.store(.randomImpressionEvent())

        let events = await self.store.fetch(2)
        try verifyEvents(events, equalTo: [event])
    }

    // - MARK: clear events

    func testClearEmptyStore() async {
        await self.store.clear(1)

        let events = await self.store.fetch(1)
        expect(events).to(beEmpty())
    }

    func testClearSingleEvent() async {
        let event: StoredEvent = .randomImpressionEvent()

        await self.store.store(event)
        await self.store.clear(1)

        let events = await self.store.fetch(1)
        expect(events).to(beEmpty())
    }

    func testClearOnlyOneEvent() async throws {
        let storedEvents: [StoredEvent] = [
            .randomImpressionEvent(),
            .randomImpressionEvent(),
            .randomImpressionEvent()
        ]

        for event in storedEvents {
            await self.store.store(event)
        }

        await self.store.clear(1)

        let events = await self.store.fetch(storedEvents.count)
        let expectedStoredEvents = Array(storedEvents.dropFirst())
        try verifyEvents(events, equalTo: expectedStoredEvents)
    }

    func testClearAllEvents() async {
        let count = 3

        for _ in 0..<count {
            await self.store.store(.randomImpressionEvent())
        }

        await self.store.clear(count)

        let events = await self.store.fetch(count)
        expect(events).to(beEmpty())
    }

    func testRemovingFirstLinesFailingClearsEntireFile() async {
        struct FakeError: Error {}

        await self.handler.setRemoveFirstLineError(FakeError())

        for _ in 0..<3 {
            await self.store.store(.randomImpressionEvent())
        }

        await self.store.clear(1)

        let events = await self.store.fetch(3)
        expect(events).to(beEmpty())

        expect(self.logger.messages).to(containElementSatisfying {
            $0.level == .error
        })
    }

}

// MARK: - Extensions

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension PaywallEventStoreTests {

    static func temporaryFolder() -> URL {
        return FileManager.default
            .temporaryDirectory
            .appendingPathComponent("paywall_event_store_tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    func verifyEventsInStore(
        _ store: PaywallEventStore,
        expectedCount: Int,
        file: FileString = #file,
        line: UInt = #line
    ) async {
        let events = await store.fetch(100)

        expect(
            file: file,
            line: line,
            events
        ).to(haveCount(expectedCount))
    }

    func verifyEvents(
        _ actual: [StoredEvent],
        equalTo expected: [StoredEvent],
        file: FileString = #file,
        line: UInt = #line
    ) throws {
        expect(file: file, line: line, actual.count) == expected.count

        for (actualEvent, expectedEvent) in zip(actual, expected) {
            expect(file: file, line: line, actualEvent.userID) == expectedEvent.userID
            expect(file: file, line: line, actualEvent.feature) == expectedEvent.feature

            let actualEventData = try XCTUnwrap(actualEvent.event.value as? [String: Any])
            let actualPaywallEvent: PaywallEvent = try XCTUnwrap(try? JSONDecoder.default.decode(dictionary: actualEventData))
            
            expect(
                file: file,
                line: line,
                expectedEvent.event.value as? PaywallEvent
            ) == actualPaywallEvent
        }
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension PaywallEvent.CreationData {

    static func random() -> Self {
        return .init(
            id: .init(),
            date: .now.removingMilliseconds
        )
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension PaywallEvent.Data {

    static func random() -> Self {
        return .init(
            offeringIdentifier: "offering",
            paywallRevision: Int.random(in: 0..<100),
            sessionID: .init(),
            displayMode: PaywallViewMode.allCases.randomElement()!,
            localeIdentifier: "es_ES",
            darkMode: Bool.random()
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallEvent {

    static func randomImpressionEvent() -> Self {
        return .impression(.random(), .random())
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension StoredEvent {

    static func randomImpressionEvent() -> Self {
        return .init(event: AnyEncodable(PaywallEvent.randomImpressionEvent()),
                     userID: UUID().uuidString,
                     feature: .paywalls)
    }

}
