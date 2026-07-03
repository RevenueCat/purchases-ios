//
//  RemoteConfigManager.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

protocol RemoteConfigManagerType: AnyObject {

    /// Whether remote config should be ignored for the current manager lifetime.
    var isDisabled: Bool { get }

    func refreshRemoteConfig(isAppBackgrounded: Bool)

    func refreshRemoteConfigIfStale(isAppBackgrounded: Bool)

    func clearCache()

    func close()

}

final class NoOpRemoteConfigManager: RemoteConfigManagerType {

    let isDisabled = true

    func refreshRemoteConfig(isAppBackgrounded: Bool) {}

    func refreshRemoteConfigIfStale(isAppBackgrounded: Bool) {}

    func clearCache() {}

    func close() {}

}

/// Coordinates a single remote config refresh.
///
/// This manager currently owns only manifest replay, inline blob extraction, and config-state persistence.
// swiftlint:disable:next todo
/// TODO: Remove this interim scope once topic handler dispatch and SDK lifecycle wiring land.
final class RemoteConfigManager: RemoteConfigManagerType {

    private static let defaultDomain = "app"

    private let remoteConfigAPI: RemoteConfigAPIType
    private let diskCache: RemoteConfigDiskCacheType
    private let blobStore: RemoteConfigBlobStoreType
    private let blobFetcher: RemoteConfigBlobFetcherType
    private let currentUserProvider: CurrentUserProvider
    private let dateProvider: DateProvider
    private let cacheDurationInSeconds: (Bool) -> TimeInterval
    private let lock = Lock()
    private var isRefreshing = false
    private var isDisabledInternal = false
    private var isClosed = false
    private var epoch = 0
    private var lastRefreshedAt: Date?

    init(
        remoteConfigAPI: RemoteConfigAPIType,
        diskCache: RemoteConfigDiskCacheType,
        blobStore: RemoteConfigBlobStoreType,
        blobFetcher: RemoteConfigBlobFetcherType,
        currentUserProvider: CurrentUserProvider,
        dateProvider: DateProvider = DateProvider(),
        cacheDurationInSeconds: @escaping (Bool) -> TimeInterval = { _ in 60 * 5.0 }
    ) {
        self.remoteConfigAPI = remoteConfigAPI
        self.diskCache = diskCache
        self.blobStore = blobStore
        self.blobFetcher = blobFetcher
        self.currentUserProvider = currentUserProvider
        self.dateProvider = dateProvider
        self.cacheDurationInSeconds = cacheDurationInSeconds
    }

    var isDisabled: Bool {
        return self.lock.perform {
            self.isDisabledInternal
        }
    }

    func refreshRemoteConfig(isAppBackgrounded: Bool) {
        guard let requestEpoch = self.prepareRefreshIfNeeded() else { return }

        let persisted = self.diskCache.read()
        let request = RemoteConfigRequest(
            appUserID: self.currentUserProvider.currentAppUserID,
            domain: persisted?.domain ?? Self.defaultDomain,
            manifest: persisted?.manifest,
            prefetchedBlobs: self.cachedPrefetchedBlobRefs(from: persisted)
        )

        self.enqueueRefreshIfCurrent(
            request: request,
            persisted: persisted,
            isAppBackgrounded: isAppBackgrounded,
            requestEpoch: requestEpoch
        )
    }

    func refreshRemoteConfigIfStale(isAppBackgrounded: Bool) {
        guard self.shouldRefresh(isAppBackgrounded: isAppBackgrounded) else { return }

        self.refreshRemoteConfig(isAppBackgrounded: isAppBackgrounded)
    }

    /// Wipes cached remote config state, for example after an identity change.
    ///
    /// The epoch bump, refresh-guard release, and cache wipe are serialized with response persistence so a late
    /// response for a previous user is either fully persisted before the wipe or dropped after the epoch changes.
    func clearCache() {
        self.lock.perform {
            self.epoch += 1
            self.isRefreshing = false
            self.lastRefreshedAt = nil
            self.diskCache.clear()
            self.blobStore.clear()
        }
    }

