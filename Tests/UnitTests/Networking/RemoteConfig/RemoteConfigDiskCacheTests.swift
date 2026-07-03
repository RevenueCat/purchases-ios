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

    private var rootURL: URL!
    private var cacheDirectoryURL: URL!
    private var fileURL: URL!
    private var directoryType: DirectoryHelper.DirectoryType!
    private var cache: RemoteConfigDiskCache!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("RemoteConfigDiskCacheTests-\(UUID().uuidString)", isDirectory: true)

        #if os(tvOS)
        self.directoryType = DirectoryHelper.DirectoryType.cache
        #else
        self.directoryType = DirectoryHelper.DirectoryType.applicationSupport(overrideURL: self.rootURL)
        #endif

        self.cache = self.makeCache()

        self.cacheDirectoryURL = try XCTUnwrap(DirectoryHelper.baseUrl(for: self.directoryType))
            .appendingPathComponent(RemoteConfigDiskCache.basePath, isDirectory: true)
        try? FileManager.default.removeItem(at: self.cacheDirectoryURL)

        self.fileURL = self.cacheDirectoryURL
            .appendingPathComponent(RemoteConfigDiskCache.fileName, isDirectory: false)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: self.cacheDirectoryURL)
        try? FileManager.default.removeItem(at: self.rootURL)
        self.cache = nil
        self.fileURL = nil
        self.cacheDirectoryURL = nil
        self.directoryType = nil
        self.rootURL = nil

        try super.tearDownWithError()
    }

    /// A fresh cache pointing at the same directory, with an empty in-memory cache so reads hit disk.
    private func makeCache() -> RemoteConfigDiskCache {
        return RemoteConfigDiskCache(cache: SynchronizedLargeItemCache(
            cache: FileManager.default,
            basePath: RemoteConfigDiskCache.basePath,
            directoryType: self.directoryType
        ))
    }

    func testReadReturnsNilWhenNothingHasBeenPersisted() {
        expect(self.cache.read()).to(beNil())
    }

    func testWriteThenReadRoundTripsManifestAndTopics() throws {
        let manifest = "v1.1710000100.product_entitlement_mapping:etag2,sources:etag1"
        let activeTopics = ["sources", "product_entitlement_mapping"]
        let topics = RemoteConfiguration.Topics(entries: [
            "sources": ["default": .init(blobRef: "blobRefA")],
            "product_entitlement_mapping": ["default": .init(blobRef: "pemBlob")]
        ])
        let prefetchBlobs = ["blobRefA", "pemBlob"]

        self.cache.write(PersistedRemoteConfiguration(
            domain: "app",
            manifest: manifest,
            activeTopics: activeTopics,
            prefetchBlobs: prefetchBlobs,
            topics: topics
        ))
        let read = try XCTUnwrap(self.makeCache().read())

        expect(read.domain) == "app"
        expect(read.manifest) == manifest
        expect(read.activeTopics) == activeTopics
        expect(read.prefetchBlobs) == prefetchBlobs
        expect(read.topics) == topics
    }

    func testInlineOnlyTopicsPersistWithContent() throws {
        let manifest = "v1.1710000100.sources:etag1"
        let inlineItem = RemoteConfiguration.ConfigItem(
            content: [
                "priority": 100,
                "url": "https://api.revenuecat.com"
            ]
        )
        let topics = RemoteConfiguration.Topics(entries: [
            "sources": ["api": inlineItem]
        ])

        self.cache.write(PersistedRemoteConfiguration(
            domain: "app",
            manifest: manifest,
            activeTopics: ["sources"],
            prefetchBlobs: [],
            topics: topics
        ))
        let read = try XCTUnwrap(self.makeCache().read())

        expect(read.topics) == topics
    }

    func testTopicsPersistUntypedMetadataRoundTrip() throws {
        let metadataItem = RemoteConfiguration.ConfigItem(
            content: [
                "array": ["one", 2, true],
                "bool": true,
                "double": 1.5,
                "int": 100,
                "nested": [
                    "enabled": false,
                    "name": "nested"
                ],
                "null": nil,
                "string": "value"
            ]
        )
        let topics = RemoteConfiguration.Topics(entries: [
            "sources": ["api": metadataItem]
        ])

        self.cache.write(PersistedRemoteConfiguration(
            manifest: "v1.1710000100.sources:etag1",
            activeTopics: ["sources"],
            topics: topics
        ))
        let read = try XCTUnwrap(self.makeCache().read())

        expect(read.topics) == topics
    }

    func testReadReturnsNilWhenPersistedFileIsCorrupt() throws {
        try FileManager.default.createDirectory(
            at: self.fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        try "{ this is not valid json".asData.write(to: self.fileURL)

        expect(self.cache.read()).to(beNil())
    }

    func testReadCachesMissAfterDecodingFailureAndDoesNotReadDiskAgain() throws {
        try FileManager.default.createDirectory(
            at: self.fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        try "{ this is not valid json".asData.write(to: self.fileURL)

        // First read fails to decode and caches the miss.
        expect(self.cache.read()).to(beNil())

        // Persist a valid configuration to disk behind the cache's back.
        self.makeCache().write(PersistedRemoteConfiguration(
            manifest: "v1.1710000100.sources:etag1",
            activeTopics: ["sources"]
        ))

        // The miss is cached, so disk is not read again.
        expect(self.cache.read()).to(beNil())
    }

    func testReadCachesMissWhenNothingPersistedAndDoesNotReadDiskAgain() throws {
        // First read finds nothing on disk and caches the miss.
        expect(self.cache.read()).to(beNil())

        // Persist a valid configuration to disk behind the cache's back.
        self.makeCache().write(PersistedRemoteConfiguration(
            manifest: "v1.1710000100.sources:etag1",
            activeTopics: ["sources"]
        ))

        // The miss is cached, so disk is not read again.
        expect(self.cache.read()).to(beNil())
    }

    func testReadDefaultsMissingTopicsToEmpty() throws {
        try FileManager.default.createDirectory(
            at: self.fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: nil
        )
        try """
        {
          "manifest": "v1.1710000100.sources:etag1"
        }
        """.asData.write(to: self.fileURL)

        let read = try XCTUnwrap(self.cache.read())

        expect(read.manifest) == "v1.1710000100.sources:etag1"
        expect(read.topics.entries).to(beEmpty())
    }

    func testWriteCreatesDirectoryWhenAbsent() {
        self.cache.write(PersistedRemoteConfiguration(
            domain: "app",
            manifest: "v1.1710000100.sources:etag1",
            activeTopics: [],
            prefetchBlobs: []
        ))

        expect(FileManager.default.fileExists(atPath: self.fileURL.path)) == true
    }

    func testWriteUsesRemoteConfigDirectoryAndFileName() {
        self.cache.write(PersistedRemoteConfiguration(
            domain: "app",
            manifest: "v1.1710000100.sources:etag1",
            activeTopics: [],
            prefetchBlobs: []
        ))

        expect(self.fileURL.deletingLastPathComponent().lastPathComponent) == "remote_config"
        expect(self.fileURL.lastPathComponent) == "remote_config.json"
        expect(FileManager.default.fileExists(atPath: self.fileURL.path)) == true
    }

    func testWriteLogsWhenCacheCannotWrite() {
        self.cache = RemoteConfigDiskCache(cache: .init(
            cache: MockSimpleCache(cacheDirectory: nil),
            basePath: RemoteConfigDiskCache.basePath
        ))

        self.cache.write(PersistedRemoteConfiguration(
            domain: "app",
            manifest: "v1.1710000100.sources:etag1",
            activeTopics: [],
            prefetchBlobs: []
        ))

        self.logger.verifyMessageWasLogged(Strings.remoteConfig.failedToWriteCache, level: .error)
    }

    func testWriteOverwritesPreviousSnapshot() throws {
        self.cache.write(PersistedRemoteConfiguration(
            domain: "app",
            manifest: "v1.1710000100.sources:old",
            activeTopics: [],
            prefetchBlobs: []
        ))
        self.cache.write(PersistedRemoteConfiguration(
            domain: "app",
            manifest: "v1.1710000100.sources:new",
            activeTopics: ["sources"],
            prefetchBlobs: []
        ))

        let read = try XCTUnwrap(self.makeCache().read())

        expect(read.manifest) == "v1.1710000100.sources:new"
    }

    func testClearDeletesPersistedState() {
        self.cache.write(PersistedRemoteConfiguration(
            domain: "app",
            manifest: "v1.1710000100.sources:etag1",
            activeTopics: ["sources"],
            prefetchBlobs: []
        ))

        self.cache.clear()

        expect(self.cache.read()).to(beNil())
        expect(self.makeCache().read()).to(beNil())
    }

    func testClearIsNoOpWhenNothingHasBeenPersisted() {
        self.cache.clear()

        expect(self.cache.read()).to(beNil())
    }

    func testTopicReturnsPersistedTopic() throws {
        let sourcesTopic: RemoteConfiguration.ConfigTopic = ["default": .init(blobRef: "blobRefA")]
        self.cache.write(PersistedRemoteConfiguration(
            manifest: "v1.1710000100.sources:etag1",
            activeTopics: ["sources"],
            topics: RemoteConfiguration.Topics(entries: ["sources": sourcesTopic])
        ))

        expect(self.cache.topic("sources")) == sourcesTopic
    }

    func testTopicReturnsNilForUnknownTopic() {
        self.cache.write(PersistedRemoteConfiguration(
            manifest: "v1.1710000100.sources:etag1",
            activeTopics: ["sources"],
            topics: RemoteConfiguration.Topics(entries: ["sources": ["default": .init(blobRef: "blobRefA")]])
        ))

        expect(self.cache.topic("unknown")).to(beNil())
    }

    func testTopicReturnsNilWhenNothingHasBeenPersisted() {
        expect(self.cache.topic("sources")).to(beNil())
    }

    func testReadAndTopicServeFromMemoryAfterFirstLoad() throws {
        let sourcesTopic: RemoteConfiguration.ConfigTopic = ["default": .init(blobRef: "blobRefA")]
        self.cache.write(PersistedRemoteConfiguration(
            manifest: "v1.1710000100.sources:etag1",
            activeTopics: ["sources"],
            topics: RemoteConfiguration.Topics(entries: ["sources": sourcesTopic])
        ))

        // Populate the in-memory cache.
        expect(self.cache.topic("sources")) == sourcesTopic

        // Delete the persisted file behind the cache's back.
        try FileManager.default.removeItem(at: self.fileURL)

        // Both `read()` and `topic(_:)` are still served from the in-memory cache.
        expect(self.cache.read()).toNot(beNil())
        expect(self.cache.topic("sources")) == sourcesTopic
    }

    func testReadLazilyLoadsFromDiskThenServesFromMemory() throws {
        // Persist through one instance so the data only lives on disk for a fresh instance.
        self.cache.write(PersistedRemoteConfiguration(
            manifest: "v1.1710000100.sources:etag1",
            activeTopics: ["sources"],
            topics: RemoteConfiguration.Topics(entries: ["sources": ["default": .init(blobRef: "blobRefA")]])
        ))

        let freshCache = self.makeCache()

        // First read lazily loads from disk.
        expect(freshCache.read()?.manifest) == "v1.1710000100.sources:etag1"

        // Once loaded, subsequent reads are served from memory even if the file is gone.
        try FileManager.default.removeItem(at: self.fileURL)
        expect(freshCache.read()?.manifest) == "v1.1710000100.sources:etag1"
    }

    func testTopicReflectsLatestWrite() throws {
        self.cache.write(PersistedRemoteConfiguration(
            manifest: "v1.1710000100.sources:old",
            activeTopics: ["sources"],
            topics: RemoteConfiguration.Topics(entries: ["sources": ["default": .init(blobRef: "old")]])
        ))
        expect(self.cache.topic("sources")) == ["default": .init(blobRef: "old")]

        let newTopic: RemoteConfiguration.ConfigTopic = ["default": .init(blobRef: "new")]
        self.cache.write(PersistedRemoteConfiguration(
            manifest: "v1.1710000100.sources:new",
            activeTopics: ["sources"],
            topics: RemoteConfiguration.Topics(entries: ["sources": newTopic])
        ))

        expect(self.cache.topic("sources")) == newTopic
    }

    func testTopicReturnsNilAfterClear() throws {
        self.cache.write(PersistedRemoteConfiguration(
            manifest: "v1.1710000100.sources:etag1",
            activeTopics: ["sources"],
            topics: RemoteConfiguration.Topics(entries: ["sources": ["default": .init(blobRef: "blobRefA")]])
        ))
        expect(self.cache.topic("sources")).toNot(beNil())

        self.cache.clear()

        expect(self.cache.topic("sources")).to(beNil())
    }

}
