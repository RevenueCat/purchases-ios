//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowsCacheTests.swift
//
//  Created by RevenueCat.

import Foundation
import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

class WorkflowsCacheTests: TestCase {

    private var dateProvider: MockCurrentDateProvider!
    private var deviceCache: MockDeviceCache!
    private var systemInfo: MockSystemInfo!
    private var cache: WorkflowsCache!

    override func setUp() {
        super.setUp()

        self.dateProvider = MockCurrentDateProvider()
        self.systemInfo = MockSystemInfo(finishTransactions: false)
        // Production environment so foreground (5 min) and background (25 hr) TTLs differ.
        self.systemInfo.stubbedIsSandbox = false
        self.deviceCache = MockDeviceCache(systemInfo: self.systemInfo)
        self.cache = WorkflowsCache(deviceCache: self.deviceCache,
                                    dateProvider: self.dateProvider)
    }

    // MARK: - Workflow detail cache

    func testCachedWorkflowReturnsNilWhenNothingCached() {
        expect(self.cache.cachedWorkflow(workflowId: "wf_1")).to(beNil())
    }

    func testCachedWorkflowReturnsCachedValueAfterCaching() throws {
        let result = try Self.workflowDataResult(id: "wf_1")
        self.seedWorkflow(result, workflowId: "wf_1")
        expect(self.cache.cachedWorkflow(workflowId: "wf_1")) == result
    }

    func testIsWorkflowCacheStaleIsTrueWhenNothingCached() {
        expect(self.cache.isWorkflowCacheStale(workflowId: "wf_1", isAppBackgrounded: false)) == true
        expect(self.cache.isWorkflowCacheStale(workflowId: "wf_1", isAppBackgrounded: true)) == true
    }

    func testIsWorkflowCacheStaleIsFalseRightAfterCachingInForeground() throws {
        self.seedWorkflow(try Self.workflowDataResult(id: "wf_1"), workflowId: "wf_1")
        expect(self.cache.isWorkflowCacheStale(workflowId: "wf_1", isAppBackgrounded: false)) == false
    }

    func testIsWorkflowCacheStaleIsTrueAfterForegroundTTLExpires() throws {
        self.seedWorkflow(try Self.workflowDataResult(id: "wf_1"), workflowId: "wf_1")
        self.dateProvider.advance(by: 6 * 60)
        expect(self.cache.isWorkflowCacheStale(workflowId: "wf_1", isAppBackgrounded: false)) == true
    }

    func testIsWorkflowCacheStaleIsFalseAfterForegroundTTLWhenBackgrounded() throws {
        self.seedWorkflow(try Self.workflowDataResult(id: "wf_1"), workflowId: "wf_1")
        self.dateProvider.advance(by: 6 * 60)
        expect(self.cache.isWorkflowCacheStale(workflowId: "wf_1", isAppBackgrounded: true)) == false
    }

    func testIsWorkflowCacheStaleIsTrueAfterBackgroundTTLExpires() throws {
        self.seedWorkflow(try Self.workflowDataResult(id: "wf_1"), workflowId: "wf_1")
        self.dateProvider.advance(by: 26 * 60 * 60)
        expect(self.cache.isWorkflowCacheStale(workflowId: "wf_1", isAppBackgrounded: true)) == true
    }

    func testClearCacheRemovesAllCachedWorkflows() throws {
        self.seedWorkflow(try Self.workflowDataResult(id: "wf_1"), workflowId: "wf_1")
        self.seedWorkflow(try Self.workflowDataResult(id: "wf_2"), workflowId: "wf_2")

        self.cache.clearCache()

        expect(self.cache.cachedWorkflow(workflowId: "wf_1")).to(beNil())
        expect(self.cache.cachedWorkflow(workflowId: "wf_2")).to(beNil())
        expect(self.cache.isWorkflowCacheStale(workflowId: "wf_1", isAppBackgrounded: false)) == true
        expect(self.cache.isWorkflowCacheStale(workflowId: "wf_2", isAppBackgrounded: false)) == true
    }

