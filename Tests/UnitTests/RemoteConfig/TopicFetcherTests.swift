//
//  TopicFetcherTests.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 28/05/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import CryptoKit
import Foundation
import Nimble
import OHHTTPStubs
import OHHTTPStubsSwift
import XCTest

@testable import RevenueCat

final class TopicFetcherTests: TestCase {

    private var tempDir: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: self.tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        HTTPStubs.removeAllStubs()
        try? FileManager.default.removeItem(at: self.tempDir)
        super.tearDown()
    }

    // MARK: - Cache hit

    func testCacheHitReturnsNilWithoutDownloading() async throws {
        let payload = Data("{\"cached\":true}".utf8)
        let blobRef = sha256Hex(payload)
        let target = topicFile(topic: .productEntitlementMapping, blobRef: blobRef)
        try FileManager.default.createDirectory(
            at: target.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try payload.write(to: target)

        var downloadAttempted = false
        stub(condition: isHost("assets.example.com")) { _ in
            downloadAttempted = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        let error = await makeFetcher().fetchTopicIfNeeded(
            topic: .productEntitlementMapping,
            entryId: "default",
            topicEntry: .init(blobRef: blobRef),
            source: makeSource()
        )

        expect(error).to(beNil())
        expect(downloadAttempted).to(beFalse())
    }

    // MARK: - Download + verify

    func testDownloadVerifiesSHA256AndStoresAtExpectedPath() async {
        let payload = Data("{\"hello\":\"world\"}".utf8)
        let blobRef = sha256Hex(payload)
        stubDownload(url: "https://assets.example.com/\(blobRef)", data: payload)

        let error = await makeFetcher().fetchTopicIfNeeded(
            topic: .productEntitlementMapping,
            entryId: "default",
            topicEntry: .init(blobRef: blobRef),
            source: makeSource(urlFormat: "https://assets.example.com/{blob_ref}")
        )

        let target = topicFile(topic: .productEntitlementMapping, blobRef: blobRef)
        expect(error).to(beNil())
        expect(FileManager.default.fileExists(atPath: target.path)).to(beTrue())
        expect(try? Data(contentsOf: target)).to(equal(payload))
        expect(self.leftoverTempFiles(in: target.deletingLastPathComponent())).to(beEmpty())
    }

    func testDownloadSubstitutesBlobRefPlaceholderInURL() async {
        let payload = Data("{}".utf8)
        let blobRef = sha256Hex(payload)
        let expectedURL = "https://cdn.example.com/topics/\(blobRef)"

        var requestedURL: String?
        stub(condition: isAbsoluteURLString(expectedURL)) { request in
            requestedURL = request.url?.absoluteString
            return HTTPStubsResponse(data: payload, statusCode: 200, headers: nil)
        }

        let error = await makeFetcher().fetchTopicIfNeeded(
            topic: .productEntitlementMapping,
            entryId: "default",
            topicEntry: .init(blobRef: blobRef),
            source: makeSource(urlFormat: "https://cdn.example.com/topics/{blob_ref}")
        )

        expect(error).to(beNil())
        expect(requestedURL).to(equal(expectedURL))
    }

    // MARK: - Error cases

    func testDownloadSurfacesErrorWhenHTTPNon200() async {
        let payload = Data("{}".utf8)
        let blobRef = sha256Hex(payload)
        stubDownload(url: "https://assets.example.com/\(blobRef)", data: Data(), statusCode: 404)

        let error = await makeFetcher().fetchTopicIfNeeded(
            topic: .productEntitlementMapping,
            entryId: "default",
            topicEntry: .init(blobRef: blobRef),
            source: makeSource(urlFormat: "https://assets.example.com/{blob_ref}")
        )

        expect(error).toNot(beNil())
        let target = topicFile(topic: .productEntitlementMapping, blobRef: blobRef)
        expect(FileManager.default.fileExists(atPath: target.path)).to(beFalse())
    }

    func testDownloadSurfacesErrorOnNetworkFailure() async {
        let blobRef = String(repeating: "a", count: 64)
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        stub(condition: isHost("assets.example.com")) { _ in
            HTTPStubsResponse(error: networkError)
        }

        let error = await makeFetcher().fetchTopicIfNeeded(
            topic: .productEntitlementMapping,
            entryId: "default",
            topicEntry: .init(blobRef: blobRef),
            source: makeSource(urlFormat: "https://assets.example.com/{blob_ref}")
        )

        expect(error).toNot(beNil())
        let target = topicFile(topic: .productEntitlementMapping, blobRef: blobRef)
        expect(FileManager.default.fileExists(atPath: target.path)).to(beFalse())
        expect(self.leftoverTempFiles(in: target.deletingLastPathComponent())).to(beEmpty())
    }

    func testDownloadSurfacesErrorWhenSHA256Mismatch() async {
        let payload = Data("{\"actual\":\"contents\"}".utf8)
        let wrongBlobRef = String(repeating: "0", count: 64)
        stubDownload(url: "https://assets.example.com/\(wrongBlobRef)", data: payload)

        let error = await makeFetcher().fetchTopicIfNeeded(
            topic: .productEntitlementMapping,
            entryId: "default",
            topicEntry: .init(blobRef: wrongBlobRef),
            source: makeSource(urlFormat: "https://assets.example.com/{blob_ref}")
        )

        expect(error).toNot(beNil())
        let target = topicFile(topic: .productEntitlementMapping, blobRef: wrongBlobRef)
        expect(FileManager.default.fileExists(atPath: target.path)).to(beFalse())
        expect(self.leftoverTempFiles(in: target.deletingLastPathComponent())).to(beEmpty())
    }

    // MARK: - Write failure

    func testDownloadSurfacesErrorWhenRenameFails() async {
        let payload = Data("{\"hello\":\"world\"}".utf8)
        let blobRef = sha256Hex(payload)
        stubDownload(url: "https://assets.example.com/\(blobRef)", data: payload)

        let renameError = NSError(domain: NSCocoaErrorDomain, code: NSFileWriteUnknownError)
        let fetcher = TopicFetcher(
            fileManager: FailingReplaceFileManager(replaceItemAtError: renameError),
            baseCacheURL: self.tempDir
        )

        let error = await fetcher.fetchTopicIfNeeded(
            topic: .productEntitlementMapping,
            entryId: "default",
            topicEntry: .init(blobRef: blobRef),
            source: makeSource(urlFormat: "https://assets.example.com/{blob_ref}")
        )

        expect(error).toNot(beNil())
        let target = topicFile(topic: .productEntitlementMapping, blobRef: blobRef)
        expect(FileManager.default.fileExists(atPath: target.path)).to(beFalse())
        expect(self.leftoverTempFiles(in: target.deletingLastPathComponent())).to(beEmpty())
    }

    // MARK: - Multiple entries

    func testDownloadMultipleEntryIdsWriteToDistinctPaths() async {
        let payloadA = Data("{\"entryId\":\"A\"}".utf8)
        let payloadB = Data("{\"entryId\":\"B\"}".utf8)
        let blobRefA = sha256Hex(payloadA)
        let blobRefB = sha256Hex(payloadB)
        stubDownload(url: "https://assets.example.com/\(blobRefA)", data: payloadA)
        stubDownload(url: "https://assets.example.com/\(blobRefB)", data: payloadB)

        let fetcher = makeFetcher()
        let source = makeSource(urlFormat: "https://assets.example.com/{blob_ref}")

        let errorA = await fetcher.fetchTopicIfNeeded(
            topic: .productEntitlementMapping,
            entryId: "default",
            topicEntry: .init(blobRef: blobRefA),
            source: source
        )
        let errorB = await fetcher.fetchTopicIfNeeded(
            topic: .productEntitlementMapping,
            entryId: "EXPERIMENT_A",
            topicEntry: .init(blobRef: blobRefB),
            source: source
        )

        expect(errorA).to(beNil())
        expect(errorB).to(beNil())

        let targetA = topicFile(topic: .productEntitlementMapping, blobRef: blobRefA)
        let targetB = topicFile(topic: .productEntitlementMapping, blobRef: blobRefB)
        expect(FileManager.default.fileExists(atPath: targetA.path)).to(beTrue())
        expect(FileManager.default.fileExists(atPath: targetB.path)).to(beTrue())
        expect(targetA).toNot(equal(targetB))
        expect(try? Data(contentsOf: targetA)).to(equal(payloadA))
        expect(try? Data(contentsOf: targetB)).to(equal(payloadB))
    }

    // MARK: - Blob ref validation

    func testFetchTopicIfNeededRejectsMalformedBlobRef() async {
        var downloadAttempted = false
        stub(condition: isHost("assets.example.com")) { _ in
            downloadAttempted = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        let error = await makeFetcher().fetchTopicIfNeeded(
            topic: .productEntitlementMapping,
            entryId: "default",
            topicEntry: .init(blobRef: "not-valid!"),
            source: makeSource()
        )

        if case .unexpectedBackendResponse(.remoteConfigMalformedBlobRef, _, _) = error {
            // expected
        } else {
            fail("Expected .unexpectedBackendResponse(.remoteConfigMalformedBlobRef), got \(String(describing: error))")
        }
        expect(downloadAttempted).to(beFalse())
        let topicDir = tempDir
            .appendingPathComponent("RevenueCat/topics")
            .appendingPathComponent(RemoteConfigResponse.Topic.productEntitlementMapping.rawValue)
        expect(FileManager.default.fileExists(atPath: topicDir.path) &&
               (try? FileManager.default.contentsOfDirectory(atPath: topicDir.path))?.isEmpty == false
        ).to(beFalse())
    }

    func testFetchTopicIfNeededRejectsPathTraversalBlobRef() async {
        var downloadAttempted = false
        stub(condition: isHost("assets.example.com")) { _ in
            downloadAttempted = true
            return HTTPStubsResponse(data: Data(), statusCode: 200, headers: nil)
        }

        let error = await makeFetcher().fetchTopicIfNeeded(
            topic: .productEntitlementMapping,
            entryId: "default",
            topicEntry: .init(blobRef: "../../escape"),
            source: makeSource()
        )

        if case .unexpectedBackendResponse(.remoteConfigMalformedBlobRef, _, _) = error {
            // expected
        } else {
            fail("Expected .unexpectedBackendResponse(.remoteConfigMalformedBlobRef), got \(String(describing: error))")
        }
        expect(downloadAttempted).to(beFalse())
        let escapedTarget = tempDir.deletingLastPathComponent().appendingPathComponent("escape")
        expect(FileManager.default.fileExists(atPath: escapedTarget.path)).to(beFalse())
    }

    // MARK: - Cleanup

    func testCleanupDeletesFilesWhoseBlobRefIsNotInReferenceSet() async throws {
        let keptBlob = String(repeating: "a", count: 64)
        let staleBlob = String(repeating: "b", count: 64)
        let keptFile = try writeTopicFile(topic: .productEntitlementMapping, blobRef: keptBlob, byte: 1)
        let staleFile = try writeTopicFile(topic: .productEntitlementMapping, blobRef: staleBlob, byte: 2)

        await makeFetcher().cleanupUnreferencedTopics(
            referenced: [.productEntitlementMapping: [keptBlob]]
        )

        // Cleanup is dispatched on a detached task; assertions wait for it to complete.
        await expect(FileManager.default.fileExists(atPath: staleFile.path)).toEventually(beFalse())
        expect(FileManager.default.fileExists(atPath: keptFile.path)).to(beTrue())
    }

    func testCleanupDeletesEveryFileForTopicAbsentFromReferenceSet() async throws {
        let blobA = String(repeating: "a", count: 64)
        let blobB = String(repeating: "b", count: 64)
        let fileA = try writeTopicFile(topic: .productEntitlementMapping, blobRef: blobA, byte: 1)
        let fileB = try writeTopicFile(topic: .productEntitlementMapping, blobRef: blobB, byte: 2)

        await makeFetcher().cleanupUnreferencedTopics(referenced: [:])

        await expect(FileManager.default.fileExists(atPath: fileA.path)).toEventually(beFalse())
        await expect(FileManager.default.fileExists(atPath: fileB.path)).toEventually(beFalse())
    }

    func testCleanupIsNoOpWhenTopicsRootDoesNotExist() async {
        let topicsRoot = self.tempDir.appendingPathComponent("RevenueCat/topics")

        await makeFetcher().cleanupUnreferencedTopics(
            referenced: [.productEntitlementMapping: [String(repeating: "a", count: 64)]]
        )

        // Cleanup must not create the topics root itself.
        expect(FileManager.default.fileExists(atPath: topicsRoot.path)).to(beFalse())
    }

    func testCleanupSilentlySkipsTopicWhenContentsOfDirectoryFails() async throws {
        let blob = String(repeating: "a", count: 64)
        let file = try writeTopicFile(topic: .productEntitlementMapping, blobRef: blob, byte: 1)

        let fetcher = TopicFetcher(
            fileManager: ListingFailureFileManager(),
            baseCacheURL: self.tempDir
        )
        await fetcher.cleanupUnreferencedTopics(referenced: [:])

        // Listing failed silently — file is preserved, nothing crashes.
        expect(FileManager.default.fileExists(atPath: file.path)).to(beTrue())
    }

    func testCleanupKeepsTempFilesWithRcTopicPrefixUntouched() async throws {
        let staleBlob = String(repeating: "a", count: 64)
        let staleFile = try writeTopicFile(topic: .productEntitlementMapping, blobRef: staleBlob, byte: 1)
        let tempFile = staleFile.deletingLastPathComponent().appendingPathComponent("rc_topic_inflight.tmp")
        try Data([2]).write(to: tempFile)

        await makeFetcher().cleanupUnreferencedTopics(referenced: [:])

        await expect(FileManager.default.fileExists(atPath: staleFile.path)).toEventually(beFalse())
        expect(FileManager.default.fileExists(atPath: tempFile.path)).to(beTrue())
    }

    func testCleanupKeepsReferencedFileWhenOtherFilesInSameDirAreDeleted() async throws {
        let keptBlob = String(repeating: "c", count: 64)
        let staleBlob1 = String(repeating: "d", count: 64)
        let staleBlob2 = String(repeating: "e", count: 64)
        let kept = try writeTopicFile(topic: .productEntitlementMapping, blobRef: keptBlob, byte: 0)
        let stale1 = try writeTopicFile(topic: .productEntitlementMapping, blobRef: staleBlob1, byte: 1)
        let stale2 = try writeTopicFile(topic: .productEntitlementMapping, blobRef: staleBlob2, byte: 2)

        await makeFetcher().cleanupUnreferencedTopics(
            referenced: [.productEntitlementMapping: [keptBlob]]
        )

        await expect(FileManager.default.fileExists(atPath: stale1.path)).toEventually(beFalse())
        await expect(FileManager.default.fileExists(atPath: stale2.path)).toEventually(beFalse())
        expect(FileManager.default.fileExists(atPath: kept.path)).to(beTrue())
    }

    func testFetchTopicIfNeededAcceptsMixedCaseHexBlobRef() async {
        let mixedCaseHex = "ABCDEFabcdef" + String(repeating: "0", count: 52)
        let normalizedHex = mixedCaseHex.lowercased()
        // The blob ref is normalized to lowercase before use, so the URL and cache path use normalizedHex.
        stubDownload(url: "https://assets.example.com/\(normalizedHex)", data: Data("ignored".utf8))

        let error = await makeFetcher().fetchTopicIfNeeded(
            topic: .productEntitlementMapping,
            entryId: "default",
            topicEntry: .init(blobRef: mixedCaseHex),
            source: makeSource(urlFormat: "https://assets.example.com/{blob_ref}")
        )

        // Validation passes; download was attempted (SHA-256 will mismatch since "ignored" != normalizedHex)
        expect(error).toNot(beNil())
        let target = topicFile(topic: .productEntitlementMapping, blobRef: normalizedHex)
        expect(FileManager.default.fileExists(atPath: target.path)).to(beFalse())
    }

}

// MARK: - Helpers

private extension TopicFetcherTests {

    func makeFetcher() -> TopicFetcher {
        TopicFetcher(baseCacheURL: self.tempDir)
    }

    func makeSource(urlFormat: String = "https://assets.example.com/{blob_ref}") -> RemoteConfigResponse.BlobSource {
        RemoteConfigResponse.BlobSource(id: "primary", urlFormat: urlFormat, priority: 0, weight: 100)
    }

    func topicFile(topic: RemoteConfigResponse.Topic, blobRef: String) -> URL {
        self.tempDir
            .appendingPathComponent("RevenueCat/topics")
            .appendingPathComponent(topic.rawValue)
            .appendingPathComponent(blobRef)
    }

    func writeTopicFile(
        topic: RemoteConfigResponse.Topic,
        blobRef: String,
        byte: UInt8
    ) throws -> URL {
        let file = topicFile(topic: topic, blobRef: blobRef)
        try FileManager.default.createDirectory(
            at: file.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data([byte]).write(to: file)
        return file
    }

    func leftoverTempFiles(in dir: URL) -> [URL] {
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil
        )) ?? []
        return contents.filter { $0.lastPathComponent.hasPrefix("rc_topic_") }
    }

    func stubDownload(url: String, data: Data, statusCode: Int32 = 200) {
        stub(condition: isAbsoluteURLString(url)) { _ in
            HTTPStubsResponse(data: data, statusCode: statusCode, headers: nil)
        }
    }

    func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

}

private final class FailingReplaceFileManager: FileManaging {

    private let replaceItemAtError: Error
    private let base = FileManager.default

    init(replaceItemAtError: Error) {
        self.replaceItemAtError = replaceItemAtError
    }

    func fileExists(atPath path: String) -> Bool {
        base.fileExists(atPath: path)
    }

    func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes attr: [FileAttributeKey: Any]?
    ) throws {
        try base.createDirectory(at: url, withIntermediateDirectories: createIntermediates, attributes: attr)
    }

    func replaceItemAt(
        _ originalItemURL: URL,
        withItemAt newItemURL: URL,
        backupItemName: String?,
        options mask: FileManager.ItemReplacementOptions
    ) throws -> URL? {
        throw self.replaceItemAtError
    }

    func copyItem(at srcURL: URL, to dstURL: URL) throws {
        throw self.replaceItemAtError
    }

    func removeItem(at url: URL) throws {
        try base.removeItem(at: url)
    }

    func contentsOfDirectory(at url: URL) throws -> [URL] {
        try base.contentsOfDirectory(at: url)
    }

}

private final class ListingFailureFileManager: FileManaging {

    private let base = FileManager.default

    func fileExists(atPath path: String) -> Bool {
        base.fileExists(atPath: path)
    }

    func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes attr: [FileAttributeKey: Any]?
    ) throws {
        try base.createDirectory(at: url, withIntermediateDirectories: createIntermediates, attributes: attr)
    }

    func replaceItemAt(
        _ originalItemURL: URL,
        withItemAt newItemURL: URL,
        backupItemName: String?,
        options mask: FileManager.ItemReplacementOptions
    ) throws -> URL? {
        try base.replaceItemAt(
            originalItemURL,
            withItemAt: newItemURL,
            backupItemName: backupItemName,
            options: mask
        )
    }

    func copyItem(at srcURL: URL, to dstURL: URL) throws {
        try base.copyItem(at: srcURL, to: dstURL)
    }

    func removeItem(at url: URL) throws {
        try base.removeItem(at: url)
    }

    func contentsOfDirectory(at url: URL) throws -> [URL] {
        throw NSError(domain: NSCocoaErrorDomain, code: NSFileReadUnknownError)
    }

}
