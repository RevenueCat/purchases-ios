//
//  RemoteConfigBlobFetcherTests.swift
//  UnitTests
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

final class RemoteConfigBlobFetcherTests: TestCase {

    private var blobStore: MockFetcherBlobStore!
    private var downloader: SuspendingRemoteConfigBlobDownloader!
    private var sourceProvider: RemoteConfigSourceProvider!
    private var fetcher: RemoteConfigBlobFetcher!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.blobStore = MockFetcherBlobStore()
        self.downloader = SuspendingRemoteConfigBlobDownloader()
        self.sourceProvider = Self.sourceProvider(url: Self.templateURL)
        self.fetcher = RemoteConfigBlobFetcher(
            blobStore: self.blobStore,
            sourceProvider: self.sourceProvider,
            downloader: self.downloader
        )
    }

    override func tearDownWithError() throws {
        self.downloader.cancelAll()
        self.fetcher = nil
        self.sourceProvider = nil
        self.downloader = nil
        self.blobStore = nil

        try super.tearDownWithError()
    }

    func testCachedBlobReturnsTrueWithoutNetwork() async {
        let ref = Self.ref(for: "cached".asData)
        self.blobStore.stubbedContainsRefs = [ref]

        let result = await self.fetcher.ensureDownloaded(ref: ref)

        expect(result) == true
        expect(self.downloader.requestedRefs).to(beEmpty())
        expect(self.blobStore.invokedWriteCount) == 0
    }

    func testMalformedRefReturnsFalseWithoutSourceNetworkOrStoreAccess() async {
        let result = await self.fetcher.ensureDownloaded(ref: "not-a-valid-ref")

        expect(result) == false
        expect(self.downloader.requestedRefs).to(beEmpty())
        expect(self.blobStore.invokedContainsRefs).to(beEmpty())
        expect(self.blobStore.invokedWriteCount) == 0
    }

    func testDownloadsFromPlaceholderURLVerifiesAndStoresBlob() async throws {
        let payload = "a blob payload".asData
        let ref = Self.ref(for: payload)

        let task = Task { await self.fetcher.ensureDownloaded(ref: ref) }
        await self.downloader.waitForRequestCount(1)
        self.downloader.complete(ref: ref, with: .success(payload))

        let result = await task.value

        expect(result) == true
        expect(self.downloader.requestedURLs.map(\.absoluteString)) == [
            Self.templateURL.replacingOccurrences(of: Self.placeholder, with: ref)
        ]
        expect(self.blobStore.invokedWriteParameters?.ref) == ref
        expect(self.blobStore.invokedWriteParameters?.data) == payload
    }

    func testSourceWithoutBlobRefPlaceholderReturnsFalseWithoutNetwork() async {
        let ref = Self.ref(for: "missing placeholder".asData)
        self.sourceProvider = Self.sourceProvider(url: Self.urlWithoutPlaceholder)
        self.fetcher = RemoteConfigBlobFetcher(
            blobStore: self.blobStore,
            sourceProvider: self.sourceProvider,
            downloader: self.downloader
        )

        let result = await self.fetcher.ensureDownloaded(ref: ref)

        expect(result) == false
        expect(self.downloader.requestedURLs).to(beEmpty())
        expect(self.blobStore.invokedWriteCount) == 0
    }

    func testSourceWithoutBlobRefPlaceholderRetriesNextSource() async {
        let payload = "valid fallback".asData
        let ref = Self.ref(for: payload)
        self.sourceProvider = Self.sourceProvider(urls: [
            Self.urlWithoutPlaceholder,
            Self.backupTemplateURL
        ])
        self.fetcher = RemoteConfigBlobFetcher(
            blobStore: self.blobStore,
            sourceProvider: self.sourceProvider,
            downloader: self.downloader
        )

        let task = Task { await self.fetcher.ensureDownloaded(ref: ref) }
        await self.downloader.waitForRequestCount(1)
        self.downloader.complete(ref: ref, with: .success(payload))

        let result = await task.value

        expect(result) == true
        expect(self.downloader.requestedURLs.map(\.absoluteString)) == [
            Self.backupTemplateURL.replacingOccurrences(of: Self.placeholder, with: ref)
        ]
        expect(self.blobStore.invokedWriteParameters?.data) == payload
    }

    func testChecksumMismatchReturnsFalseAndDoesNotWrite() async {
        let ref = Self.ref(for: "expected".asData)

        let task = Task { await self.fetcher.ensureDownloaded(ref: ref) }
        await self.downloader.waitForRequestCount(1)
        self.downloader.complete(ref: ref, with: .success("tampered".asData))

        let result = await task.value
        expect(result) == false
        expect(self.blobStore.invokedWriteCount) == 0
    }

    func testNetworkFailureReturnsFalseAndDoesNotWrite() async {
        let ref = Self.ref(for: "failing".asData)

        let task = Task { await self.fetcher.ensureDownloaded(ref: ref) }
        await self.downloader.waitForRequestCount(1)
        self.downloader.complete(ref: ref, with: .failure(TestError()))

        let result = await task.value
        expect(result) == false
        expect(self.blobStore.invokedWriteCount) == 0
    }

    func testNetworkFailureRetriesNextSource() async {
        let payload = "fallback payload".asData
        let ref = Self.ref(for: payload)
        self.sourceProvider = Self.sourceProvider(urls: [
            Self.templateURL,
            Self.backupTemplateURL
        ])
        self.fetcher = RemoteConfigBlobFetcher(
            blobStore: self.blobStore,
            sourceProvider: self.sourceProvider,
            downloader: self.downloader
        )

        let task = Task { await self.fetcher.ensureDownloaded(ref: ref) }
        await self.downloader.waitForRequestCount(1)
        self.downloader.complete(ref: ref, with: .failure(TestError()))
        await self.downloader.waitForRequestCount(2)
        self.downloader.complete(ref: ref, with: .success(payload))

        let result = await task.value

        expect(result) == true
        expect(self.downloader.requestedURLs.map(\.absoluteString)) == [
            Self.templateURL.replacingOccurrences(of: Self.placeholder, with: ref),
            Self.backupTemplateURL.replacingOccurrences(of: Self.placeholder, with: ref)
        ]
        expect(self.blobStore.invokedWriteParameters?.data) == payload
    }

    func testNotFoundDoesNotMarkSourceUnhealthyOrRetryNextSource() async {
        let missingRef = Self.ref(for: "missing blob".asData)
        let availablePayload = "available blob".asData
        let availableRef = Self.ref(for: availablePayload)
        self.sourceProvider = Self.sourceProvider(urls: [
            Self.templateURL,
            Self.backupTemplateURL
        ])
        self.fetcher = RemoteConfigBlobFetcher(
            blobStore: self.blobStore,
            sourceProvider: self.sourceProvider,
            downloader: self.downloader
        )

        let missing = Task { await self.fetcher.ensureDownloaded(ref: missingRef) }
        await self.downloader.waitForRequestCount(1)
        self.downloader.complete(
            ref: missingRef,
            with: .failure(URLSessionRemoteConfigBlobDownloader.Error.unexpectedStatusCode(404))
        )

        let missingResult = await missing.value
        expect(missingResult) == false

        let available = Task { await self.fetcher.ensureDownloaded(ref: availableRef) }
        await self.downloader.waitForRequestCount(2)
        self.downloader.complete(ref: availableRef, with: .success(availablePayload))

        let availableResult = await available.value
        expect(availableResult) == true
        expect(self.downloader.requestedURLs.map(\.absoluteString)) == [
            Self.templateURL.replacingOccurrences(of: Self.placeholder, with: missingRef),
            Self.templateURL.replacingOccurrences(of: Self.placeholder, with: availableRef)
        ]
    }

    func testNetworkFailureReturnsTrueWhenBlobIsCachedConcurrently() async {
        let ref = Self.ref(for: "cached concurrently".asData)

        let task = Task { await self.fetcher.ensureDownloaded(ref: ref) }
        await self.downloader.waitForRequestCount(1)
        self.blobStore.stubbedContainsRefs.insert(ref)
        self.downloader.complete(ref: ref, with: .failure(TestError()))

        let result = await task.value
        expect(result) == true
        expect(self.blobStore.invokedWriteCount) == 0
    }

    func testWriteFailureReturnsFalseWhenBlobWasNotCached() async {
        let payload = "unpersisted".asData
        let ref = Self.ref(for: payload)
        self.blobStore.stubbedWriteResult = false

        let task = Task { await self.fetcher.ensureDownloaded(ref: ref) }
        await self.downloader.waitForRequestCount(1)
        self.downloader.complete(ref: ref, with: .success(payload))

        let result = await task.value
        expect(result) == false
        expect(self.blobStore.invokedWriteCount) == 1
    }

    func testMissingSourceReturnsFalse() async {
        self.sourceProvider = Self.sourceProvider(urls: [])
        self.fetcher = RemoteConfigBlobFetcher(
            blobStore: self.blobStore,
            sourceProvider: self.sourceProvider,
            downloader: self.downloader
        )
        let ref = Self.ref(for: "missing source".asData)

        let result = await self.fetcher.ensureDownloaded(ref: ref)

        expect(result) == false
        expect(self.downloader.requestedRefs).to(beEmpty())
    }

    func testConcurrentRequestsForSameRefShareSingleDownload() async {
        let payload = "shared".asData
        let ref = Self.ref(for: payload)

        let first = Task { await self.fetcher.ensureDownloaded(ref: ref) }
        await self.downloader.waitForRequestCount(1)
        let second = Task { await self.fetcher.ensureDownloaded(ref: ref) }
        await self.downloader.waitForRequestCount(1)
        self.downloader.complete(ref: ref, with: .success(payload))

        let firstResult = await first.value
        let secondResult = await second.value
        expect(firstResult) == true
        expect(secondResult) == true
        expect(self.downloader.requestedRefs) == [ref]
        expect(self.blobStore.invokedWriteCount) == 1
    }

    func testDifferentRefsRunConcurrentlyUpToWorkerLimit() async {
        let refs = (0..<6).map { Self.ref(for: "blob-\($0)".asData) }

        self.fetcher.prefetch(refs: refs)

        await self.downloader.waitForRequestCount(4)
        expect(self.downloader.activeRequestCount) == 4

        self.downloader.complete(ref: refs[0], with: .success("blob-0".asData))
        await self.downloader.waitForRequestCount(5)
        expect(Array(self.downloader.requestedRefs.prefix(4))) == Array(refs.prefix(4))
    }

    func testPrefetchSchedulesLowPriorityRefs() async {
        let refs = (0..<4).map { Self.ref(for: "prefetch-\($0)".asData) }

        self.fetcher.prefetch(refs: refs)

        await self.downloader.waitForRequestCount(4)
        expect(Set(self.downloader.requestedRefs)) == Set(refs)
    }

    func testOnDemandRequestRunsBeforeQueuedPrefetches() async {
        let prefetchRefs = (0..<5).map { Self.ref(for: "prefetch-\($0)".asData) }
        let onDemandPayload = "on demand".asData
        let onDemandRef = Self.ref(for: onDemandPayload)

        self.fetcher.prefetch(refs: prefetchRefs)
        await self.downloader.waitForRequestCount(4)

        let onDemand = Task { await self.fetcher.ensureDownloaded(ref: onDemandRef) }
        await self.waitForScheduledTaskToReachFetcher()
        self.downloader.complete(ref: prefetchRefs[0], with: .success("prefetch-0".asData))

        await self.downloader.waitForRequestCount(5)
        expect(self.downloader.requestedRefs[4]) == onDemandRef

        self.downloader.complete(ref: onDemandRef, with: .success(onDemandPayload))
        let result = await onDemand.value
        expect(result) == true
    }

    func testOnDemandRequestBoostsAndJoinsQueuedPrefetch() async {
        let prefetchRefs = (0..<5).map { Self.ref(for: "prefetch-\($0)".asData) }
        let boostedPayload = "boosted".asData
        let boostedRef = Self.ref(for: boostedPayload)

        self.fetcher.prefetch(refs: prefetchRefs + [boostedRef])
        await self.downloader.waitForRequestCount(4)

        let boosted = Task { await self.fetcher.ensureDownloaded(ref: boostedRef) }
        await self.waitForScheduledTaskToReachFetcher()
        self.downloader.complete(ref: prefetchRefs[0], with: .success("prefetch-0".asData))

        await self.downloader.waitForRequestCount(5)
        expect(self.downloader.requestedRefs[4]) == boostedRef
        expect(self.downloader.requestedRefs.filter { $0 == boostedRef }).to(haveCount(1))

        self.downloader.complete(ref: boostedRef, with: .success(boostedPayload))
        let result = await boosted.value
        expect(result) == true
    }

    func testEnsureAllDownloadedReturnsFalseWhenAnyRefFails() async {
        let successPayload = "success".asData
        let successRef = Self.ref(for: successPayload)
        let failureRef = Self.ref(for: "failure".asData)

        let task = Task { await self.fetcher.ensureAllDownloaded(refs: [successRef, failureRef]) }
        await self.downloader.waitForRequestCount(2)
        self.downloader.complete(ref: successRef, with: .success(successPayload))
        self.downloader.complete(ref: failureRef, with: .failure(TestError()))

        let result = await task.value
        expect(result) == false
    }

}

