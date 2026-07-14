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
//  Wraps the real blob downloader and records what actually crossed the network, so a
//  real-backend test can check transport health the SDK does not expose (how many blobs
//  downloaded, how many failed, total bytes, and which hosts were hit).

import Foundation
@testable import RevenueCat

final class RecordingBlobDownloader: RemoteConfigBlobDownloaderType {

    private let wrapped: RemoteConfigBlobDownloaderType
    private let lock = NSLock()

    private var _successCount = 0
    private var _failureCount = 0
    private var _totalBytes = 0
    private var _hosts: [String] = []

    init(wrapping wrapped: RemoteConfigBlobDownloaderType = URLSessionRemoteConfigBlobDownloader()) {
        self.wrapped = wrapped
    }

    var successCount: Int { self.lock.withLock { self._successCount } }
    var failureCount: Int { self.lock.withLock { self._failureCount } }
    var totalBytes: Int { self.lock.withLock { self._totalBytes } }
    var distinctHostCount: Int { self.lock.withLock { Set(self._hosts).count } }

    func data(from url: URL) async throws -> Data {
        do {
            let data = try await self.wrapped.data(from: url)
            self.lock.withLock {
                self._successCount += 1
                self._totalBytes += data.count
                if let host = url.host { self._hosts.append(host) }
            }
            return data
        } catch {
            self.lock.withLock {
                self._failureCount += 1
                if let host = url.host { self._hosts.append(host) }
            }
            throw error
        }
    }

}
