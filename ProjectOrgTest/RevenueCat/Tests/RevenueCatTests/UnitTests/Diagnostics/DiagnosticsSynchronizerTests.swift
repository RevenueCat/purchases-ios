//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DiagnosticsSynchronizerTests.swift
//
//  Created by Cesar de la Vega on 11/4/24.

import Foundation
import Nimble

@testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class DiagnosticsSynchronizerTests: TestCase {

    fileprivate var api: MockInternalAPI!
    fileprivate var fileHandler: FileHandler!
    fileprivate var handler: DiagnosticsFileHandler!
    fileprivate var synchronizer: DiagnosticsSynchronizer!
    fileprivate var userDefaults: MockUserDefaults!

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.api = .init()
        self.fileHandler = try Self.createWithTemporaryFile()
        self.handler = .init(self.fileHandler)
        self.userDefaults = .init()
        self.synchronizer = .init(internalAPI: self.api,
                                  handler: self.handler,
                                  userDefaults: .init(userDefaults: self.userDefaults))
    }

    // MARK: - syncDiagnosticsIfNeeded

    func testSyncEmptyEvents() async throws {
        try await self.synchronizer.syncDiagnosticsIfNeeded()

        expect(self.api.invokedPostPaywallEvents) == false
    }

    func testSyncOneEvent() async throws {
        let event = await self.storeEvent()

        try await self.synchronizer.syncDiagnosticsIfNeeded()

        expect(self.api.invokedPostDiagnosticsEvents) == true
        expect(self.api.invokedPostDiagnosticsEventsParameters) == [[
            event
        ]]

        await self.verifyEmptyStore()
    }

    func testSyncMultipleEvents() async throws {
        let event1 = await self.storeEvent()
        let event2 = await self.storeEvent(timestamp: Self.eventTimestamp2)

        try await self.synchronizer.syncDiagnosticsIfNeeded()

        expect(self.api.invokedPostDiagnosticsEvents) == true
        expect(self.api.invokedPostDiagnosticsEventsParameters) == [[ event1, event2 ]]

        await self.verifyEmptyStore()
    }

    func testSyncWithUnsuccessfulError() async throws {
        let event = await self.storeEvent()
        let expectedError: NetworkError = .offlineConnection()

        self.api.stubbedPostDiagnosticsEventsCompletionResult = .networkError(expectedError)
        do {
            _ = try await self.synchronizer.syncDiagnosticsIfNeeded()
            fail("Expected error")
        } catch BackendError.networkError(expectedError) {
            // Expected
        } catch {
            throw error
        }

        expect(self.api.invokedPostDiagnosticsEvents) == true
        expect(self.api.invokedPostDiagnosticsEventsParameters) == [[ event ]]

        await self.verifyEvents([event])
    }

    func testSyncWithSuccessfullySyncedError() async throws {
        _ = await self.storeEvent()
        _ = await self.storeEvent(timestamp: Self.eventTimestamp2)

        let expectedError: NetworkError = .errorResponse(.defaultResponse, .invalidRequest)

        self.api.stubbedPostDiagnosticsEventsCompletionResult = .networkError(expectedError)
        do {
            _ = try await self.synchronizer.syncDiagnosticsIfNeeded()
            fail("Expected error")
        } catch BackendError.networkError(.errorResponse) {
            // Expected
        } catch {
            throw error
        }

        expect(self.api.invokedPostDiagnosticsEvents) == true

        await self.verifyEmptyStore()
    }

    func testCannotSyncMultipleTimesInParallel() async throws {
        // The way this test is written does not work in iOS 15.
        // The second Task does not start until the first one is done.
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        _ = await self.storeEvent()
        _ = await self.storeEvent(timestamp: Self.eventTimestamp2)

        let syncer = self.synchronizer!
        async let sync1: () = await syncer.syncDiagnosticsIfNeeded()
        async let sync2: () = await syncer.syncDiagnosticsIfNeeded()

        let (result1: (), result2: ()) = try await (sync1, sync2)

        expect(self.api.invokedPostDiagnosticsEvents) == true

        self.logger.verifyMessageWasLogged(Strings.diagnostics.event_sync_already_in_progress,
                                           level: .debug,
                                           expectedCount: 1)
    }

    func testClearsDiagnosticsFileAndRetriesIfMaxRetriesReached() async throws {
        _ = await self.storeEvent()

        let cacheKey = "com.revenuecat.diagnostics.number_sync_retries"

        let expectedError: NetworkError = .errorResponse(.defaultResponse, .invalidRequest)

        self.api.stubbedPostDiagnosticsEventsCompletionResult = .networkError(expectedError)

        self.userDefaults.mockValues = [cacheKey: 3]

        do {
            try await self.synchronizer.syncDiagnosticsIfNeeded()

            fail("Should have errored")
        } catch {
            await self.verifyEmptyStore()
            expect(self.userDefaults.removeObjectForKeyCalledValues) == [cacheKey]
        }
    }

    func testMultipleErrorsEventuallyClearDiagnosticsFileAndRetriesIfMaxRetriesReached() async throws {
        let event = await self.storeEvent()

        let cacheKey = "com.revenuecat.diagnostics.number_sync_retries"

        let expectedError: NetworkError = .offlineConnection()

        self.api.stubbedPostDiagnosticsEventsCompletionResult = .networkError(expectedError)

        try? await self.synchronizer.syncDiagnosticsIfNeeded()
        try? await self.synchronizer.syncDiagnosticsIfNeeded()
        try? await self.synchronizer.syncDiagnosticsIfNeeded()
        await self.verifyEvents([event])

        expect(self.userDefaults.mockValues[cacheKey] as? Int) == 3

        try? await self.synchronizer.syncDiagnosticsIfNeeded()

        await self.verifyEmptyStore()
        expect(self.userDefaults.removeObjectForKeyCalledValues) == [cacheKey]
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension DiagnosticsSynchronizerTests {

    func storeEvent(timestamp: Date = eventTimestamp1) async -> DiagnosticsEvent {
        let event = DiagnosticsEvent(eventType: .httpRequestPerformed,
                                     properties: [.verificationResultKey: AnyEncodable("FAILED")],
                                     timestamp: timestamp)
        await self.handler.appendEvent(diagnosticsEvent: event)

        return event
    }

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

    func verifyEmptyStore(file: StaticString = #file, line: UInt = #line) async {
        let events = await self.handler.getEntries()
        expect(file: file, line: line, events).to(beEmpty())
    }

    func verifyEvents(
        _ expected: [DiagnosticsEvent],
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let events = await self.handler.getEntries()
        expect(file: file, line: line, events) == expected
    }
}
