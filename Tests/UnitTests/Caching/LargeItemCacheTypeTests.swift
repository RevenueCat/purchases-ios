//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LargeItemCacheTypeTests.swift
//
//  Created by Jacob Zivan Rakidzich on 10/6/25.

import Nimble
@_spi(Internal) @testable import RevenueCat
import XCTest

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
final class LargeItemCacheTypeTests: TestCase {

    private var fileManager = FileManager.default
    private lazy var testDirectory = fileManager
        .urls(for: .cachesDirectory, in: .userDomainMask).first?
        .appendingPathExtension(#filePath) ?? fileManager.temporaryDirectory

    // MARK: - saveData Tests

    func testSaveDataWritesDataToFile() async throws {
        let testData = "Hello, World!"
        let url = self.testDirectory.appendingPathComponent("test.txt")
        let stream = createAsyncStream(from: testData)

        try await self.fileManager.saveData(stream, to: url, checksum: nil)

        let savedData = try Data(contentsOf: url)
        let savedString = String(data: savedData, encoding: .utf8)

        expect(savedString) == testData
        try fileManager.removeItem(at: url)
    }

    func testSaveDataCreatesParentDirectoryIfNeeded() throws {
        let nonExistentSubdir = UUID().uuidString
        let url = self.testDirectory
            .appendingPathComponent(nonExistentSubdir)
            .appendingPathComponent("nested_file.txt")
        let testData = Data("test content".utf8)

        // Ensure the directory doesn't exist
        expect(self.fileManager.fileExists(atPath: url.deletingLastPathComponent().path)) == false

        try self.fileManager.saveData(testData, to: url)

        let savedData = try Data(contentsOf: url)
        expect(savedData) == testData

        // Cleanup
        try fileManager.removeItem(at: self.testDirectory.appendingPathComponent(nonExistentSubdir))
    }

    func testSaveDataAsyncCreatesParentDirectoryIfNeeded() async throws {
        let nonExistentSubdir = UUID().uuidString
        let url = self.testDirectory
            .appendingPathComponent(nonExistentSubdir)
            .appendingPathComponent("nested_async_file.txt")
        let testData = "async test content"
        let stream = createAsyncStream(from: testData)

        // Ensure the directory doesn't exist
        expect(self.fileManager.fileExists(atPath: url.deletingLastPathComponent().path)) == false

        try await self.fileManager.saveData(stream, to: url, checksum: nil)

        let savedData = try Data(contentsOf: url)
        let savedString = String(data: savedData, encoding: .utf8)
        expect(savedString) == testData

        // Cleanup
        try fileManager.removeItem(at: self.testDirectory.appendingPathComponent(nonExistentSubdir))
    }

    func testSaveDataWithValidChecksumSucceeds() async throws {
        let testData = "Test data for checksum"
        let data = Data(testData.utf8)
        let checksum = Checksum.generate(from: data, with: .sha256)
        let url = self.testDirectory.appendingPathComponent("checksum_test.txt")
        let stream = createAsyncStream(from: testData)

        try await self.fileManager.saveData(stream, to: url, checksum: checksum)

        let savedData = try Data(contentsOf: url)
        expect(savedData) == data
        try fileManager.removeItem(at: url)
    }

    func testSaveDataWithInvalidChecksumThrows() async throws {
        let testData = "Test data"
        let wrongChecksum = Checksum.generate(from: Data("Different data".utf8), with: .sha256)
        let url = self.testDirectory.appendingPathComponent("invalid_checksum.txt")
        let stream = createAsyncStream(from: testData)

        do {
            try await self.fileManager.saveData(stream, to: url, checksum: wrongChecksum)
            XCTFail("Expected checksum validation to fail")
        } catch {
            expect(error).to(beAKindOf(Checksum.ChecksumValidationFailure.self))
        }

        // Verify the file was not saved to the final location
        expect(self.fileManager.fileExists(atPath: url.path)) == false
    }

    func testSaveDataWithLargeDataSucceeds() async throws {
        // Create data larger than the buffer size (256KB)
        let largeData = String(repeating: "A", count: 500_000)
        let url = self.testDirectory.appendingPathComponent("large_file.txt")
        let stream = createAsyncStream(from: largeData)

        try await self.fileManager.saveData(stream, to: url, checksum: nil)

        let savedData = try Data(contentsOf: url)
        let savedString = String(data: savedData, encoding: .utf8)

        expect(savedString) == largeData
        expect(savedData.count) == 500_000
        try fileManager.removeItem(at: url)

    }

    func testSaveDataWithMultipleChunksWritesCorrectly() async throws {
        let testData = String(repeating: "X", count: 1_000_000) // 1MB
        let url = self.testDirectory.appendingPathComponent("chunked_file.txt")
        let stream = createAsyncStream(from: testData)
        let checksum = Checksum.generate(from: testData.asData, with: .sha256)
        try await self.fileManager.saveData(stream, to: url, checksum: checksum)

        let savedData = try Data(contentsOf: url)
        expect(savedData.count) == 1_000_000
        try fileManager.removeItem(at: url)

    }

    func testSaveDataWithChecksumAlgorithmsSucceeds() async throws {
        let testData = "Algorithm test"
        let data = Data(testData.utf8)
        let algorithms: [Checksum.Algorithm] = [.sha256, .sha384, .sha512, .md5]

        for algorithm in algorithms {
            let checksum = Checksum.generate(from: data, with: algorithm)
            let url = self.testDirectory.appendingPathComponent("checksum_\(algorithm.rawValue).txt")
            let stream = createAsyncStream(from: testData)

            try await self.fileManager.saveData(stream, to: url, checksum: checksum)

            let savedData = try Data(contentsOf: url)
            expect(savedData) == data
            try fileManager.removeItem(at: url)

        }
    }

    // MARK: - cachedContentExists Tests

    func testCachedContentExistsReturnsTrueForExistingFile() throws {
        let url = self.testDirectory.appendingPathComponent("existing.txt")
        let testData = "Existing content"
        try testData.write(to: url, atomically: true, encoding: .utf8)

        let exists = self.fileManager.cachedContentExists(at: url)

        expect(exists) == true
        try fileManager.removeItem(at: url)

    }

    func testCachedContentExistsReturnsFalseForNonExistentFile() {
        let url = self.testDirectory.appendingPathComponent("nonexistent.txt")

        let exists = self.fileManager.cachedContentExists(at: url)

        expect(exists) == false
    }

    func testCachedContentExistsReturnsFalseForEmptyFile() throws {
        let url = self.testDirectory.appendingPathComponent("empty.txt")
        try Data().write(to: url)

        let exists = self.fileManager.cachedContentExists(at: url)

        expect(exists) == false
        try fileManager.removeItem(at: url)

    }

    func testCachedContentExistsReturnsTrueForNonEmptyFile() throws {
        let url = self.testDirectory.appendingPathComponent("nonempty.txt")
        try "A".write(to: url, atomically: true, encoding: .utf8)

        let exists = self.fileManager.cachedContentExists(at: url)

        expect(exists) == true
        try fileManager.removeItem(at: url)

    }

    // MARK: - loadFile Tests

    func testLoadFileReturnsCorrectData() throws {
        let url = self.testDirectory.appendingPathComponent("load_test.txt")
        let testData = "Data to load"
        try testData.write(to: url, atomically: true, encoding: .utf8)

        let loadedData = try self.fileManager.loadFile(at: url)
        let loadedString = String(data: loadedData, encoding: .utf8)

        expect(loadedString) == testData
        try fileManager.removeItem(at: url)

    }

    func testLoadFileThrowsForNonExistentFile() {
        let url = self.testDirectory.appendingPathComponent("missing.txt")

        expect {
            try self.fileManager.loadFile(at: url)
        }.to(throwError())
    }

    func testLoadFileReturnsEmptyDataForEmptyFile() throws {
        let url = self.testDirectory.appendingPathComponent("empty_load.txt")
        try Data().write(to: url)

        let loadedData = try self.fileManager.loadFile(at: url)

        expect(loadedData.isEmpty) == true
        try fileManager.removeItem(at: url)

    }

    // MARK: - createCacheDirectoryIfNeeded Tests

    func testCreateCacheDirectoryIfNeededCreatesDirectory() {
        let basePath = "TestCache/Subdirectory"

        let createdURL = self.fileManager.createCacheDirectoryIfNeeded(basePath: basePath)

        expect(createdURL).toNot(beNil())
        if let url = createdURL {
            var isDirectory: ObjCBool = false
            let exists = self.fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
            expect(exists) == true
            expect(isDirectory.boolValue) == true
        }

    }

    func testCreateCacheDirectoryIfNeededCreatesIntermediateDirectories() {
        let basePath = "TestCache/Level1/Level2/Level3"

        let createdURL = self.fileManager.createCacheDirectoryIfNeeded(basePath: basePath)

        expect(createdURL).toNot(beNil())
        if let url = createdURL {
            var isDirectory: ObjCBool = false
            let exists = self.fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
            expect(exists) == true
            expect(isDirectory.boolValue) == true
        }

    }

    func testCreateCacheDirectoryIfNeededDoesNotFailWhenDirectoryExists() throws {
        let basePath = "TestCache/\(UUID().uuidString)"

        let firstURL = self.fileManager.createCacheDirectoryIfNeeded(basePath: basePath)
        let secondURL = self.fileManager.createCacheDirectoryIfNeeded(basePath: basePath)

        expect(firstURL).toNot(beNil())
        expect(secondURL).toNot(beNil())
        expect(secondURL?.standardizedFileURL.path) == firstURL?.standardizedFileURL.path

        if let url = firstURL {
            var isDirectory: ObjCBool = false
            let exists = self.fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
            expect(exists) == true
            expect(isDirectory.boolValue) == true
            try self.fileManager.removeItem(at: url)
        }
    }

    // MARK: - Integration Tests

    func testSaveAndLoadRoundTrip() async throws {
        let testData = "Round trip test"
        let url = self.testDirectory.appendingPathComponent("roundtrip.txt")
        let stream = createAsyncStream(from: testData)

        try await self.fileManager.saveData(stream, to: url, checksum: nil)
        let loadedData = try self.fileManager.loadFile(at: url)
        let loadedString = String(data: loadedData, encoding: .utf8)

        expect(loadedString) == testData
        try fileManager.removeItem(at: url)

    }

    func testSaveDataThenCheckExists() async throws {
        let testData = "Existence test"
        let url = self.testDirectory.appendingPathComponent("exists_test.txt")
        let stream = createAsyncStream(from: testData)

        let existsBefore = self.fileManager.cachedContentExists(at: url)
        try await self.fileManager.saveData(stream, to: url, checksum: nil)
        let existsAfter = self.fileManager.cachedContentExists(at: url)

        expect(existsBefore) == false
        expect(existsAfter) == true
        try fileManager.removeItem(at: url)

    }

    func testSaveDataWithChecksumThenLoad() async throws {
        let testData = "Checksum round trip"
        let data = Data(testData.utf8)
        let checksum = Checksum.generate(from: data, with: .sha256)
        let url = self.testDirectory.appendingPathComponent("checksum_roundtrip.txt")
        let stream = createAsyncStream(from: testData)

        try await self.fileManager.saveData(stream, to: url, checksum: checksum)
        let loadedData = try self.fileManager.loadFile(at: url)

        expect(loadedData) == data

        // Verify checksum of loaded data
        let loadedChecksum = Checksum.generate(from: loadedData, with: .sha256)
        expect(loadedChecksum) == checksum
        try fileManager.removeItem(at: url)

    }

    // MARK: - Helper Methods

    private func createAsyncStream(from string: String) -> AsyncThrowingStream<UInt8, Error> {
        let data = Data(string.utf8)
        return AsyncThrowingStream { continuation in
            for byte in data {
                continuation.yield(byte)
            }
            continuation.finish()
        }
    }
}
