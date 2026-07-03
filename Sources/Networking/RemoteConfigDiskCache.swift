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

    private let snapshot: Atomic<Snapshot> = .init(.notLoaded)

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
        return self.snapshot.modify { snapshot in
            switch snapshot {
            case .notLoaded:
                let configuration = self.readFromDisk()
                snapshot = .loaded(configuration)
                return configuration
            case .loaded(let configuration):
                return configuration
            }
        }
    }

    @discardableResult
    func write(_ configuration: PersistedRemoteConfiguration) -> Bool {
        let didWrite = self.cache.set(codable: configuration, forKey: Self.fileName)
        if didWrite {
            self.snapshot.value = .loaded(configuration)
        } else {
            Logger.error(Strings.remoteConfig.failedToWriteCache)
        }

        return didWrite
    }

    func clear() {
        self.cache.clear()
        self.snapshot.value = .loaded(nil)
    }

    private func readFromDisk() -> PersistedRemoteConfiguration? {
        do {
            return try self.cache.value(forKey: Self.fileName)
        } catch {
            Logger.error(Strings.remoteConfig.failedToReadCache(error))
            return nil
        }
    }

}

extension RemoteConfigDiskCache {

    /// In-memory snapshot of the persisted configuration, so `read()` only hits disk once.
    /// `.loaded(nil)` means we've already checked and nothing is persisted, avoiding repeated
    /// disk reads while no configuration exists.
    private enum Snapshot {
        case notLoaded
        case loaded(PersistedRemoteConfiguration?)
    }

}

extension RemoteConfigDiskCache: RemoteConfigTopicStoreType {

    func topic(_ name: String) -> RemoteConfiguration.ConfigTopic? {
        return self.read()?.topics.entries[name]
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
