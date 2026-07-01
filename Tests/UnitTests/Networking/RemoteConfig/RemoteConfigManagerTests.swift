//
//  RemoteConfigManagerTests.swift
//  UnitTests
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation
import Nimble
@testable import RevenueCat
import XCTest

final class RemoteConfigManagerTests: TestCase {

    private static let appUserID = "app-user-id"

    private var remoteConfigAPI: MockRemoteConfigAPI!
    private var diskCache: MockRemoteConfigDiskCache!
    private var blobStore: MockRemoteConfigBlobStore!
    private var blobFetcher: MockRemoteConfigBlobFetcher!
    private var currentUserProvider: MockCurrentUserProvider!
    private var manager: RemoteConfigManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.remoteConfigAPI = MockRemoteConfigAPI()
        self.diskCache = MockRemoteConfigDiskCache()
        self.blobStore = MockRemoteConfigBlobStore()
        self.blobFetcher = MockRemoteConfigBlobFetcher()
        self.currentUserProvider = MockCurrentUserProvider(mockAppUserID: Self.appUserID)
        self.manager = RemoteConfigManager(
            remoteConfigAPI: self.remoteConfigAPI,
            diskCache: self.diskCache,
            blobStore: self.blobStore,
            blobFetcher: self.blobFetcher,
            currentUserProvider: self.currentUserProvider
        )
    }

    override func tearDownWithError() throws {
        self.manager = nil
        self.blobFetcher = nil
        self.blobStore = nil
        self.currentUserProvider = nil
        self.diskCache = nil
        self.remoteConfigAPI = nil

        try super.tearDownWithError()
    }

    func testFirstRunSendsDefaultAppDomainManifest() throws {
        self.diskCache.stubbedRead = nil

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.appUserID) == Self.appUserID
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.manifest).to(beNil())
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.prefetchedBlobs).to(beEmpty())
    }

    func testSubsequentRunReplaysPersistedManifest() throws {
        let persistedManifest = "v1.1710000100.sources:etag1"
        self.blobStore.stubbedContainsRefs = ["prefetchedBlob"]
        self.diskCache.stubbedRead = Self.persisted(
            domain: "custom",
            manifest: persistedManifest,
            prefetchBlobs: ["prefetchedBlob"],
            topics: .init()
        )

        self.manager.refreshRemoteConfig(isAppBackgrounded: true)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.appUserID) == Self.appUserID
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.domain) == "custom"
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.manifest) == persistedManifest
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.prefetchedBlobs) == ["prefetchedBlob"]
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.isAppBackgrounded) == true
    }

    func testOverlappingRefreshesAreIgnoredUntilInFlightRefreshCompletes() {
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.manager.refreshRemoteConfig(isAppBackgrounded: true)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1

        self.remoteConfigAPI.complete(with: .success(.test(container: nil)))
        self.manager.refreshRemoteConfig(isAppBackgrounded: true)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2
        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.isAppBackgrounded) == true
    }

    func testSubsequentRunSendsOnlyRequestedPrefetchBlobsStillCachedLocally() throws {
        self.blobStore.stubbedContainsRefs = ["cachedBlob"]
        self.diskCache.stubbedRead = PersistedRemoteConfiguration(
            manifest: "v1.1710000100.sources:etag1",
            prefetchBlobs: ["cachedBlob", "purgedBlob"],
            topics: .init()
        )

        self.manager.refreshRemoteConfig(isAppBackgrounded: true)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigParameters?.request.prefetchedBlobs) == ["cachedBlob"]
        expect(self.blobStore.invokedCachedRefsCount) == 1
    }

    func testContainerResponsePersistsServerManifestAndChangedTopics() throws {
        self.diskCache.stubbedRead = nil
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "prefetch_blobs": ["newBlob"],
          "topics": {
            "sources": {
              "default": { "blob_ref": "newBlob" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )

        expect(self.diskCache.invokedWriteCount) == 1
        expect(self.diskCache.invokedWriteParameter?.domain) == "app"
        expect(self.diskCache.invokedWriteParameter?.manifest)
            == "v1.1710000100.sources:etag2"
        expect(self.diskCache.invokedWriteParameter?.activeTopics) == ["sources"]
        expect(self.diskCache.invokedWriteParameter?.prefetchBlobs) == ["newBlob"]
        expect(Self.blobRefsByTopic(from: self.diskCache.invokedWriteParameter?.topics)) == ["sources": ["newBlob"]]
    }

    func testContainerResponseDecodesCompressedConfigElement() throws {
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "api": { "url": "https://api.revenuecat.com" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.compressedContainer(
                config: response,
                configEncoding: .gzip
            )))
        )

        expect(self.diskCache.invokedWriteCount) == 1
        expect(self.diskCache.invokedWriteParameter?.manifest) == "v1.1710000100.sources:etag2"
    }

    func testContainerResponseMergesUnchangedTopicsAndPrunesDroppedTopics() throws {
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.product_entitlement_mapping:pemEtag1,sources:etag1",
            topics: .init(entries: [
                "sources": ["default": .init(blobRef: "oldSources")],
                "product_entitlement_mapping": ["default": .init(blobRef: "pemBlob")]
            ])
        )
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "default": { "blob_ref": "newSources" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )

        expect(Self.blobRefsByTopic(from: self.diskCache.invokedWriteParameter?.topics)) == ["sources": ["newSources"]]
        expect(self.blobStore.invokedRetainOnlyParameters) == Set(["newSources"])
    }

    func testContainerResponseKeepsPreviousEntriesForUnchangedTopicsStillActive() throws {
        let previousProductMapping = RemoteConfiguration.ConfigItem(
            blobRef: "pemBlob",
            content: ["format": "v1"]
        )
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.product_entitlement_mapping:pemEtag1,sources:etag1",
            topics: .init(entries: [
                "sources": ["default": .init(blobRef: "oldSources")],
                "product_entitlement_mapping": ["default": previousProductMapping]
            ])
        )
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.product_entitlement_mapping:pemEtag1,sources:etag2",
          "active_topics": ["sources", "product_entitlement_mapping"],
          "topics": {
            "sources": {
              "default": { "blob_ref": "newSources" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )

        expect(Self.blobRefsByTopic(from: self.diskCache.invokedWriteParameter?.topics)) == [
            "sources": ["newSources"],
            "product_entitlement_mapping": ["pemBlob"]
        ]
        expect(self.diskCache.invokedWriteParameter?.topics.entries["product_entitlement_mapping"]?["default"])
            == previousProductMapping
    }

    func testContainerResponsePersistsInlineOnlyChangedTopics() throws {
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "api": {
                "url": "https://api.revenuecat.com",
                "priority": 100
              }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )

        let item = self.diskCache.invokedWriteParameter?.topics.entries["sources"]?["api"]
        expect(item?.blobRef).to(beNil())
        expect(item?.content["url"]) == "https://api.revenuecat.com"
        expect(item?.content["priority"]) == 100
    }

    func testNoContentResponseWithPersistedCacheLeavesCacheUntouched() {
        let previous = Self.persisted(
            domain: "app",
            manifest: "v1.1710000100.sources:etag1",
            activeTopics: ["sources"],
            prefetchBlobs: ["prefetchBlob"],
            topics: .init(entries: ["sources": ["default": .init(blobRef: "sourceBlob")]])
        )
        self.diskCache.stubbedRead = previous

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .success(.test(container: nil)))

        expect(self.diskCache.invokedWriteCount) == 0
        expect(self.blobStore.invokedWriteCount) == 0
        expect(self.blobStore.invokedRetainOnlyCount) == 0
        expect(self.blobFetcher.invokedPrefetchCount) == 0
    }

    func testNoContentResponseWithNoPersistedCacheLeavesCacheUntouched() {
        self.diskCache.stubbedRead = nil

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(with: .success(.test(container: nil)))

        expect(self.diskCache.invokedWriteCount) == 0
        expect(self.blobStore.invokedWriteCount) == 0
        expect(self.blobStore.invokedRetainOnlyCount) == 0
        expect(self.blobFetcher.invokedPrefetchCount) == 0
    }

    func testBackendErrorLeavesCacheUntouched() {
        self.diskCache.stubbedRead = Self.persisted(
            manifest: "v1.1710000100.sources:etag1"
        )

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .failure(.networkError(.networkError(NSError(domain: "test", code: 1))))
        )

        expect(self.diskCache.invokedWriteCount) == 0
        expect(self.blobStore.invokedWriteCount) == 0
        expect(self.blobStore.invokedRetainOnlyCount) == 0
        expect(self.blobFetcher.invokedPrefetchCount) == 0
    }

    func testMalformedConfigPayloadLeavesCacheUntouched() throws {
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: "{ not valid json")))
        )

        expect(self.diskCache.invokedWriteCount) == 0
        expect(self.blobStore.invokedWriteCount) == 0
        expect(self.blobStore.invokedRetainOnlyCount) == 0
        expect(self.blobFetcher.invokedPrefetchCount) == 0
    }

    func testConfigDecodingUsesOnlyContainerConfigElement() throws {
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "default": { "blob_ref": "newBlob" }
            }
          }
        }
        """
        let invalidContentElement = "{ invalid content element json".asData

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(
                container: try Self.container(config: response, contentElements: [invalidContentElement])
            ))
        )

        expect(self.diskCache.invokedWriteCount) == 1
        expect(Self.blobRefsByTopic(from: self.diskCache.invokedWriteParameter?.topics)) == ["sources": ["newBlob"]]
    }

    func testContainerResponseCachesInlineContentElements() throws {
        let blob = "blob payload".asData
        let blobRef = RCContainerTestData.blobRef(for: blob)
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "default": { "blob_ref": "\(blobRef)" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(
                container: try Self.container(config: response, contentElements: [blob]),
                verificationResult: .verified
            ))
        )

        expect(self.blobStore.invokedWriteParameters?.ref) == blobRef
        expect(self.blobStore.invokedWriteParameters?.data) == blob
    }

    func testSingleElementFixtureCachesReferencedWorkflowBlob() throws {
        let fixture = try XCTUnwrap(RCContainerTestData.allFixtures.first { $0.fileName == "v1_single_element.bin" })
        let container = try RemoteConfigContainer(data: RCContainerTestData.container(fixture: fixture))
        let workflowBlobRef = RCContainerTestData.blobRef(for: RCContainerTestData.workflowBlob)
        let summerWorkflowBlobRef = RCContainerTestData.blobRef(for: RCContainerTestData.summerWorkflowBlob)

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(
                container: container,
                verificationResult: .verified
            ))
        )

        expect(self.diskCache.invokedWriteParameter?.activeTopics) == ["workflows"]
        expect(Self.blobRefsByTopic(from: self.diskCache.invokedWriteParameter?.topics)) == [
            "workflows": [workflowBlobRef, summerWorkflowBlobRef]
        ]
        expect(self.blobStore.invokedWriteParameters?.ref) == workflowBlobRef
        expect(self.blobStore.invokedWriteParameters?.data) == RCContainerTestData.workflowBlob
    }

    func testContainerResponseCachesDecodedCompressedInlineContentElements() throws {
        let blob = Data(repeating: UInt8(ascii: "b"), count: 2048)
        let blobRef = RCContainerTestData.blobRef(for: blob)
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "default": { "blob_ref": "\(blobRef)" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(
                container: try Self.compressedContainer(
                    config: response,
                    contentElements: [(payload: blob, encoding: .gzip)]
                ),
                verificationResult: .verified
            ))
        )

        expect(self.blobStore.invokedWriteParameters?.ref) == blobRef
        expect(self.blobStore.invokedWriteParameters?.data) == blob
    }

    func testContainerResponseSkipsUnsupportedCodecInlineContentElements() throws {
        let blob = "unsupported codec blob".asData
        let blobRef = RCContainerTestData.blobRef(for: blob)
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "default": { "blob_ref": "\(blobRef)" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(
                container: try Self.compressedContainer(
                    config: response,
                    contentElements: [(payload: blob, encoding: .zstd)]
                ),
                verificationResult: .verified
            ))
        )

        expect(self.blobStore.invokedWriteCount) == 0
        expect(Self.blobRefsByTopic(from: self.diskCache.invokedWriteParameter?.topics)) == ["sources": [blobRef]]
    }

    func testContainerResponseSkipsGzipInlineContentElementWithTrailingBytes() throws {
        let blob = Data(repeating: UInt8(ascii: "b"), count: 2048)
        let blobRef = RCContainerTestData.blobRef(for: blob)
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "default": { "blob_ref": "\(blobRef)" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(
                container: try RemoteConfigContainer(
                    data: RCContainerTestData.compressedContainerWithTrailingGzipContentElement(
                        config: response.asData,
                        content: blob,
                        trailingBytes: Data([0xff])
                    )
                ),
                verificationResult: .verified
            ))
        )

        expect(self.blobStore.invokedWriteCount) == 0
        expect(Self.blobRefsByTopic(from: self.diskCache.invokedWriteParameter?.topics)) == ["sources": [blobRef]]
    }

    func testContainerResponseCachesOnlyReferencedInlineContentElements() throws {
        let referencedBlob = "referenced blob".asData
        let unreferencedBlob = "unreferenced blob".asData
        let referencedBlobRef = RCContainerTestData.blobRef(for: referencedBlob)
        let unreferencedBlobRef = RCContainerTestData.blobRef(for: unreferencedBlob)
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "default": { "blob_ref": "\(referencedBlobRef)" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(
                container: try Self.container(config: response, contentElements: [referencedBlob, unreferencedBlob]),
                verificationResult: .verified
            ))
        )

        expect(self.blobStore.invokedWriteParametersList.map(\.ref)) == [referencedBlobRef]
        expect(self.blobStore.invokedWriteParametersList.map(\.data)) == [referencedBlob]
        expect(self.blobStore.invokedWriteParametersList.map(\.ref)).toNot(contain(unreferencedBlobRef))
    }

    func testContainerResponseCachesInlineContentElementReferencedOnlyByPrefetchBlobs() throws {
        let prefetchBlob = "prefetch blob".asData
        let prefetchBlobRef = RCContainerTestData.blobRef(for: prefetchBlob)
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "prefetch_blobs": ["\(prefetchBlobRef)"],
          "topics": {
            "sources": {
              "api": { "url": "https://api.revenuecat.com" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(
                container: try Self.container(config: response, contentElements: [prefetchBlob]),
                verificationResult: .verified
            ))
        )

        expect(self.blobStore.invokedWriteParameters?.ref) == prefetchBlobRef
        expect(self.blobStore.invokedWriteParameters?.data) == prefetchBlob
    }

    func testContainerResponseCachesOnlyValidInlineContentElements() throws {
        let validBlob = "valid blob".asData
        let invalidBlob = "invalid blob".asData
        let validBlobRef = RCContainerTestData.blobRef(for: validBlob)
        let invalidBlobRef = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "default": { "blob_ref": "\(validBlobRef)" }
            }
          }
        }
        """
        let containerData = RCContainerTestData.container(
            config: response.asData,
            contentElements: [validBlob, invalidBlob],
            checksumOverride: { index, payload in
                return index == 2
                    ? Array(repeating: 0, count: RCContainerTestData.checksumSize)
                    : RCContainerTestData.checksum(for: payload)
            }
        )

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(
                container: try RemoteConfigContainer(data: containerData),
                verificationResult: .verified
            ))
        )

        expect(self.blobStore.invokedWriteParametersList.map(\.ref)) == [validBlobRef]
        expect(self.blobStore.invokedWriteParametersList.map(\.data)) == [validBlob]
        expect(self.blobStore.invokedWriteParametersList.map(\.ref)).toNot(contain(invalidBlobRef))
    }

    func testContainerResponseRetainsPrefetchAndTopicBlobRefs() throws {
        let topicBlobRef = RCContainerTestData.blobRef(for: "topic blob".asData)
        let prefetchBlobRef = RCContainerTestData.blobRef(for: "prefetch blob".asData)
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "prefetch_blobs": ["\(prefetchBlobRef)"],
          "topics": {
            "sources": {
              "default": { "blob_ref": "\(topicBlobRef)" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(
                container: try Self.container(config: response),
                verificationResult: .verified
            ))
        )

        expect(self.blobStore.invokedRetainOnlyParameters) == Set([topicBlobRef, prefetchBlobRef])
    }

    func testContainerResponsePersistsServerPrefetchBlobRefs() throws {
        let cachedRef = RCContainerTestData.blobRef(for: "cached".asData)
        let missingRef = RCContainerTestData.blobRef(for: "missing".asData)
        self.blobStore.stubbedContainsRefs = [cachedRef]
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "prefetch_blobs": ["\(cachedRef)", "\(missingRef)"]
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(
                container: try Self.container(config: response),
                verificationResult: .verified
            ))
        )

        expect(self.diskCache.invokedWriteParameter?.prefetchBlobs) == [cachedRef, missingRef]
    }

    func testContainerResponsePrefetchesServerPrefetchBlobRefs() throws {
        let cachedRef = RCContainerTestData.blobRef(for: "cached".asData)
        let missingRef = RCContainerTestData.blobRef(for: "missing".asData)
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "prefetch_blobs": ["\(cachedRef)", "\(missingRef)"]
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(
                container: try Self.container(config: response),
                verificationResult: .verified
            ))
        )

        expect(self.blobFetcher.invokedPrefetchRefs) == [cachedRef, missingRef]
    }

    func testContainerResponseDoesNotPruneBlobStoreWhenCacheWriteFails() throws {
        let oldRef = RCContainerTestData.blobRef(for: "old".asData)
        let newRef = RCContainerTestData.blobRef(for: "new".asData)
        self.diskCache.stubbedWriteResult = false
        self.diskCache.stubbedRead = PersistedRemoteConfiguration(
            manifest: "v1.1710000100.sources:etag1",
            topics: .init(entries: ["sources": ["default": .init(blobRef: oldRef)]])
        )
        let blob = "new".asData
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "default": { "blob_ref": "\(newRef)" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(
                container: try Self.container(config: response, contentElements: [blob]),
                verificationResult: .verified
            ))
        )

        expect(self.diskCache.invokedWriteCount) == 1
        expect(self.blobStore.invokedWriteCount) == 0
        expect(self.blobStore.invokedRetainOnlyCount) == 0
    }

    func testClearCacheWipesDiskCacheAndBlobStore() {
        self.manager.clearCache()

        expect(self.diskCache.invokedClearCount) == 1
        expect(self.blobStore.invokedClearCount) == 1
    }

    func testResponseThatArrivesAfterClearCacheDoesNotPersist() throws {
        self.diskCache.stubbedRead = nil
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "default": { "blob_ref": "newBlob" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.manager.clearCache()
        self.remoteConfigAPI.complete(
            at: 0,
            with: .success(.test(container: try Self.container(config: response)))
        )

        expect(self.diskCache.invokedWriteCount) == 0
        expect(self.blobStore.invokedWriteCount) == 0
        expect(self.blobStore.invokedRetainOnlyCount) == 0
    }

    func testClearCacheWhileBuildingRequestDoesNotSendStaleRequest() {
        self.diskCache.readHandler = { [manager] in
            manager?.clearCache()
            return nil
        }

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 0
        expect(self.diskCache.invokedClearCount) == 1
        expect(self.blobStore.invokedClearCount) == 1
    }

    func testStaleNoContentResponseDoesNotReleaseNewerRefreshGuard() {
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.manager.clearCache()
        self.manager.refreshRemoteConfig(isAppBackgrounded: true)

        self.remoteConfigAPI.complete(at: 0, with: .success(.test(container: nil)))
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2

        self.remoteConfigAPI.complete(at: 1, with: .success(.test(container: nil)))
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 3
    }

    func testStaleContainerResponseDoesNotReleaseNewerRefreshGuard() throws {
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "default": { "blob_ref": "newBlob" }
            }
          }
        }
        """

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.manager.clearCache()
        self.manager.refreshRemoteConfig(isAppBackgrounded: true)

        self.remoteConfigAPI.complete(
            at: 0,
            with: .success(.test(container: try Self.container(config: response)))
        )
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2
        expect(self.diskCache.invokedWriteCount) == 0

        self.remoteConfigAPI.complete(at: 1, with: .success(.test(container: nil)))
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 3
    }

    func testStaleErrorResponseDoesNotReleaseNewerRefreshGuard() {
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.manager.clearCache()
        self.manager.refreshRemoteConfig(isAppBackgrounded: true)

        self.remoteConfigAPI.complete(
            at: 0,
            with: .failure(.networkError(.networkError(NSError(domain: "test", code: 1))))
        )
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 2

        self.remoteConfigAPI.complete(at: 1, with: .success(.test(container: nil)))
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 3
    }

    func testManagerCanSyncAgainAfterClearCache() throws {
        self.diskCache.stubbedRead = nil
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "default": { "blob_ref": "newBlob" }
            }
          }
        }
        """

        self.manager.clearCache()
        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        self.remoteConfigAPI.complete(
            with: .success(.test(container: try Self.container(config: response)))
        )

        expect(self.remoteConfigAPI.invokedGetRemoteConfigCount) == 1
        expect(self.diskCache.invokedWriteCount) == 1
    }

    func testClearCacheDuringPersistWaitsAndWipesAfterWrite() throws {
        self.diskCache.stubbedRead = nil
        let writeStarted = DispatchSemaphore(value: 0)
        let releaseWrite = DispatchSemaphore(value: 0)
        let clearEntered = DispatchSemaphore(value: 0)
        let writeReleaseResult: Atomic<DispatchTimeoutResult?> = nil
        let response = """
        {
          "domain": "app",
          "manifest": "v1.1710000100.sources:etag2",
          "active_topics": ["sources"],
          "topics": {
            "sources": {
              "default": { "blob_ref": "newBlob" }
            }
          }
        }
        """
        let container = try Self.container(config: response)
        self.diskCache.writeHandler = { _ in
            writeStarted.signal()
            writeReleaseResult.value = releaseWrite.wait(timeout: .now() + .seconds(5))
            return true
        }
        self.diskCache.clearHandler = {
            clearEntered.signal()
        }

        self.manager.refreshRemoteConfig(isAppBackgrounded: false)
        DispatchQueue.global().async {
            self.remoteConfigAPI.complete(
                with: .success(.test(container: container))
            )
        }
        expect(writeStarted.wait(timeout: .now() + .seconds(5))) == .success

        DispatchQueue.global().async {
            self.manager.clearCache()
        }

        expect(clearEntered.wait(timeout: .now() + .milliseconds(200))) == .timedOut

        releaseWrite.signal()
        expect(clearEntered.wait(timeout: .now() + .seconds(5))) == .success
        expect(writeReleaseResult.value) == .success
        expect(self.diskCache.invokedWriteCount) == 1
        expect(self.diskCache.invokedClearCount) == 1
    }

}

