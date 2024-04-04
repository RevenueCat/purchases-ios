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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class DiagnosticsFileHandlerTests: TestCase {

    fileprivate var fileHandler: FileHandler!
    fileprivate var handler: DiagnosticsFileHandler!

    override func setUp() async throws {
        try await super.setUp()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.fileHandler = try Self.createWithTemporaryFile()
        self.handler = .init(self.fileHandler)
    }

    override func tearDown() async throws {
        self.handler = nil

        try await super.tearDown()
    }

    // MARK: - append

    func testAppendEventWithProperties() async throws {
        let content = DiagnosticsEvent(name: "HTTP_REQUEST_PERFORMED",
                                       properties: ["key": AnyEncodable("value")],
                                       timestamp: Date())

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
        let line1 = """
        {
          "properties": {"key": "value"},
          "timestamp": "2024-04-04T12:55:59Z",
          "name": "HTTP_REQUEST_PERFORMED",
          "version": 1
        }
        """.trimmingWhitespacesAndNewLines
        let line2 = """
        {
          "properties": {"key": "value"},
          "timestamp": "2024-04-04T13:55:59Z",
          "name": "HTTP_REQUEST_PERFORMED",
          "version": 1
        }
        """.trimmingWhitespacesAndNewLines

        await self.fileHandler.append(line: line1)
        await self.fileHandler.append(line: line2)

        let content1 = DiagnosticsEvent(name: "HTTP_REQUEST_PERFORMED",
                                        properties: ["key": AnyEncodable("value")],
                                        timestamp: Date(millisecondsSince1970: 1712235359000))

        let content2 = DiagnosticsEvent(name: "HTTP_REQUEST_PERFORMED",
                                        properties: ["key": AnyEncodable("value")],
                                        timestamp: Date(millisecondsSince1970: 1712238959000))

        let entries = await self.handler.getEntries()
        expect(entries[0]).to(equal(content1))
        expect(entries[1]).to(equal(content2))
    }

    // MARK: - emptyFile

    func testEmptyFile() async throws {
        let line1 = """
        {
          "properties": {"key": "value"},
          "timestamp": "2024-04-04T12:55:59Z",
          "name": "HTTP_REQUEST_PERFORMED",
          "type": "event",
          "version": 1
        }
        """.trimmingWhitespacesAndNewLines
        let line2 = """
        {
          "properties": {"key": "value"},
          "timestamp": "2024-04-04T13:55:59Z",
          "name": "HTTP_REQUEST_PERFORMED",
          "type": "event",
          "version": 1
        }
        """.trimmingWhitespacesAndNewLines

        await self.fileHandler.append(line: line1)
        await self.fileHandler.append(line: line2)

        var data = try await self.fileHandler.readFile()
        expect(data).toNot(beEmpty())

        await self.handler.emptyDiagnosticsFile()

        data = try await self.fileHandler.readFile()
        expect(data).to(beEmpty())
    }

}

// MARK: - Private

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension DiagnosticsFileHandlerTests {

    func reCreateHandler() async throws {
        self.fileHandler = try FileHandler(await self.fileHandler.url)
        self.handler = .init(self.fileHandler)
    }

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
        return DiagnosticsEvent(name: "HTTP_REQUEST_PERFORMED",
                                properties: ["key": AnyEncodable("value")],
                                timestamp: Date())
    }

}

private extension String {

    var trimmingWhitespacesAndNewLines: String {
        return self.replacingOccurrences(of: "[\\s\\n]+", with: "", options: .regularExpression, range: nil)
    }

}
