//
//  RemoteConfigManager.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

protocol RemoteConfigManagerType: AnyObject {

    func refreshRemoteConfig(isAppBackgrounded: Bool)

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
    private let dateProvider: DateProvider
    private let isRefreshing: Atomic<Bool> = false
    private let blobStore: RemoteConfigBlobStoreType

    init(
        remoteConfigAPI: RemoteConfigAPIType,
        diskCache: RemoteConfigDiskCacheType,
        blobStore: RemoteConfigBlobStoreType,
        dateProvider: DateProvider = DateProvider()
    ) {
        self.remoteConfigAPI = remoteConfigAPI
        self.diskCache = diskCache
        self.blobStore = blobStore
        self.dateProvider = dateProvider
    }

    func refreshRemoteConfig(isAppBackgrounded: Bool) {
        guard self.beginRefreshIfNeeded() else { return }

        let persisted = self.diskCache.read()
        let request = RemoteConfigRequest(
            domain: persisted?.domain ?? Self.defaultDomain,
            manifest: persisted?.manifest,
            prefetchedBlobs: self.cachedPrefetchedBlobRefs(from: persisted)
        )

        self.remoteConfigAPI.getRemoteConfig(
            request: request,
            isAppBackgrounded: isAppBackgrounded
        ) { [weak self] result in
            guard let self else { return }
            defer { self.endRefresh() }

            switch result {
            case let .success(fetchResult):
                self.persist(container: fetchResult.container, previous: persisted)
            case let .failure(error):
                Logger.error(Strings.remoteConfig.refreshFailed(error))
            }
        }
    }

}

private extension RemoteConfigManager {

    func beginRefreshIfNeeded() -> Bool {
        return self.isRefreshing.modify { isRefreshing in
            guard !isRefreshing else { return false }
            isRefreshing = true
            return true
        }
    }

    func endRefresh() {
        self.isRefreshing.value = false
    }

    /// Replays only requested prefetch blobs that are still present in the blob store.
    func cachedPrefetchedBlobRefs(from persisted: PersistedRemoteConfiguration?) -> [String] {
        return persisted?.prefetchBlobs.filter { self.blobStore.contains(ref: $0) } ?? []
    }

    /// Persists the config sync state and any valid inline blobs from a successful container response.
    func persist(
        container: RemoteConfigContainer?,
        previous: PersistedRemoteConfiguration?
    ) {
        guard let container else {
            self.persistLastRefreshAt(previous: previous)
            return
        }

        do {
            let response = try container.configElement.withPayloadBytes { bytes in
                try JSONDecoder.default.decode(
                    RemoteConfiguration.self,
                    from: Data(bytes)
                )
            }

            let postSyncTopicBlobRefs = self.postSyncTopicBlobRefs(
                previous: previous,
                response: response
            )
            let postSyncReferencedBlobRefs = self.postSyncReferencedBlobRefs(
                response: response,
                postSyncTopicBlobRefs: postSyncTopicBlobRefs
            )

            let persistedConfiguration = PersistedRemoteConfiguration(
                domain: response.domain,
                manifest: response.manifest,
                activeTopics: response.activeTopics,
                prefetchBlobs: response.prefetchBlobs,
                topicBlobRefs: postSyncTopicBlobRefs,
                lastRefreshAt: self.dateProvider.now()
            )

            guard self.diskCache.write(persistedConfiguration) else { return }

            self.extractInlineBlobs(from: container, keepingOnly: postSyncReferencedBlobRefs)
            self.blobStore.retainOnly(postSyncReferencedBlobRefs)
        } catch {
            Logger.error(Strings.remoteConfig.failedToParseResponse(error))
        }
    }

    func persistLastRefreshAt(previous: PersistedRemoteConfiguration?) {
        guard let previous else { return }

        self.diskCache.write(PersistedRemoteConfiguration(
            domain: previous.domain,
            manifest: previous.manifest,
            activeTopics: previous.activeTopics,
            prefetchBlobs: previous.prefetchBlobs,
            topicBlobRefs: previous.topicBlobRefs,
            lastRefreshAt: self.dateProvider.now()
        ))
    }

    /// Returns the topic blob refs that should be persisted after this response is applied.
    ///
    /// Changed topics overwrite previous refs, unchanged active topics keep previous refs, and inactive topics
    /// are removed.
    func postSyncTopicBlobRefs(
        previous: PersistedRemoteConfiguration?,
        response: RemoteConfiguration
    ) -> [String: [String]] {
        return (previous?.topicBlobRefs ?? [:])
            .merging(response.topics.topicBlobRefs) { _, changed in changed }
            .filter { topic, _ in response.activeTopics.contains(topic) }
    }

    /// Returns the post-sync set of blob refs the SDK should keep locally.
    ///
    /// This includes requested prefetch blobs plus blob refs used by active topics after merging changed
    /// response topics with previously persisted unchanged topics.
    func postSyncReferencedBlobRefs(
        response: RemoteConfiguration,
        postSyncTopicBlobRefs: [String: [String]]
    ) -> Set<String> {
        return Set(response.prefetchBlobs).union(postSyncTopicBlobRefs.values.flatMap { $0 })
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

            guard element.isChecksumValid() else {
                Logger.error(Strings.remoteConfig.skippingInvalidBlob(ref))
                continue
            }

            element.withPayloadBytes { bytes in
                self.blobStore.write(ref: ref, bytes: bytes)
            }
        }
    }

}

fileprivate extension RemoteConfiguration.Topics {

    /// The blob refs each changed topic's items reference, keyed by topic name.
    var topicBlobRefs: [String: [String]] {
        return self.entries.mapValues { topic in
            topic.values.compactMap(\.blobRef).sorted()
        }
    }

}