private extension RemoteConfigManagerTests {

    static func persisted(
        domain: String = RemoteConfiguration.defaultDomain,
        manifest: String,
        activeTopics: [String] = [],
        prefetchBlobs: [String] = [],
        topics: RemoteConfiguration.Topics = .init()
    ) -> PersistedRemoteConfiguration {
        return PersistedRemoteConfiguration(
            domain: domain,
            manifest: manifest,
            activeTopics: activeTopics,
            prefetchBlobs: prefetchBlobs,
            topics: topics
        )
    }

    static func blobRefsByTopic(from topics: RemoteConfiguration.Topics?) -> [String: Set<String>] {
        guard let topics else { return [:] }

        return topics.entries.mapValues { topic in
            Set(topic.values.compactMap(\.blobRef))
        }
    }

    static func container(
        config: String,
        contentElements: [Data] = []
    ) throws -> RemoteConfigContainer {
        return try RemoteConfigContainer(data: RCContainerTestData.container(
            config: config.asData,
            contentElements: contentElements
        ))
    }

    static func compressedContainer(
        config: String,
        configEncoding: RCContainer.Element.ContentEncoding = .none,
        contentElements: [(payload: Data, encoding: RCContainer.Element.ContentEncoding)] = []
    ) throws -> RemoteConfigContainer {
        return try RemoteConfigContainer(data: RCContainerTestData.compressedContainer(
            config: config.asData,
            configEncoding: configEncoding,
            contentElements: contentElements
        ))
    }

}

