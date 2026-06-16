//
//  RemoteConfigurationDecodingTests.swift
//  RevenueCat
//
//  Created by Rick van der Linden on 27/05/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

final class RemoteConfigurationDecodingTests: TestCase {

    func testDeserializesFullFirstResponse() throws {
        let response = try JSONDecoder.default.decode(RemoteConfiguration.self, from: Self.fullPayload)

        expect(response.domain) == "app"
        expect(response.subdomains) == ["app_workflows"]
        expect(response.appUUID) == "1a2b3c4d"
        expect(response.stateHash) == "x3R7YvQw2NfM"
        expect(response.manifest.domain) == "app"
        expect(response.manifest.topics) == [
            "sources": "Jc83RzcK1LqA",
            "product_entitlement_mapping": "9v1DnUu6rXbE"
        ]
        expect(response.manifest.prefetchBlobs) == [
            "AAECAwQFBgcICQoLDA0ODxAREhMUFRYX"
        ]
        expect(response.manifest.prefetchedBlobs) == [
            "GBkaGxwdHh8gISIjJCUmJygpKissLS4v"
        ]
        expect(response.manifest.lastRefreshAt) == 1710000100

        try self.expectFullPayloadSources(in: response)

        expect(response.topics.entries["product_entitlement_mapping"]?["default"]?.blobRef)
            == "AAECAwQFBgcICQoLDA0ODxAREhMUFRYX"
        expect(response.topics.entries["product_entitlement_mapping"]?["default"]?.prefetch) == true
    }

    func testDeserializesSourcesTopic() throws {
        let response = try JSONDecoder.default.decode(RemoteConfiguration.self, from: Self.fullPayload)

        try self.expectFullPayloadSources(in: response)
    }

    private func expectFullPayloadSources(in response: RemoteConfiguration) throws {
        let sourcesTopic = try XCTUnwrap(response.topics.entries["sources"])

        expect(sourcesTopic["api"]?.content) == [
            "sources": [
                [
                    "id": "primary",
                    "url": "https://api.revenuecat.com/",
                    "priority": 0,
                    "weight": 100
                ]
            ]
        ]
        expect(sourcesTopic["blob"]?.content) == [
            "sources": [
                [
                    "id": "primary",
                    "url_format": "https://assets.revenuecat.com/app-prefix/{blob_ref}",
                    "priority": 0,
                    "weight": 100
                ]
            ]
        ]
    }

    func testDeserializesChangedTopicsOnlyResponse() throws {
        let payload = """
        {
          "domain": "app",
          "manifest": {
            "domain": "app",
            "topics": {
              "sources": "new-sources-etag",
              "product_entitlement_mapping": "unchanged-pem-etag"
            }
          },
          "topics": {
            "sources": {
              "api": {
                "id": "secondary",
                "url": "https://api-secondary.revenuecat.com/",
                "priority": 1,
                "weight": 50
              }
            }
          }
        }
        """.asData

        let response = try JSONDecoder.default.decode(RemoteConfiguration.self, from: payload)

        expect(response.manifest.topics) == [
            "sources": "new-sources-etag",
            "product_entitlement_mapping": "unchanged-pem-etag"
        ]
        let sourcesTopic = try XCTUnwrap(response.topics.entries["sources"])
        expect(sourcesTopic["api"]?.content) == [
            "id": "secondary",
            "url": "https://api-secondary.revenuecat.com/",
            "priority": 1,
            "weight": 50
        ]
        expect(response.topics.entries["product_entitlement_mapping"]).to(beNil())
    }

    func testChangedTopicBodyIsAbsentWhenTopicIsUnchanged() throws {
        let payload = """
        {
          "domain": "app",
          "manifest": {
            "domain": "app",
            "topics": {
              "sources": "same-sources-etag"
            }
          },
          "topics": {}
        }
        """.asData

        let response = try JSONDecoder.default.decode(RemoteConfiguration.self, from: payload)

        expect(response.topics.entries["sources"]).to(beNil())
    }

