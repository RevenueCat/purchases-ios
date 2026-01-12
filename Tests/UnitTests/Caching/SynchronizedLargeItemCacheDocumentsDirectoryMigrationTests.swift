//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SynchronizedLargeItemCacheDocumentsDirectoryMigrationTests.swift
//
//  Created by Rick van der Linden on 09/01/2026.

import Nimble
@_spi(Internal) @testable import RevenueCat
import XCTest

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, visionOS 1.0, watchOS 8.0, *)
// swiftlint:disable type_name
final class LargeItemCacheTypeDocumentsDirectoryMigrationTests: TestCase {

    let fileManager = FileManager.default

    static let oldBasePath = "old"
    static let newBasePath = "new"

    override func setUp() async throws {
        try await super.setUp()

        let directoryURLs = [
            fileManager.urls(for: .documentDirectory, in: .userDomainMask).first,
            DirectoryHelper.baseUrl(for: .cache)
        ].compactMap(\.self)

        for directoryURL in directoryURLs {
            try? fileManager.removeItem(at: directoryURL)
        }
    }

    func testRemoveOldDirectoryStrategy() async throws {
        let files = ["one", "two"]
        let oldDocumentsDirectoryURL = try XCTUnwrap(createOldDocumentsDirectory(with: files))

        let oldFileOne = try XCTUnwrap(oldFileURL(file: files[0]))
        let oldFileTwo = try XCTUnwrap(oldFileURL(file: files[1]))
        expect(self.fileManager.fileExists(atPath: oldFileOne.path)).to(beTrue())
        expect(self.fileManager.fileExists(atPath: oldFileTwo.path)).to(beTrue())

        let sut = createSut(.remove(oldBasePath: Self.oldBasePath))

        // Reading a file should triger the removal of the old directory
        let value: TestData? = sut.value(forKey: CacheKey(rawValue: "dummy-key"))
        expect(value).to(beNil())

        expect(self.fileManager.fileExists(atPath: oldDocumentsDirectoryURL.path)).to(beFalse())
        expect(self.fileManager.fileExists(atPath: oldFileOne.path)).to(beFalse())
        expect(self.fileManager.fileExists(atPath: oldFileTwo.path)).to(beFalse())

        let newFileOne = try XCTUnwrap(newFileURL(file: files[0]))
        let newFileTwo = try XCTUnwrap(newFileURL(file: files[1]))
        expect(self.fileManager.fileExists(atPath: newFileOne.path)).to(beFalse())
        expect(self.fileManager.fileExists(atPath: newFileTwo.path)).to(beFalse())
    }

    func testMoveFileStragey() async throws {
        let files = ["one", "two"]
        let oldDocumentsDirectoryURL = try XCTUnwrap(createOldDocumentsDirectory(with: files))

        let oldFileOne = try XCTUnwrap(oldFileURL(file: files[0]))
        let oldFileTwo = try XCTUnwrap(oldFileURL(file: files[1]))
        expect(self.fileManager.fileExists(atPath: oldFileOne.path)).to(beTrue())
        expect(self.fileManager.fileExists(atPath: oldFileTwo.path)).to(beTrue())

        let sut = createSut(.migrate(oldBasePath: Self.oldBasePath))

        // When retrieving the first file it should be migrated, but the old directory should still have the second file
        let testDataOne: TestData = try XCTUnwrap(sut.value(forKey: CacheKey(rawValue: files[0])))
        expect(self.fileManager.fileExists(atPath: oldDocumentsDirectoryURL.path)).to(beTrue())
        expect(self.fileManager.fileExists(atPath: oldFileOne.path)).to(beFalse())
        expect(self.fileManager.fileExists(atPath: oldFileTwo.path)).to(beTrue())

        // Now the second file should be migrated as well and the old directory should be removed
        let testDataTwo: TestData = try XCTUnwrap(sut.value(forKey: CacheKey(rawValue: files[1])))
        expect(self.fileManager.fileExists(atPath: oldDocumentsDirectoryURL.path)).to(beFalse())
        expect(self.fileManager.fileExists(atPath: oldFileOne.path)).to(beFalse())
        expect(self.fileManager.fileExists(atPath: oldFileTwo.path)).to(beFalse())

        // Additional check, the file should now be loaded from the new location
        expect(try XCTUnwrap(sut.value(forKey: CacheKey(rawValue: files[0])))) == testDataOne
        expect(try XCTUnwrap(sut.value(forKey: CacheKey(rawValue: files[1])))) == testDataTwo
    }

