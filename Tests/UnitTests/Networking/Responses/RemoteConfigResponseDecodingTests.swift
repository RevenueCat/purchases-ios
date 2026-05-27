//
//  RemoteConfigResponseDecodingTests.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 27/05/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

final class RemoteConfigResponseDecodingTests: TestCase {

    // MARK: - Full payload

    func testDeserializesFullPayload() throws {
        let payload = """
        {
          "api_sources": [
            {
              "id": "primary",
              "url": "https://api.revenuecat.com/",
              "priority": 0,
              "weight": 100
            }
          ],
          "blob_sources": [
            {
              "id": "cloudfront-primary",
              "url_format": "https://assets.revenuecat.com/rc_app_1234/{blob_ref}",
              "priority": 0,
              "weight": 100
            }
          ],
          "manifest": {
            "topics": {
              "product_entitlement_mapping": {
                "default": {
                  "blob_ref": "abc123"
                }
              }
            }
          }
        }
        """.asData

        let response = try JSONDecoder.default.decode(RemoteConfigResponse.self, from: payload)

        expect(response.apiSources).to(haveCount(1))
        expect(response.apiSources[0].id) == "primary"
        expect(response.apiSources[0].url) == "https://api.revenuecat.com/"
        expect(response.apiSources[0].priority) == 0
        expect(response.apiSources[0].weight) == 100

        expect(response.blobSources).to(haveCount(1))
        expect(response.blobSources[0].id) == "cloudfront-primary"
        expect(response.blobSources[0].urlFormat) == "https://assets.revenuecat.com/rc_app_1234/{blob_ref}"
        expect(response.blobSources[0].priority) == 0
        expect(response.blobSources[0].weight) == 100

        let pem = try XCTUnwrap(response.manifest.topics[.productEntitlementMapping])
        expect(pem["default"]?.blobRef) == "abc123"
    }

    // MARK: - Default values

    func testMissingSourcesAndManifestFallBackToDefaults() throws {
        let response = try JSONDecoder.default.decode(RemoteConfigResponse.self, from: "{}".asData)

        expect(response.apiSources).to(beEmpty())
        expect(response.blobSources).to(beEmpty())
        expect(response.manifest.topics).to(beEmpty())
    }

    func testMissingManifestTopicsFallsBackToEmpty() throws {
        let response = try JSONDecoder.default.decode(
            RemoteConfigResponse.self,
            from: #"{"manifest": {}}"#.asData
        )

        expect(response.manifest.topics).to(beEmpty())
    }

    // MARK: - Unknown fields are ignored

    func testUnknownTopLevelFieldsAreIgnored() throws {
        let payload = """
        {
          "future_top_level": true,
          "api_sources": [
            {
              "id": "primary",
              "url": "https://api.revenuecat.com/",
              "priority": 0,
              "weight": 100,
              "future_field": "ignored"
            }
          ],
          "blob_sources": [
            {
              "id": "primary",
              "url_format": "https://assets.example/{blob_ref}",
              "priority": 0,
              "weight": 100,
              "future_field": "ignored"
            }
          ],
          "manifest": {
            "future_manifest_field": [],
            "topics": {
              "product_entitlement_mapping": {
                "default": {
                  "blob_ref": "abc",
                  "future_per_entry": 7
                }
              }
            }
          }
        }
        """.asData

        let response = try JSONDecoder.default.decode(RemoteConfigResponse.self, from: payload)

        expect(response.apiSources).to(haveCount(1))
        expect(response.apiSources[0].id) == "primary"
        expect(response.blobSources).to(haveCount(1))
        expect(response.blobSources[0].id) == "primary"
        expect(response.manifest.topics[.productEntitlementMapping]?["default"]?.blobRef) == "abc"
    }

    // MARK: - Unknown topic keys dropped

