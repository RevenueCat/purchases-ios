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

    init(session: URLSession = .shared) {
        self.session = session
    }

    func data(from url: URL) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let task = self.session.dataTask(with: url) { data, response, error in
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
