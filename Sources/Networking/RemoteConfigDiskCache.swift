//
//  RemoteConfigDiskCache.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

protocol RemoteConfigDiskCacheType: AnyObject {

    func read() -> PersistedRemoteConfiguration?

    func write(_ configuration: PersistedRemoteConfiguration)

}

struct PersistedRemoteConfiguration: Codable, Equatable {

    let domain: String
    let manifest: String
    let activeTopics: [String]
    let prefetchBlobs: [String]
    let topicBlobRefs: [String: [String]]
    let lastRefreshAt: Date?

    init(
        domain: String,
        manifest: String,
        activeTopics: [String],
        prefetchBlobs: [String],
        topicBlobRefs: [String: [String]],
        lastRefreshAt: Date?
    ) {
        self.domain = domain
        self.manifest = manifest
        self.activeTopics = activeTopics
        self.prefetchBlobs = prefetchBlobs
        self.topicBlobRefs = topicBlobRefs
        self.lastRefreshAt = lastRefreshAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            domain: try container.decodeIfPresent(String.self, forKey: .domain) ?? RemoteConfiguration.defaultDomain,
            manifest: try container.decode(String.self, forKey: .manifest),
            activeTopics: try container.decodeIfPresent([String].self, forKey: .activeTopics) ?? [],
            prefetchBlobs: try container.decodeIfPresent([String].self, forKey: .prefetchBlobs) ?? [],
            topicBlobRefs: try container.decodeIfPresent([String: [String]].self, forKey: .topicBlobRefs) ?? [:],
            lastRefreshAt: try container.decodeIfPresent(Date.self, forKey: .lastRefreshAt)
        )
    }

    private enum CodingKeys: String, CodingKey {
        case domain
        case manifest
        case activeTopics
        case prefetchBlobs
        case topicBlobRefs
        case lastRefreshAt
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

    func write(_ configuration: PersistedRemoteConfiguration) {
        guard self.cache.cacheURL != nil else {
            Logger.error(Strings.remoteConfig.cacheURLNotAvailable)
            return
        }

        if !self.cache.set(codable: configuration, forKey: Self.fileName) {
            Logger.error(Strings.remoteConfig.failedToWriteCache)
        }
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
