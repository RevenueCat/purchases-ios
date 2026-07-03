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
    case exhaustedBlobSources(String)
    case failedToBuildBlobURL(String)
    case failedToDownloadBlob(String, URL, Error)
    case duplicateSourceURL(String)
    case failedToParseResponse(Error)
    case malformedBlobRef(String)
    case notModified
    case prefetchEnqueued(Int)
    case prefetchingBlobCount(Int)
    case receivedConfiguration(activeTopics: [String], changedTopics: [String])
    case refreshing(domain: String, manifestPresent: Bool, isAppBackgrounded: Bool)
    case refreshFailed(BackendError)
    case skippingInvalidBlob(String)
    case persistedConfiguration(domain: String, activeTopicCount: Int, referencedBlobCount: Int)
    case sourceUnhealthy(ref: String, hasNextSource: Bool)
    case storedBlob(String, byteCount: Int, URL)
    case storedInlineBlob(String, byteCount: Int)

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
        case let .exhaustedBlobSources(ref):
            return "Failed to download remote config blob '\(ref)': all blob sources were exhausted."
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
        case .notModified:
            return "Remote config was not modified. Keeping cached configuration."
        case let .prefetchEnqueued(count):
            return "Enqueued \(count) remote config blob prefetch downloads."
        case let .prefetchingBlobCount(count):
            return "Prefetching \(count) remote config blobs requested by the latest configuration."
        case let .receivedConfiguration(activeTopics, changedTopics):
            return "Received remote config with \(activeTopics.count) active topics " +
                "(\(activeTopics.sorted().joined(separator: ", "))) and \(changedTopics.count) changed topics " +
                "(\(changedTopics.sorted().joined(separator: ", ")))."
        case let .refreshing(domain, manifestPresent, isAppBackgrounded):
            return "Refreshing remote config for domain '\(domain)' " +
                "(manifestPresent: \(manifestPresent), isAppBackgrounded: \(isAppBackgrounded))."
        case let .refreshFailed(error):
            return "Remote config refresh failed. Keeping cached configuration. Error: \(error)"
        case let .skippingInvalidBlob(ref):
            return "Skipping remote config blob '\(ref)': checksum verification failed."
        case let .persistedConfiguration(domain, activeTopicCount, referencedBlobCount):
            return "Persisted remote config for domain '\(domain)' with \(activeTopicCount) active topics " +
                "and \(referencedBlobCount) referenced blobs."
        case let .sourceUnhealthy(ref, hasNextSource):
            return "Marked remote config blob source unhealthy while downloading blob '\(ref)' " +
                "(hasNextSource: \(hasNextSource))."
        case let .storedBlob(ref, byteCount, url):
            return "Stored remote config blob '\(ref)' with \(byteCount) bytes downloaded from \(url.absoluteString)."
        case let .storedInlineBlob(ref, byteCount):
            return "Stored inline remote config blob '\(ref)' with \(byteCount) bytes."
        }
    }

    var category: String { return "remote_config" }

}