private extension RemoteConfigBlobFetcherTests {

    static let placeholder = "{blob_ref}"
    static let templateURL = "https://config.revenuecat-static.com/\(placeholder)"
    static let backupTemplateURL = "https://config-backup.revenuecat-static.com/\(placeholder)"
    static let urlWithoutPlaceholder = "https://config.revenuecat-static.com/blobs"

    static func sourceProvider(url: String) -> RemoteConfigSourceProvider {
        return self.sourceProvider(urls: [url])
    }

    static func sourceProvider(urls: [String]) -> RemoteConfigSourceProvider {
        let sourcesTopic: RemoteConfiguration.ConfigTopic = [
            "blob": RemoteConfiguration.ConfigItem(content: [
                "sources": .array(urls.enumerated().map { priority, url in
                    .object([
                        "url_format": .string(url),
                        "priority": .int(priority),
                        "weight": .int(1)
                    ])
                })
            ])
        ]

        return RemoteConfigSourceProvider(
            topicStore: BlobFetcherSourceTopicStore(sourcesTopic)
        )
    }

    static func ref(for data: Data) -> String {
        return data.withUnsafeBytes { RemoteConfigBlobRefHelpers.ref(for: $0) }
    }

    func waitForScheduledTaskToReachFetcher() async {
        await Task.yield()
        try? await Task.sleep(nanoseconds: 50_000_000)
    }

