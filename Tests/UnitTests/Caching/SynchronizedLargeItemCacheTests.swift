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
