//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PerformanceBackend.swift
//

import Foundation
@testable import RevenueCat
import XCTest

enum PerformanceBackend {

    static func makeManager(apiKey: String, rootURL: URL) throws -> RemoteConfigManager {
        let directoryType = DirectoryHelper.DirectoryType.applicationSupport(overrideURL: rootURL)
        let cacheBasePath = "\(RemoteConfigDiskCache.basePath)-\(UUID().uuidString)"
        let synchronizedCache = SynchronizedLargeItemCache(
            cache: FileManager.default,
            basePath: cacheBasePath,
            directoryType: directoryType
        )
        let cacheDirectoryURL = try XCTUnwrap(DirectoryHelper.baseUrl(for: directoryType))
            .appendingPathComponent(cacheBasePath, isDirectory: true)

        let diskCache = RemoteConfigDiskCache(cache: synchronizedCache)
        let blobStore = RemoteConfigBlobStore(
            fileManager: .default,
            directoryURL: cacheDirectoryURL.appendingPathComponent("blobs", isDirectory: true)
        )

        let systemInfo = SystemInfo(
            platformInfo: nil,
            finishTransactions: true,
            apiKey: apiKey,
            preferredLocalesProvider: PreferredLocalesProvider(preferredLocaleOverride: nil)
        )
        let backend = Backend(
            systemInfo: systemInfo,
            eTagManager: ETagManager(),
            tokenManager: TokenManager(enabled: false, storage: Keychain(access: nil)),
            operationDispatcher: .default,
            attributionFetcher: AttributionFetcher(
                attributionFactory: AttributionTypeFactory(),
                systemInfo: systemInfo
            ),
            offlineCustomerInfoCreator: nil,
            diagnosticsTracker: nil,
            apiSourceProvider: nil,
            timeoutManager: HTTPRequestTimeoutManager(networkTimeout: .default),
            subscriberDimensionsStore: SubscriberDimensionsStore(
                deviceCache: DeviceCache(systemInfo: systemInfo, userDefaults: .standard)
            )
        )
        return RemoteConfigManager(
            remoteConfigAPI: backend.remoteConfigAPI,
            diskCache: diskCache,
            blobStore: blobStore,
            blobFetcher: RemoteConfigBlobFetcher(
                blobStore: blobStore,
                sourceProvider: RemoteConfigSourceProvider(topicStore: diskCache),
                downloader: URLSessionRemoteConfigBlobDownloader(
                    timeoutManager: HTTPRequestTimeoutManager(networkTimeout: .default)
                )
            ),
            currentUserProvider: PerformanceTestUserProvider()
        )
    }

}

private final class PerformanceTestUserProvider: CurrentUserProvider {
    var currentAppUserID: String { "workflow-memory-benchmark" }
    var currentUserIsAnonymous: Bool { true }
}