    func testDeserializesNoChangedTopicsResponseShape() throws {
        let payload = """
        {
          "domain": "app",
          "manifest": {
            "domain": "app",
            "topics": {
              "sources": "same-sources-etag"
            }
          },
          "topics": {}
        }
        """.asData

        let response = try JSONDecoder.default.decode(RemoteConfiguration.self, from: payload)

        expect(response.manifest.topics) == ["sources": "same-sources-etag"]
        expect(response.topics.entries).to(beEmpty())
        expect(response.topics.entries["sources"]).to(beNil())
    }

    func testPreservesUnknownTopicNames() throws {
        let payload = """
        {
          "domain": "app",
          "manifest": {
            "domain": "app",
            "topics": {
              "future_topic": "future-etag"
            }
          },
          "topics": {
            "future_topic": {
              "default": {
                "blob_ref": "AAECAwQFBgcICQoLDA0ODxAREhMUFRYX"
              }
            }
          }
        }
        """.asData

        let response = try JSONDecoder.default.decode(RemoteConfiguration.self, from: payload)

        expect(response.manifest.topics) == ["future_topic": "future-etag"]
        expect(response.topics.entries["future_topic"]?["default"]?.blobRef)
            == "AAECAwQFBgcICQoLDA0ODxAREhMUFRYX"
    }

    func testInlineItemContentIsPreservedAndReservedKeysAreExcluded() throws {
        let item = try JSONDecoder.default.decode(
            RemoteConfiguration.ConfigItem.self,
            from: """
            {
              "title": "Paywall",
              "revision": 3,
              "enabled": true,
              "blob_ref": "AAECAwQFBgcICQoLDA0ODxAREhMUFRYX",
              "prefetch": true
            }
            """.asData
        )

        expect(item.blobRef) == "AAECAwQFBgcICQoLDA0ODxAREhMUFRYX"
        expect(item.prefetch) == true
        expect(item.content) == [
            "title": "Paywall",
            "revision": 3,
            "enabled": true
        ]
    }

    func testBlobRefItemWithPrefetch() throws {
        let item = try JSONDecoder.default.decode(
            RemoteConfiguration.ConfigItem.self,
            from: """
            {
              "blob_ref": "AAECAwQFBgcICQoLDA0ODxAREhMUFRYX",
              "prefetch": true
            }
            """.asData
        )

        expect(item.blobRef) == "AAECAwQFBgcICQoLDA0ODxAREhMUFRYX"
        expect(item.prefetch) == true
        expect(item.content).to(beEmpty())
    }

    func testMissingOptionalFieldsFallBackToDefaults() throws {
        let payload = """
        {
          "domain": "app",
          "manifest": {
            "domain": "app"
          }
        }
        """.asData

        let response = try JSONDecoder.default.decode(RemoteConfiguration.self, from: payload)

        expect(response.subdomains).to(beEmpty())
        expect(response.appUUID).to(beNil())
        expect(response.stateHash).to(beNil())
        expect(response.topics.entries).to(beEmpty())
        expect(response.manifest.topics).to(beEmpty())
        expect(response.manifest.prefetchBlobs).to(beEmpty())
        expect(response.manifest.prefetchedBlobs).to(beEmpty())
        expect(response.manifest.lastRefreshAt) == 0
    }

    func testFailsWhenRequiredTopLevelDomainIsMissing() {
        let payload = """
        {
          "manifest": {
            "domain": "app"
          }
        }
        """.asData

        XCTAssertThrowsError(try JSONDecoder.default.decode(RemoteConfiguration.self, from: payload))
    }

    func testFailsWhenRequiredManifestIsMissing() {
        let payload = """
        {
          "domain": "app"
        }
        """.asData

        XCTAssertThrowsError(try JSONDecoder.default.decode(RemoteConfiguration.self, from: payload))
    }

