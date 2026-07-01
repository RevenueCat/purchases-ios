//
//  RemoteConfigManager.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

protocol RemoteConfigManagerType: AnyObject {

    func refreshRemoteConfig(isAppBackgrounded: Bool)

    func clearCache()

}

/// Coordinates a single remote config refresh.
///
/// This manager currently owns only manifest replay, inline blob extraction, and config-state persistence.
// swiftlint:disable:next todo
/// TODO: Remove this interim scope once network blob fetching, topic handler dispatch, and SDK lifecycle wiring land.
final class RemoteConfigManager: RemoteConfigManagerType {

    private static let defaultDomain = "app"

    private let remoteConfigAPI: RemoteConfigAPIType
    private let diskCache: RemoteConfigDiskCacheType
    private let blobStore: RemoteConfigBlobStoreType
    private let currentUserProvider: CurrentUserProvider
    private let cacheLock = Lock()
    private var isRefreshing = false
    private var epoch = 0

    init(
        remoteConfigAPI: RemoteConfigAPIType,
        diskCache: RemoteConfigDiskCacheType,
        blobStore: RemoteConfigBlobStoreType,
        currentUserProvider: CurrentUserProvider
    ) {
        self.remoteConfigAPI = remoteConfigAPI
        self.diskCache = diskCache
        self.blobStore = blobStore
        self.currentUserProvider = currentUserProvider
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

        guard self.isCurrent(requestEpoch) else { return }

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

    /// Wipes cached remote config state, for example after an identity change.
    ///
    /// The epoch bump, refresh-guard release, and cache wipe are serialized with response persistence so a late
    /// response for a previous user is either fully persisted before the wipe or dropped after the epoch changes.
    func clearCache() {
        self.cacheLock.perform {
            self.epoch += 1
            self.isRefreshing = false
            self.diskCache.clear()
            self.blobStore.clear()
        }
    }

}

private extension RemoteConfigManager {

    func prepareRefreshIfNeeded() -> Int? {
        return self.cacheLock.perform {
            guard !self.isRefreshing else { return nil }
            self.isRefreshing = true
            return self.epoch
        }
    }

    @discardableResult
    func releaseGuardIfOwned(requestEpoch: Int) -> Bool {
        return self.cacheLock.perform {
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
        guard let container = fetchResult.container else {
            self.releaseGuardIfOwned(requestEpoch: requestEpoch)
            return
        }

        do {
            let response = try container.configElement.withDecodedPayloadBytes { bytes in
                try JSONDecoder.default.decode(
                    RemoteConfiguration.self,
                    from: Data(bytes)
                )
            }

            self.cacheLock.perform {
                guard self.epoch == requestEpoch else { return }
                self.persist(
                    container: container,
                    previous: previous,
                    response: response
                )
            }
        } catch {
            Logger.error(Strings.remoteConfig.failedToParseResponse(error))
        }

        self.releaseGuardIfOwned(requestEpoch: requestEpoch)
    }

    func handleFailure(
        _ error: BackendError,
        requestEpoch: Int
    ) {
        if self.releaseGuardIfOwned(requestEpoch: requestEpoch) {
            Logger.error(Strings.remoteConfig.refreshFailed(error))
        }
    }

    func isCurrent(_ requestEpoch: Int) -> Bool {
        return self.cacheLock.perform {
            self.epoch == requestEpoch
        }
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
                    try element.validateChecksum(decodedPayloadBytes: bytes)
                    self.blobStore.write(ref: ref, bytes: bytes)
                }
            } catch {
                Logger.error(Strings.remoteConfig.skippingInvalidBlob(ref))
            }
        }
    }

}

fileprivate extension RemoteConfiguration.Topics {

    /// All blob refs referenced by this topic collection.
    var blobRefs: Set<String> {
        return Set(self.entries.values.flatMap { $0.values.compactMap(\.blobRef) })
    }

}
