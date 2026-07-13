//
//  RemoteConfigIntegrationTests.swift
//  UnitTests
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation
import Nimble
@preconcurrency @testable import RevenueCat
import XCTest

/// Integration-style tests for the remote config local pipeline.
///
/// These keep the production API operation, manager, disk cache, blob store, source provider, and blob fetcher
/// in play, while mocking only backend response bytes and blob downloads so responses stay deterministic.
final class RemoteConfigIntegrationTests: TestCase {

    private var rootURL: URL!
    private var systemInfo: MockSystemInfo!
    private var httpClient: MockHTTPClient!
    private var operationDispatcher: MockOperationDispatcher!
    private var diskCache: RemoteConfigDiskCache!
    private var blobStore: RemoteConfigBlobStore!
    private var sourceProvider: RemoteConfigSourceProvider!
    private var downloader: MockIntegrationBlobDownloader!
    private var remoteConfigAPI: RemoteConfigAPI!
    private var manager: RemoteConfigManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("RemoteConfigIntegrationTests-\(UUID().uuidString)", isDirectory: true)

        #if os(tvOS)
        let directoryType = DirectoryHelper.DirectoryType.cache
        #else
        let directoryType = DirectoryHelper.DirectoryType.applicationSupport(overrideURL: self.rootURL)
        #endif

        let cacheBasePath = "\(RemoteConfigDiskCache.basePath)-\(UUID().uuidString)"
        let synchronizedCache = SynchronizedLargeItemCache(
            cache: FileManager.default,
            basePath: cacheBasePath,
            directoryType: directoryType
        )
        let cacheDirectoryURL = try XCTUnwrap(DirectoryHelper.baseUrl(for: directoryType))
            .appendingPathComponent(cacheBasePath, isDirectory: true)