    func close() {
        self.lock.perform {
            self.epoch += 1
            self.isClosed = true
            self.isRefreshing = false
        }
    }

}

private extension RemoteConfigManager {

    func prepareRefreshIfNeeded() -> Int? {
        return self.lock.perform {
            guard !self.isRefreshing,
                  !self.isDisabledInternal,
                  !self.isClosed else { return nil }
            self.isRefreshing = true
            return self.epoch
        }
    }

    func shouldRefresh(isAppBackgrounded: Bool) -> Bool {
        return self.lock.perform {
            guard !self.isClosed else { return false }
            guard let lastRefreshedAt = self.lastRefreshedAt else { return true }

            return self.dateProvider.now().timeIntervalSince(lastRefreshedAt)
                > self.cacheDurationInSeconds(isAppBackgrounded)
        }
    }

    func enqueueRefreshIfCurrent(
        request: RemoteConfigRequest,
        persisted: PersistedRemoteConfiguration?,
        isAppBackgrounded: Bool,
        requestEpoch: Int
    ) {
        // Keep the epoch check and operation enqueue atomic with clearCache(), so a clear cannot slip in between them.
        // This assumes getRemoteConfig only registers/enqueues work and does not synchronously call its completion.
        self.lock.perform {
            guard self.epoch == requestEpoch else { return }

            self.remoteConfigAPI.getRemoteConfig(
                request: request,
                isAppBackgrounded: isAppBackgrounded
            ) { [weak self] result in
                guard let self else { return }

                switch result {
                case let .success(fetchResult):
                    self.handleSuccess(
                        fetchResult,
                        previous: persisted,
                        requestEpoch: requestEpoch
                    )
                case let .failure(error):
                    self.handleFailure(error, requestEpoch: requestEpoch)
                }
            }
        }
    }

    @discardableResult
    func releaseGuardIfOwned(requestEpoch: Int) -> Bool {
        return self.lock.perform {
            guard self.epoch == requestEpoch else { return false }
            self.isRefreshing = false
            return true
        }
    }

    func handleSuccess(
        _ fetchResult: RemoteConfigFetchResult,
        previous: PersistedRemoteConfiguration?,
        requestEpoch: Int
    ) {
        guard self.isCurrent(requestEpoch) else { return }
        defer { self.releaseGuardIfOwned(requestEpoch: requestEpoch) }

        guard let container = fetchResult.container else {
            self.markRefreshedIfCurrent(requestEpoch)
            return
        }

        do {
            let response = try container.configElement.withDecodedPayloadBytes { bytes in
                try JSONDecoder.default.decode(
                    RemoteConfiguration.self,
                    from: Data(bytes)
                )
            }

            self.lock.perform {
                guard self.epoch == requestEpoch else { return }
                self.persist(
                    container: container,
                    previous: previous,
                    response: response
                )
                self.markRefreshed()
            }
        } catch {
            Logger.error(Strings.remoteConfig.failedToParseResponse(error))
        }

    }

    func handleFailure(
        _ error: BackendError,
        requestEpoch: Int
    ) {
        let isCurrentFailure = self.lock.perform {
            guard self.epoch == requestEpoch else { return false }

            self.disableRefreshIfNeeded(for: error)
            self.isRefreshing = false

            return true
        }

        guard isCurrentFailure else { return }

        Logger.error(Strings.remoteConfig.refreshFailed(error))
    }

    func disableRefreshIfNeeded(for error: BackendError) {
        guard error.isRemoteConfigDisablingClientError else { return }

        self.isDisabledInternal = true
    }

    func isCurrent(_ requestEpoch: Int) -> Bool {
        return self.lock.perform {
            self.epoch == requestEpoch
        }
    }

    func markRefreshedIfCurrent(_ requestEpoch: Int) {
        self.lock.perform {
            guard self.epoch == requestEpoch else { return }

            self.markRefreshed()
        }
    }

    func markRefreshed() {
        self.lastRefreshedAt = self.dateProvider.now()
    }

