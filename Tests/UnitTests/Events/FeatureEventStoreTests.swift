//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FeatureEventStoreTests.swift
//
//  Created by Nacho Soto on 9/5/23.

import Foundation
import Nimble
@_spi(Internal) @testable import RevenueCat
import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class FeatureEventStoreTests: TestCase {

    private var handler: MockFileHandler!
    private var store: FeatureEventStore!

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.handler = .init()
        self.store = .init(handler: self.handler)
    }

    // - MARK: -

    func testCreateDefaultDoesNotThrow() throws {
        _ = try FeatureEventStore.createDefault(applicationSupportDirectory: nil)
    }

    func testPersistsEventsAcrossInitialization() async throws {
        let container = Self.temporaryFolder()

        var store = try FeatureEventStore.createDefault(
            applicationSupportDirectory: container
        )

        await store.store(.randomImpressionEvent())
        await self.verifyEventsInStore(store, expectedCount: 1)

        store = try FeatureEventStore.createDefault(
            applicationSupportDirectory: container
        )
        await self.verifyEventsInStore(store, expectedCount: 1)
    }

    func testCreateDefaultRemovesDocumentsContainer() async throws {
        let applicationSupport = Self.temporaryFolder()
        let documents = Self.temporaryFolder()

        // 1. Initialize store with documents directory:
        var store = try FeatureEventStore.createDefault(applicationSupportDirectory: documents)

        // 2. Store event
        await store.store(.randomImpressionEvent())
        await self.verifyEventsInStore(store, expectedCount: 1)

        // 3. Initialize store with new directories
        store = try FeatureEventStore.createDefault(
            applicationSupportDirectory: applicationSupport,
            documentsDirectory: documents
        )
        await self.verifyEventsInStore(store, expectedCount: 0)

        // 4. Verify events were removed
        store = try FeatureEventStore.createDefault(applicationSupportDirectory: documents)
        await self.verifyEventsInStore(store, expectedCount: 0)
    }

    // - MARK: store and fetch

    func testFetchWithEmptyStore() async {
        let events = await self.store.fetch(1)
        expect(events).to(beEmpty())
    }

    func testFetchingLineWithError() async throws {
        try await self.handler.append(line: "this is not an event")

        let events = await self.store.fetch(1)
        expect(events).to(beEmpty())
    }

    func testStoreOneEvent() async throws {
        let event: StoredFeatureEvent = .randomImpressionEvent()
        await self.store.store(event)

        let events = await self.store.fetch(1)
        expect(events) == [event]
    }

    func testFetchEventsDoesNotRemoveEvents() async {
        await self.store.store(.randomImpressionEvent())

        let eventsBeforeFetching = await self.store.fetch(1)
        let eventsAfterFetching = await self.store.fetch(1)

        expect(eventsBeforeFetching).toNot(beEmpty())
        expect(eventsAfterFetching).toNot(beEmpty())
    }

    func testStoreMultipleEvents() async throws {
        let event1: StoredFeatureEvent = .randomImpressionEvent()
        let event2: StoredFeatureEvent = .randomImpressionEvent()

        await self.store.store(event1)
        await self.store.store(event2)

        let events = await self.store.fetch(2)
        expect(events) == [event1, event2]
    }

    func testFetchOnlySomeEvents() async throws {
        let event: StoredFeatureEvent = .randomImpressionEvent()

        await self.store.store(event)
        await self.store.store(.randomImpressionEvent())
        await self.store.store(.randomImpressionEvent())

        let events = await self.store.fetch(1)
        expect(events) == [event]
    }

    func testFetchEventsWithUnrecognizedLines() async throws {
        let event: StoredFeatureEvent = .randomImpressionEvent()

        await self.store.store(event)
        try await self.handler.append(line: "not an event")
        await self.store.store(.randomImpressionEvent())

        let events = await self.store.fetch(2)
        expect(events) == [event]
    }

    // - MARK: clear events

    func testClearEmptyStore() async {
        await self.store.clear(1)

        let events = await self.store.fetch(1)
        expect(events).to(beEmpty())
    }

    func testClearSingleEvent() async {
        let event: StoredFeatureEvent = .randomImpressionEvent()

        await self.store.store(event)
        await self.store.clear(1)

        let events = await self.store.fetch(1)
        expect(events).to(beEmpty())
    }

    func testClearOnlyOneEvent() async throws {
        let storedEvents: [StoredFeatureEvent] = [
            .randomImpressionEvent(),
            .randomImpressionEvent(),
            .randomImpressionEvent()
        ]

        for event in storedEvents {
            await self.store.store(event)
        }

        await self.store.clear(1)

        let events = await self.store.fetch(storedEvents.count)
        expect(events) == Array(storedEvents.dropFirst())
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

    func testAppendingLineFailureLogsError() async {
        struct FakeError: Error {}

        await self.handler.setAppendLineError(FakeError())

        await self.store.store(.randomImpressionEvent())

        expect(self.logger.messages).to(containElementSatisfying {
            $0.message.contains("Error storing event: ")
        })
    }

    // - MARK: size limit tests

    func testSizeLimitCausesOldEventsToBeDropped() async {
        // Store 60 events first
        for _ in 0..<60 {
            await self.store.store(.randomImpressionEvent())
        }

        // Mock file size to be over the limit (2048 KB)
        await self.handler.setMockedFileSizeInKB(2100)

        // Store one more event, which should trigger cleanup
        await self.store.store(.randomImpressionEvent())

        // Reset mocked size to reflect actual file size after cleanup
        await self.handler.setMockedFileSizeInKB(nil)

        // Should have cleared 50 events, leaving 11 (60 - 50 + 1)
        let events = await self.store.fetch(100)
        expect(events).to(haveCount(11))
    }

    func testSizeLimitLogsWarning() async {
        // Mock file size to be over the limit
        await self.handler.setMockedFileSizeInKB(2100)

        // Store an event, which should trigger size check and log warning
        await self.store.store(.randomImpressionEvent())

        expect(self.logger.messages).to(containElementSatisfying {
            $0.level == .warn && $0.message.contains("size limit reached")
        })
    }

    func testNoCleanupWhenBelowSizeLimit() async {
        // Store some events - file will naturally be below 2048 KB limit
        for _ in 0..<10 {
            await self.store.store(.randomImpressionEvent())
        }

        // Store one more event
        await self.store.store(.randomImpressionEvent())

        // Should still have all 11 events (no cleanup occurred)
        let events = await self.store.fetch(100)
        expect(events).to(haveCount(11))

        // Should not log warning
        expect(self.logger.messages).toNot(containElementSatisfying {
            $0.level == .warn && $0.message.contains("size limit reached")
        })
    }

    func testSizeLimitKeepsLatest11Events() async {
        // Store 60 events and keep track of them
        var allEvents: [StoredFeatureEvent] = []
        for _ in 0..<60 {
            let event = StoredFeatureEvent.randomImpressionEvent()
            allEvents.append(event)
            await self.store.store(event)
        }

        // Mock file size to be over the limit (2048 KB)
        await self.handler.setMockedFileSizeInKB(2100)

        // Store one more event, which should trigger cleanup
        let finalEvent = StoredFeatureEvent.randomImpressionEvent()
        allEvents.append(finalEvent)
        await self.store.store(finalEvent)

        // Reset mocked size to reflect actual file size after cleanup
        await self.handler.setMockedFileSizeInKB(nil)

        // Fetch remaining events
        let remainingEvents = await self.store.fetch(100)

        // Should have the latest 11 events (last 10 from original 60 + the final event)
        let expectedEvents = Array(allEvents.suffix(11))
        expect(remainingEvents) == expectedEvents
    }

}

// MARK: - Extensions

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension FeatureEventStoreTests {

    static func temporaryFolder() -> URL {
        return FileManager.default
            .temporaryDirectory
            .appendingPathComponent("paywall_event_store_tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    func verifyEventsInStore(
        _ store: FeatureEventStore,
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
            paywallIdentifier: "test_paywall_id",
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
private extension StoredFeatureEvent {

    static func randomImpressionEvent() -> Self {
        let event = PaywallEvent.randomImpressionEvent()
        return .init(event: event,
                     userID: UUID().uuidString,
                     feature: .paywalls,
                     appSessionID: UUID(),
                     eventDiscriminator: "impression")!
    }

}
