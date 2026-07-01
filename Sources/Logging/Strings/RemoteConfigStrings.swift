//
//  RemoteConfigStrings.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

enum RemoteConfigStrings {

    case cacheURLNotAvailable
    case failedToClearBlobStore(Error)
    case failedToDeleteBlob(String, Error)
    case failedToReadBlob(String, Error)
    case failedToReadCache(Error)
    case failedToWriteBlob(String, Error)
    case failedToWriteCache
    case failedToBuildBlobURL(String)
    case failedToDownloadBlob(String, URL, Error)
    case duplicateSourceURL(String)
    case failedToParseResponse(Error)
    case malformedBlobRef(String)
    case refreshFailed(BackendError)
    case skippingInvalidBlob(String)

}

extension RemoteConfigStrings: LogMessage {

    var description: String {
        switch self {
        case .cacheURLNotAvailable:
            return "Remote config cache URL is not available."
        case let .failedToClearBlobStore(error):
            return "Failed to clear remote config blob store: \(error.localizedDescription)"
        case let .failedToDeleteBlob(ref, error):
            return "Failed to delete unreferenced remote config blob '\(ref)': \(error.localizedDescription)"
        case let .failedToReadBlob(ref, error):
            return "Failed to read remote config blob '\(ref)' from disk: \(error.localizedDescription)"
        case let .failedToReadCache(error):
            return "Failed to read remote config cache from disk: \(error.localizedDescription)"
        case let .failedToWriteBlob(ref, error):
            return "Failed to write remote config blob '\(ref)' to disk: \(error.localizedDescription)"
        case .failedToWriteCache:
            return "Failed to write remote config cache to disk."
        case let .failedToBuildBlobURL(ref):
            return "Failed to build remote config blob URL for ref '\(ref)'."
        case let .failedToDownloadBlob(ref, url, error):
            return "Failed to download remote config blob '\(ref)' from \(url.absoluteString): " +
                "\(error.localizedDescription)"
        case let .duplicateSourceURL(url):
            return "Found remote config sources sharing the same URL with conflicting priority/weight " +
                "(\(url)). Keeping the highest-priority one (lowest priority number), tie-broken by weight."
        case let .failedToParseResponse(error):
            return "Failed to parse remote config response. Keeping cached configuration. Error: " +
            "\(error.localizedDescription)"
        case let .malformedBlobRef(ref):
            return "Refusing remote config blob operation with malformed ref '\(ref)'."
        case let .refreshFailed(error):
            return "Remote config refresh failed. Keeping cached configuration. Error: \(error)"
        case let .skippingInvalidBlob(ref):
            return "Skipping remote config blob '\(ref)': checksum verification failed."
        }
    }

    var category: String { return "remote_config" }

}