private extension RemoteConfigFetchResult {

    /// Builds a fetch result through the production initializer. A `nil` container
    /// represents a `204 No Content` response.
    static func test(
        container: RemoteConfigContainer?,
        verificationResult: VerificationResult = .verified
    ) -> RemoteConfigFetchResult {
        return RemoteConfigFetchResult(response: .init(
            httpStatusCode: container == nil ? .noContent : .success,
            responseHeaders: [:],
            body: container,
            verificationResult: verificationResult,
            isLoadShedderResponse: false,
            isFallbackUrlResponse: false
        ))
    }

}

private final class MockRemoteConfigAPI: RemoteConfigAPIType {

    private(set) var invokedGetRemoteConfigCount = 0
    private(set) var invokedGetRemoteConfigParameters: (
        request: RemoteConfigRequest,
        isAppBackgrounded: Bool
    )?
    private(set) var invokedGetRemoteConfigParametersList: [(
        request: RemoteConfigRequest,
        isAppBackgrounded: Bool
    )] = []

    private var completions: [Backend.ResponseHandler<RemoteConfigFetchResult>] = []

    func getRemoteConfig(
        request: RemoteConfigRequest,
        isAppBackgrounded: Bool,
        completion: @escaping Backend.ResponseHandler<RemoteConfigFetchResult>
    ) {
        self.invokedGetRemoteConfigCount += 1
        self.invokedGetRemoteConfigParameters = (request, isAppBackgrounded)
        self.invokedGetRemoteConfigParametersList.append((request, isAppBackgrounded))
        self.completions.append(completion)
    }