    func testDifferentWorkflowIdsAreCachedIndependently() throws {
        let first = try Self.workflowDataResult(id: "wf_1")
        self.seedWorkflow(first, workflowId: "wf_1")
        self.dateProvider.advance(by: 6 * 60)
        let second = try Self.workflowDataResult(id: "wf_2")
        self.seedWorkflow(second, workflowId: "wf_2")

        // Both values remain retrievable.
        expect(self.cache.cachedWorkflow(workflowId: "wf_1")) == first
        expect(self.cache.cachedWorkflow(workflowId: "wf_2")) == second

        // wf_1 was cached 6 minutes ago so it is stale in foreground; wf_2 is fresh.
        expect(self.cache.isWorkflowCacheStale(workflowId: "wf_1", isAppBackgrounded: false)) == true
        expect(self.cache.isWorkflowCacheStale(workflowId: "wf_2", isAppBackgrounded: false)) == false
    }

    // MARK: - Workflows list cache

    func testIsWorkflowsListCacheStaleIsTrueInitiallyAndFalseAfterCaching() {
        expect(self.cache.isWorkflowsListCacheStale(isAppBackgrounded: false)) == true
        self.seedWorkflowsList(.init(workflows: []))
        expect(self.cache.isWorkflowsListCacheStale(isAppBackgrounded: false)) == false
    }

    func testIsWorkflowsListCacheStaleIsTrueAfterForegroundTTLExpires() {
        self.seedWorkflowsList(.init(workflows: []))
        self.dateProvider.advance(by: 6 * 60)
        expect(self.cache.isWorkflowsListCacheStale(isAppBackgrounded: false)) == true
    }

    func testIsWorkflowsListCacheStaleIsFalseAfterForegroundTTLWhenBackgrounded() {
        self.seedWorkflowsList(.init(workflows: []))
        self.dateProvider.advance(by: 6 * 60)
        expect(self.cache.isWorkflowsListCacheStale(isAppBackgrounded: true)) == false
    }

    func testIsWorkflowsListCacheStaleIsTrueAfterBackgroundTTLExpires() {
        self.seedWorkflowsList(.init(workflows: []))
        self.dateProvider.advance(by: 26 * 60 * 60)
        expect(self.cache.isWorkflowsListCacheStale(isAppBackgrounded: true)) == true
    }

    func testWorkflowIdForOfferingIdIsDerivedFromTheCachedList() {
        self.seedWorkflowsList(.init(workflows: [
            .init(id: "wf_1", displayName: "Flow", offeringId: "default", prefetch: false)
        ]))
        expect(self.cache.workflowId(forOfferingId: "default")) == "wf_1"
        expect(self.cache.workflowId(forOfferingId: "premium")).to(beNil())
    }

    func testWorkflowIdForOfferingIdReturnsLastMatchWhenOfferingIsDuplicated() {
        self.seedWorkflowsList(.init(workflows: [
            .init(id: "wf_1", displayName: "Flow", offeringId: "default", prefetch: false),
            .init(id: "wf_2", displayName: "Flow", offeringId: "default", prefetch: false)
        ]))
        expect(self.cache.workflowId(forOfferingId: "default")) == "wf_2"
    }

    func testWorkflowIdForOfferingIdDoesNotFallBackToDiskWhenNotInMemory() {
        // The lookup is in-memory only. Restoring the disk copy is the caller's job (via
        // `cachedWorkflowsListResponseFromDisk()` + `cache(workflowsList:ifGeneration:)`), so an
        // uncached list resolves to nil without touching disk.
        self.deviceCache.stubbedCachedWorkflowsListResponse = .init(workflows: [
            .init(id: "wf_1", displayName: "Flow", offeringId: "default", prefetch: false)
        ])

        expect(self.cache.workflowId(forOfferingId: "default")).to(beNil())
        expect(self.deviceCache.invokedCachedWorkflowsListResponse) == false
    }

    func testClearCacheResetsWorkflowsListStalenessAndWorkflowIdLookup() {
        self.seedWorkflowsList(.init(workflows: [
            .init(id: "wf_1", displayName: "Flow", offeringId: "default", prefetch: false)
        ]))
        self.cache.clearCache()
        expect(self.cache.isWorkflowsListCacheStale(isAppBackgrounded: false)) == true
        expect(self.cache.workflowId(forOfferingId: "default")).to(beNil())
    }

