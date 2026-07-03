//
//  RemoteConfigBlobStoreTests.swift
//  UnitTests
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

final class RemoteConfigBlobStoreTests: TestCase {

    private var directoryURL: URL!
    private var blobStore: RemoteConfigBlobStore!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("RemoteConfigBlobStoreTests-\(UUID().uuidString)", isDirectory: true)
        self.blobStore = RemoteConfigBlobStore(directoryURL: self.directoryURL)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: self.directoryURL)
        self.blobStore = nil
        self.directoryURL = nil

        try super.tearDownWithError()
    }

    func testReadReturnsNilForMissingBlob() {
        expect(self.blobStore.read(ref: Self.refA)).to(beNil())
    }

    func testWriteThenReadRoundTripsBlobBytes() throws {
        let data = Data([1, 2, 3, 4, 5])

        expect(self.write(ref: Self.refA, data: data)) == true

        expect(self.blobStore.read(ref: Self.refA)) == data
    }

    func testContainsReflectsWhetherBlobHasBeenWritten() {
        expect(self.blobStore.contains(ref: Self.refA)) == false

        self.write(ref: Self.refA, data: Data([1]))

        expect(self.blobStore.contains(ref: Self.refA)) == true
    }

    func testContainsAndCachedRefsLoadBlobsFromPreviousInstance() {
        self.write(ref: Self.refA, data: Data([1]))

        let reopened = RemoteConfigBlobStore(directoryURL: self.directoryURL)

        expect(reopened.contains(ref: Self.refA)) == true
        expect(reopened.cachedRefs()) == [Self.refA]
    }

    func testContainsReturnsFalseForDirectoryWithValidRefName() throws {
        try FileManager.default.createDirectory(
            at: self.directoryURL.appendingPathComponent(Self.refA, isDirectory: true),
            withIntermediateDirectories: true,
            attributes: nil
        )

        expect(self.blobStore.contains(ref: Self.refA)) == false
    }

    func testCachedRefsReturnsOnlyValidBlobFiles() throws {
        self.write(ref: Self.refA, data: Data([1]))
        self.write(ref: Self.refB, data: Data([2]))
        try FileManager.default.createDirectory(
            at: self.directoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        try Data([3]).write(to: self.directoryURL.appendingPathComponent("not-a-valid-ref"))

        expect(self.blobStore.cachedRefs()) == [Self.refA, Self.refB]
    }

    func testReadSelfHealsCachedRefsWhenUnderlyingFileIsGone() throws {
        self.write(ref: Self.refA, data: Data([1]))
        expect(self.blobStore.contains(ref: Self.refA)) == true

        try FileManager.default.removeItem(at: self.directoryURL.appendingPathComponent(Self.refA))

        expect(self.blobStore.read(ref: Self.refA)).to(beNil())
        expect(self.blobStore.contains(ref: Self.refA)) == false
    }

    func testContainsSelfHealsCachedRefsWhenUnderlyingFileIsGone() throws {
        self.write(ref: Self.refA, data: Data([1]))
        expect(self.blobStore.contains(ref: Self.refA)) == true

        try FileManager.default.removeItem(at: self.directoryURL.appendingPathComponent(Self.refA))

        expect(self.blobStore.contains(ref: Self.refA)) == false
        expect(self.blobStore.cachedRefs()).to(beEmpty())
    }

    func testRetainOnlyDeletesUnreferencedBlobs() {
        self.write(ref: Self.refA, data: Data([1]))
        self.write(ref: Self.refB, data: Data([2]))

        self.blobStore.retainOnly([Self.refA])

        expect(self.blobStore.contains(ref: Self.refA)) == true
        expect(self.blobStore.contains(ref: Self.refB)) == false
    }

    func testRetainOnlyPrunesOrphanTempFilesAndInvalidNamedFiles() throws {
        self.write(ref: Self.refA, data: Data([1]))
        let orphanTemp = self.directoryURL.appendingPathComponent("rc_blob_orphan.tmp")
        let invalidNamed = self.directoryURL.appendingPathComponent("not-a-valid-ref")
        try Data([9]).write(to: orphanTemp)
        try Data([9]).write(to: invalidNamed)

        self.blobStore.retainOnly([Self.refA])

        expect(FileManager.default.fileExists(atPath: orphanTemp.path)) == false
        expect(FileManager.default.fileExists(atPath: invalidNamed.path)) == false
        expect(self.blobStore.contains(ref: Self.refA)) == true
        expect(self.blobStore.cachedRefs()) == [Self.refA]
    }

    func testRetainOnlyWithEmptySetClearsBlobs() {
        self.write(ref: Self.refA, data: Data([1]))

        self.blobStore.retainOnly([])

        expect(self.blobStore.cachedRefs()).to(beEmpty())
    }

    func testRetainOnlyIgnoresMalformedRefs() {
        self.write(ref: Self.refA, data: Data([1]))
        self.write(ref: Self.refB, data: Data([2]))

        self.blobStore.retainOnly([Self.refA, "not-a-valid-ref"])

        expect(self.blobStore.contains(ref: Self.refA)) == true
        expect(self.blobStore.contains(ref: Self.refB)) == false
    }

    func testClearDeletesAllBlobs() {
        self.write(ref: Self.refA, data: Data([1]))
        self.write(ref: Self.refB, data: Data([2]))

        self.blobStore.clear()

        expect(self.blobStore.cachedRefs()).to(beEmpty())
        expect(self.blobStore.contains(ref: Self.refA)) == false
        expect(self.blobStore.contains(ref: Self.refB)) == false
    }

    func testClearDeletesEntireBlobDirectory() throws {
        self.write(ref: Self.refA, data: Data([1]))
        try FileManager.default.createDirectory(
            at: self.directoryURL.appendingPathComponent("nested", isDirectory: true),
            withIntermediateDirectories: true,
            attributes: nil
        )
        try Data([2]).write(to: self.directoryURL.appendingPathComponent("not-a-valid-ref"))

        self.blobStore.clear()

        expect(FileManager.default.fileExists(atPath: self.directoryURL.path)) == false
    }

    func testClearIsNoOpWhenNothingHasBeenWritten() {
        self.blobStore.clear()

        expect(self.blobStore.cachedRefs()).to(beEmpty())
    }

    func testMalformedRefIsRejectedAndCannotEscapeBlobDirectory() {
        let malformedRef = "../escape"

        expect(self.write(ref: malformedRef, data: Data([1, 2, 3]))) == false

        expect(self.blobStore.contains(ref: malformedRef)) == false
        expect(self.blobStore.read(ref: malformedRef)).to(beNil())
        expect(FileManager.default.fileExists(atPath: self.directoryURL.deletingLastPathComponent()
            .appendingPathComponent("escape")
            .path)
        ) == false
    }

    func testRetainOnlyWaitsForInProgressWrite() {
        let fileManager = BlockingFileManager()
        self.blobStore = RemoteConfigBlobStore(fileManager: fileManager, directoryURL: self.directoryURL)

        let writeFinished = DispatchSemaphore(value: 0)
        let retainStarted = DispatchSemaphore(value: 0)
        let retainFinished = DispatchSemaphore(value: 0)

        let data = Data([1])
        DispatchQueue.global().async {
            self.write(ref: Self.refA, data: data)
            writeFinished.signal()
        }

        expect(fileManager.waitForDirectoryCreation()) == true

        DispatchQueue.global().async {
            retainStarted.signal()
            self.blobStore.retainOnly([Self.refA])
            retainFinished.signal()
        }

        expect(retainStarted.wait(timeout: .now() + 1)) == .success
        expect(fileManager.waitForContentsOfDirectory(timeout: .now() + 0.1)) == false

        fileManager.unblockDirectoryCreation()

        expect(writeFinished.wait(timeout: .now() + 1)) == .success
        expect(retainFinished.wait(timeout: .now() + 1)) == .success
        expect(fileManager.waitForContentsOfDirectory()) == true
    }

}

