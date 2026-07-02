//
//  RemoteConfigBlobFetcher.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

protocol RemoteConfigBlobFetcherType {

    func ensureDownloaded(ref: String) async -> Bool
    func ensureAllDownloaded(refs: [String]) async -> Bool
    func prefetch(refs: [String])

}

/// Downloads remote config blobs into the same content-addressed store used for inline blobs.
///
/// On-demand requests are high priority. Prefetches are low priority and can be boosted if a consumer
/// later requests the same ref before the download starts.
final class RemoteConfigBlobFetcher: RemoteConfigBlobFetcherType {

    private let scheduler: RemoteConfigBlobFetchScheduler

    init(
        blobStore: RemoteConfigBlobStoreType,
        sourceProvider: RemoteConfigSourceProviderType,
        downloader: RemoteConfigBlobDownloaderType = URLSessionRemoteConfigBlobDownloader()
    ) {
        self.scheduler = RemoteConfigBlobFetchScheduler(
            blobStore: blobStore,
            sourceProvider: sourceProvider,
            downloader: downloader
        )
    }

    /// Ensures a consumer-requested blob is available locally, enqueueing high-priority work if needed.
    func ensureDownloaded(ref: String) async -> Bool {
        return await self.scheduler.ensureDownloaded(ref: ref)
    }

    /// Ensures multiple consumer-requested blobs are available and returns whether all unique refs succeeded.
    func ensureAllDownloaded(refs: [String]) async -> Bool {
        return await self.scheduler.ensureAllDownloaded(refs: refs)
    }

    /// Starts best-effort low-priority downloads for refs the backend suggests warming.
    func prefetch(refs: [String]) {
        Task {
            await self.scheduler.prefetch(refs: refs)
        }
    }

}