    func testForceWorkflowsListCacheStaleMarksStaleButKeepsWorkflowIdLookup() {
        self.seedWorkflowsList(.init(workflows: [
            .init(id: "wf_1", displayName: "Flow", offeringId: "default", prefetch: false)
        ]))
        expect(self.cache.isWorkflowsListCacheStale(isAppBackgrounded: false)) == false

        self.cache.forceWorkflowsListCacheStale()

        // Stale (so the next fetch refetches) but the map still resolves until then.
        expect(self.cache.isWorkflowsListCacheStale(isAppBackgrounded: false)) == true
        expect(self.cache.workflowId(forOfferingId: "default")) == "wf_1"
    }

    func testForceWorkflowsListCacheStaleIsNoOpWhenNothingCached() {
        self.cache.forceWorkflowsListCacheStale()
        expect(self.cache.isWorkflowsListCacheStale(isAppBackgrounded: false)) == true
        expect(self.cache.workflowId(forOfferingId: "default")).to(beNil())
    }

    // MARK: - Disk persistence

    func testCacheWorkflowsListForwardsResponseToDeviceCache() {
        self.seedWorkflowsList(.init(workflows: [
            .init(id: "wf_1", displayName: "Flow", offeringId: "default", prefetch: false)
        ]))
        expect(self.deviceCache.cacheWorkflowsListResponseCount) == 1
    }

    func testClearCacheClearsDiskCache() {
        self.cache.clearCache()
        expect(self.deviceCache.clearWorkflowsListResponseCacheCount) == 1
    }

    func testCachedWorkflowsListResponseFromDiskReturnsPersistedResponse() {
        self.deviceCache.stubbedCachedWorkflowsListResponse = .init(workflows: [
            .init(id: "wf_1", displayName: "Flow", offeringId: "default", prefetch: false)
        ])
        let response = self.cache.cachedWorkflowsListResponseFromDisk()
        expect(response?.workflows.first?.id) == "wf_1"
    }

    func testCachedWorkflowsListResponseFromDiskReturnsNilWhenNothingCached() {
        self.deviceCache.stubbedCachedWorkflowsListResponse = nil
        expect(self.cache.cachedWorkflowsListResponseFromDisk()).to(beNil())
    }

    // MARK: - Workflow detail disk persistence

    func testPersistWorkflowDetailsToDiskPersistsKeyedByWorkflowId() throws {
        let result = try Self.workflowDataResult(id: "wf_1")
        self.cache.persistWorkflowDetailsToDisk(["wf_1": result],
                                                ifGeneration: self.cache.currentCacheGeneration())

        expect(self.deviceCache.cacheWorkflowDetailsCount) == 1
        expect(self.deviceCache.cachedWorkflowDetailsParameter?["wf_1"]) == result
    }

    func testPersistWorkflowDetailsToDiskMergesIntoExistingPersisted() throws {
        let existing = try Self.workflowDataResult(id: "wf_existing")
        self.deviceCache.stubbedCachedWorkflowDetails = ["wf_existing": existing]

        let new = try Self.workflowDataResult(id: "wf_new")
        self.cache.persistWorkflowDetailsToDisk(["wf_new": new],
                                                ifGeneration: self.cache.currentCacheGeneration())

        let persisted = try XCTUnwrap(self.deviceCache.cachedWorkflowDetailsParameter)
        expect(persisted.keys).to(contain("wf_existing", "wf_new"))
        expect(persisted["wf_existing"]) == existing
        expect(persisted["wf_new"]) == new
    }

    func testPersistWorkflowDetailsToDiskIsNoOpForEmptyBatch() {
        self.cache.persistWorkflowDetailsToDisk([:], ifGeneration: self.cache.currentCacheGeneration())
        expect(self.deviceCache.cacheWorkflowDetailsCount) == 0
    }

    func testPersistWorkflowDetailsToDiskIsDroppedWhenGenerationChanged() throws {
        // A prefetch captures the generation, then an identity change clears the cache (bumping it),
        // then the prefetch's batch write lands: it must be dropped rather than reviving the old data.
        let staleGeneration = self.cache.currentCacheGeneration()
        self.cache.clearCache()

        self.cache.persistWorkflowDetailsToDisk(["wf_1": try Self.workflowDataResult(id: "wf_1")],
                                                ifGeneration: staleGeneration)

        expect(self.deviceCache.cacheWorkflowDetailsCount) == 0
        expect(self.deviceCache.cachedWorkflowDetailsParameter).to(beNil())
    }

