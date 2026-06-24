//
//  RemoteConfigDiskCacheTests.swift
//  UnitTests
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

final class RemoteConfigDiskCacheTests: TestCase {

    private var directoryURL: URL!
    private var cache: RemoteConfigDiskCache!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("RemoteConfigDiskCacheTests-\(UUID().uuidString)", isDirectory: true)
        self.cache = RemoteConfigDiskCache(directoryURL: self.directoryURL)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: self.directoryURL)
        self.cache = nil
        self.directoryURL = nil

        try super.tearDownWithError()
    }

    func testReadReturnsNilWhenNothingHasBeenPersisted() {
        expect(self.cache.read()).to(beNil())
    }

    func testWriteThenReadRoundTripsManifestAndTopicBlobRefs() throws {
        let manifest = RemoteConfigManifestToken("v1.1710000100.product_entitlement_mapping:etag2,sources:etag1")
        let activeTopics = ["sources", "product_entitlement_mapping"]
        let topicBlobRefs = [
            "sources": ["blobRefA"],
            "product_entitlement_mapping": ["pemBlob"]
        ]
        let prefetchBlobs = ["blobRefA", "pemBlob"]
        let lastRefreshAt = Date(timeIntervalSince1970: 1_710_000_100)

        self.cache.write(PersistedRemoteConfiguration(
            domain: "app",
            manifest: manifest,
            activeTopics: activeTopics,
            prefetchBlobs: prefetchBlobs,
            topicBlobRefs: topicBlobRefs,
            lastRefreshAt: lastRefreshAt
        ))
        let read = try XCTUnwrap(self.cache.read())

        expect(read.domain) == "app"
        expect(read.manifest) == manifest
        expect(read.activeTopics) == activeTopics
        expect(read.prefetchBlobs) == prefetchBlobs
        expect(read.topicBlobRefs) == topicBlobRefs
        expect(read.lastRefreshAt) == lastRefreshAt
    }

    func testInlineOnlyTopicsPersistWithEmptyBlobRefList() throws {
        let manifest = RemoteConfigManifestToken("v1.1710000100.sources:etag1")
        let topicBlobRefs = ["sources": [String]()]

        self.cache.write(PersistedRemoteConfiguration(
            domain: "app",
            manifest: manifest,
            activeTopics: ["sources"],
            prefetchBlobs: [],
            topicBlobRefs: topicBlobRefs,
            lastRefreshAt: Date()
        ))
        let read = try XCTUnwrap(self.cache.read())

        expect(read.topicBlobRefs) == topicBlobRefs
    }

    func testReadReturnsNilWhenPersistedFileIsCorrupt() throws {
        try FileManager.default.createDirectory(
            at: self.directoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        try "{ this is not valid json".asData.write(to: self.fileURL)

        expect(self.cache.read()).to(beNil())
    }

    func testReadToleratesOldFormatByDroppingUnknownTopicBodies() throws {
        try FileManager.default.createDirectory(
            at: self.directoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        try """
        {
          "manifest": "v1.1710000100.sources:etag1",
          "topics": {
            "sources": {
              "default": { "blob_ref": "oldBlob" }
            }
          }
        }
        """.asData.write(to: self.fileURL)

        let read = try XCTUnwrap(self.cache.read())

        expect(read.domain) == "app"
        expect(read.manifest) == RemoteConfigManifestToken("v1.1710000100.sources:etag1")
        expect(read.activeTopics).to(beEmpty())
        expect(read.prefetchBlobs).to(beEmpty())
        expect(read.topicBlobRefs).to(beEmpty())
        expect(read.lastRefreshAt).to(beNil())
    }

    func testWriteCreatesDirectoryWhenAbsent() {
        self.cache.write(PersistedRemoteConfiguration(
            domain: "app",
            manifest: RemoteConfigManifestToken("v1.1710000100.sources:etag1"),
            activeTopics: [],
            prefetchBlobs: [],
            topicBlobRefs: [:],
            lastRefreshAt: Date()
        ))

        expect(FileManager.default.fileExists(atPath: self.fileURL.path)) == true
    }

    func testWriteOverwritesPreviousSnapshot() throws {
        self.cache.write(PersistedRemoteConfiguration(
            domain: "app",
            manifest: RemoteConfigManifestToken("v1.1710000100.sources:old"),
            activeTopics: [],
            prefetchBlobs: [],
            topicBlobRefs: [:],
            lastRefreshAt: Date(timeIntervalSince1970: 1)
        ))
        self.cache.write(PersistedRemoteConfiguration(
            domain: "app",
            manifest: RemoteConfigManifestToken("v1.1710000100.sources:new"),
            activeTopics: ["sources"],
            prefetchBlobs: [],
            topicBlobRefs: [:],
            lastRefreshAt: Date(timeIntervalSince1970: 2)
        ))

        let read = try XCTUnwrap(self.cache.read())

        expect(read.manifest) == RemoteConfigManifestToken("v1.1710000100.sources:new")
    }

}

private extension RemoteConfigDiskCacheTests {

    var fileURL: URL {
        return self.directoryURL.appendingPathComponent("remoteConfig.json", isDirectory: false)
    }

}