    struct TestError: Error { }

}

private final class BlobFetcherSourceTopicStore: RemoteConfigTopicStoreType {

    private let sourcesTopic: RemoteConfiguration.ConfigTopic?

    init(_ sourcesTopic: RemoteConfiguration.ConfigTopic?) {
        self.sourcesTopic = sourcesTopic
    }

    func topic(_ name: String) -> RemoteConfiguration.ConfigTopic? {
        return name == "sources" ? self.sourcesTopic : nil
    }

}

private final class MockFetcherBlobStore: RemoteConfigBlobStoreType {

    var stubbedContainsRefs: Set<String> = []
    var stubbedWriteResult = true

    private(set) var invokedContainsRefs: [String] = []
    private(set) var invokedWriteCount = 0
    private(set) var invokedWriteParameters: (ref: String, data: Data)?

    func contains(ref: String) -> Bool {
        self.invokedContainsRefs.append(ref)
        return self.stubbedContainsRefs.contains(ref)
    }

    func read(ref: String) -> Data? {
        return nil
    }

    @discardableResult
    func write(
        ref: String,
        bytes: UnsafeRawBufferPointer
    ) -> Bool {
        self.invokedWriteCount += 1
        var data = Data()
        data.append(contentsOf: bytes.bindMemory(to: UInt8.self))
        self.invokedWriteParameters = (ref, data)
        if self.stubbedWriteResult {
            self.stubbedContainsRefs.insert(ref)
        }
        return self.stubbedWriteResult
    }

