//
//  RemoteConfiguration.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 27/05/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

/// The `/v2/config` configuration object.
///
/// This is returned by the remote config API either as the config JSON inside an `RCContainer`
/// response or as the plain JSON HTTP response body.
struct RemoteConfiguration: Equatable {

    let domain: String
    /// Other domains the SDK should also sync to assemble the full configuration.
    let subdomains: [String]
    let appUUID: String?
    let manifest: Manifest
    /// Changed topic bodies only. If a topic's client-sent etag still matches, the topic is omitted
    /// and the client keeps its cached topic data. `manifest` lists every active topic and its current
    /// etag, including unchanged ones, so it is the source of truth for which topics exist.
    let topics: Topics
    let stateHash: String?

    init(
        domain: String,
        subdomains: [String] = [],
        appUUID: String? = nil,
        manifest: Manifest,
        topics: Topics = .init(),
        stateHash: String? = nil
    ) {
        self.domain = domain
        self.subdomains = subdomains
        self.appUUID = appUUID
        self.manifest = manifest
        self.topics = topics
        self.stateHash = stateHash
    }

}

extension RemoteConfiguration {

    struct Manifest: Codable, Equatable {

        static let appDomain = "app"

        let domain: String
        /// Topic name to compact topic etag. Lists every active topic, including unchanged ones.
        let topics: [String: String]
        /// Blob refs the server believes the SDK should have prefetched.
        let prefetchBlobs: [String]
        /// Blob refs the SDK has actually cached locally. Sent on the request; absent from server responses.
        let prefetchedBlobs: [String]
        /// Timestamp from the previous server manifest. Used only for refresh cadence.
        let lastRefreshAt: Int

        init(
            domain: String = Self.appDomain,
            topics: [String: String] = [:],
            prefetchBlobs: [String] = [],
            prefetchedBlobs: [String] = [],
            lastRefreshAt: Int = 0
        ) {
            self.domain = domain
            self.topics = topics
            self.prefetchBlobs = prefetchBlobs
            self.prefetchedBlobs = prefetchedBlobs
            self.lastRefreshAt = lastRefreshAt
        }

    }

    struct Topics: Equatable {

        /// Changed topic bodies only: topic name to item name to config item.
        let entries: [String: [String: ConfigItem]]

        init(
            entries: [String: [String: ConfigItem]] = [:]
        ) {
            self.entries = entries
        }

    }

    /// A single item within a topic.
    ///
    /// Items are arbitrary topic-specific JSON. `blob_ref` and `prefetch` are the only
    /// reserved keys the SDK interprets; every other key is preserved in `content`.
    /// Payloads may be inline in `content` or external via `blobRef`, depending on what
    /// the server chooses for a given response.
    struct ConfigItem: Codable, Equatable {
        /// When present, the item's payload is an external static blob addressed by this ref.
        let blobRef: String?
        /// When true, the SDK should proactively cache this item's blob.
        let prefetch: Bool
        /// Topic-specific item content, excluding the reserved `blob_ref` and `prefetch` keys.
        let content: [String: AnyDecodable]

        init(
            blobRef: String? = nil,
            prefetch: Bool = false,
            content: [String: AnyDecodable] = [:]
        ) {
            self.blobRef = blobRef
            self.prefetch = prefetch
            self.content = content
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: DynamicCodingKey.self)

            self.blobRef = try? container.decode(String.self, forKey: Self.blobRefKey)
            self.prefetch = (try? container.decode(Bool.self, forKey: Self.prefetchKey)) ?? false

            self.content = try container.allKeys.reduce(into: [String: AnyDecodable]()) { content, key in
                guard key != Self.blobRefKey, key != Self.prefetchKey else { return }
                content[key.stringValue] = try container.decode(AnyDecodable.self, forKey: key)
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: DynamicCodingKey.self)
            for (key, value) in self.content {
                try container.encode(value, forKey: DynamicCodingKey(key))
            }
            if let blobRef = self.blobRef {
                try container.encode(blobRef, forKey: Self.blobRefKey)
            }
            if self.prefetch {
                try container.encode(self.prefetch, forKey: Self.prefetchKey)
            }
        }

        private static let blobRefKey = DynamicCodingKey("blobRef")
        private static let prefetchKey = DynamicCodingKey("prefetch")

    }

}

// MARK: - Codable

extension RemoteConfiguration: Codable {

    private enum CodingKeys: String, CodingKey {
        case domain
        case subdomains
        case appUUID = "appUuid"
        case manifest
        case topics
        case stateHash
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.domain = try container.decode(String.self, forKey: .domain)
        self.subdomains = try container.decodeIfPresent([String].self, forKey: .subdomains) ?? []
        self.appUUID = try container.decodeIfPresent(String.self, forKey: .appUUID)
        self.manifest = try container.decode(Manifest.self, forKey: .manifest)
        self.topics = try container.decodeIfPresent(Topics.self, forKey: .topics) ?? Topics()
        self.stateHash = try container.decodeIfPresent(String.self, forKey: .stateHash)
    }

}

extension RemoteConfiguration.Manifest {

    private enum CodingKeys: String, CodingKey {
        case domain
        case topics
        case prefetchBlobs
        case prefetchedBlobs
        case lastRefreshAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.init(
            domain: try container.decode(String.self, forKey: .domain),
            topics: try container.decodeIfPresent([String: String].self, forKey: .topics) ?? [:],
            prefetchBlobs: try container.decodeIfPresent([String].self, forKey: .prefetchBlobs) ?? [],
            prefetchedBlobs: try container.decodeIfPresent([String].self, forKey: .prefetchedBlobs) ?? [],
            lastRefreshAt: try container.decodeIfPresent(Int.self, forKey: .lastRefreshAt) ?? 0
        )
    }

}

extension RemoteConfiguration.Topics: Codable {

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(entries: try container.decode([String: [String: RemoteConfiguration.ConfigItem]].self))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.entries)
    }

}

private struct DynamicCodingKey: CodingKey, Hashable {

    let stringValue: String
    let intValue: Int? = nil

    init(_ stringValue: String) {
        self.stringValue = stringValue
    }

    init?(stringValue: String) {
        self.init(stringValue)
    }

    init?(intValue: Int) {
        return nil
    }

}
