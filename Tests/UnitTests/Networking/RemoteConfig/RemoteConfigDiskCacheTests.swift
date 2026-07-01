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
    private var cache: RemoteConfigDiskCache!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("RemoteConfigDiskCacheTests-\(UUID().uuidString)", isDirectory: true)

        #if os(tvOS)
        let directoryType = DirectoryHelper.DirectoryType.cache
        #else
        let directoryType = DirectoryHelper.DirectoryType.applicationSupport(overrideURL: self.rootURL)
        #endif

        let synchronizedCache = SynchronizedLargeItemCache(
            cache: FileManager.default,
            basePath: RemoteConfigDiskCache.basePath,
            directoryType: directoryType
        )
        self.cache = RemoteConfigDiskCache(cache: synchronizedCache)

        self.cacheDirectoryURL = try XCTUnwrap(DirectoryHelper.baseUrl(for: directoryType))
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
        self.rootURL = nil

        try super.tearDownWithError()
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
        let read = try XCTUnwrap(self.cache.read())

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
        let read = try XCTUnwrap(self.cache.read())

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
        let read = try XCTUnwrap(self.cache.read())

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

        let read = try XCTUnwrap(self.cache.read())

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
    }

    func testClearIsNoOpWhenNothingHasBeenPersisted() {
        self.cache.clear()

        expect(self.cache.read()).to(beNil())
    }

}
