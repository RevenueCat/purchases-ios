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
//  Created by RevenueCat on 1/21/25.

import Foundation
import Nimble
@_spi(Experimental) @testable import RevenueCat
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

    // On tvOS CI, some simulator instances have a broken filesystem where
    // creating subdirectories under Library/Caches fails with EIO (POSIX code 5).
    // This is an environment issue: the simulator's disk image is corrupted or
    // has accumulated too many temporary directories (rdar://50553219, FB13722352).
    // The condition is persistent for the entire test run but intermittent across
    // CI runs. We probe the filesystem first and skip when it's unhealthy, so the
    // test still validates the real default path on healthy simulators.
    func testCreateDefaultReturnsNonNil() throws {
        #if os(tvOS)
        try Self.skipIfCachesDirectoryIsNotWritable()
        #endif

        let store = AdEventStore.createDefault(persistenceDirectory: nil)
        expect(store).toNot(beNil())
    }

    func testPersistsEventsAcrossInitialization() async throws {
        let container = Self.temporaryFolder()

        var store = try XCTUnwrap(AdEventStore.createDefault(
            persistenceDirectory: container
        ))

        await store.store(.randomDisplayedEvent())
        await self.verifyEventsInStore(store, expectedCount: 1)

        store = try XCTUnwrap(AdEventStore.createDefault(
            persistenceDirectory: container
        ))
        await self.verifyEventsInStore(store, expectedCount: 1)
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
        let event: StoredAdEvent = .randomDisplayedEvent()
        await self.store.store(event)

        let events = await self.store.fetch(1)
        expect(events) == [event]
    }

    func testFetchEventsDoesNotRemoveEvents() async {
        await self.store.store(.randomDisplayedEvent())

        let eventsBeforeFetching = await self.store.fetch(1)
        let eventsAfterFetching = await self.store.fetch(1)

        expect(eventsBeforeFetching).toNot(beEmpty())
        expect(eventsAfterFetching).toNot(beEmpty())
    }

    func testStoreMultipleEvents() async throws {
        let event1: StoredAdEvent = .randomDisplayedEvent()
        let event2: StoredAdEvent = .randomDisplayedEvent()

        await self.store.store(event1)
        await self.store.store(event2)

        let events = await self.store.fetch(2)
        expect(events) == [event1, event2]
    }

    func testFetchOnlySomeEvents() async throws {
        let event: StoredAdEvent = .randomDisplayedEvent()

        await self.store.store(event)
        await self.store.store(.randomDisplayedEvent())
        await self.store.store(.randomDisplayedEvent())

        let events = await self.store.fetch(1)
        expect(events) == [event]
    }

    func testFetchEventsWithUnrecognizedLines() async throws {
        let event: StoredAdEvent = .randomDisplayedEvent()

        await self.store.store(event)
        try await self.handler.append(line: "not an event")
        await self.store.store(.randomDisplayedEvent())

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
        let event: StoredAdEvent = .randomDisplayedEvent()

        await self.store.store(event)
        await self.store.clear(1)

        let events = await self.store.fetch(1)
        expect(events).to(beEmpty())
    }

    func testClearOnlyOneEvent() async throws {
        let storedEvents: [StoredAdEvent] = [
            .randomDisplayedEvent(),
            .randomDisplayedEvent(),
            .randomDisplayedEvent()
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
            await self.store.store(.randomDisplayedEvent())
        }

        await self.store.clear(count)

        let events = await self.store.fetch(count)
        expect(events).to(beEmpty())
    }

    func testRemovingFirstLinesFailingClearsEntireFile() async {
        struct FakeError: Error {}

        await self.handler.setRemoveFirstLineError(FakeError())

        for _ in 0..<3 {
            await self.store.store(.randomDisplayedEvent())
        }

        await self.store.clear(1)

        let events = await self.store.fetch(3)
        expect(events).to(beEmpty())

        expect(self.logger.messages).to(containElementSatisfying {
            $0.level == .error
        })
    }

    func testSizeLimitTriggersCleanup() async throws {
        let firstEvent: StoredAdEvent = .randomDisplayedEvent()
        await self.store.store(firstEvent)

        let events = await self.store.fetch(1)
        expect(events) == [firstEvent]

        // Mock file size to exceed size limit to test cleanup behavior
        await self.handler.setMockedFileSizeInKB(2049)

        // Store another event, which should trigger cleanup of old events
        let secondEvent: StoredAdEvent = .randomDisplayedEvent()
        await self.store.store(secondEvent)

        // After cleanup, only the new event should remain
        let remainingEvents = await self.store.fetch(2)
        expect(remainingEvents) == [secondEvent]

        // Verify cleanup was logged
        expect(self.logger.messages).to(containElementSatisfying {
            $0.level == .warn || $0.level == .info
        })
    }

}

// MARK: - Extensions

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension AdEventStoreTests {

    static func skipIfCachesDirectoryIsNotWritable() throws {
        let caches: URL
        if #available(tvOS 16.0, *) {
            caches = URL.cachesDirectory
        } else {
            caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        }
        let probe = caches.appendingPathComponent("revenuecat_probe_\(UUID().uuidString)")
        NSLog("[skipIfCachesDirectoryIsNotWritable] caches URL: \(caches)")
        NSLog("[skipIfCachesDirectoryIsNotWritable] probe URL: \(probe)")
        NSLog("[skipIfCachesDirectoryIsNotWritable] caches exists: \(FileManager.default.fileExists(atPath: caches.path))")
        NSLog("[skipIfCachesDirectoryIsNotWritable] caches isDir: \(FileManager.default.fileExists(atPath: caches.path))")
        if let attrs = try? FileManager.default.attributesOfItem(atPath: caches.path) {
            NSLog("[skipIfCachesDirectoryIsNotWritable] caches attrs: \(attrs)")
        }
        do {
            try FileManager.default.createDirectory(at: probe, withIntermediateDirectories: true)
            NSLog("[skipIfCachesDirectoryIsNotWritable] probe created successfully")
            try FileManager.default.removeItem(at: probe)
            NSLog("[skipIfCachesDirectoryIsNotWritable] probe removed successfully")
        } catch {
            NSLog("[skipIfCachesDirectoryIsNotWritable] probe FAILED: \(error)")
            throw XCTSkip("Library/Caches is not writable on this simulator: \(error)")
        }
    }

    static func temporaryFolder() -> URL {
        return FileManager.default
            .temporaryDirectory
            .appendingPathComponent("ad_event_store_tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    func verifyEventsInStore(
        _ store: AdEventStore,
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
extension AdEvent.CreationData {

    static func random() -> Self {
        return .init(
            id: .init(),
            date: .now.removingMilliseconds
        )
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension AdDisplayed {

    static func random() -> Self {
        return .init(
            networkName: "AdMob",
            mediatorName: .appLovin,
            adFormat: .banner,
            placement: "home_screen",
            adUnitId: "ca-app-pub-\(UUID().uuidString)",
            impressionId: "impression-\(UUID().uuidString)"
        )
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
extension AdEvent {

    static func randomDisplayedEvent() -> Self {
        return .displayed(.random(), .random())
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension StoredAdEvent {

    static func randomDisplayedEvent() -> Self {
        let event = AdEvent.randomDisplayedEvent()
        return .init(event: event,
                     userID: UUID().uuidString,
                     appSessionID: UUID())!
    }

}