    func testUnknownTopicNamesAreDropped() throws {
        let payload = """
        {
          "manifest": {
            "topics": {
              "product_entitlement_mapping": {"default": {"blob_ref": "abc"}},
              "future_topic": {"default": {"blob_ref": "def"}},
              "another_unknown": {"default": {"blob_ref": "ghi"}}
            }
          }
        }
        """.asData

        let response = try JSONDecoder.default.decode(RemoteConfigResponse.self, from: payload)

        expect(response.manifest.topics).to(haveCount(1))
        expect(response.manifest.topics.keys).to(contain(.productEntitlementMapping))
    }

    func testAllUnknownTopicsProducesEmptyMap() throws {
        let payload = """
        {"manifest": {"topics": {"future_topic": {"default": {"blob_ref": "abc"}}}}}
        """.asData

        let response = try JSONDecoder.default.decode(RemoteConfigResponse.self, from: payload)

        expect(response.manifest.topics).to(beEmpty())
    }

    func testEmptyTopicsObjectProducesEmptyMap() throws {
        let response = try JSONDecoder.default.decode(
            RemoteConfigResponse.self,
            from: #"{"manifest": {"topics": {}}}"#.asData
        )

        expect(response.manifest.topics).to(beEmpty())
    }

    func testMultipleVariantKeysForKnownTopicArePreserved() throws {
        let payload = """
        {
          "manifest": {
            "topics": {
              "product_entitlement_mapping": {
                "default": {"blob_ref": "default-blob"},
                "EXPERIMENT_A": {"blob_ref": "experiment-blob"}
              }
            }
          }
        }
        """.asData

        let response = try JSONDecoder.default.decode(RemoteConfigResponse.self, from: payload)

        let variants = try XCTUnwrap(response.manifest.topics[.productEntitlementMapping])
        expect(variants).to(haveCount(2))
        expect(variants["default"]?.blobRef) == "default-blob"
        expect(variants["EXPERIMENT_A"]?.blobRef) == "experiment-blob"
    }

    // MARK: - Encoding round-trip

    func testTopicsEncodeBackToWireKey() throws {
        let manifest = RemoteConfigResponse.Manifest(
            topics: [.productEntitlementMapping: ["default": .init(blobRef: "abc")]]
        )

        let encoded = try JSONEncoder().encode(manifest)
        let json = try XCTUnwrap(String(data: encoded, encoding: .utf8))

        expect(json).to(contain("\"product_entitlement_mapping\""))
        expect(json).toNot(contain("productEntitlementMapping"))
    }

    func testRoundTripPreservesKnownTopics() throws {
        let original = RemoteConfigResponse(
            apiSources: [.init(id: "primary", url: "https://api.revenuecat.com/", priority: 0, weight: 100)],
            blobSources: [.init(id: "cdn", urlFormat: "https://assets.example/{blob_ref}", priority: 0, weight: 100)],
            manifest: .init(topics: [.productEntitlementMapping: ["default": .init(blobRef: "abc")]])
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder.default.decode(RemoteConfigResponse.self, from: encoded)

        expect(decoded) == original
    }

    // MARK: - Topic init

    func testTopicInitFromKnownWireKey() {
        expect(RemoteConfigResponse.Topic(wireKey: "product_entitlement_mapping")) == .productEntitlementMapping
    }

    func testTopicInitReturnsNilForUnknownWireKey() {
        expect(RemoteConfigResponse.Topic(wireKey: "future_topic")).to(beNil())
        expect(RemoteConfigResponse.Topic(wireKey: "PRODUCT_ENTITLEMENT_MAPPING")).to(beNil())
        expect(RemoteConfigResponse.Topic(wireKey: "")).to(beNil())
    }

    // MARK: - Type errors are rejected

    func testWrongTypeForBlobSourcesIsRejected() {
        expect {
            try JSONDecoder.default.decode(
                RemoteConfigResponse.self,
                from: #"{"blob_sources": "not-an-array"}"#.asData
            )
        }.to(throwError())
    }

    func testWrongTypeForApiSourcesIsRejected() {
        expect {
            try JSONDecoder.default.decode(
                RemoteConfigResponse.self,
                from: #"{"api_sources": "not-an-array"}"#.asData
            )
        }.to(throwError())
    }

}