    func testFailsWhenRequiredManifestDomainIsMissing() {
        let payload = """
        {
          "domain": "app",
          "manifest": {}
        }
        """.asData

        XCTAssertThrowsError(try JSONDecoder.default.decode(RemoteConfiguration.self, from: payload))
    }

    func testInvalidReservedItemFieldsFallBackWithoutDroppingContent() throws {
        let item = try JSONDecoder.default.decode(
            RemoteConfiguration.ConfigItem.self,
            from: """
            {
              "blob_ref": 123,
              "prefetch": "yes",
              "name": "inline",
              "value": 42
            }
            """.asData
        )

        expect(item.blobRef).to(beNil())
        expect(item.prefetch) == false
        expect(item.content) == [
            "name": "inline",
            "value": 42
        ]
    }

    func testConfigItemEncodesFlatShape() throws {
        let item = RemoteConfiguration.ConfigItem(
            blobRef: "AAECAwQFBgcICQoLDA0ODxAREhMUFRYX",
            prefetch: true,
            content: [
                "title": "Paywall",
                "revision": 3
            ]
        )

        let data = try JSONEncoder.default.encode(item)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        expect(json["title"] as? String) == "Paywall"
        expect(json["revision"] as? Int) == 3
        expect(json["blob_ref"] as? String) == "AAECAwQFBgcICQoLDA0ODxAREhMUFRYX"
        expect(json["prefetch"] as? Bool) == true
    }

    func testConfigItemOmitsFalsePrefetchWhenEncoding() throws {
        let item = RemoteConfiguration.ConfigItem(
            blobRef: "AAECAwQFBgcICQoLDA0ODxAREhMUFRYX",
            prefetch: false
        )

        let data = try JSONEncoder.default.encode(item)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        expect(json["blob_ref"] as? String) == "AAECAwQFBgcICQoLDA0ODxAREhMUFRYX"
        expect(json["prefetch"]).to(beNil())
    }

    func testManifestEncodeRoundTripPreservesRequestShape() throws {
        let manifest = RemoteConfiguration.Manifest(
            domain: "app",
            topics: ["sources": "sources-etag"],
            prefetchBlobs: ["blob-b", "blob-a"],
            prefetchedBlobs: ["blob-a"],
            lastRefreshAt: 123
        )
        let request = RemoteConfigRequest(manifest: manifest)

        let data = try JSONEncoder.default.encode(request)
        let decoded = try JSONDecoder.default.decode(RemoteConfigRequest.self, from: data)

        expect(decoded) == request
    }

}

private extension RemoteConfigurationDecodingTests {

    static let fullPayload = """
    {
      "domain": "app",
      "subdomains": ["app_workflows"],
      "app_uuid": "1a2b3c4d",
      "manifest": {
        "domain": "app",
        "topics": {
          "sources": "Jc83RzcK1LqA",
          "product_entitlement_mapping": "9v1DnUu6rXbE"
        },
        "prefetch_blobs": ["AAECAwQFBgcICQoLDA0ODxAREhMUFRYX"],
        "prefetched_blobs": ["GBkaGxwdHh8gISIjJCUmJygpKissLS4v"],
        "last_refresh_at": 1710000100
      },
      "topics": {
        "sources": {
          "api": {
            "sources": [
              {
                "id": "primary",
                "url": "https://api.revenuecat.com/",
                "priority": 0,
                "weight": 100
              }
            ]
          },
          "blob": {
            "sources": [
              {
                "id": "primary",
                "url_format": "https://assets.revenuecat.com/app-prefix/{blob_ref}",
                "priority": 0,
                "weight": 100
              }
            ]
          }
        },
        "product_entitlement_mapping": {
          "default": {
            "blob_ref": "AAECAwQFBgcICQoLDA0ODxAREhMUFRYX",
            "prefetch": true
          }
        }
      },
      "state_hash": "x3R7YvQw2NfM"
    }
    """.asData

}