    func testPersistWorkflowDetailsToDiskWritesWithCurrentGenerationAfterClear() throws {
        self.cache.clearCache()
        // A fresh prefetch (post-clear) captures the new generation and persists normally.
        self.cache.persistWorkflowDetailsToDisk(["wf_1": try Self.workflowDataResult(id: "wf_1")],
                                                ifGeneration: self.cache.currentCacheGeneration())

        expect(self.deviceCache.cachedWorkflowDetailsParameter?["wf_1"]).toNot(beNil())
    }

    // MARK: - Restore from disk

    func testRestoreWorkflowDetailsFromDiskRestoresFreshIntoMemory() throws {
        let result = try Self.workflowDataResult(id: "wf_1")
        self.deviceCache.stubbedCachedWorkflowDetails = ["wf_1": result]

        self.cache.restoreWorkflowDetailsFromDisk()

        expect(self.cache.cachedWorkflow(workflowId: "wf_1")) == result
        // Restored fresh, so it is served offline without a refetch.
        expect(self.cache.isWorkflowCacheStale(workflowId: "wf_1", isAppBackgrounded: false)) == false
    }

    func testRestoreWorkflowDetailsFromDiskIsNoOpWhenNothingPersisted() {
        self.deviceCache.stubbedCachedWorkflowDetails = nil
        self.cache.restoreWorkflowDetailsFromDisk()
        expect(self.cache.cachedWorkflow(workflowId: "wf_1")).to(beNil())
    }

    func testCacheWorkflowsListPrunesDetailsNotInNewList() throws {
        self.deviceCache.stubbedCachedWorkflowDetails = [
            "wf_old": try Self.workflowDataResult(id: "wf_old"),
            "wf_keep": try Self.workflowDataResult(id: "wf_keep")
        ]

        self.seedWorkflowsList(.init(workflows: [
            .init(id: "wf_keep", displayName: "Keep", offeringId: "default", prefetch: true)
        ]))

        let persisted = try XCTUnwrap(self.deviceCache.cachedWorkflowDetailsParameter)
        expect(persisted.keys).to(contain("wf_keep"))
        expect(persisted.keys).toNot(contain("wf_old"))
    }

    func testCacheWorkflowsListDoesNotRewriteDetailsWhenNothingPruned() throws {
        self.deviceCache.stubbedCachedWorkflowDetails = [
            "wf_keep": try Self.workflowDataResult(id: "wf_keep")
        ]

        self.seedWorkflowsList(.init(workflows: [
            .init(id: "wf_keep", displayName: "Keep", offeringId: "default", prefetch: true)
        ]))

        // Nothing to prune, so the detail store is left untouched (no rewrite).
        expect(self.deviceCache.cacheWorkflowDetailsCount) == 0
    }

    func testCacheWorkflowsListPruneIsNoOpWhenNoDetailsPersisted() {
        self.deviceCache.stubbedCachedWorkflowDetails = nil
        self.seedWorkflowsList(.init(workflows: [
            .init(id: "wf_1", displayName: "Flow", offeringId: "default", prefetch: true)
        ]))
        expect(self.deviceCache.cacheWorkflowDetailsCount) == 0
    }

    func testClearCacheClearsPersistedWorkflowDetails() {
        self.cache.clearCache()
        expect(self.deviceCache.clearWorkflowDetailsCacheCount) == 1
    }

    // MARK: - Generation-guarded in-memory cache

    func testCacheWorkflowWithCurrentGenerationStoresInMemory() throws {
        let result = try Self.workflowDataResult(id: "wf_1")
        self.cache.cache(workflow: result,
                         workflowId: "wf_1",
                         ifGeneration: self.cache.currentCacheGeneration())

        expect(self.cache.cachedWorkflow(workflowId: "wf_1")) == result
    }

    func testCacheWorkflowIsDroppedFromMemoryWhenGenerationChanged() throws {
        // A fetch captures the generation, then an identity change clears the cache (bumping it),
        // then the fetch's in-memory write lands: it must be dropped so the previous user's
        // (user-scoped) workflow detail can't repopulate memory for the new user.
        let staleGeneration = self.cache.currentCacheGeneration()
        self.cache.clearCache()

        self.cache.cache(workflow: try Self.workflowDataResult(id: "wf_1"),
                         workflowId: "wf_1",
                         ifGeneration: staleGeneration)

        expect(self.cache.cachedWorkflow(workflowId: "wf_1")).to(beNil())
    }