        self.diskCache = RemoteConfigDiskCache(cache: synchronizedCache)
        self.blobStore = RemoteConfigBlobStore(
            fileManager: .default,
            directoryURL: cacheDirectoryURL.appendingPathComponent("blobs", isDirectory: true)
        )
        self.sourceProvider = RemoteConfigSourceProvider(topicStore: self.diskCache)
        self.downloader = MockIntegrationBlobDownloader()
        self.systemInfo = MockSystemInfo(finishTransactions: false)
        self.httpClient = MockHTTPClient(
            systemInfo: self.systemInfo,
            eTagManager: MockETagManager(),
            diagnosticsTracker: nil,
            sourceTestFile: #file
        )
        self.httpClient.disableSnapshotTesting()
        self.operationDispatcher = MockOperationDispatcher()
        self.remoteConfigAPI = RemoteConfigAPI(backendConfig: BackendConfiguration(
            httpClient: self.httpClient,
            operationDispatcher: self.operationDispatcher,
            operationQueue: MockBackend.QueueProvider.createBackendQueue(),
            diagnosticsQueue: MockBackend.QueueProvider.createDiagnosticsQueue(),
            systemInfo: self.systemInfo,
            offlineCustomerInfoCreator: MockOfflineCustomerInfoCreator(),
            dateProvider: MockDateProvider(stubbedNow: MockBackend.referenceDate)
        ))
        self.manager = self.createManager(blobStore: self.blobStore)
    }

    override func tearDownWithError() throws {
        self.manager.close()
        try? FileManager.default.removeItem(at: self.rootURL)

        self.manager = nil
        self.remoteConfigAPI = nil
        self.downloader = nil
        self.sourceProvider = nil
        self.blobStore = nil
        self.diskCache = nil
        self.operationDispatcher = nil
        self.httpClient = nil
        self.systemInfo = nil
        self.rootURL = nil

        try super.tearDownWithError()
    }

    func testUncompressedConfigAndInlineBlobCanBeReadThroughFacade() async throws {
        let blob = #"{"workflow":"inline"}"#.asData
        let ref = RCContainerTestData.blobRef(for: blob)
        let container = try Self.containerData(
            topics: Self.workflowTopic(ref: ref),
            contentElements: [(blob, .none)]
        )

        await self.refresh(with: container)

        let maybeData = await self.manager.blobData(for: .workflows, itemKey: "default")
        let data = try XCTUnwrap(maybeData)
        let requestedURLs = await self.downloader.requestedURLs()

        expect(data) == blob
        expect(requestedURLs).to(beEmpty())
    }

    func testGzipConfigAndInlineBlobCanBeReadThroughFacade() async throws {
        let blob = Data(repeating: UInt8(ascii: "g"), count: 2048)
        let ref = RCContainerTestData.blobRef(for: blob)
        let container = try Self.containerData(
            topics: Self.workflowTopic(ref: ref),
            configEncoding: .gzip,
            contentElements: [(blob, .gzip)]
        )

        await self.refresh(with: container)

        let maybeData = await self.manager.blobData(for: .workflows, itemKey: "default")
        let data = try XCTUnwrap(maybeData)
        let requestedURLs = await self.downloader.requestedURLs()

        expect(data) == blob
        expect(requestedURLs).to(beEmpty())
    }

    func testBrotliConfigAndInlineBlobCanBeReadThroughFacade() async throws {
        guard RCContainer.Element.ContentEncoding.brotli.isSupported else {
            throw XCTSkip("Brotli compression is only available on newer Apple OS versions.")
        }

        let blob = Data(repeating: UInt8(ascii: "b"), count: 2048)
        let ref = RCContainerTestData.blobRef(for: blob)
        let container = try Self.containerData(
            topics: Self.workflowTopic(ref: ref),
            configEncoding: .brotli,
            contentElements: [(blob, .brotli)]
        )

        await self.refresh(with: container)

        let maybeData = await self.manager.blobData(for: .workflows, itemKey: "default")
        let data = try XCTUnwrap(maybeData)
        let requestedURLs = await self.downloader.requestedURLs()

        expect(data) == blob
        expect(requestedURLs).to(beEmpty())
    }

    func testMixedCompressionContainerStoresDecodedInlineBlobs() async throws {
        guard RCContainer.Element.ContentEncoding.brotli.isSupported else {
            throw XCTSkip("Brotli compression is only available on newer Apple OS versions.")
        }

        let smallBlob = #"{"workflow":"small"}"#.asData
        let gzipBlob = Data(repeating: UInt8(ascii: "g"), count: 2048)
        let brotliBlob = Data(repeating: UInt8(ascii: "b"), count: 2048)
        let smallRef = RCContainerTestData.blobRef(for: smallBlob)
        let gzipRef = RCContainerTestData.blobRef(for: gzipBlob)
        let brotliRef = RCContainerTestData.blobRef(for: brotliBlob)
        let container = try Self.containerData(
            topics: Self.workflowTopic(items: [
                "small": .init(blobRef: smallRef),
                "gzip": .init(blobRef: gzipRef),
                "brotli": .init(blobRef: brotliRef)
            ]),
            configEncoding: .gzip,
            contentElements: [
                (smallBlob, .none),
                (gzipBlob, .gzip),
                (brotliBlob, .brotli)
            ]
        )

        await self.refresh(with: container)

        let smallData = await self.manager.blobData(for: .workflows, itemKey: "small")
        let gzipData = await self.manager.blobData(for: .workflows, itemKey: "gzip")
        let brotliData = await self.manager.blobData(for: .workflows, itemKey: "brotli")
        let requestedURLs = await self.downloader.requestedURLs()

        expect(smallData) == smallBlob
        expect(gzipData) == gzipBlob
        expect(brotliData) == brotliBlob
        expect(requestedURLs).to(beEmpty())
    }

    func testUnsupportedInlineBlobEncodingIsSkipped() async throws {
        let blob = #"{"workflow":"unsupported"}"#.asData
        let ref = RCContainerTestData.blobRef(for: blob)
        let container = try Self.containerData(
            topics: Self.workflowTopic(ref: ref),
            contentElements: [(blob, .zstd)]
        )

        await self.refresh(with: container)

        let data = await self.manager.blobData(for: .workflows, itemKey: "default")
        let requestedURLs = await self.downloader.requestedURLs()

        expect(data).to(beNil())
        expect(requestedURLs).to(beEmpty())
    }

    func testExternalBlobDownloadsStoresAndReadsThroughFacade() async throws {
        let blob = #"{"workflow":"external"}"#.asData
        let ref = RCContainerTestData.blobRef(for: blob)
        let source = Self.blobSource("primary")
        let container = try Self.containerData(topics: Self.topics(
            sources: Self.sourcesTopic(blobSources: [source]),
            workflows: Self.workflowTopic(ref: ref)
        ))
        await self.downloader.setResponse(.success(blob), for: source, ref: ref)
        await self.refresh(with: container)

        let maybeData = await self.manager.blobData(for: .workflows, itemKey: "default")
        let data = try XCTUnwrap(maybeData)
        let requestedURLs = await self.downloader.requestedURLStrings()

        expect(data) == blob
        expect(requestedURLs) == [Self.url(source, ref: ref)]
        expect(self.blobStore.read(ref: ref)) == blob
    }

    func testFallbackConfigDownloadsExternalBlobThroughFacade() async throws {
        let blob = #"{"workflow":"fallback"}"#.asData
        let ref = RCContainerTestData.blobRef(for: blob)
        let source = Self.blobSource("primary")
        let topics = Self.topics(
            sources: Self.sourcesTopic(blobSources: [source]),
            workflows: Self.workflowTopic(ref: ref)
        )
        await self.downloader.setResponse(.success(blob), for: source, ref: ref)

        await self.refreshFromFallback(with: try Self.configData(topics: topics))

        let maybeData = await self.manager.blobData(for: .workflows, itemKey: "default")
        let data = try XCTUnwrap(maybeData)
        let requestedURLs = await self.downloader.requestedURLStrings()

        expect(data) == blob
        expect(requestedURLs) == [Self.url(source, ref: ref)]
        expect(self.blobStore.read(ref: ref)) == blob
    }

    func testMixedInlineAndExternalBlobsOnlyDownloadsExternalBlob() async throws {
        let inlineBlob = #"{"workflow":"inline"}"#.asData
        let externalBlob = #"{"workflow":"external"}"#.asData
        let inlineRef = RCContainerTestData.blobRef(for: inlineBlob)
        let externalRef = RCContainerTestData.blobRef(for: externalBlob)
        let source = Self.blobSource("primary")
        let container = try Self.containerData(
            topics: Self.topics(
                sources: Self.sourcesTopic(blobSources: [source]),
                workflows: Self.workflowTopic(items: [
                    "inline": .init(blobRef: inlineRef),
                    "external": .init(blobRef: externalRef)
                ])
            ),
            contentElements: [(inlineBlob, .none)]
        )
        await self.downloader.setResponse(.success(externalBlob), for: source, ref: externalRef)
        await self.refresh(with: container)

        let maybeInlineData = await self.manager.blobData(for: .workflows, itemKey: "inline")
        let maybeExternalData = await self.manager.blobData(for: .workflows, itemKey: "external")
        let inlineData = try XCTUnwrap(maybeInlineData)
        let externalData = try XCTUnwrap(maybeExternalData)
        let requestedURLs = await self.downloader.requestedURLStrings()

        expect(inlineData) == inlineBlob
        expect(externalData) == externalBlob
        expect(requestedURLs) == [Self.url(source, ref: externalRef)]
    }

    func testInlineBlobWriteFailureFallsBackToExternalBlobDownload() async throws {
        let blob = #"{"workflow":"inline-write-failed"}"#.asData
        let ref = RCContainerTestData.blobRef(for: blob)
        let source = Self.blobSource("primary")
        let failingBlobStore = FailsFirstWriteBlobStore(delegate: self.blobStore)
        let container = try Self.containerData(
            topics: Self.topics(
                sources: Self.sourcesTopic(blobSources: [source]),
                workflows: Self.workflowTopic(ref: ref)
            ),
            contentElements: [(blob, .none)]
        )
        self.manager.close()
        self.manager = self.createManager(blobStore: failingBlobStore)
        await self.downloader.setResponse(.success(blob), for: source, ref: ref)

        await self.refresh(with: container)
        await self.waitUntil(file: #filePath, line: #line) {
            failingBlobStore.writeCount == 1
        }

        expect(failingBlobStore.writeCount) == 1
        expect(self.blobStore.read(ref: ref)).to(beNil())

        let maybeData = await self.manager.blobData(for: .workflows, itemKey: "default")
        let data = try XCTUnwrap(maybeData)
        let requestedURLs = await self.downloader.requestedURLStrings()

        expect(data) == blob
        expect(requestedURLs) == [Self.url(source, ref: ref)]
        expect(self.blobStore.read(ref: ref)) == blob
    }

    func testBlobDownloadFailsOverToNextSourceForSameBlob() async throws {
        let blob = #"{"workflow":"fallback"}"#.asData
        let ref = RCContainerTestData.blobRef(for: blob)
        let primary = Self.blobSource("primary")
        let backup = Self.blobSource("backup", priority: 10)
        let container = try Self.containerData(topics: Self.topics(
            sources: Self.sourcesTopic(blobSources: [primary, backup]),
            workflows: Self.workflowTopic(ref: ref)
        ))
        await self.downloader.setResponse(.failure(RemoteConfigIntegrationTestError()), for: primary, ref: ref)
        await self.downloader.setResponse(.success(blob), for: backup, ref: ref)
        await self.refresh(with: container)

        let maybeData = await self.manager.blobData(for: .workflows, itemKey: "default")
        let data = try XCTUnwrap(maybeData)
        let requestedURLs = await self.downloader.requestedURLStrings()

        expect(data) == blob
        expect(requestedURLs) == [
            Self.url(primary, ref: ref),
            Self.url(backup, ref: ref)
        ]
    }

    func testExhaustedBlobSourcesRestartOnLaterOnDemandRead() async throws {
        let blob = #"{"workflow":"recovered"}"#.asData
        let ref = RCContainerTestData.blobRef(for: blob)
        let primary = Self.blobSource("primary")
        let backup = Self.blobSource("backup", priority: 10)
        let container = try Self.containerData(topics: Self.topics(
            sources: Self.sourcesTopic(blobSources: [primary, backup]),
            workflows: Self.workflowTopic(ref: ref)
        ))
        await self.downloader.setResponses([
            .failure(RemoteConfigIntegrationTestError()),
            .success(blob)
        ], for: primary, ref: ref)
        await self.downloader.setResponse(.failure(RemoteConfigIntegrationTestError()), for: backup, ref: ref)
        await self.refresh(with: container)

        let firstAttempt = await self.manager.blobData(for: .workflows, itemKey: "default")
        let maybeRecovered = await self.manager.blobData(for: .workflows, itemKey: "default")
        let recovered = try XCTUnwrap(maybeRecovered)
        let requestedURLs = await self.downloader.requestedURLStrings()

        expect(firstAttempt).to(beNil())
        expect(recovered) == blob
        expect(requestedURLs) == [
            Self.url(primary, ref: ref),
            Self.url(backup, ref: ref),
            Self.url(primary, ref: ref)
        ]
    }

    func testNoBlobSourceLeavesExternalBlobUnavailable() async throws {
        let blob = #"{"workflow":"missing-source"}"#.asData
        let ref = RCContainerTestData.blobRef(for: blob)
        let container = try Self.containerData(topics: Self.workflowTopic(ref: ref))

        await self.refresh(with: container)

        let data = await self.manager.blobData(for: .workflows, itemKey: "default")
        let requestedURLs = await self.downloader.requestedURLs()

        expect(data).to(beNil())
        expect(requestedURLs).to(beEmpty())
    }

    func testNoContentDuringOnDemandReadCompletesWithoutMutation() async throws {
        self.mockRemoteConfigResponse(statusCode: .noContent, body: Data())

        let task = Task {
            await self.manager.topic(.workflows)
        }

        let topic = await task.value

        expect(topic).to(beNil())
        expect(self.diskCache.read()).to(beNil())
        expect(self.blobStore.cachedRefs()).to(beEmpty())
    }

    func testInformationalFailedVerificationStillPersistsResponse() async throws {
        let blob = #"{"workflow":"informational"}"#.asData
        let ref = RCContainerTestData.blobRef(for: blob)
        let container = try Self.containerData(
            topics: Self.workflowTopic(ref: ref),
            contentElements: [(blob, .none)]
        )

        await self.refresh(with: container, verificationResult: .failed)

        expect(self.diskCache.read()?.manifest) == Self.manifest
        let data = await self.manager.blobData(for: .workflows, itemKey: "default")
        expect(data) == blob
    }

    func testEnforcedVerificationFailureDoesNotPersistResponse() async throws {
        self.mockRemoteConfigError(.signatureVerificationFailed(
            path: HTTPRequest.Path.remoteConfig(domain: RemoteConfiguration.defaultDomain),
            code: .success
        ))

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        await self.waitForRemoteConfigRequestCount(1)

        expect(self.diskCache.read()).to(beNil())
        expect(self.blobStore.cachedRefs()).to(beEmpty())
    }

    func testFetchedSourcesTopicReplacesEmbeddedAPIDefault() async throws {
        expect(self.sourceProvider.getCurrent(for: .api)?.url) == "https://api.revenuecat.com/"

        let fetchedAPI = RemoteConfigSource(url: "https://api.example.com/", priority: 0, weight: 1)
        let container = try Self.containerData(topics: .init(entries: [
            RemoteConfigTopic.sources.wireName: Self.sourcesTopic(apiSources: [fetchedAPI])
        ]))

        await self.refresh(with: container)

        expect(self.sourceProvider.getCurrent(for: .api)?.url) == fetchedAPI.url
    }

    func testNoSourcesTopicUsesEmbeddedAPIDefaultAndNoBlobDefault() async throws {
        let container = try Self.containerData(topics: Self.workflowTopic(ref: "unused"))

        await self.refresh(with: container)

        expect(self.sourceProvider.getCurrent(for: .api)?.url) == "https://api.revenuecat.com/"
        expect(self.sourceProvider.getCurrent(for: .blob)).to(beNil())
    }

    func testChecksumInvalidInlineBlobIsSkippedWhileValidInlineBlobIsStored() async throws {
        let validBlob = #"{"workflow":"valid"}"#.asData
        let invalidBlob = #"{"workflow":"invalid"}"#.asData
        let checksumMismatchedBlob = #"{"workflow":"tampered"}"#.asData
        let validRef = RCContainerTestData.blobRef(for: validBlob)
        let invalidRef = RCContainerTestData.blobRef(for: invalidBlob)
        let container = RCContainerTestData.container(
            config: try Self.configData(topics: Self.workflowTopic(items: [
                "valid": .init(blobRef: validRef),
                "invalid": .init(blobRef: invalidRef)
            ])),
            contentElements: [validBlob, checksumMismatchedBlob],
            checksumOverride: { index, data in
                return index == 2
                    ? RCContainerTestData.checksum(for: invalidBlob)
                    : RCContainerTestData.checksum(for: data)
            }
        )

        await self.refresh(with: container)

        let validData = await self.manager.blobData(for: .workflows, itemKey: "valid")
        let invalidData = await self.manager.blobData(for: .workflows, itemKey: "invalid")

        expect(validData) == validBlob
        expect(invalidData).to(beNil())
    }

    func testDuplicateBlobRefsAreStoredAndRetainedOnce() async throws {
        let blob = #"{"workflow":"shared"}"#.asData
        let ref = RCContainerTestData.blobRef(for: blob)
        let container = try Self.containerData(
            topics: Self.workflowTopic(items: [
                "first": .init(blobRef: ref),
                "second": .init(blobRef: ref)
            ]),
            contentElements: [(blob, .none)]
        )

        await self.refresh(with: container)

        await self.waitForCachedBlobRefs([ref])
        let firstData = await self.manager.blobData(for: .workflows, itemKey: "first")
        let secondData = await self.manager.blobData(for: .workflows, itemKey: "second")

        expect(firstData) == blob
        expect(secondData) == blob
    }

    func testEndpointDisabledPreventsReadTriggeredNetworkWork() async throws {
        self.mockRemoteConfigError(Self.disablingNetworkError)

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        await self.waitForRemoteConfigRequestCount(1)

        let topic = await self.manager.topic(.workflows)
        let data = await self.manager.blobData(for: .workflows, itemKey: "default")

        expect(topic).to(beNil())
        expect(data).to(beNil())
        expect(self.manager.isDisabled) == true
        let requestedURLs = await self.downloader.requestedURLs()

        expect(self.remoteConfigRequestCount) == 1
        expect(requestedURLs).to(beEmpty())
    }

    func testMalformedRawContainerResponseDoesNotPersistConfigOrBlobs() async throws {
        self.mockRemoteConfigResponse(body: #"{"not":"an rc container"}"#.asData)

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        await self.waitForRemoteConfigRequestCount(1)

        expect(self.diskCache.read()).to(beNil())
        expect(self.blobStore.cachedRefs()).to(beEmpty())
    }

}

