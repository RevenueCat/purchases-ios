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
/// This manager currently owns only manifest replay and config-state persistence.
// swiftlint:disable:next todo
/// TODO: Remove this interim scope once blob extraction, topic handler dispatch, and SDK lifecycle wiring land.
final class RemoteConfigManager: RemoteConfigManagerType {

    private static let defaultDomain = "app"

    private let remoteConfigAPI: RemoteConfigAPIType
    private let diskCache: RemoteConfigDiskCacheType
    private let dateProvider: DateProvider
    private let isRefreshing: Atomic<Bool> = false

    init(
        remoteConfigAPI: RemoteConfigAPIType,
        diskCache: RemoteConfigDiskCacheType,
        dateProvider: DateProvider = DateProvider()
    ) {
        self.remoteConfigAPI = remoteConfigAPI
        self.diskCache = diskCache
        self.dateProvider = dateProvider
    }

    func refreshRemoteConfig(isAppBackgrounded: Bool) {
        guard self.beginRefreshIfNeeded() else { return }

        let persisted = self.diskCache.read()
        let request = RemoteConfigRequest(
            domain: persisted?.domain ?? Self.defaultDomain,
            manifest: persisted?.manifest,
            prefetchedBlobs: persisted?.prefetchBlobs ?? []
        )

        self.remoteConfigAPI.getRemoteConfig(
            request: request,
            isAppBackgrounded: isAppBackgrounded
        ) { [weak self] result in
            guard let self else { return }
            defer { self.endRefresh() }

            switch result {
            case let .success(.container(container, _)):
                self.persist(container: container, previous: persisted)
            case .success(.noContent):
                break
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

    func persist(
        container: RCContainer,
        previous: PersistedRemoteConfiguration?
    ) {
        do {
            let response = try container.config.withPayloadBytes { bytes in
                try JSONDecoder.default.decode(
                    RemoteConfiguration.self,
                    from: Data(bytes)
                )
            }

            let topicBlobRefs = self.mergedTopicBlobRefs(
                previous: previous?.topicBlobRefs ?? [:],
                response: response
            )

            self.diskCache.write(PersistedRemoteConfiguration(
                domain: response.domain,
                manifest: response.manifest,
                activeTopics: response.activeTopics,
                prefetchBlobs: response.prefetchBlobs,
                topicBlobRefs: topicBlobRefs,
                lastRefreshAt: self.dateProvider.now()
            ))
        } catch {
            Logger.error(Strings.remoteConfig.failedToParseResponse(error))
        }
    }

    func mergedTopicBlobRefs(
        previous: [String: [String]],
        response: RemoteConfiguration
    ) -> [String: [String]] {
        return previous
            .merging(response.topics.topicBlobRefs) { _, changed in changed }
            .filter { topic, _ in response.activeTopics.contains(topic) }
    }

}
