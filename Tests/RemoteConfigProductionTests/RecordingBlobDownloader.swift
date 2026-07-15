//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RecordingBlobDownloader.swift
//
//  Wraps the real blob downloader and records what actually crossed the network, so a real-backend
//  test can check whether a specific blob was served from the CDN (its ref appears in a download
//  URL), how many downloads failed, and how many distinct hosts were hit.

import Foundation
@testable import RevenueCat

final class RecordingBlobDownloader: RemoteConfigBlobDownloaderType {

    private let wrapped: RemoteConfigBlobDownloaderType
    private let lock = NSLock()

    private var _downloadedURLs: [URL] = []
    private var _failureCount = 0

    init(wrapping wrapped: RemoteConfigBlobDownloaderType = URLSessionRemoteConfigBlobDownloader()) {
        self.wrapped = wrapped
    }

    var failureCount: Int { self.lock.withLock { self._failureCount } }

    var distinctHostCount: Int {
        self.lock.withLock { Set(self._downloadedURLs.compactMap(\.host)).count }
    }

    /// Whether this blob ref was downloaded from the CDN (the ref is substituted into the source URL).
    func didDownload(ref: String) -> Bool {
        self.lock.withLock { self._downloadedURLs.contains { $0.absoluteString.contains(ref) } }
    }

    func data(from url: URL) async throws -> Data {
        do {
            let data = try await self.wrapped.data(from: url)
            self.lock.withLock { self._downloadedURLs.append(url) }
            return data
        } catch {
            self.lock.withLock { self._failureCount += 1 }
            throw error
        }
    }

}