private extension RemoteConfigIntegrationTests {

    static let manifest = "v1.1710000100.workflows:etag1,sources:etag1"

    static var disablingNetworkError: NetworkError {
        return .errorResponse(
            .init(code: .unknownError, originalCode: BackendErrorCode.unknownError.rawValue),
            .invalidRequest
        )
    }

    func createManager(blobStore: RemoteConfigBlobStoreType) -> RemoteConfigManager {
        return RemoteConfigManager(
            remoteConfigAPI: self.remoteConfigAPI,
            diskCache: self.diskCache,
            blobStore: blobStore,
            blobFetcher: RemoteConfigBlobFetcher(
                blobStore: blobStore,
                sourceProvider: self.sourceProvider,
                downloader: self.downloader
            ),
            currentUserProvider: MockCurrentUserProvider(mockAppUserID: "integration-test-user")
        )
    }

    func refresh(
        with body: Data,
        verificationResult: VerificationResult = .verified
    ) async {
        self.mockRemoteConfigResponse(body: body, verificationResult: verificationResult)

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        await self.waitForRemoteConfigRequestCount(1)
        await self.waitForPersistedManifest(Self.manifest)
    }

    func refreshFromFallback(
        with body: Data,
        verificationResult: VerificationResult = .verified
    ) async {
        self.mockRemoteConfigError(.errorResponse(
            .init(code: .unknownError, originalCode: BackendErrorCode.unknownError.rawValue),
            .internalServerError
        ))
        self.mockRemoteConfigFallbackResponse(body: body, verificationResult: verificationResult)

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        await self.waitForRemoteConfigRequestCount(1)
        await self.waitForRemoteConfigFallbackRequestCount(1)
        await self.waitForPersistedManifest(Self.manifest)
    }

