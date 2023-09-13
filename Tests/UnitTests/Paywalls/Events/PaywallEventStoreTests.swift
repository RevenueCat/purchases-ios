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
        _ = try PaywallEventStore.createDefault(documentsDirectory: nil)
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

    func testStoreOneEvent() async {
        let event: PaywallStoredEvent = .randomViewEvent()

        await self.store.store(event)

        let events = await self.store.fetch(1)
        expect(events) == [event]
    }

    func testFetchEventsDoesNotRemoveEvents() async {
        await self.store.store(.randomViewEvent())

        let eventsBeforeFetching = await self.store.fetch(1)
        let eventsAfterFetching = await self.store.fetch(1)

        expect(eventsBeforeFetching).toNot(beEmpty())
        expect(eventsAfterFetching).toNot(beEmpty())
    }

    func testStoreMultipleEvents() async {
        let event1: PaywallStoredEvent = .randomViewEvent()
        let event2: PaywallStoredEvent = .randomViewEvent()

        await self.store.store(event1)
        await self.store.store(event2)

        let events = await self.store.fetch(2)
        expect(events) == [event1, event2]
    }

    func testFetchOnlySomeEvents() async {
        let event: PaywallStoredEvent = .randomViewEvent()

        await self.store.store(event)
        await self.store.store(.randomViewEvent())
        await self.store.store(.randomViewEvent())

        let events = await self.store.fetch(1)
        expect(events) == [event]
    }

    func testFetchEventsWithUnrecognizedLines() async {
        let event: PaywallStoredEvent = .randomViewEvent()

        await self.store.store(event)
        await self.handler.append(line: "not an event")
        await self.store.store(.randomViewEvent())

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
        let event: PaywallStoredEvent = .randomViewEvent()

        await self.store.store(event)
        await self.store.clear(1)

        let events = await self.store.fetch(1)
        expect(events).to(beEmpty())
    }

    func testClearOnlyOneEvent() async {
        let storedEvents: [PaywallStoredEvent] = [
            .randomViewEvent(),
            .randomViewEvent(),
            .randomViewEvent()
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
            await self.store.store(.randomViewEvent())
        }

        await self.store.clear(count)

        let events = await self.store.fetch(count)
        expect(events).to(beEmpty())
    }

    func testRemovingFirstLinesFailingClearsEntireFile() async {
        struct FakeError: Error {}

        await self.handler.setRemoveFirstLineError(FakeError())

        for _ in 0..<3 {
            await self.store.store(.randomViewEvent())
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
extension PaywallEvent.Data {

    static func random() -> Self {
        return .init(
            offeringIdentifier: "offering",
            paywallRevision: Int.random(in: 0..<100),
            sessionID: .init(),
            displayMode: PaywallViewMode.allCases.randomElement()!,
            localeIdentifier: "es_ES",
            darkMode: Bool.random(),
            date: .now.removingMilliseconds
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallEvent {

    static func randomViewEvent() -> Self {
        return .view(.random())
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallStoredEvent {

    static func randomViewEvent() -> Self {
        return .init(event: .randomViewEvent(), userID: UUID().uuidString)
    }

}
