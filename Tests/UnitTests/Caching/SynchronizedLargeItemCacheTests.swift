//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SynchronizedLargeItemCacheTests.swift
//
//  Created by Jacob Zivan Rakidzich on 10/10/25.

@testable import RevenueCat
import XCTest

@MainActor
class SynchronizedLargeItemCacheTests: TestCase {
    let baseDirectory = URL(string: "data:mock-dir").unsafelyUnwrapped

    func testSetPersistsDataToCacheDirectory() throws {
        let (mock, sut) = self.makeSystemUnderTest()
        let key = "test-key"
        let value = TestValue(identifier: "abc", count: 42)

        mock
            .stubSaveData(
                with: .success(
                    .init(
                        data: value.asData,
                        url: baseDirectory.appendingPathExtension(key)
                    )
                )
            )

        let didStore = sut.set(codable: value, forKey: key)

        XCTAssertTrue(didStore)
        XCTAssertEqual(mock.saveDataInvocations.count, 1)
    }

    func testValueReturnsDecodedData() throws {
        let (mock, sut) = self.makeSystemUnderTest()
        let key = "value-key"
        let value = TestValue(identifier: "value", count: 7)

        mock.stubLoadFile(with: .success(value.asData))

        let cached: TestValue? = sut.value(forKey: key)

        XCTAssertEqual(cached, value)
    }

    func testValueReturnsNilWhenErrorIsReturned() {
        let (mock, sut) = self.makeSystemUnderTest()
        let key = "missing-key"

        mock.stubLoadFile(with: .failure(MockError()))

        let cached: TestValue? = sut.value(forKey: key)

        XCTAssertNil(cached)
    }

    func testRemoveObjectDeletesStoredFile() throws {
        let (mock, sut) = self.makeSystemUnderTest()
        let key = "remove-key"

        sut.removeObject(forKey: key)

        XCTAssertEqual(mock.removeInvocations.count, 1)
    }

    func testClearRemovesEntireCacheDirectory() throws {
        let (mock, sut) = self.makeSystemUnderTest()

        sut.clear()

        XCTAssertEqual(mock.removeInvocations.count, 1)
        XCTAssertEqual(mock.removeInvocations[0], mock.workingCacheDirectory)
    }

    func testSetReturnsFalseWhenCacheWriteFails() throws {
        let (mock, sut) = self.makeSystemUnderTest()
        let key = "fail-key"
        let value = TestValue(identifier: "test", count: 1)

        mock.stubSaveData(with: .failure(MockError()))

        let didStore = sut.set(codable: value, forKey: key)

        XCTAssertFalse(didStore)
    }

    func testValueReturnsNilWhenDecodingFails() throws {
        let (mock, sut) = self.makeSystemUnderTest()
        let key = "bad-data-key"

        // Return invalid JSON data that can't be decoded to TestValue
        mock.stubLoadFile(with: .success(Data("invalid json".utf8)))

        let cached: TestValue? = sut.value(forKey: key)

        XCTAssertNil(cached)
    }

    // MARK: - Old directory deletion