    func mockRemoteConfigResponse(
        statusCode: HTTPStatusCode = .success,
        body: Data,
        verificationResult: VerificationResult = .verified
    ) {
        self.httpClient.mock(
            requestPath: HTTPRequest.Path.remoteConfig(domain: RemoteConfiguration.defaultDomain),
            response: .init(statusCode: statusCode, body: body, verificationResult: verificationResult)
        )
    }

    func mockRemoteConfigFallbackResponse(
        statusCode: HTTPStatusCode = .success,
        body: Data,
        verificationResult: VerificationResult = .verified
    ) {
        self.httpClient.mock(
            requestPath: HTTPRequest.FallbackPath.remoteConfig(domain: RemoteConfiguration.defaultDomain),
            response: .init(statusCode: statusCode, body: body, verificationResult: verificationResult)
        )
    }

    func mockRemoteConfigError(_ error: NetworkError) {
        self.httpClient.mock(
            requestPath: HTTPRequest.Path.remoteConfig(domain: RemoteConfiguration.defaultDomain),
            response: .init(error: error)
        )
    }

    var remoteConfigRequestCount: Int {
        return self.httpClient.calls.filter {
            $0.request.path.url == HTTPRequest.Path.remoteConfig(domain: RemoteConfiguration.defaultDomain).url
        }.count
    }