    // MARK: - Restore from disk does not clobber fresher memory

    func testRestoreWorkflowDetailsFromDiskFillsOnlyMissingIds() throws {
        let memoryValue = try Self.workflowDataResult(id: "wf_1", enrolledVariants: ["src": "memory"])
        let diskValue = try Self.workflowDataResult(id: "wf_1", enrolledVariants: ["src": "disk"])
        let filledValue = try Self.workflowDataResult(id: "wf_2")

        // An on-demand fetch already put a fresher wf_1 in memory that was never persisted.
        self.seedWorkflow(memoryValue, workflowId: "wf_1")
        self.deviceCache.stubbedCachedWorkflowDetails = ["wf_1": diskValue, "wf_2": filledValue]

        self.cache.restoreWorkflowDetailsFromDisk()

        // wf_1 keeps the fresher in-memory value; wf_2 is filled from disk.
        expect(self.cache.cachedWorkflow(workflowId: "wf_1")) == memoryValue
        expect(self.cache.cachedWorkflow(workflowId: "wf_2")) == filledValue
    }

    // MARK: - Disk persistence stays a subset of the latest list

    func testPersistWorkflowDetailsToDiskDropsIdsNotInCurrentList() throws {
        // The latest list only knows wf_keep.
        self.seedWorkflowsList(.init(workflows: [
            .init(id: "wf_keep", displayName: "Keep", offeringId: "default", prefetch: true)
        ]))

        // A slower prefetch from an earlier list tries to persist a since-pruned id alongside it.
        self.cache.persistWorkflowDetailsToDisk(
            [
                "wf_keep": try Self.workflowDataResult(id: "wf_keep"),
                "wf_stale": try Self.workflowDataResult(id: "wf_stale")
            ],
            ifGeneration: self.cache.currentCacheGeneration()
        )

        let persisted = try XCTUnwrap(self.deviceCache.cachedWorkflowDetailsParameter)
        expect(persisted.keys).to(contain("wf_keep"))
        expect(persisted.keys).toNot(contain("wf_stale"))
    }

    // MARK: - Generation-guarded list write

    func testCacheWorkflowsListWithCurrentGenerationWrites() {
        let didCache = self.cache.cache(workflowsList: .init(workflows: [
            .init(id: "wf_1", displayName: "Flow", offeringId: "default", prefetch: false)
        ]), ifGeneration: self.cache.currentCacheGeneration())

        expect(didCache) == true
        expect(self.cache.workflowId(forOfferingId: "default")) == "wf_1"
        expect(self.cache.isWorkflowsListCacheStale(isAppBackgrounded: false)) == false
    }

    func testCacheWorkflowsListIsDroppedWhenGenerationChanged() {
        // A list fetch captures the generation, then an identity change clears the cache (bumping it),
        // then the fetch's write lands: it must be dropped (and report false) so the previous user's
        // offeringId -> workflowId map can't repopulate the cleared cache.
        let staleGeneration = self.cache.currentCacheGeneration()
        self.cache.clearCache()

        let didCache = self.cache.cache(workflowsList: .init(workflows: [
            .init(id: "wf_1", displayName: "Flow", offeringId: "default", prefetch: false)
        ]), ifGeneration: staleGeneration)

        expect(didCache) == false
        expect(self.cache.workflowId(forOfferingId: "default")).to(beNil())
        expect(self.cache.isWorkflowsListCacheStale(isAppBackgrounded: false)) == true
    }

    // MARK: - WorkflowDataResult Codable round-trip
    // The disk cache encodes/decodes `WorkflowDataResult` as JSON, so it must round-trip losslessly,
    // including the `AnyDecodable`-backed fields (metadata, config, param values).

    func testWorkflowDataResultRoundTripsThroughCodable() throws {
        let original = WorkflowDataResult(
            workflow: try Self.richPublishedWorkflow(id: "wf_round_trip"),
            enrolledVariants: ["experiment_a": "variant_b"]
        )

        let encoded = try JSONEncoder.default.encode(original)
        let decoded = try JSONDecoder.default.decode(WorkflowDataResult.self, from: encoded)

        expect(decoded) == original
    }

    func testWorkflowDataResultRoundTripsWithoutEnrolledVariants() throws {
        let original = try Self.workflowDataResult(id: "wf_no_variants")

        let encoded = try JSONEncoder.default.encode(original)
        let decoded = try JSONDecoder.default.decode(WorkflowDataResult.self, from: encoded)

        expect(decoded) == original
        expect(decoded.enrolledVariants).to(beNil())
    }