private actor RemoteConfigBlobFetchScheduler {

    private enum Priority: Int {
        case low
        case high
    }

    private struct Download {
        let ref: String
        var priority: Priority
        var sequence: Int
        var continuations: [CheckedContinuation<Bool, Never>]
    }

    private static let maxConcurrentDownloads = 4
    private static let blobRefPlaceholder = "{blob_ref}"

    private let blobStore: RemoteConfigBlobStoreType
    private let sourceProvider: RemoteConfigSourceProviderType
    private let downloader: RemoteConfigBlobDownloaderType

    private var queued: [String: Download] = [:]
    private var activeContinuations: [String: [CheckedContinuation<Bool, Never>]] = [:]
    private var inFlight: Set<String> = []
    private var sequence = 0

    init(
        blobStore: RemoteConfigBlobStoreType,
        sourceProvider: RemoteConfigSourceProviderType,
        downloader: RemoteConfigBlobDownloaderType
    ) {
        self.blobStore = blobStore
        self.sourceProvider = sourceProvider
        self.downloader = downloader
    }

    /// Enqueues a high-priority consumer request and suspends until that ref resolves.
    func ensureDownloaded(ref: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            self.enqueue(
                ref: ref,
                priority: .high,
                continuation: continuation,
                restartsExhaustedSources: true
            )
        }
    }

    /// Fans out high-priority requests for each unique ref and succeeds only if every ref is available.
    func ensureAllDownloaded(refs: [String]) async -> Bool {
        let uniqueRefs = Array(Set(refs))

        return await withTaskGroup(of: Bool.self) { group in
            for ref in uniqueRefs {
                group.addTask {
                    return await self.ensureDownloaded(ref: ref)
                }
            }

            var allDownloaded = true
            for await result in group {
                allDownloaded = allDownloaded && result
            }

            return allDownloaded
        }
    }

    /// Enqueues low-priority work without a waiting continuation.
    func prefetch(refs: [String]) {
        let wouldDownload: (String) -> Bool = { ref in
            RemoteConfigBlobRefHelpers.isValid(ref) && !self.blobStore.contains(ref: ref)
        }

        if refs.contains(where: wouldDownload) {
            self.restartBlobSourcesIfExhausted()
        }

        for ref in refs {
            self.enqueue(ref: ref, priority: .low, continuation: nil)
        }
    }

    /// Performs the actual download, source failover, checksum validation, and disk write.
    private func downloadVerifyAndStore(ref: String) async -> Bool {
        guard RemoteConfigBlobRefHelpers.isValid(ref) else {
            Logger.error(Strings.remoteConfig.malformedBlobRef(ref))
            return false
        }

        guard !self.blobStore.contains(ref: ref) else {
            return true
        }

        while let source = self.sourceProvider.getCurrent(for: .blob) {
            guard let url = self.url(for: ref, source: source) else {
                Logger.error(Strings.remoteConfig.failedToBuildBlobURL(ref))
                self.sourceProvider.reportUnhealthy(source)
                continue
            }

            do {
                let data = try await self.downloader.data(from: url)
                return data.withUnsafeBytes { bytes in
                    guard RemoteConfigBlobRefHelpers.isValidPayload(bytes, expectedRef: ref) else {
                        Logger.error(Strings.remoteConfig.skippingInvalidBlob(ref))
                        return false
                    }

                    return self.blobStore.write(ref: ref, bytes: bytes)
                }
            } catch {
                Logger.error(Strings.remoteConfig.failedToDownloadBlob(ref, url, error))
                guard self.shouldReportSourceUnhealthy(for: error) else {
                    return false
                }

                self.sourceProvider.reportUnhealthy(source)
                if self.blobStore.contains(ref: ref) {
                    return true
                }
            }
        }

        Logger.error(Strings.remoteConfig.exhaustedBlobSources(ref))
        return false
    }

    /// Whether a download failure is a source-health signal rather than a request-specific outcome.
    private func shouldReportSourceUnhealthy(for error: Error) -> Bool {
        if error is CancellationError {
            return false
        }

        if let urlError = error as? URLError, urlError.code == .cancelled {
            return false
        }

        guard let downloaderError = error as? URLSessionRemoteConfigBlobDownloader.Error else {
            return true
        }

        switch downloaderError {
        case let .unexpectedStatusCode(statusCode):
            return statusCode != HTTPStatusCode.notFoundError.rawValue
        case .invalidResponse:
            return true
        }
    }

    /// Adds a ref to the scheduler, coalescing duplicate queued or in-flight requests.
    private func enqueue(
        ref: String,
        priority: Priority,
        continuation: CheckedContinuation<Bool, Never>?,
        restartsExhaustedSources: Bool = false
    ) {
        guard RemoteConfigBlobRefHelpers.isValid(ref) else {
            Logger.error(Strings.remoteConfig.malformedBlobRef(ref))
            continuation?.resume(returning: false)
            return
        }

        guard !self.blobStore.contains(ref: ref) else {
            continuation?.resume(returning: true)
            return
        }

        if restartsExhaustedSources {
            self.restartBlobSourcesIfExhausted()
        }

        // Coalesce duplicate queued requests into one future download, keeping every waiting consumer.
        if var download = self.queued[ref] {
            if let continuation {
                download.continuations.append(continuation)
            }
            // A consumer request upgrades queued prefetch work, but keeps it behind already queued high-priority work.
            if priority.rawValue > download.priority.rawValue {
                download.priority = priority
                download.sequence = self.nextSequence()
            }
            self.queued[ref] = download
            return
        }

        // If the download already started, only attach this consumer to the in-flight result.
        if self.inFlight.contains(ref) {
            if let continuation {
                self.activeContinuations[ref, default: []].append(continuation)
            }
            return
        }

        self.queued[ref] = Download(
            ref: ref,
            priority: priority,
            sequence: self.nextSequence(),
            continuations: continuation.map { [$0] } ?? []
        )
        self.scheduleDownloads()
    }

    /// Starts a new blob-source pass when a previous request exhausted every known source.
    private func restartBlobSourcesIfExhausted() {
        self.sourceProvider.restartIfExhausted(for: .blob)
    }

    /// Starts queued downloads until the concurrency limit is reached.
    private func scheduleDownloads() {
        while self.inFlight.count < Self.maxConcurrentDownloads,
              let download = self.nextDownload() {
            self.queued[download.ref] = nil
            self.inFlight.insert(download.ref)
            self.activeContinuations[download.ref] = download.continuations

            Task {
                let result = await self.downloadVerifyAndStore(ref: download.ref)
                self.complete(ref: download.ref, result: result)
            }
        }
    }

    /// Finishes one in-flight ref, wakes all waiting consumers, then fills any newly opened download slot.
    private func complete(ref: String, result: Bool) {
        let continuations = self.activeContinuations.removeValue(forKey: ref) ?? []
        self.inFlight.remove(ref)
        let resolvedResult = result || self.blobStore.contains(ref: ref)
        continuations.forEach { $0.resume(returning: resolvedResult) }

        self.scheduleDownloads()
    }

    /// Chooses the next queued item by priority first, then FIFO order within that priority.
    private func nextDownload() -> Download? {
        return self.queued.values.sorted {
            if $0.priority != $1.priority {
                return $0.priority.rawValue > $1.priority.rawValue
            }

            return $0.sequence < $1.sequence
        }.first
    }

    /// Returns a monotonically increasing sequence number used to preserve FIFO ordering.
    private func nextSequence() -> Int {
        defer { self.sequence += 1 }
        return self.sequence
    }

    /// Builds the concrete blob URL from a source format that contains the blob-ref placeholder.
    private func url(
        for ref: String,
        source: RemoteConfigSourceHandle
    ) -> URL? {
        // Blob sources are URL formats, not base URLs: the backend must provide the blob-ref placeholder.
        guard source.url.contains(Self.blobRefPlaceholder) else {
            return nil
        }

        return URL(string: source.url.replacingOccurrences(of: Self.blobRefPlaceholder, with: ref))
    }

}
