//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RemoteConfigBlobHealthTests.swift
//
//  Real-backend health check for the remote config CDN blob path. Runs against a live project
//  that serves CDN blobs and verifies they actually download and validate, so we find out when
//  production (the backend, the CDN, or the offload flag) is broken, which mocked tests cannot.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

final class RemoteConfigBlobHealthTests: TestCase {

    // Substituted at CI time. Must be a project that serves CDN blobs (the prepared stress-test
    // project with the CDN-offload flag on); otherwise there is nothing to download to check.
    private static let apiKey = "REVENUECAT_REMOTE_CONFIG_API_KEY"

    private var rootURL: URL!
    private var recorder: RecordingBlobDownloader!
    private var blobStore: RemoteConfigBlobStore!
    private var manager: RemoteConfigManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        try XCTSkipIf(
            Self.apiKey == "REVENUECAT_REMOTE_CONFIG_API_KEY",
            "No live API key substituted; skipping the real-backend blob health check."
        )

        self.rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("RemoteConfigProductionTests-\(UUID().uuidString)", isDirectory: true)
        let directoryType = DirectoryHelper.DirectoryType.applicationSupport(overrideURL: self.rootURL)
        let cacheBasePath = "\(RemoteConfigDiskCache.basePath)-\(UUID().uuidString)"
        let synchronizedCache = SynchronizedLargeItemCache(
            cache: FileManager.default,
            basePath: cacheBasePath,
            directoryType: directoryType
        )
        let cacheDirectoryURL = try XCTUnwrap(DirectoryHelper.baseUrl(for: directoryType))
            .appendingPathComponent(cacheBasePath, isDirectory: true)

        let diskCache = RemoteConfigDiskCache(cache: synchronizedCache)
        self.blobStore = RemoteConfigBlobStore(
            fileManager: .default,
            directoryURL: cacheDirectoryURL.appendingPathComponent("blobs", isDirectory: true)
        )
        let sourceProvider = RemoteConfigSourceProvider(topicStore: diskCache)
        self.recorder = RecordingBlobDownloader()
        self.manager = self.makeManager(diskCache: diskCache, sourceProvider: sourceProvider)
    }

    private func makeManager(
        diskCache: RemoteConfigDiskCache,
        sourceProvider: RemoteConfigSourceProvider
    ) -> RemoteConfigManager {
        let systemInfo = SystemInfo(
            platformInfo: nil,
            finishTransactions: true,
            apiKey: Self.apiKey,
            preferredLocalesProvider: PreferredLocalesProvider(preferredLocaleOverride: nil)
        )
        let backend = Backend(
            systemInfo: systemInfo,
            eTagManager: ETagManager(),
            operationDispatcher: .default,
            attributionFetcher: AttributionFetcher(
                attributionFactory: AttributionTypeFactory(),
                systemInfo: systemInfo
            ),
            offlineCustomerInfoCreator: nil,
            diagnosticsTracker: nil
        )
        return RemoteConfigManager(
            remoteConfigAPI: backend.remoteConfigAPI,
            diskCache: diskCache,
            blobStore: self.blobStore,
            blobFetcher: RemoteConfigBlobFetcher(
                blobStore: self.blobStore,
                sourceProvider: sourceProvider,
                downloader: self.recorder
            ),
            currentUserProvider: ProductionTestUserProvider()
        )
    }

    override func tearDownWithError() throws {
        self.manager?.close()
        if let rootURL = self.rootURL {
            try? FileManager.default.removeItem(at: rootURL)
        }
        self.manager = nil
        self.blobStore = nil
        self.recorder = nil
        self.rootURL = nil
        try super.tearDownWithError()
    }

    func testProductionWorkflowBlobsDownloadAndValidateHealthily() async throws {
        // Fetch config from the live backend and download the workflows topic's prefetch blobs
        // through the real CDN path.
        let maybeTopic = await self.manager.awaitTopicAndPrefetchBlobsReady(.workflows)
        let topic = try XCTUnwrap(maybeTopic, "No workflows topic returned from the live backend.")

        let blobItemKeys = topic.compactMap { key, item in item.blobRef == nil ? nil : key }

        // Every blob-backed item must read back. A download or checksum failure returns nil,
        // so this covers checksum-failures == 0 and "all referenced blobs present".
        for key in blobItemKeys {
            let data = await self.manager.blobData(for: .workflows, itemKey: key)
            expect(data).toNot(beNil(), description: "Blob for item \(key) did not resolve.")
        }

        // Transport-health invariants (recorded by RecordingBlobDownloader):
        expect(self.recorder.successCount) > 0        // blobs_downloaded > 0
        expect(self.recorder.failureCount) == 0       // error_count / failed_requests == 0
        expect(self.recorder.distinctHostCount) <= 1  // fallback_host_requests == 0 (no second host)
        expect(self.recorder.totalBytes) > 0          // blob bytes
    }

}

private struct ProductionTestUserProvider: CurrentUserProvider {
    var currentAppUserID: String { "remote-config-production-test-user" }
    var currentUserIsAnonymous: Bool { true }
}
