//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DiagnosticsFileHandlerTests.swift
//
//  Created by Cesar de la Vega on 2/4/24.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

private actor MockDiagnosticsFileHandlerDelegate: DiagnosticsFileHandlerDelegate {
    private(set) var onFileSizeIncreasedBeyondAutomaticSyncLimitCallCount = 0

    func onFileSizeIncreasedBeyondAutomaticSyncLimit() async {
        onFileSizeIncreasedBeyondAutomaticSyncLimitCallCount += 1
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class DiagnosticsFileHandlerTests: TestCase {

    fileprivate var fileHandler: FileHandler!
    fileprivate var handler: DiagnosticsFileHandlerType!

    override func setUp() async throws {
        try await super.setUp()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.fileHandler = try Self.createWithTemporaryFile()
        self.handler = DiagnosticsFileHandler(self.fileHandler)
    }

    override func tearDown() async throws {
        self.handler = nil

        try await super.tearDown()
    }

    // MARK: - append

    func testAppendEventWithProperties() async throws {
        let content = DiagnosticsEvent(name: .customerInfoVerificationResult,
                                       properties: DiagnosticsEvent.Properties(verificationResult: "FAILED"),
                                       timestamp: Date(),
                                       appSessionId: UUID())

        var entries = await self.handler.getEntries()
        expect(entries.count).to(equal(0))

        await self.handler.appendEvent(diagnosticsEvent: content)

        entries = await self.handler.getEntries()
        let encodedContent = try content.encodeAndDecode()
        expect(entries.count).to(equal(1))
        expect(entries[0]).to(equal(encodedContent))
    }

    // MARK: - cleanSentDiagnostics

    func testCleanSentDiagnostics() async throws {
        await self.handler.appendEvent(diagnosticsEvent: Self.sampleEvent())
        await self.handler.appendEvent(diagnosticsEvent: Self.sampleEvent())
        await self.handler.appendEvent(diagnosticsEvent: Self.sampleEvent())
        await self.handler.appendEvent(diagnosticsEvent: Self.sampleEvent())

        var entries = await self.handler.getEntries()
        expect(entries.count).to(equal(4))

        await self.handler.cleanSentDiagnostics(diagnosticsSentCount: 2)
        entries = await self.handler.getEntries()
        expect(entries.count).to(equal(2))

        await self.handler.cleanSentDiagnostics(diagnosticsSentCount: 2)
        entries = await self.handler.getEntries()
        expect(entries.count).to(equal(0))
    }

    // MARK: - getEntries

    func testGetEntries() async throws {
        try await self.fileHandler.append(line: Self.line1)
        try await self.fileHandler.append(line: Self.line2)

        let content1 = DiagnosticsEvent(id: UUID(uuidString: "8FDEAD13-A05B-4236-84CF-36BCDD36A7BC")!,
                                        name: .customerInfoVerificationResult,
                                        properties: DiagnosticsEvent.Properties(verificationResult: "FAILED"),
                                        timestamp: Date(millisecondsSince1970: 1712235359000),
                                        appSessionId: UUID(uuidString: "4FAF3FE9-F239-4CC1-BB07-C3320BA40BCF")!)

        let content2 = DiagnosticsEvent(id: UUID(uuidString: "FD06888D-DEA6-43C5-A36A-A1E06F2D6A42")!,
                                        name: .customerInfoVerificationResult,
                                        properties: DiagnosticsEvent.Properties(verificationResult: "FAILED"),
                                        timestamp: Date(millisecondsSince1970: 1712238959000),
                                        appSessionId: UUID(uuidString: "4FAF3FE9-F239-4CC1-BB07-C3320BA40BCF")!)

        let entries = await self.handler.getEntries()
        expect(entries[0]).to(equal(content1))
        expect(entries[1]).to(equal(content2))
    }

    // MARK: - emptyFile

    func testEmptyFile() async throws {
        try await self.fileHandler.append(line: Self.line1)
        try await self.fileHandler.append(line: Self.line2)

        var data = try await self.fileHandler.readFile()
        expect(data).toNot(beEmpty())

        await self.handler.emptyDiagnosticsFile()

        data = try await self.fileHandler.readFile()
        expect(data).to(beEmpty())
    }

    // MARK: - isDiagnosticsFileTooBig

    func testDiagnosticsFileIsNotTooBigIfEmpty() async {
        let entries = await self.handler.getEntries()
        expect(entries).to(beEmpty())

        let result = await self.handler.isDiagnosticsFileTooBig()
        expect(result).to(beFalse())
    }

    func testDiagnosticsFileIsNotTooBigWithAFewEvents() async throws {
        await self.handler.appendEvent(diagnosticsEvent: Self.sampleEvent())
        await self.handler.appendEvent(diagnosticsEvent: Self.sampleEvent())

        let data = try await self.fileHandler.readFile()
        expect(data).toNot(beEmpty())

        let result = await self.handler.isDiagnosticsFileTooBig()
        expect(result).to(beFalse())
    }

    func testDiagnosticsFileIsTooBigWithALotOfEvents() async throws {
        for iterator in 0...8000 {
            let line = """
            {
              "properties": {"verification_result": "FAILED"},
              "timestamp": "2024-04-04T12:55:59Z",
              "name": "http_request_performed",
              "version": \(iterator)
            }
            """.trimmingWhitespacesAndNewLines
            try await self.fileHandler.append(line: line)
        }

        let data = try await self.fileHandler.readFile()
        expect(data.compactMap { $0 }).toNot(beEmpty())

        let result = await self.handler.isDiagnosticsFileTooBig()
        expect(result).to(beTrue())
    }

    func testFileHandlerDelegateSizeToAutomaticSyncIsCalledIfFileBigEnough() async throws {
        let delegate = MockDiagnosticsFileHandlerDelegate()

        await self.handler.updateDelegate(delegate)

        for iterator in 0...8000 {
            let line = """
            {
              "properties": {"verification_result": "FAILED"},
              "timestamp": "2024-04-04T12:55:59Z",
              "name": "http_request_performed",
              "version": \(iterator)
            }
            """.trimmingWhitespacesAndNewLines
            try await self.fileHandler.append(line: line)
        }

        let data = try await self.fileHandler.readFile()
        expect(data.compactMap { $0 }).toNot(beEmpty())

        var count = await delegate.onFileSizeIncreasedBeyondAutomaticSyncLimitCallCount
        expect(count) == 0

        let event = Self.sampleEvent()

        await self.handler.appendEvent(diagnosticsEvent: event)

        count = await delegate.onFileSizeIncreasedBeyondAutomaticSyncLimitCallCount
        expect(count) == 1

        await self.handler.appendEvent(diagnosticsEvent: event)
        await self.handler.appendEvent(diagnosticsEvent: event)

        count = await delegate.onFileSizeIncreasedBeyondAutomaticSyncLimitCallCount
        expect(count) == 3
    }

    func testFileHandlerDelegateSizeToAutomaticSyncIsNotCalledIfFileNotBigEnough() async throws {
        let delegate = MockDiagnosticsFileHandlerDelegate()

        await self.handler.updateDelegate(delegate)

        let event = Self.sampleEvent()

        await self.handler.appendEvent(diagnosticsEvent: event)
        await self.handler.appendEvent(diagnosticsEvent: event)
        await self.handler.appendEvent(diagnosticsEvent: event)
        await self.handler.appendEvent(diagnosticsEvent: event)

        let count = await delegate.onFileSizeIncreasedBeyondAutomaticSyncLimitCallCount
        expect(count) == 0
    }

    // MARK: - Invalid entries

    func testGetEntriesWithInvalidLine() async throws {
        try await self.fileHandler.append(line: Self.invalidEntryLine)
        try await self.fileHandler.append(line: Self.line1)
        try await self.fileHandler.append(line: Self.line2)

        let content1 = DiagnosticsEvent(id: UUID(uuidString: "8FDEAD13-A05B-4236-84CF-36BCDD36A7BC")!,
                                        name: .customerInfoVerificationResult,
                                        properties: DiagnosticsEvent.Properties(verificationResult: "FAILED"),
                                        timestamp: Date(millisecondsSince1970: 1712235359000),
                                        appSessionId: UUID(uuidString: "4FAF3FE9-F239-4CC1-BB07-C3320BA40BCF")!)

        let content2 = DiagnosticsEvent(id: UUID(uuidString: "FD06888D-DEA6-43C5-A36A-A1E06F2D6A42")!,
                                        name: .customerInfoVerificationResult,
                                        properties: DiagnosticsEvent.Properties(verificationResult: "FAILED"),
                                        timestamp: Date(millisecondsSince1970: 1712238959000),
                                        appSessionId: UUID(uuidString: "4FAF3FE9-F239-4CC1-BB07-C3320BA40BCF")!)

        let entries = await self.handler.getEntries()
        expect(entries[0]).to(beNil())
        expect(entries[1]).to(equal(content1))
        expect(entries[2]).to(equal(content2))
    }

    // MARK: - FileHandler throwing errors

    func testAppendEventWhenFileManagerAppendLineThrowsError() async throws {
        struct FakeError: Error {}

        let fileHandler = MockFileHandler()
        await fileHandler.setAppendLineError(FakeError())

        self.handler = DiagnosticsFileHandler(fileHandler)

        await self.handler.appendEvent(diagnosticsEvent: Self.sampleEvent())

        expect(self.logger.messages).to(containElementSatisfying {
            $0.message.contains("Failed to store diagnostics event: ")
        })
    }

    // MARK: - Old file deletion

    func testDeletesOldDiagnosticsFileFromDocumentsDirectory() throws {
        // Create old diagnostics file in documents directory
        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        let comRevenueCatFolder = documentsURL.appendingPathComponent("com.revenuecat")
        let oldDiagnosticsFile = comRevenueCatFolder
            .appendingPathComponent("diagnostics")
            .appendingPathExtension("jsonl")

        // Create directory structure
        try FileManager.default.createDirectory(
            at: oldDiagnosticsFile.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )

        // Create the old file
        try "test content".write(to: oldDiagnosticsFile, atomically: true, encoding: .utf8)

        // Verify file and folder exist
        expect(FileManager.default.fileExists(atPath: oldDiagnosticsFile.path)).to(beTrue())
        expect(FileManager.default.fileExists(atPath: comRevenueCatFolder.path)).to(beTrue())

        // Initialize DiagnosticsFileHandler (should delete old file and folder)
        let handler = DiagnosticsFileHandler()
        expect(handler).toNot(beNil())

        // Verify old file is deleted
        expect(FileManager.default.fileExists(atPath: oldDiagnosticsFile.path)).to(beFalse())

        // Verify containing folder is also deleted
        expect(FileManager.default.fileExists(atPath: comRevenueCatFolder.path)).to(beFalse())

        // Verify new file is created
        let persistenceDirectoryURL = try XCTUnwrap(DirectoryHelper.baseUrl(for: .persistence))

        let newDiagnosticsFileURL = persistenceDirectoryURL
            .appendingPathComponent("diagnostics", isDirectory: true)
            .appendingPathComponent("diagnostics")
            .appendingPathExtension("jsonl")

        expect(FileManager.default.fileExists(atPath: newDiagnosticsFileURL.path)).to(beTrue())
    }

}

// MARK: - Private

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension DiagnosticsFileHandlerTests {

    static let invalidEntryLine = "This is an invalid diagnostics event entry"

    static let line1 = """
    {
      "id": "8FDEAD13-A05B-4236-84CF-36BCDD36A7BC",
      "properties": {"verification_result": "FAILED"},
      "timestamp": "2024-04-04T12:55:59Z",
      "name": "customer_info_verification_result",
      "version": 1,
      "app_session_id": "4FAF3FE9-F239-4CC1-BB07-C3320BA40BCF"
    }
    """.trimmingWhitespacesAndNewLines

    static let line2 = """
    {
      "id": "FD06888D-DEA6-43C5-A36A-A1E06F2D6A42",
      "properties": {"verification_result": "FAILED"},
      "timestamp": "2024-04-04T13:55:59Z",
      "name": "customer_info_verification_result",
      "version": 1,
      "app_session_id": "4FAF3FE9-F239-4CC1-BB07-C3320BA40BCF"
    }
    """.trimmingWhitespacesAndNewLines

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

    static func sampleEvent() -> DiagnosticsEvent {
        return DiagnosticsEvent(name: .httpRequestPerformed,
                                properties: DiagnosticsEvent.Properties(verificationResult: "FAILED"),
                                timestamp: Date(),
                                appSessionId: UUID())
    }

}

private extension String {

    var trimmingWhitespacesAndNewLines: String {
        return self.replacingOccurrences(of: "[\\s\\n]+", with: "", options: .regularExpression, range: nil)
    }

}
