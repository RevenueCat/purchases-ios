//
//  RemoteConfigResponse.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 27/05/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation

struct RemoteConfigResponse: Equatable {

    let apiSources: [ApiSource]
    let blobSources: [BlobSource]
    let manifest: Manifest

    init(
        apiSources: [ApiSource] = [],
        blobSources: [BlobSource] = [],
        manifest: Manifest = Manifest()
    ) {
        self.apiSources = apiSources
        self.blobSources = blobSources
        self.manifest = manifest
    }

}

extension RemoteConfigResponse {

    struct ApiSource: Codable, Equatable {
        let id: String
        let url: String
        let priority: Int
        let weight: Int
    }

    struct BlobSource: Codable, Equatable {
        let id: String
        let urlFormat: String
        let priority: Int
        let weight: Int
    }

    struct Manifest: Equatable {

        let topics: [Topic: [String: TopicEntry]]

        init(topics: [Topic: [String: TopicEntry]] = [:]) {
            self.topics = topics
        }

    }

    enum Topic: Hashable {

        case productEntitlementMapping

        var wireKey: String {
            switch self {
            case .productEntitlementMapping: return "product_entitlement_mapping"
            }
        }

        init?(wireKey: String) {
            switch wireKey {
            case "product_entitlement_mapping": self = .productEntitlementMapping
            default: return nil
            }
        }

    }

    struct TopicEntry: Codable, Equatable {
        let blobRef: String
    }

}

// MARK: - Codable

extension RemoteConfigResponse: Codable {

    private enum CodingKeys: CodingKey {
        case apiSources, blobSources, manifest
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.apiSources = try container.decodeIfPresent([ApiSource].self, forKey: .apiSources) ?? []
        self.blobSources = try container.decodeIfPresent([BlobSource].self, forKey: .blobSources) ?? []
        self.manifest = try container.decodeIfPresent(Manifest.self, forKey: .manifest) ?? Manifest()
    }

}

extension RemoteConfigResponse.Manifest: Codable {

    private enum CodingKeys: CodingKey {
        case topics
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawTopics = try container.decodeIfPresent(
            [String: [String: RemoteConfigResponse.TopicEntry]].self,
            forKey: .topics
        ) ?? [:]
        self.topics = rawTopics.reduce(into: [:]) { result, pair in
            if let topic = RemoteConfigResponse.Topic(wireKey: pair.key) {
                result[topic] = pair.value
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let rawTopics = Dictionary(uniqueKeysWithValues: topics.map { ($0.key.wireKey, $0.value) })
        try container.encode(rawTopics, forKey: .topics)
    }

}

// MARK: - HTTPResponseBody

extension RemoteConfigResponse: HTTPResponseBody {}