    func complete(with result: Result<RemoteConfigFetchResult, BackendError>) {
        self.completions.last?(result)
    }

    func complete(
        at index: Int,
        with result: Result<RemoteConfigFetchResult, BackendError>
    ) {
        self.completions[index](result)
    }

}

private final class MockRemoteConfigDiskCache: RemoteConfigDiskCacheType {

    var stubbedRead: PersistedRemoteConfiguration?
    var stubbedWriteResult = true
    var readHandler: (() -> PersistedRemoteConfiguration?)?
    var writeHandler: ((PersistedRemoteConfiguration) -> Bool)?
    var clearHandler: (() -> Void)?

    private(set) var invokedWriteCount = 0
    private(set) var invokedWriteParameter: PersistedRemoteConfiguration?
    private(set) var invokedClearCount = 0

    func read() -> PersistedRemoteConfiguration? {
        return self.readHandler?() ?? self.stubbedRead
    }

    @discardableResult
    func write(_ configuration: PersistedRemoteConfiguration) -> Bool {
        self.invokedWriteCount += 1
        self.invokedWriteParameter = configuration

        return self.writeHandler?(configuration) ?? self.stubbedWriteResult
    }

    func clear() {
        self.invokedClearCount += 1
        self.clearHandler?()
    }

}

private final class MockRemoteConfigBlobStore: RemoteConfigBlobStoreType {