private extension RemoteConfigBlobStoreTests {

    static let refA = "AAAABBBBCCCCDDDDEEEEFFFFGGGGHHHH"
    static let refB = "IIIIJJJJKKKKLLLLMMMMNNNNOOOOPPPP"

    @discardableResult
    func write(ref: String, data: Data) -> Bool {
        return data.withUnsafeBytes { bytes in
            self.blobStore.write(ref: ref, bytes: bytes)
        }
    }

}

private final class BlockingFileManager: FileManager {

    private let enteredDirectoryCreation = DispatchSemaphore(value: 0)
    private let allowDirectoryCreation = DispatchSemaphore(value: 0)
    private let enteredContentsOfDirectory = DispatchSemaphore(value: 0)

    override func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]? = nil
    ) throws {
        self.enteredDirectoryCreation.signal()
        _ = self.allowDirectoryCreation.wait(timeout: .now() + 5)

        try super.createDirectory(
            at: url,
            withIntermediateDirectories: createIntermediates,
            attributes: attributes
        )
    }

    override func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: FileManager.DirectoryEnumerationOptions = []
    ) throws -> [URL] {
        self.enteredContentsOfDirectory.signal()
        return try super.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: keys,
            options: mask
        )
    }

    func waitForDirectoryCreation(timeout: DispatchTime = .now() + 1) -> Bool {
        return self.enteredDirectoryCreation.wait(timeout: timeout) == .success
    }

    func waitForContentsOfDirectory(timeout: DispatchTime = .now() + 1) -> Bool {
        return self.enteredContentsOfDirectory.wait(timeout: timeout) == .success
    }

    func unblockDirectoryCreation() {
        self.allowDirectoryCreation.signal()
    }

}