    func cachedRefs() -> Set<String> {
        return self.stubbedContainsRefs
    }

    func retainOnly(_ refs: Set<String>) { }

    func clear() { }

}

private final class SuspendingRemoteConfigBlobDownloader: RemoteConfigBlobDownloaderType {

    private struct PendingRequest {
        let url: URL
        let continuation: CheckedContinuation<Data, Error>
    }

    private let lock = Lock()
    private var pendingRequests: [PendingRequest] = []
    private var requestedURLHistory: [URL] = []

    var requestedURLs: [URL] {
        return self.lock.perform { self.requestedURLHistory }
    }

    var requestedRefs: [String] {
        return self.requestedURLs.map(\.lastPathComponent)
    }

    var activeRequestCount: Int {
        return self.lock.perform { self.pendingRequests.count }
    }

    func data(from url: URL) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            self.lock.perform {
                self.requestedURLHistory.append(url)
                self.pendingRequests.append(PendingRequest(url: url, continuation: continuation))
            }
        }
    }

    func complete(ref: String, with result: Result<Data, Error>) {
        let request = self.lock.perform {
            guard let index = self.pendingRequests.firstIndex(where: { $0.url.lastPathComponent == ref }) else {
                return nil as PendingRequest?
            }

            return self.pendingRequests.remove(at: index)
        }

        switch result {
        case let .success(data):
            request?.continuation.resume(returning: data)
        case let .failure(error):
            request?.continuation.resume(throwing: error)
        }
    }

    func waitForRequestCount(
        _ count: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            if self.requestedURLs.count >= count {
                return
            }

            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        XCTFail("Timed out waiting for \(count) requests", file: file, line: line)
    }

    func cancelAll() {
        let requests = self.lock.perform { () -> [PendingRequest] in
            let requests = self.pendingRequests
            self.pendingRequests = []
            return requests
        }

        requests.forEach { $0.continuation.resume(throwing: CancellationError()) }
    }

}
