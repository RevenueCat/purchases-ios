//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DiagnosticsTrackerTests.swift
//
//  Created by Cesar de la Vega on 11/4/24.

import Foundation
import Nimble

@testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class DiagnosticsTrackerTests: TestCase {

    fileprivate var fileHandler: FileHandler!
    fileprivate var handler: DiagnosticsFileHandler!
    fileprivate var tracker: DiagnosticsTracker!

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.fileHandler = try Self.createWithTemporaryFile()
        self.handler = .init(self.fileHandler)
        self.tracker = .init(diagnosticsFileHandler: self.handler)
    }

    override func tearDown() async throws {
        self.handler = nil

        try await super.tearDown()
    }

    // MARK: - trackEvent

    func testTrackEvent() async {
        let event = DiagnosticsEvent(eventType: .httpRequestPerformed,
                                     properties: ["key": AnyEncodable("property")],
                                     timestamp: Self.eventTimestamp1)

        await self.tracker.track(event)

        let entries = await self.handler.getEntries()
        expect(entries) == [
            .init(eventType: .httpRequestPerformed,
                  properties: ["key": AnyEncodable("property")],
                  timestamp: Self.eventTimestamp1)
        ]
    }

    func testTrackMultipleEvents() async {
        let event1 = DiagnosticsEvent(eventType: .httpRequestPerformed,
                                      properties: ["key": AnyEncodable("property")],
                                      timestamp: Self.eventTimestamp1)
        let event2 = DiagnosticsEvent(eventType: .customerInfoVerificationResult,
                                      properties: ["key": AnyEncodable("property")],
                                      timestamp: Self.eventTimestamp2)

        await self.tracker.track(event1)
        await self.tracker.track(event2)

        let entries = await self.handler.getEntries()
        expect(entries) == [
            .init(eventType: .httpRequestPerformed,
                  properties: ["key": AnyEncodable("property")],
                  timestamp: Self.eventTimestamp1),
            .init(eventType: .customerInfoVerificationResult,
                  properties: ["key": AnyEncodable("property")],
                  timestamp: Self.eventTimestamp2)
        ]
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension DiagnosticsTrackerTests {

    static let eventTimestamp1: Date = .init(timeIntervalSince1970: 1694029328)
    static let eventTimestamp2: Date = .init(timeIntervalSince1970: 1694022321)

    static func temporaryFileURL() -> URL {
        return FileManager.default
            .temporaryDirectory
            .appendingPathComponent("file_handler_tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: false)
            .appendingPathExtension("jsonl")
    }

    static func createWithTemporaryFile() throws -> FileHandler {
        return try FileHandler(Self.temporaryFileURL())
    }
}
