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

        self.write(ref: Self.refA, data: data)

        expect(self.blobStore.read(ref: Self.refA)) == data
    }

    func testContainsReflectsWhetherBlobHasBeenWritten() {
        expect(self.blobStore.contains(ref: Self.refA)) == false

        self.write(ref: Self.refA, data: Data([1]))

        expect(self.blobStore.contains(ref: Self.refA)) == true
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

    func testRetainOnlyDeletesUnreferencedBlobs() {
        self.write(ref: Self.refA, data: Data([1]))
        self.write(ref: Self.refB, data: Data([2]))

        self.blobStore.retainOnly([Self.refA])

        expect(self.blobStore.contains(ref: Self.refA)) == true
        expect(self.blobStore.contains(ref: Self.refB)) == false
    }

    func testRetainOnlyWithEmptySetClearsBlobs() {
        self.write(ref: Self.refA, data: Data([1]))

        self.blobStore.retainOnly([])

        expect(self.blobStore.cachedRefs()).to(beEmpty())
    }

    func testMalformedRefIsRejectedAndCannotEscapeBlobDirectory() {
        let malformedRef = "../escape"

        self.write(ref: malformedRef, data: Data([1, 2, 3]))

        expect(self.blobStore.contains(ref: malformedRef)) == false
        expect(self.blobStore.read(ref: malformedRef)).to(beNil())
        expect(FileManager.default.fileExists(atPath: self.directoryURL.deletingLastPathComponent()
            .appendingPathComponent("escape")
            .path)
        ) == false
    }

}

private extension RemoteConfigBlobStoreTests {

    static let refA = "AAAABBBBCCCCDDDDEEEEFFFFGGGGHHHH"
    static let refB = "IIIIJJJJKKKKLLLLMMMMNNNNOOOOPPPP"

    func write(ref: String, data: Data) {
        data.withUnsafeBytes { bytes in
            self.blobStore.write(ref: ref, bytes: bytes)
        }
    }

}