    var remoteConfigFallbackRequestCount: Int {
        return self.httpClient.calls.filter {
            $0.request.path.url
                == HTTPRequest.FallbackPath.remoteConfig(domain: RemoteConfiguration.defaultDomain).url
        }.count
    }

    func waitForRemoteConfigRequestCount(
        _ count: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        await self.waitUntil(file: file, line: line) {
            self.remoteConfigRequestCount >= count
        }
    }

    func waitForRemoteConfigFallbackRequestCount(
        _ count: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        await self.waitUntil(file: file, line: line) {
            self.remoteConfigFallbackRequestCount >= count
        }
    }

    func waitForPersistedManifest(
        _ manifest: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        await self.waitUntil(file: file, line: line) {
            self.diskCache.read()?.manifest == manifest
        }
    }

    /// Waits until the blob store reflects the expected refs.
    ///
    /// Inline blobs are written after the manifest within the same persist pass, so a persisted manifest does not
    /// guarantee the blobs are on disk yet. Tests reading the blob store directly should wait on this instead.
    func waitForCachedBlobRefs(
        _ refs: Set<String>,
        file: FileString = #filePath,
        line: UInt = #line
    ) async {
        await expect(file: file, line: line, self.blobStore.cachedRefs())
            .toEventually(equal(refs), timeout: .seconds(2), pollInterval: .milliseconds(10))
    }

