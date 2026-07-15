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
//  Real-backend health check for the remote config blob path. Runs against two live projects with
//  fixed serving modes so we find out when production (the backend, the CDN, or the offload flag)
//  is broken, which mocked tests cannot: one project forces blobs onto the CDN, one serves inline.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

final class RemoteConfigBlobHealthTests: TestCase {

    // Two projects with fixed serving modes. Substituted at CI time; each test skips until its key
    // is provided. `cdnApiKey` must be a project with the CDN-offload flag on; `inlineApiKey` off.
    private static let cdnApiKey = "REVENUECAT_REMOTE_CONFIG_CDN_API_KEY"
    private static let inlineApiKey = "REVENUECAT_REMOTE_CONFIG_INLINE_API_KEY"

    private var rootURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("RemoteConfigProductionTests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        if let rootURL = self.rootURL {
            try? FileManager.default.removeItem(at: rootURL)
        }
        self.rootURL = nil
        try super.tearDownWithError()
    }

    // The CDN-forced project: every referenced blob must be downloaded from the CDN, once, one host.
    func testCDNProjectDownloadsEveryReferencedBlobFromOneHost() async throws {
        try XCTSkipIf(
            Self.cdnApiKey == "REVENUECAT_REMOTE_CONFIG_CDN_API_KEY",
            "No CDN-project key substituted; skipping."
        )

        let (blobRefs, recorder) = try await self.resolveWorkflowBlobs(apiKey: Self.cdnApiKey)

        // resolveWorkflowBlobs guarantees blobRefs is non-empty (and every blob read back), so these
        // checks are not vacuous. Every workflows blob was served from the CDN, and none failed. No
        // workflows failure also means no fallback to another host (fallback only happens after one).
        expect(blobRefs.allSatisfy { recorder.didDownload(ref: $0) })
            .to(beTrue(), description: "Not every workflows blob was downloaded from the CDN.")
        expect(blobRefs.contains { recorder.didFail(ref: $0) })
            .to(beFalse(), description: "A workflows blob download failed or fell back to another source.")
    }

    // The inline project: blobs arrive inside the config response, so nothing hits the CDN.
    func testInlineProjectServesEveryBlobWithoutHittingTheCDN() async throws {
        try XCTSkipIf(
            Self.inlineApiKey == "REVENUECAT_REMOTE_CONFIG_INLINE_API_KEY",
            "No inline-project key substituted; skipping."
        )

        let (blobRefs, recorder) = try await self.resolveWorkflowBlobs(apiKey: Self.inlineApiKey)

        // resolveWorkflowBlobs guarantees blobRefs is non-empty (and every blob read back), so these
        // checks are not vacuous. No workflows blob touched the CDN: none downloaded, none failed.
        expect(blobRefs.contains { recorder.didDownload(ref: $0) })
            .to(beFalse(), description: "A workflows blob was unexpectedly downloaded from the CDN.")
        expect(blobRefs.contains { recorder.didFail(ref: $0) })
            .to(beFalse(), description: "A workflows blob download failed.")
    }

    /// Builds a real manager for `apiKey`, resolves the workflows topic's blobs through the real
    /// backend, asserts every referenced blob is present and non-empty (shared by both modes), and
    /// returns the distinct blob refs plus the recorder for the caller's transport assertions.
    private func resolveWorkflowBlobs(
        apiKey: String
    ) async throws -> (blobRefs: Set<String>, recorder: RecordingBlobDownloader) {
        let recorder = RecordingBlobDownloader()
        let manager = try self.makeManager(apiKey: apiKey, recorder: recorder)
        defer { manager.close() }

        let maybeTopic = await manager.awaitTopicAndPrefetchBlobsReady(.workflows)
        let topic = try XCTUnwrap(maybeTopic, "No workflows topic returned from the live backend.")

        let blobRefs = Set(topic.values.compactMap(\.blobRef))
        let blobItemKeys = topic.compactMap { key, item in item.blobRef == nil ? nil : key }

        // The project must actually reference blobs, or there is nothing to monitor.
        expect(blobRefs).toNot(beEmpty())

        // Every referenced blob resolves to non-empty content (a bad checksum stores nothing -> nil).
        for key in blobItemKeys {
            let data = await manager.blobData(for: .workflows, itemKey: key)
            let blob = try XCTUnwrap(data, "Blob for item \(key) did not resolve.")
            expect(blob.isEmpty).to(beFalse(), description: "Blob for item \(key) was empty.")
        }

        return (blobRefs, recorder)
    }

    private func makeManager(apiKey: String, recorder: RecordingBlobDownloader) throws -> RemoteConfigManager {
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
        let blobStore = RemoteConfigBlobStore(
            fileManager: .default,
            directoryURL: cacheDirectoryURL.appendingPathComponent("blobs", isDirectory: true)
        )
        let sourceProvider = RemoteConfigSourceProvider(topicStore: diskCache)

        let systemInfo = SystemInfo(
            platformInfo: nil,
            finishTransactions: true,
            apiKey: apiKey,
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
            blobStore: blobStore,
            blobFetcher: RemoteConfigBlobFetcher(
                blobStore: blobStore,
                sourceProvider: sourceProvider,
                downloader: recorder
            ),
            currentUserProvider: ProductionTestUserProvider()
        )
    }

}

private struct ProductionTestUserProvider: CurrentUserProvider {
    var currentAppUserID: String { "remote-config-production-test-user" }
    var currentUserIsAnonymous: Bool { true }
}
