//
//  RemoteConfigDiskCache.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

protocol RemoteConfigDiskCacheType: AnyObject {

    func read() -> PersistedRemoteConfiguration?

    @discardableResult
    func write(_ configuration: PersistedRemoteConfiguration) -> Bool

    func clear()

}

struct PersistedRemoteConfiguration: Codable, Equatable {

    let domain: String
    let manifest: String
    let activeTopics: [String]
    let prefetchBlobs: [String]
    let topics: RemoteConfiguration.Topics

    init(
        domain: String = RemoteConfiguration.defaultDomain,
        manifest: String,
        activeTopics: [String] = [],
        prefetchBlobs: [String] = [],
        topics: RemoteConfiguration.Topics = .init()
    ) {
        self.domain = domain
        self.manifest = manifest
        self.activeTopics = activeTopics
        self.prefetchBlobs = prefetchBlobs
        self.topics = topics
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            domain: try container.decodeIfPresent(String.self, forKey: .domain) ?? RemoteConfiguration.defaultDomain,
            manifest: try container.decode(String.self, forKey: .manifest),
            activeTopics: try container.decodeIfPresent([String].self, forKey: .activeTopics) ?? [],
            prefetchBlobs: try container.decodeIfPresent([String].self, forKey: .prefetchBlobs) ?? [],
            topics: try container.decodeIfPresent(RemoteConfiguration.Topics.self, forKey: .topics) ?? .init()
        )
    }

    private enum CodingKeys: String, CodingKey {
        case domain
        case manifest
        case activeTopics
        case prefetchBlobs
        case topics
    }

}

final class RemoteConfigDiskCache: RemoteConfigDiskCacheType {

    private let cache: SynchronizedLargeItemCache

    init(
        cache: SynchronizedLargeItemCache = .init(
            cache: FileManager.default,
            basePath: RemoteConfigDiskCache.basePath,
            directoryType: RemoteConfigDiskCache.directoryType
        )
    ) {
        self.cache = cache
    }

    func read() -> PersistedRemoteConfiguration? {
        do {
            return try self.cache.value(forKey: Self.fileName)
        } catch {
            Logger.error(Strings.remoteConfig.failedToReadCache(error))
            return nil
        }
    }

    @discardableResult
    func write(_ configuration: PersistedRemoteConfiguration) -> Bool {
        let didWrite = self.cache.set(codable: configuration, forKey: Self.fileName)
        if !didWrite {
            Logger.error(Strings.remoteConfig.failedToWriteCache)
        }

        return didWrite
    }

    func clear() {
        self.cache.clear()
    }

}

/// Adapts the persisted remote configuration to the read-only `RemoteConfigTopicStoreType` that
/// `RemoteConfigSourceProvider` reads its `sources` topic from.
///
/// The provider reads the topic store on every source lookup (i.e. once per outgoing request), so this
/// snapshots the persisted topics once at init instead of hitting disk on that hot path. Before any
/// config has been fetched the snapshot is empty and the provider falls back to its embedded defaults.
///
/// - Note: The snapshot is not refreshed mid-session; a config fetched during the current session is
///   picked up on the next launch. A live, manager-updated topic store will replace this once the
///   remote-config lifecycle wiring lands.
final class RemoteConfigDiskCacheTopicStore: RemoteConfigTopicStoreType {

    private let topics: RemoteConfiguration.Topics

    init(diskCache: RemoteConfigDiskCacheType) {
        self.topics = diskCache.read()?.topics ?? .init()
    }

    func topic(_ name: String) -> RemoteConfiguration.ConfigTopic? {
        return self.topics.entries[name]
    }

}

extension RemoteConfigDiskCache {

    static let basePath = "remote_config"
    static let fileName = "remote_config.json"

    static var directoryType: DirectoryHelper.DirectoryType {
        #if os(tvOS)
        return .cache
        #else
        return .applicationSupport()
        #endif
    }

}