    func waitUntil(
        file: StaticString,
        line: UInt,
        condition: @escaping () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            if condition() {
                return
            }

            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        XCTFail("Timed out waiting for remote config integration condition", file: file, line: line)
    }

    static func containerData(
        topics: RemoteConfiguration.ConfigTopic,
        configEncoding: RCContainer.Element.ContentEncoding = .none,
        contentElements: [(Data, RCContainer.Element.ContentEncoding)] = []
    ) throws -> Data {
        return try self.containerData(
            topics: .init(entries: [
                RemoteConfigTopic.workflows.wireName: topics
            ]),
            configEncoding: configEncoding,
            contentElements: contentElements
        )
    }

    static func containerData(
        topics: RemoteConfiguration.Topics,
        configEncoding: RCContainer.Element.ContentEncoding = .none,
        contentElements: [(Data, RCContainer.Element.ContentEncoding)] = []
    ) throws -> Data {
        return try RCContainerTestData.compressedContainer(
            config: self.configData(topics: topics),
            configEncoding: configEncoding,
            contentElements: contentElements.map { ($0.0, $0.1) }
        )
    }

    static func configData(topics: RemoteConfiguration.ConfigTopic) throws -> Data {
        return try self.configData(topics: .init(entries: [
            RemoteConfigTopic.workflows.wireName: topics
        ]))
    }