    // MARK: - Helpers

    /// Seeds the in-memory detail cache. The production write is generation-guarded, so tests seed
    /// with the current generation, which always matches and lets the write land.
    private func seedWorkflow(_ result: WorkflowDataResult, workflowId: String) {
        self.cache.cache(workflow: result, workflowId: workflowId, ifGeneration: self.cache.currentCacheGeneration())
    }

    /// Seeds the workflows list cache. The production write is generation-guarded, so tests seed with
    /// the current generation, which always matches and lets the write land.
    private func seedWorkflowsList(_ response: WorkflowsListResponse) {
        self.cache.cache(workflowsList: response, ifGeneration: self.cache.currentCacheGeneration())
    }

    private static func workflowDataResult(id: String) throws -> WorkflowDataResult {
        return .init(workflow: try self.publishedWorkflow(id: id), enrolledVariants: nil)
    }

    private static func workflowDataResult(id: String,
                                           enrolledVariants: [String: String]?) throws -> WorkflowDataResult {
        return .init(workflow: try self.publishedWorkflow(id: id), enrolledVariants: enrolledVariants)
    }

    private static func publishedWorkflow(id: String) throws -> PublishedWorkflow {
        let json = """
        {
          "id": "\(id)",
          "display_name": "Test",
          "initial_step_id": "step_1",
          "steps": {
            "step_1": { "id": "step_1", "type": "screen", "screen_id": "screen_1" }
          },
          "screens": {
            "screen_1": {
              "template_name": "tmpl",
              "asset_base_url": "https://assets.revenuecat.com",
              "default_locale": "en_US",
              "components_localizations": {},
              "components_config": {
                "base": {
                  "stack": {
                    "type": "stack",
                    "components": [],
                    "dimension": { "type": "vertical", "alignment": "center", "distribution": "center" },
                    "size": { "width": { "type": "fill" }, "height": { "type": "fill" } },
                    "padding": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
                    "margin": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 }
                  },
                  "background": {
                    "type": "color",
                    "value": { "light": { "type": "hex", "value": "#FFFFFF" } }
                  }
                }
              },
              "offering_identifier": "default"
            }
          },
          "ui_config": {
            "app": { "colors": {}, "fonts": {} },
            "localizations": {}
          }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        return try JSONDecoder.default.decode(PublishedWorkflow.self, from: data)
    }

    /// Like ``publishedWorkflow(id:)`` but with the `AnyDecodable`-backed fields (`metadata`, step
    /// `config`/`param_values`) populated with nested values, so the Codable round-trip exercises
    /// `AnyDecodable` encoding rather than just empty dictionaries.
    private static func richPublishedWorkflow(id: String) throws -> PublishedWorkflow {
        let json = """
        {
          "id": "\(id)",
          "display_name": "Test",
          "initial_step_id": "step_1",
          "metadata": { "source": "cdn", "version": 3, "flags": ["a", "b"] },
          "steps": {
            "step_1": {
              "id": "step_1",
              "type": "screen",
              "screen_id": "screen_1",
              "param_values": { "count": 2, "label": "hello", "nested": { "k": true } },
              "metadata": { "note": "step-meta" }
            }
          },
          "screens": {
            "screen_1": {
              "template_name": "tmpl",
              "asset_base_url": "https://assets.revenuecat.com",
              "default_locale": "en_US",
              "components_localizations": {},
              "config": { "theme": "dark", "scale": 1.5 },
              "components_config": {
                "base": {
                  "stack": {
                    "type": "stack",
                    "components": [],
                    "dimension": { "type": "vertical", "alignment": "center", "distribution": "center" },
                    "size": { "width": { "type": "fill" }, "height": { "type": "fill" } },
                    "padding": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
                    "margin": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 }
                  },
                  "background": {
                    "type": "color",
                    "value": { "light": { "type": "hex", "value": "#FFFFFF" } }
                  }
                }
              },
              "offering_identifier": "default"
            }
          },
          "ui_config": {
            "app": { "colors": {}, "fonts": {} },
            "localizations": {}
          }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        return try JSONDecoder.default.decode(PublishedWorkflow.self, from: data)
    }

}