    /// Replays only requested prefetch blobs that are still present in the blob store.
    func cachedPrefetchedBlobRefs(from persisted: PersistedRemoteConfiguration?) -> [String] {
        guard let persisted else { return [] }

        let cachedRefs = self.blobStore.cachedRefs()
        return persisted.prefetchBlobs.filter { cachedRefs.contains($0) }
    }

    /// Persists the config sync state and any valid inline blobs from a successful container response.
    func persist(
        container: RemoteConfigContainer,
        previous: PersistedRemoteConfiguration?,
        response: RemoteConfiguration
    ) {
        let postSyncTopics = self.postSyncTopics(
            previous: previous,
            response: response
        )
        let postSyncReferencedBlobRefs = self.postSyncReferencedBlobRefs(
            response: response,
            postSyncTopics: postSyncTopics
        )

        let persistedConfiguration = PersistedRemoteConfiguration(
            domain: response.domain,
            manifest: response.manifest,
            activeTopics: response.activeTopics,
            prefetchBlobs: response.prefetchBlobs,
            topics: postSyncTopics
        )

        guard self.diskCache.write(persistedConfiguration) else { return }

        self.extractInlineBlobs(from: container, keepingOnly: postSyncReferencedBlobRefs)
        self.blobStore.retainOnly(postSyncReferencedBlobRefs)
        self.blobFetcher.prefetch(refs: response.prefetchBlobs)
    }

    /// Returns the full topic index that should be persisted after this response is applied.
    ///
    /// Changed topics overwrite previous entries, unchanged active topics keep previous entries, and inactive topics
    /// are removed.
    func postSyncTopics(
        previous: PersistedRemoteConfiguration?,
        response: RemoteConfiguration
    ) -> RemoteConfiguration.Topics {
        let entries = (previous?.topics.entries ?? [:])
            .merging(response.topics.entries) { _, changed in changed }
            .filter { topic, _ in response.activeTopics.contains(topic) }

        return RemoteConfiguration.Topics(entries: entries)
    }

    /// Returns the post-sync set of blob refs the SDK should keep locally.
    ///
    /// This includes requested prefetch blobs plus blob refs used by active topics after merging changed
    /// response topics with previously persisted unchanged topics.
    func postSyncReferencedBlobRefs(
        response: RemoteConfiguration,
        postSyncTopics: RemoteConfiguration.Topics
    ) -> Set<String> {
        return Set(response.prefetchBlobs).union(postSyncTopics.blobRefs)
    }

    /// Writes valid inline content elements that are referenced by this config response.
    ///
    /// Invalid or unreferenced content elements are skipped because inline blobs are opportunistic cache entries.
    func extractInlineBlobs(
        from container: RemoteConfigContainer,
        keepingOnly referencedBlobRefs: Set<String>
    ) {
        for (ref, element) in container.inlineContentElements {
            guard referencedBlobRefs.contains(ref) else { continue }

            do {
                try element.withDecodedPayloadBytes { bytes in
                    guard RemoteConfigBlobRefHelpers.isValidPayload(bytes, expectedRef: ref) else {
                        throw RCContainer.Parser.FormatError.checksumMismatch(
                            expected: ref,
                            actual: RemoteConfigBlobRefHelpers.ref(for: bytes)
                        )
                    }

                    self.blobStore.write(ref: ref, bytes: bytes)
                }
            } catch {
                Logger.error(Strings.remoteConfig.skippingInvalidBlob(ref))
            }
        }
    }

}

private extension BackendError {

    /// Client errors disable remote config refreshes as a safety mechanism for the current manager lifetime.
    var isRemoteConfigDisablingClientError: Bool {
        guard case let .networkError(.errorResponse(_, statusCode, _)) = self else {
            return false
        }

        return 400...499 ~= statusCode.rawValue
    }

}

fileprivate extension RemoteConfiguration.Topics {

    /// All blob refs referenced by this topic collection.
    var blobRefs: Set<String> {
        return Set(self.entries.values.flatMap { $0.values.compactMap(\.blobRef) })
    }

}
