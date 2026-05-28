//
//  RemoteConfigStrings.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 27/05/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

// swiftlint:disable identifier_name

enum RemoteConfigStrings {

    case remote_config_cache_hit
    case remote_config_cache_stale_fetching_from_network
    case remote_config_fetched_from_network
    case remote_config_fetch_error(BackendError)

    case topic_malformed_blob_ref(topic: RemoteConfigResponse.Topic, entryId: String)
    case topic_cache_hit(topic: RemoteConfigResponse.Topic, entryId: String)
    case topic_fetched(topic: RemoteConfigResponse.Topic, entryId: String)
    case topic_fetch_error(topic: RemoteConfigResponse.Topic, entryId: String, error: BackendError)

}

extension RemoteConfigStrings: LogMessage {

    var description: String {
        switch self {
        case .remote_config_cache_hit:
            return "RemoteConfig: cache is still fresh."

        case .remote_config_cache_stale_fetching_from_network:
            return "RemoteConfig: cache is stale, fetching from network."

        case .remote_config_fetched_from_network:
            return "RemoteConfig: fetched from network."

        case let .remote_config_fetch_error(error):
            return "RemoteConfig: failed to fetch from network: \(error.localizedDescription)"

        case let .topic_malformed_blob_ref(topic, entryId):
            return "RemoteConfig: topic \(topic) (\(entryId)) has a malformed blob_ref; refusing to fetch."

        case let .topic_cache_hit(topic, entryId):
            return "RemoteConfig: topic \(topic) (\(entryId)) already cached, skipping download."

        case let .topic_fetched(topic, entryId):
            return "RemoteConfig: topic \(topic) (\(entryId)) downloaded and cached."

        case let .topic_fetch_error(topic, entryId, error):
            return "RemoteConfig: failed to fetch topic \(topic) (\(entryId)): \(error.localizedDescription)"
        }
    }

    var category: String { return "remote_config" }

}
