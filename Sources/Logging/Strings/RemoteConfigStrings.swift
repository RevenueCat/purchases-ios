//
//  RemoteConfigStrings.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 27/05/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

// swiftlint:disable identifier_name

enum RemoteConfigStrings {

    case remote_config_fetch_error(BackendError)

    case topic_malformed_blob_ref(topic: RemoteConfigResponse.Topic, entryId: String)
    case topic_caches_dir_unavailable(topic: RemoteConfigResponse.Topic, entryId: String)
    case topic_invalid_blob_url(topic: RemoteConfigResponse.Topic, entryId: String, urlString: String)
    case topic_cache_hit(topic: RemoteConfigResponse.Topic, entryId: String)
    case topic_fetched(topic: RemoteConfigResponse.Topic, entryId: String)
    case topic_fetch_error(topic: RemoteConfigResponse.Topic, entryId: String, error: BackendError)

    case topic_cleanup_deleted(path: String)
    case topic_cleanup_delete_failed(path: String, error: Error)
    case topic_cleanup_list_failed(path: String, error: Error)

}

extension RemoteConfigStrings: LogMessage {

    var description: String {
        switch self {
        case let .remote_config_fetch_error(error):
            return "RemoteConfig: failed to fetch from network: \(error.localizedDescription)"

        case let .topic_malformed_blob_ref(topic, entryId):
            return "RemoteConfig: topic \(topic) (\(entryId)) has a malformed blob_ref; refusing to fetch."

        case let .topic_caches_dir_unavailable(topic, entryId):
            return "RemoteConfig: topic \(topic) (\(entryId)) could not resolve caches directory; skipping."

        case let .topic_invalid_blob_url(topic, entryId, urlString):
            return "RemoteConfig: topic \(topic) (\(entryId)) produced an invalid URL '\(urlString)'; skipping."

        case let .topic_cache_hit(topic, entryId):
            return "RemoteConfig: topic \(topic) (\(entryId)) already cached, skipping download."

        case let .topic_fetched(topic, entryId):
            return "RemoteConfig: topic \(topic) (\(entryId)) downloaded and cached."

        case let .topic_fetch_error(topic, entryId, error):
            return "RemoteConfig: failed to fetch topic \(topic) (\(entryId)): \(error.localizedDescription)"

        case let .topic_cleanup_deleted(path):
            return "RemoteConfig: deleted unreferenced topic file at \(path)."

        case let .topic_cleanup_delete_failed(path, error):
            return "RemoteConfig: failed to delete unreferenced topic file at \(path): " +
                "\(error.localizedDescription)"

        case let .topic_cleanup_list_failed(path, error):
            return "RemoteConfig: failed to list topic files at \(path); skipping cleanup for that " +
                "topic: \(error.localizedDescription)"
        }
    }

    var category: String { return "remote_config" }

}
