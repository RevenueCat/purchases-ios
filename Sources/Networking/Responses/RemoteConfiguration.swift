//
//  RemoteConfiguration.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 27/05/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

/// The `/v1/config` configuration object.
///
/// This is returned by the remote config API either as the config JSON inside an `RCContainer`
/// response or as the plain JSON HTTP response body.
struct RemoteConfiguration: Equatable {

    static let defaultDomain = "app"

    let domain: String
    /// Other domains the SDK should also sync to assemble the full configuration.
    let subdomains: [String]
    /// Opaque token returned by the server and replayed on future requests.
    let manifest: String
    /// Full set of active topic names, including unchanged topics omitted from `topics`.
    let activeTopics: [String]
    /// Blob refs the server expects the SDK to have cached for this configuration.
    let prefetchBlobs: [String]
    /// Changed topic bodies only. If a topic's client-sent etag still matches, the topic is omitted
    /// and the client keeps its cached topic data. `activeTopics` is the source of truth for topic
    /// existence, so cached topics absent there should be removed.
    let topics: Topics

    init(
        domain: String,
        subdomains: [String] = [],
        manifest: String,
        activeTopics: [String],
        prefetchBlobs: [String] = [],
        topics: Topics = .init()
    ) {
        self.domain = domain
        self.subdomains = subdomains
        self.manifest = manifest
        self.activeTopics = activeTopics
        self.prefetchBlobs = prefetchBlobs
        self.topics = topics
    }

}

extension RemoteConfiguration {

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

        // JSONDecoder.default converts `blob_ref` to `blobRef` before matching dynamic keys.
        private static let blobRefKey = DynamicCodingKey("blobRef")
        private static let prefetchKey = DynamicCodingKey("prefetch")

    }

}

// MARK: - Codable

extension RemoteConfiguration: Codable {

    private enum CodingKeys: String, CodingKey {
        case domain
        case subdomains
        case manifest
        case activeTopics
        case prefetchBlobs
        case topics
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.domain = try container.decode(String.self, forKey: .domain)
        self.subdomains = try container.decodeIfPresent([String].self, forKey: .subdomains) ?? []
        self.manifest = try container.decode(String.self, forKey: .manifest)
        self.activeTopics = try container.decode([String].self, forKey: .activeTopics)
        self.prefetchBlobs = try container.decodeIfPresent([String].self, forKey: .prefetchBlobs) ?? []
        self.topics = try container.decodeIfPresent(Topics.self, forKey: .topics) ?? Topics()
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
