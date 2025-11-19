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
    fileprivate var dateProvider: MockDateProvider!

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.fileHandler = try Self.createWithTemporaryFile()
        self.handler = .init(self.fileHandler)
        self.dateProvider = .init(stubbedNow: Self.eventTimestamp1, subsequentNows: Self.eventTimestamp2)
        self.tracker = .init(diagnosticsFileHandler: self.handler,
                             dateProvider: self.dateProvider)
    }

    override func tearDown() async throws {
        self.handler = nil

        try await super.tearDown()
    }

    // MARK: - trackEvent

    func testTrackEvent() async {
        let event = DiagnosticsEvent(eventType: .httpRequestPerformed,
                                     properties: [.verificationResultKey: AnyEncodable("FAILED")],
                                     timestamp: Self.eventTimestamp1)

        await self.tracker.track(event)

        let entries = await self.handler.getEntries()
        expect(entries) == [
            .init(eventType: .httpRequestPerformed,
                  properties: [.verificationResultKey: AnyEncodable("FAILED")],
                  timestamp: Self.eventTimestamp1)
        ]
    }

    func testTrackMultipleEvents() async {
        let event1 = DiagnosticsEvent(eventType: .httpRequestPerformed,
                                      properties: [.verificationResultKey: AnyEncodable("FAILED")],
                                      timestamp: Self.eventTimestamp1)
        let event2 = DiagnosticsEvent(eventType: .customerInfoVerificationResult,
                                      properties: [.verificationResultKey: AnyEncodable("FAILED")],
                                      timestamp: Self.eventTimestamp2)

        await self.tracker.track(event1)
        await self.tracker.track(event2)

        let entries = await self.handler.getEntries()
        expect(entries) == [
            .init(eventType: .httpRequestPerformed,
                  properties: [.verificationResultKey: AnyEncodable("FAILED")],
                  timestamp: Self.eventTimestamp1),
            .init(eventType: .customerInfoVerificationResult,
                  properties: [.verificationResultKey: AnyEncodable("FAILED")],
                  timestamp: Self.eventTimestamp2)
        ]
    }

    // MARK: - customer info verification

    func testDoesNotTrackWhenVerificationIsNotRequested() async {
        let customerInfo: CustomerInfo = .emptyInfo.copy(with: .notRequested)

        await self.tracker.trackCustomerInfoVerificationResultIfNeeded(customerInfo)

        let entries = await self.handler.getEntries()
        expect(entries.count) == 0
    }

    func testTracksCustomerInfoVerificationFailed() async {
        let customerInfo: CustomerInfo = .emptyInfo.copy(with: .failed)

        await self.tracker.trackCustomerInfoVerificationResultIfNeeded(customerInfo)

        let entries = await self.handler.getEntries()
        expect(entries) == [
            .init(eventType: .customerInfoVerificationResult,
                  properties: [.verificationResultKey: AnyEncodable("FAILED")],
                  timestamp: Self.eventTimestamp1)
        ]
    }

    // MARK: - http request performed

    func testTracksHttpRequestPerformedWithExpectedParameters() async {
        await self.tracker.trackHttpRequestPerformed(endpointName: "mock_endpoint",
                                                     responseTime: 50,
                                                     wasSuccessful: true,
                                                     responseCode: 200,
                                                     resultOrigin: .cache,
                                                     verificationResult: .verified)
        let entries = await self.handler.getEntries()
        expect(entries) == [
            .init(eventType: .httpRequestPerformed,
                  properties: [
                    .endpointNameKey: AnyEncodable("mock_endpoint"),
                    .responseTimeMillisKey: AnyEncodable(50000),
                    .successfulKey: AnyEncodable(true),
                    .responseCodeKey: AnyEncodable(200),
                    .eTagHitKey: AnyEncodable(true),
                    .verificationResultKey: AnyEncodable("VERIFIED")],
                  timestamp: Self.eventTimestamp1)
        ]
    }

    // MARK: - empty diagnostics file when too big

    func testTrackingEventClearsDiagnosticsFileIfTooBig() async throws {
        for _ in 0...8000 {
            await self.handler.appendEvent(diagnosticsEvent: .init(eventType: .httpRequestPerformed,
                                                                   properties: [:],
                                                                   timestamp: Date()))
        }

        let entries = await self.handler.getEntries()
        expect(entries.count) == 8001

        let event = DiagnosticsEvent(eventType: .httpRequestPerformed,
                                     properties: [.verificationResultKey: AnyEncodable("FAILED")],
                                     timestamp: Self.eventTimestamp2)

        await self.tracker.track(event)

        let entries2 = await self.handler.getEntries()
        expect(entries2.count) == 2
        expect(entries2) == [
            .init(eventType: .maxEventsStoredLimitReached,
                  properties: [:],
                  timestamp: Self.eventTimestamp1),
            .init(eventType: .httpRequestPerformed,
                  properties: [.verificationResultKey: AnyEncodable("FAILED")],
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
