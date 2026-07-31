//
//  RemoteConfigBlobDownloader.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

protocol RemoteConfigBlobDownloaderType: AnyObject {

    func data(from url: URL) async throws -> Data

}

/// Small `URLSession.dataTask` async adapter for remote config blobs.
///
/// This intentionally stays separate from fetcher scheduling so the iOS 13-compatible callback bridge
/// can be removed cleanly once the SDK can rely on newer async `URLSession` APIs everywhere.
final class URLSessionRemoteConfigBlobDownloader: RemoteConfigBlobDownloaderType {

    enum Error: Swift.Error, Equatable {
        case invalidResponse
        case unexpectedStatusCode(Int)
    }

    private let session: URLSession
    private let timeoutManager: HTTPRequestTimeoutManagerType

    convenience init(timeoutManager: HTTPRequestTimeoutManagerType) {
        let ceiling = timeoutManager.blobDownloadTimeoutCeiling
        self.init(timeoutManager: timeoutManager,
                  session: URLSession(configuration: Self.sessionConfiguration(timeoutCeiling: ceiling)))
    }

    init(timeoutManager: HTTPRequestTimeoutManagerType, session: URLSession) {
        self.timeoutManager = timeoutManager
        self.session = session
    }

    static func sessionConfiguration(timeoutCeiling: TimeInterval) -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        // `URLRequest.timeoutInterval` only bounds the gap between bytes, so a source trickling data would
        // keep an attempt alive indefinitely without a resource timeout capping the whole download.
        configuration.timeoutIntervalForRequest = timeoutCeiling
        configuration.timeoutIntervalForResource = timeoutCeiling
        // Blobs are content-addressed and cached by `RemoteConfigBlobStore`, so an HTTP cache would only
        // duplicate them on disk.
        configuration.urlCache = nil
        return configuration
    }

    func data(from url: URL) async throws -> Data {
        let host = url.host

        var request = URLRequest(url: url)
        request.timeoutInterval = self.timeoutManager.blobDownloadTimeout(host: host)

        do {
            let data = try await self.performRequest(request)
            self.timeoutManager.recordRequestResult(host: host, .successOnMainBackend)
            return data
        } catch {
            let isTimeout = (error as? URLError)?.code == .timedOut
            self.timeoutManager.recordRequestResult(host: host, isTimeout ? .mainSourceTimedOut : .other)
            throw error
        }
    }

    private func performRequest(_ request: URLRequest) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let task = self.session.dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let response = response as? HTTPURLResponse else {
                    continuation.resume(throwing: Error.invalidResponse)
                    return
                }

                guard response.statusCode == 200 else {
                    continuation.resume(throwing: Error.unexpectedStatusCode(response.statusCode))
                    return
                }

                continuation.resume(returning: data ?? Data())
            }

            task.resume()
        }
    }

}

private extension HTTPRequestTimeoutManagerType {

    /// The timeout for a blob-source download attempt against `host`.
    ///
    /// Blob sources have no fallback URLs and are never proxied, and they always opt into the re-tiered
    /// fail-fast timeouts independently of the `usesRemoteConfigAPISources` setting, which only gates
    /// main-API requests.
    func blobDownloadTimeout(host: String?) -> TimeInterval {
        return self.timeout(host: host,
                            isFallbackHostRequest: false,
                            endpointSupportsFallbackURLs: false,
                            isProxied: false,
                            reTieredTimeoutsEnabled: true)
    }

    /// The widest timeout `blobDownloadTimeout(host:)` can return, so it doubles as the ceiling for the
    /// whole download: it is the base tier, which no per-host reduced tier ever exceeds.
    var blobDownloadTimeoutCeiling: TimeInterval {
        return self.blobDownloadTimeout(host: nil)
    }

}
