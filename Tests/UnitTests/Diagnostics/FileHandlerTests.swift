//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FileHandlerTests.swift
//
//  Created by Nacho Soto on 6/16/23.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

class BaseFileHandlerTests: TestCase {

    fileprivate var handler: FileHandler!

    override func setUp() async throws {
        try await super.setUp()

        self.handler = try Self.createWithTemporaryFile()
    }

    override func tearDown() async throws {
        self.handler = nil

        try await super.tearDown()
    }

}

class FileHandlerTests: BaseFileHandlerTests {

    // MARK: - readFile

    func testReadingEmptyFile() async throws {
        let data = try await self.handler.readFile()
        expect(data).to(beEmpty())
    }

    // MARK: - append

    func testAppendOneLine() async throws {
        let content = Self.sampleLine()

        await self.handler.append(line: content)

        let data = try await self.handler.readFile()
        expect(data).to(matchLines(content))
    }

    func testAppendMultipleLines() async throws {
        let line1 = Self.sampleLine()
        let line2 = Self.sampleLine()

        await self.handler.append(line: line1)
        await self.handler.append(line: line2)

        let data = try await self.handler.readFile()
        expect(data).to(matchLines(line1, line2))
    }

    func testAppendsToExistingContent() async throws {
        let line1 = Self.sampleLine()
        let line2 = Self.sampleLine()

        await self.handler.append(line: line1)

        // Re-create handler to ensure lines are appended
        try await self.reCreateHandler()

        await self.handler.append(line: line2)

        let data = try await self.handler.readFile()
        expect(data).to(matchLines(line1, line2))
    }

    // MARK: - emptyFile

    func testEmptyFileWhenEmpty() async throws {
        try await self.handler.emptyFile()

        let data = try await self.handler.readFile()
        expect(data).to(beEmpty())
    }

    func testEmptyFile() async throws {
        await self.handler.append(line: Self.sampleLine())

        try await self.handler.emptyFile()

        let data = try await self.handler.readFile()
        expect(data).to(beEmpty())
    }

    func testEmptyFileSavesContent() async throws {
        await self.handler.append(line: Self.sampleLine())
        try await self.handler.emptyFile()

        try await self.reCreateHandler()

        let data = try await self.handler.readFile()
        expect(data).to(beEmpty())
    }

    // MARK: - removeFirstLines

    func testRemoveOneLineFromEmptyFile() async throws {
        try await self.handler.removeFirstLines(1)

        let data = try await self.handler.readFile()
        expect(data).to(beEmpty())
    }

    func testRemoveSingleLine() async throws {
        await self.handler.append(line: Self.sampleLine())
        try await self.handler.removeFirstLines(1)

        let data = try await self.handler.readFile()
        expect(data).to(beEmpty())
    }

    func testRemoveOneLine() async throws {
        let line1 = "line 1"
        let line2 = "line 2"

        await self.handler.append(line: line1)
        await self.handler.append(line: line2)
        try await self.handler.removeFirstLines(1)

        let data = try await self.handler.readFile()
        expect(data).to(matchLines(line2))
    }

    func testRemoveMultipleLines() async throws {
        let lines = (0..<10).map { "Line-\($0 + 1)" }
        let linesToRemove = 4

        for line in lines {
            await self.handler.append(line: line)
        }

        try await self.handler.removeFirstLines(linesToRemove)

        let data = try await self.handler.readFile()
        expect(data).to(matchLines(lines.suffix(lines.count - linesToRemove)))
    }

    func testRemoveMultipleLinesOnLongFile() async throws {
        let lines = (0..<10000).map { "Line-\($0 + 1)" }
        let linesToRemove = lines.count / 3

        // This is faster than calling `append(line:)` 10,000 times
        await self.handler.append(line: lines.joined(separator: "\n"))

        try await self.handler.removeFirstLines(linesToRemove)

        let data = try await self.handler.readFile()
        expect(data).to(matchLines(lines.suffix(lines.count - linesToRemove)))
    }

    func testRemoveAllLines() async throws {
        let count = 6

        for _ in 0..<6 {
            await self.handler.append(line: Self.sampleLine())
        }

        try await self.handler.removeFirstLines(count)

        let data = try await self.handler.readFile()
        expect(data).to(beEmpty())
    }

    // MARK: - fileSizeInKB

    func testFileSizeInKBForEmptyFile() async throws {
        let result = try await self.handler.fileSizeInKB()
        expect(result) == 0
    }

    func testFileSizeInKBForFileWithSomeData() async throws {
        let content = Self.sampleLine()

        await self.handler.append(line: content)

        let result = try await self.handler.fileSizeInKB()
        expect(result) > 0
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class IOS15FileHandlerTests: BaseFileHandlerTests {

    override func setUp() async throws {
        try await super.setUp()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    func testReadLinesWithEmptyFile() async throws {
        let lines = try await self.handler.readLines().extractValues()
        expect(lines).to(beEmpty())
    }

    func testReadLinesWithOneLine() async throws {
        let line = Self.sampleLine()

        await self.handler.append(line: line)
        let lines = try await self.handler.readLines().extractValues()

        expect(lines) == [line]
    }

    func testReadLinesWithMultipleLine() async throws {
        let line1 = Self.sampleLine()
        let line2 = Self.sampleLine()

        await self.handler.append(line: line1)
        await self.handler.append(line: line2)

        let lines = try await self.handler.readLines().extractValues()
        expect(lines) == [line1, line2]
    }

    func testReadLinesWithExistingFile() async throws {
        let line = Self.sampleLine()
        await self.handler.append(line: line)

        try await self.reCreateHandler()

        let lines = try await self.handler.readLines().extractValues()
        expect(lines) == [line]
    }

}

// MARK: - Private

private extension BaseFileHandlerTests {

    func reCreateHandler() async throws {
        self.handler = try .init(await self.handler.url)
    }

    static func temporaryFileURL() -> URL {
        return FileManager.default
            .temporaryDirectory
            .appendingPathComponent("file_handler_tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: false)
            .appendingPathExtension("jsonl")
    }

    static func createWithTemporaryFile() throws -> FileHandler {
        return try .init(Self.temporaryFileURL())
    }

    static func sampleLine() -> String {
        return UUID().uuidString
    }

}

// MARK: - Matchers

private func matchLines(_ lines: String...) -> Nimble.Predicate<Data> {
    return matchLines(Array(lines))
}

private func matchLines(_ lines: [String]) -> Nimble.Predicate<Data> {
    return matchData(
        (lines + [""]) // For trailing line break
            .joined(separator: "\n")
            .asData
    )
}

private func matchData(_ expectedValue: Data) -> Nimble.Predicate<Data> {
    return Predicate.define { actualExpression, msg in
        guard let actualValue = try actualExpression.evaluate() else {
            return PredicateResult(
                status: .fail,
                message: msg.appendedBeNilHint()
            )
        }

        return PredicateResult(
            bool: expectedValue == actualValue,
            message: .expectedCustomValueTo(
                "equal '\(expectedValue.asUTF8String)'",
                actual: "'\(actualValue.asUTF8String)'"
            )
        )
    }
}

private extension Data {

    var asUTF8String: String {
        return .init(data: self, encoding: .utf8)!
            .replacingOccurrences(of: "\n", with: "<br>")
    }

}
