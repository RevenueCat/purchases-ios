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
//  Wraps the real blob downloader and records the URL of every download attempt by outcome, so a
//  real-backend test can check a SPECIFIC blob's transport (its ref is substituted into the source
//  URL) rather than a global count that mixes in unrelated topics fetched during the same sync.

import Foundation
@testable import RevenueCat

final class RecordingBlobDownloader: RemoteConfigBlobDownloaderType {

    private let wrapped: RemoteConfigBlobDownloaderType
    private let lock = NSLock()

    private var _downloadedURLs: [URL] = []
    private var _failedURLs: [URL] = []

    init(wrapping wrapped: RemoteConfigBlobDownloaderType = URLSessionRemoteConfigBlobDownloader()) {
        self.wrapped = wrapped
    }

    /// Whether this blob ref was downloaded from the CDN (the ref is substituted into the source URL).
    func didDownload(ref: String) -> Bool {
        self.lock.withLock { self._downloadedURLs.contains { $0.absoluteString.contains(ref) } }
    }

    /// Whether a download attempt for this blob ref failed (a primary that later fell over counts).
    func didFail(ref: String) -> Bool {
        self.lock.withLock { self._failedURLs.contains { $0.absoluteString.contains(ref) } }
    }

    func data(from url: URL) async throws -> Data {
        do {
            let data = try await self.wrapped.data(from: url)
            self.lock.withLock { self._downloadedURLs.append(url) }
            return data
        } catch {
            self.lock.withLock { self._failedURLs.append(url) }
            throw error
        }
    }

}
