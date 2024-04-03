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

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
class BaseDiagnosticsFileHandlerTests: TestCase {

    fileprivate var fileHandler: FileHandler!
    fileprivate var handler: DiagnosticsFileHandler!

    override func setUp() async throws {
        try await super.setUp()

        try AvailabilityChecks.iOS13APIAvailableOrSkipTest()

        self.fileHandler = try Self.createWithTemporaryFile()
        self.handler = .init(self.fileHandler)
    }

    override func tearDown() async throws {
        self.handler = nil

        try await super.tearDown()
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
class DiagnosticsFileHandlerTests: BaseDiagnosticsFileHandlerTests {

    // MARK: - append

    func testAppendEvent() async throws {
        let content = DiagnosticsEvent(name: "HTTP_REQUEST_PERFORMED",
                                       properties: ["key": AnyEncodable("value")],
                                       timestamp: Date())

        await self.handler.appendEvent(diagnosticsEvent: content)

        let entries = await self.handler.getEntries()
        expect(entries[0]).to(equal(content))
    }

}

// MARK: - Private

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
private extension BaseDiagnosticsFileHandlerTests {

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

    static func sampleLine() -> String {
        return UUID().uuidString
    }

}