    func testSetMigratesFileFromOldDirectory() async throws {
        let files = ["one", "two"]
        let oldDocumentsDirectoryURL = try XCTUnwrap(createOldDocumentsDirectory(with: files))

        let oldFileOne = try XCTUnwrap(oldFileURL(file: files[0]))
        let oldFileTwo = try XCTUnwrap(oldFileURL(file: files[1]))
        let newFileOne = try XCTUnwrap(newFileURL(file: files[0]))
        let newFileTwo = try XCTUnwrap(newFileURL(file: files[1]))

        expect(self.fileManager.fileExists(atPath: oldFileOne.path)).to(beTrue())
        expect(self.fileManager.fileExists(atPath: oldFileTwo.path)).to(beTrue())
        expect(self.fileManager.fileExists(atPath: newFileOne.path)).to(beFalse())
        expect(self.fileManager.fileExists(atPath: newFileTwo.path)).to(beFalse())

        let sut = createSut(.migrate(oldBasePath: Self.oldBasePath))

        // Writing to the first file should write it to the new location and delete the old file
        let newDataOne = TestData()
        sut.set(codable: newDataOne, forKey: CacheKey(rawValue: files[0]))
        expect(self.fileManager.fileExists(atPath: newFileOne.path)).to(beTrue())
        expect(self.fileManager.fileExists(atPath: oldFileOne.path)).to(beFalse())

        // The second file should still be in the old location
        expect(self.fileManager.fileExists(atPath: oldFileTwo.path)).to(beTrue())
        expect(self.fileManager.fileExists(atPath: oldDocumentsDirectoryURL.path)).to(beTrue())

        // Writing to the second file should write it to thew new location as well
        let newDataTwo = TestData()
        sut.set(codable: newDataTwo, forKey: CacheKey(rawValue: files[1]))
        expect(self.fileManager.fileExists(atPath: newFileTwo.path)).to(beTrue())
        expect(self.fileManager.fileExists(atPath: oldFileTwo.path)).to(beFalse())

        // The old directory should now also be removed
        expect(self.fileManager.fileExists(atPath: oldDocumentsDirectoryURL.path)).to(beFalse())

        // Reading should return the new values from the new location
        let retrievedOne: TestData? = sut.value(forKey: CacheKey(rawValue: files[0]))
        let retrievedTwo: TestData? = sut.value(forKey: CacheKey(rawValue: files[1]))
        expect(retrievedOne) == newDataOne
        expect(retrievedTwo) == newDataTwo
    }

    func createSut(
        _ strategy: SynchronizedLargeItemCache.DocumentsDirectoryMigrationStrategy
    ) -> SynchronizedLargeItemCache {
        SynchronizedLargeItemCache(
            cache: fileManager,
            basePath: Self.newBasePath,
            documentsDirectoryMigrationStrategy: strategy
        )
    }

    func createOldDocumentsDirectory(with files: [String] = [String]()) throws -> URL? {
        guard let oldDocumentsDirectoryURL else { return nil }

        try fileManager.createDirectory(
            at: oldDocumentsDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )

        for file in files {
            if let url = oldFileURL(file: file) {
                try JSONEncoder().encode(TestData()).write(to: url)
            }
        }

        return oldDocumentsDirectoryURL
    }

    func oldFileURL(file: String) -> URL? {
        oldDocumentsDirectoryURL?.appendingPathComponent(file)
    }

    func newFileURL(file: String) -> URL? {
        cacheDirectoryURL?.appendingPathComponent(file)
    }

    var oldDocumentsDirectoryURL: URL? {
        fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first?.appendingPathComponent(Self.oldBasePath, isDirectory: true)
    }

    var cacheDirectoryURL: URL? {
        DirectoryHelper.baseUrl(for: .cache)?.appendingPathComponent(Self.newBasePath)
    }

    struct TestData: Codable, Equatable {
        let value: UUID

        init() {
            value = UUID()
        }
    }

    struct CacheKey: DeviceCacheKeyType {
        var rawValue: String
    }
}