    var stubbedContainsRefs: Set<String> = []

    private(set) var invokedWriteCount = 0
    private(set) var invokedWriteParameters: (ref: String, data: Data)?
    private(set) var invokedWriteParametersList: [(ref: String, data: Data)] = []
    private(set) var invokedCachedRefsCount = 0
    private(set) var invokedRetainOnlyCount = 0
    private(set) var invokedRetainOnlyParameters: Set<String>?
    private(set) var invokedClearCount = 0

    func contains(ref: String) -> Bool {
        return self.stubbedContainsRefs.contains(ref)
    }

    func read(ref: String) -> Data? {
        return nil
    }

    @discardableResult
    func write(
        ref: String,
        bytes: UnsafeRawBufferPointer
    ) -> Bool {
        self.invokedWriteCount += 1
        var data = Data()
        data.append(contentsOf: bytes.bindMemory(to: UInt8.self))
        self.invokedWriteParameters = (ref, data)
        self.invokedWriteParametersList.append((ref, data))
        return true
    }

    func cachedRefs() -> Set<String> {
        self.invokedCachedRefsCount += 1
        return self.stubbedContainsRefs
    }

    func retainOnly(_ refs: Set<String>) {
        self.invokedRetainOnlyCount += 1
        self.invokedRetainOnlyParameters = refs
    }

    func clear() {
        self.invokedClearCount += 1
    }

}

private final class MockRemoteConfigBlobFetcher: RemoteConfigBlobFetcherType {

    private(set) var invokedEnsureDownloadedRefs: [String] = []
    private(set) var invokedEnsureAllDownloadedRefs: [String] = []
    private(set) var invokedPrefetchCount = 0
    private(set) var invokedPrefetchRefs: [String] = []
    private(set) var invokedFetchAndVerifyRefs: [String] = []

    func ensureDownloaded(ref: String) async -> Bool {
        self.invokedEnsureDownloadedRefs.append(ref)
        return true
    }

    func ensureAllDownloaded(refs: [String]) async -> [String: Bool] {
        self.invokedEnsureAllDownloadedRefs = refs
        return Dictionary(uniqueKeysWithValues: refs.map { ($0, true) })
    }

    func prefetch(refs: [String]) {
        self.invokedPrefetchCount += 1
        self.invokedPrefetchRefs = refs
    }

    func fetchAndVerify(ref: String) async -> Bool {
        self.invokedFetchAndVerifyRefs.append(ref)
        return true
    }

}