    static func configData(topics: RemoteConfiguration.Topics) throws -> Data {
        return try JSONEncoder.default.encode(RemoteConfiguration(
            domain: RemoteConfiguration.defaultDomain,
            manifest: Self.manifest,
            activeTopics: Array(topics.entries.keys),
            topics: topics
        ))
    }

    static func topics(
        sources: RemoteConfiguration.ConfigTopic,
        workflows: RemoteConfiguration.ConfigTopic
    ) -> RemoteConfiguration.Topics {
        return .init(entries: [
            RemoteConfigTopic.sources.wireName: sources,
            RemoteConfigTopic.workflows.wireName: workflows
        ])
    }

    static func workflowTopic(ref: String) -> RemoteConfiguration.ConfigTopic {
        return self.workflowTopic(items: [
            "default": .init(blobRef: ref)
        ])
    }

    static func workflowTopic(items: RemoteConfiguration.ConfigTopic) -> RemoteConfiguration.ConfigTopic {
        return items
    }

    static func sourcesTopic(
        apiSources: [RemoteConfigSource] = [],
        blobSources: [RemoteConfigSource] = []
    ) -> RemoteConfiguration.ConfigTopic {
        var topic: RemoteConfiguration.ConfigTopic = [:]
        if !apiSources.isEmpty {
            topic["api"] = .init(content: [
                "sources": .array(apiSources.map { self.sourceObject($0, key: "url") })
            ])
        }
        if !blobSources.isEmpty {
            topic["blob"] = .init(content: [
                "sources": .array(blobSources.map { self.sourceObject($0, key: "url_format") })
            ])
        }

        return topic
    }

