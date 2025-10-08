//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdEventStoreTests.swift
//
//  Created by RevenueCat on 1/8/25.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class AdEventStoreTests: TestCase {

    private var handler: MockFileHandler!
    private var store: AdEventStore!

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.handler = .init()
        self.store = .init(handler: self.handler)
    }

    // - MARK: -

    func testCreateDefaultDoesNotThrow() throws {
        _ = try AdEventStore.createDefault(applicationSupportDirectory: nil)
    }

    func testPersistsEventsAcrossInitialization() async throws {
        let container = Self.temporaryFolder()

        var store = try AdEventStore.createDefault(
            applicationSupportDirectory: container
        )

        await store.store(.randomDisplayedEvent())
        await self.verifyEventsInStore(store, expectedCount: 1)

        store = try AdEventStore.createDefault(
            applicationSupportDirectory: container
        )
        await self.verifyEventsInStore(store, expectedCount: 1)
    }

    func testCreateDefaultRemovesDocumentsContainer() async throws {
        let applicationSupport = Self.temporaryFolder()
        let documents = Self.temporaryFolder()

        var store = try AdEventStore.createDefault(applicationSupportDirectory: documents)

        await store.store(.randomDisplayedEvent())
        await self.verifyEventsInStore(store, expectedCount: 1)

        store = try AdEventStore.createDefault(
            applicationSupportDirectory: applicationSupport,
            documentsDirectory: documents
        )
        await self.verifyEventsInStore(store, expectedCount: 0)

        store = try AdEventStore.createDefault(applicationSupportDirectory: documents)
        await self.verifyEventsInStore(store, expectedCount: 0)
    }

    // - MARK: store and fetch

    func testStoreOneEvent() async throws {
        let event = StoredEvent.randomDisplayedEvent()
        await self.store.store(event)

        let events = await self.store.fetch(1)
        expect(events) == [event]
    }

    func testStoreMultipleEvents() async throws {
        let event1 = StoredEvent.randomDisplayedEvent()
        let event2 = StoredEvent.randomOpenedEvent()

        await self.store.store(event1)
        await self.store.store(event2)

        let events = await self.store.fetch(2)
        expect(events) == [event1, event2]
    }

    func testFetchReturnsEventsInOrder() async throws {
        let event1 = StoredEvent.randomDisplayedEvent()
        let event2 = StoredEvent.randomOpenedEvent()
        let event3 = StoredEvent.randomRevenueEvent()

        await self.store.store(event1)
        await self.store.store(event2)
        await self.store.store(event3)

        let events = await self.store.fetch(3)
        expect(events) == [event1, event2, event3]
    }

    func testFetchOnlyFetchesRequestedCount() async throws {
        let event1 = StoredEvent.randomDisplayedEvent()
        let event2 = StoredEvent.randomOpenedEvent()

        await self.store.store(event1)
        await self.store.store(event2)

        let events = await self.store.fetch(1)
        expect(events) == [event1]
    }

    // - MARK: clear

    func testClearRemovesEvents() async throws {
        let event = StoredEvent.randomDisplayedEvent()
        await self.store.store(event)

        await self.store.clear(1)

        let events = await self.store.fetch(1)
        expect(events).to(beEmpty())
    }

    func testClearOnlyRemovesRequestedCount() async throws {
        let event1 = StoredEvent.randomDisplayedEvent()
        let event2 = StoredEvent.randomOpenedEvent()
        let event3 = StoredEvent.randomRevenueEvent()

        await self.store.store(event1)
        await self.store.store(event2)
        await self.store.store(event3)

        await self.store.clear(2)

        let events = await self.store.fetch(10)
        expect(events) == [event3]
    }

    // MARK: -

    private func verifyEventsInStore(_ store: AdEventStore, expectedCount: Int) async {
        let events = await store.fetch(expectedCount + 1)
        expect(events).to(haveCount(expectedCount))
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension AdEventStoreTests {

    static func temporaryFolder() -> URL {
        return FileManager.default
            .temporaryDirectory
            .appendingPathComponent("ad_event_store_tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

}

// MARK: - Test Helpers

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension AdEvent.CreationData {

    static func random() -> Self {
        return .init(
            id: .init(),
            date: .now.removingMilliseconds
        )
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension AdEvent.Data {

    static func random() -> Self {
        return .init(
            networkName: ["AdMob", "AppLovin", "Unity", "IronSource"].randomElement()!,
            mediatorName: ["MAX", "AdMob", "IronSource"].randomElement()!,
            placement: ["home_screen", "game_over", "menu", nil].randomElement()!,
            adUnitId: "ca-app-pub-\(Int.random(in: 100000000...999999999))",
            adInstanceId: "instance-\(UUID().uuidString.prefix(8))",
            sessionIdentifier: .init()
        )
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension AdEvent.RevenueData {

    static func random() -> Self {
        return .init(
            networkName: ["AdMob", "AppLovin", "Unity", "IronSource"].randomElement()!,
            mediatorName: ["MAX", "AdMob", "IronSource"].randomElement()!,
            placement: ["home_screen", "game_over", "menu", nil].randomElement()!,
            adUnitId: "ca-app-pub-\(Int.random(in: 100000000...999999999))",
            adInstanceId: "instance-\(UUID().uuidString.prefix(8))",
            sessionIdentifier: .init(),
            revenueMicros: Int.random(in: 1000...10000000),
            currency: ["USD", "EUR", "GBP", "JPY"].randomElement()!,
            precision: Precision.allCases.randomElement()!
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension AdEvent {

    static func randomDisplayedEvent() -> Self {
        return .displayed(.random(), .random())
    }

    static func randomOpenedEvent() -> Self {
        return .opened(.random(), .random())
    }

    static func randomRevenueEvent() -> Self {
        return .revenue(.random(), .random())
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension StoredEvent {

    static func randomDisplayedEvent() -> Self {
        let event = AdEvent.randomDisplayedEvent()
        return .init(event: event,
                     userID: UUID().uuidString,
                     feature: .ads,
                     appSessionID: UUID(),
                     eventDiscriminator: nil)!
    }

    static func randomOpenedEvent() -> Self {
        let event = AdEvent.randomOpenedEvent()
        return .init(event: event,
                     userID: UUID().uuidString,
                     feature: .ads,
                     appSessionID: UUID(),
                     eventDiscriminator: nil)!
    }

    static func randomRevenueEvent() -> Self {
        let event = AdEvent.randomRevenueEvent()
        return .init(event: event,
                     userID: UUID().uuidString,
                     feature: .ads,
                     appSessionID: UUID(),
                     eventDiscriminator: nil)!
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension Precision: CaseIterable {
    public static var allCases: [Precision] {
        return [.exact, .publisherDefined, .estimated, .unknown]
    }
}
