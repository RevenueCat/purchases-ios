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

    init(timeoutManager: HTTPRequestTimeoutManagerType, session: URLSession = .shared) {
        self.timeoutManager = timeoutManager
        self.session = session
    }

    func data(from url: URL) async throws -> Data {
        let host = url.host
        // Blob sources never support fallback URLs, so each attempt uses the no-fallback tier (15s base, 5s if this
        // host timed out recently), keyed by the source host and sharing the per-host memory with API requests.
        let timeout = self.timeoutManager.timeout(host: host,
                                                  isFallbackHostRequest: false,
                                                  endpointSupportsFallbackURLs: false,
                                                  isProxied: false)

        var request = URLRequest(url: url)
        request.timeoutInterval = timeout

        do {
            let data = try await self.performRequest(request)
            // The source answered, so clear any fail-fast memory for it.
            self.timeoutManager.recordRequestResult(host: host, .successOnMainBackend)
            return data
        } catch {
            // A timeout arms the source's fail-fast memory so a re-hit within 10 min bails out sooner.
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