    static func sourceObject(
        _ source: RemoteConfigSource,
        key: String
    ) -> AnyDecodable {
        return .object([
            key: .string(source.url),
            "priority": .int(source.priority),
            "weight": .int(source.weight)
        ])
    }

    static func blobSource(
        _ name: String,
        priority: Int = 0
    ) -> RemoteConfigSource {
        return .init(
            url: "https://\(name).example.com/blobs/{blob_ref}",
            priority: priority,
            weight: 1
        )
    }

    static func url(
        _ source: RemoteConfigSource,
        ref: String
    ) -> String {
        return source.url.replacingOccurrences(of: "{blob_ref}", with: ref)
    }

}

private final class FailsFirstWriteBlobStore: RemoteConfigBlobStoreType {

    private let delegate: RemoteConfigBlobStoreType
    private let lock = Lock(.nonRecursive)
    private var remainingWriteFailures = 1
    private var writeCountValue = 0

    var writeCount: Int {
        return self.lock.perform { self.writeCountValue }
    }

    init(delegate: RemoteConfigBlobStoreType) {
        self.delegate = delegate
    }

    func contains(ref: String) -> Bool {
        return self.delegate.contains(ref: ref)
    }

    func read(ref: String) -> Data? {
        return self.delegate.read(ref: ref)
    }

    func write(
        ref: String,
        bytes: UnsafeRawBufferPointer
    ) -> Bool {
        let shouldFail = self.lock.perform {
            self.writeCountValue += 1
            guard self.remainingWriteFailures == 0 else {
                self.remainingWriteFailures -= 1
                return true
            }

            return false
        }
        if shouldFail {
            return false
        }

        return self.delegate.write(ref: ref, bytes: bytes)
    }

    func cachedRefs() -> Set<String> {
        return self.delegate.cachedRefs()
    }

    func retainOnly(_ refs: Set<String>) {
        self.delegate.retainOnly(refs)
    }

    func clear() {
        self.delegate.clear()
    }

}

private actor MockIntegrationBlobDownloader: RemoteConfigBlobDownloaderType {

    private var responses: [String: [Result<Data, Error>]] = [:]
    private var requests: [URL] = []

    func data(from url: URL) async throws -> Data {
        self.requests.append(url)
        let key = url.absoluteString
        guard var queue = self.responses[key],
              !queue.isEmpty else {
            throw RemoteConfigIntegrationTestError()
        }

        let result = queue.removeFirst()
        self.responses[key] = queue
        return try result.get()
    }

    func setResponse(
        _ response: Result<Data, Error>,
        for source: RemoteConfigSource,
        ref: String
    ) {
        self.setResponses([response], for: source, ref: ref)
    }

    func setResponses(
        _ responses: [Result<Data, Error>],
        for source: RemoteConfigSource,
        ref: String
    ) {
        self.responses[RemoteConfigIntegrationTests.url(source, ref: ref)] = responses
    }

    func requestedURLs() -> [URL] {
        return self.requests
    }

    func requestedURLStrings() -> [String] {
        return self.requests.map(\.absoluteString)
    }

}

private struct RemoteConfigIntegrationTestError: Error {}
