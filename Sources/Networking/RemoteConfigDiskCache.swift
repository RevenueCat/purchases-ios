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
    let manifest: RemoteConfigManifestToken
    let activeTopics: [String]
    let prefetchBlobs: [String]
    let topicBlobRefs: [String: [String]]
    let lastRefreshAt: Date?

    init(
        domain: String = "app",
        manifest: RemoteConfigManifestToken,
        activeTopics: [String] = [],
        prefetchBlobs: [String] = [],
        topicBlobRefs: [String: [String]] = [:],
        lastRefreshAt: Date? = nil
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
            domain: try container.decodeIfPresent(String.self, forKey: .domain) ?? "app",
            manifest: try container.decode(RemoteConfigManifestToken.self, forKey: .manifest),
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

    private let fileManager: FileManager
    private let directoryURL: URL?

    init(
        fileManager: FileManager = .default,
        directoryURL: URL? = RemoteConfigDiskCache.defaultDirectoryURL
    ) {
        self.fileManager = fileManager
        self.directoryURL = directoryURL
    }

    func read() -> PersistedRemoteConfiguration? {
        guard let fileURL = self.fileURL,
              self.fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder.default.decode(PersistedRemoteConfiguration.self, from: data)
        } catch {
            Logger.error(Strings.remoteConfig.failedToReadCache(error))
            return nil
        }
    }

    func write(_ configuration: PersistedRemoteConfiguration) {
        guard let directoryURL = self.directoryURL else {
            Logger.error(Strings.remoteConfig.cacheURLNotAvailable)
            return
        }

        do {
            try self.fileManager.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true,
                attributes: nil
            )

            let data = try JSONEncoder.default.encode(configuration)
            try data.write(to: directoryURL.appendingPathComponent(Self.fileName, isDirectory: false), options: .atomic)
        } catch {
            Logger.error(Strings.remoteConfig.failedToWriteCache(error))
        }
    }

    private var fileURL: URL? {
        return self.directoryURL?.appendingPathComponent(Self.fileName, isDirectory: false)
    }

}

private extension RemoteConfigDiskCache {

    static let directoryName = "remote_config"
    static let fileName = "remote_config.json"

    static var defaultDirectoryURL: URL? {
        #if os(tvOS)
        let directoryType = DirectoryHelper.DirectoryType.cache
        #else
        let directoryType = DirectoryHelper.DirectoryType.applicationSupport()
        #endif

        return DirectoryHelper.baseUrl(for: directoryType)?
            .appendingPathComponent(Self.directoryName, isDirectory: true)
    }

}