    func testClearDeletesOldDirectoryFromDocumentsForRemoveStrategy() throws {
        let fileManager = FileManager.default

        // Create old directory in documents
        let documentsURL = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        let basePath = "TestCacheDirectory-ClearRemove-\(UUID().uuidString)"
        let oldDirectory = documentsURL.appendingPathComponent(basePath)
        let testFile = oldDirectory.appendingPathComponent("test-file")

        // Initialize SynchronizedLargeItemCache with .remove strategy
        // This will delete the old directory on init, so we need to recreate it after
        let sut = SynchronizedLargeItemCache(
            cache: fileManager,
            basePath: basePath,
            documentsDirectoryMigrationStrategy: .remove(oldBasePath: basePath)
        )

        // Recreate the old directory to test that clear() deletes it
        try fileManager.createDirectory(
            at: oldDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        // Create a test file
        try "test content".write(to: testFile, atomically: true, encoding: .utf8)

        // Verify old directory exists
        XCTAssertTrue(fileManager.fileExists(atPath: oldDirectory.path))

        // Clear the cache
        sut.clear()

        // Verify old directory is deleted after clear
        XCTAssertFalse(fileManager.fileExists(atPath: oldDirectory.path))
    }

    func testClearDeletesOldDirectoryFromDocumentsForMigrateStrategy() throws {
        let fileManager = FileManager.default

        // Create old directory in documents
        let documentsURL = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        let basePath = "TestCacheDirectory-ClearMigrate-\(UUID().uuidString)"
        let oldDirectory = documentsURL.appendingPathComponent(basePath)
        let testFile = oldDirectory.appendingPathComponent("test-file")

        // Create directory structure
        try fileManager.createDirectory(
            at: oldDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        // Create a test file
        try "test content".write(to: testFile, atomically: true, encoding: .utf8)

        // Verify old directory exists
        XCTAssertTrue(fileManager.fileExists(atPath: oldDirectory.path))

        // Initialize SynchronizedLargeItemCache with .migrate strategy
        let sut = SynchronizedLargeItemCache(
            cache: fileManager,
            basePath: basePath,
            documentsDirectoryMigrationStrategy: .migrate(oldBasePath: basePath)
        )

        // Verify old directory still exists (not deleted on init for .migrate strategy)
        XCTAssertTrue(fileManager.fileExists(atPath: oldDirectory.path))

        // Clear the cache
        sut.clear()

        // Verify old directory is deleted after clear
        XCTAssertFalse(fileManager.fileExists(atPath: oldDirectory.path))
    }

    func testDeletesOldDirectoryFromDocumentsOnInitialization() throws {

        // Needs a real file manager in order to test the old file being removed from documents.
        // Since the cache no longer works with the documents directory
        let fileManager = FileManager.default

        // Create old directory in documents
        let documentsURL = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        let basePath = "TestCacheDirectory-\(UUID().uuidString)"
        let oldDirectory = documentsURL.appendingPathComponent(basePath)
        let testFile = oldDirectory.appendingPathComponent("test-file")

        // Create directory structure
        try fileManager.createDirectory(
            at: oldDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        // Create a test file
        try "test content".write(to: testFile, atomically: true, encoding: .utf8)

        // Verify old directory exists
        XCTAssertTrue(fileManager.fileExists(atPath: oldDirectory.path))

        // Initialize SynchronizedLargeItemCache (deletion is deferred to first access)
        let sut = SynchronizedLargeItemCache(
            cache: fileManager,
            basePath: basePath,
            documentsDirectoryMigrationStrategy: .remove(oldBasePath: basePath)
        )

        // Verify old directory still exists after init (deletion is lazy)
        XCTAssertTrue(fileManager.fileExists(atPath: oldDirectory.path))

        // Trigger first access to cause lazy deletion
        let _: String? = sut.value(forKey: "dummy-key")

        // Verify old directory is deleted after first access
        XCTAssertFalse(fileManager.fileExists(atPath: oldDirectory.path))

        // Verify new cache directory is used
        let newCacheDirectory = try XCTUnwrap(DirectoryHelper.baseUrl(for: .cache)?.appendingPathComponent(basePath))

        XCTAssertTrue(fileManager.fileExists(atPath: newCacheDirectory.path))
    }

    // MARK: - Helpers

    private func makeSystemUnderTest(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (MockSimpleCache, SynchronizedLargeItemCache) {

        let cache = createAndTrackForMemoryLeak(
            file: file,
            line: line,
            MockSimpleCache(cacheDirectory: baseDirectory)
        )

        let basePath = "SynchronizedLargeItemCacheTests-\(UUID().uuidString)"
        let sut = createAndTrackForMemoryLeak(
            file: file,
            line: line,
            SynchronizedLargeItemCache(cache: cache, basePath: basePath)
        )

        return (cache, sut)
    }

}

// MARK: - Test helpers

private struct TestValue: Codable, Equatable {
    var identifier: String
    var count: Int

    var asData: Data {
        // swiftlint:disable:next force_try
        try! JSONEncoder.default.encode(self)
    }
}

private struct MockError: Error { }
