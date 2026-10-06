//
//  SubscriberDimensionsConfigProviderTests.swift
//  RevenueCatTests
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation
import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

final class SubscriberDimensionsConfigProviderTests: TestCase {

    private var manager: MockRemoteConfigManager!
    private var provider: SubscriberDimensionsConfigProvider!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.manager = MockRemoteConfigManager()
        self.provider = SubscriberDimensionsConfigProvider(manager: self.manager)
    }

    /// Pinned as a literal so the SDK cannot silently diverge from the backend topic name.
    func testTopicWireNameMatchesTheBackend() {
        expect(RemoteConfigTopic.subscriberDimensions.wireName) == "subscriber_dimensions"
    }

    func testCachedDimensionsIsNilBeforeWarm() {
        expect(self.provider.cachedDimensions()).to(beNil())
    }

    func testWarmIsANoOpBeforeConfigIsCommitted() async {
        self.manager.stubbedHasCommittedConfig = false
        self.manager.stubbedTopics[.subscriberDimensions] = Self.spainTopic

        await self.provider.warm()

        expect(self.provider.cachedDimensions()).to(beNil())
    }

    func testWarmCachesNotConfiguredWhenTheTopicIsAbsent() async {
        await self.provider.warm()

        expect(self.provider.cachedDimensions()) == .notConfigured
    }

    func testWarmCachesTheDefaultItemsInlineContent() async {
        self.manager.stubbedTopics[.subscriberDimensions] = Self.spainTopic

        await self.provider.warm()

        expect(self.provider.cachedDimensions()) == .resolved(Self.spain)
    }

    func testWarmCachesUnavailableWhenTheDefaultItemIsMissing() async {
        self.manager.stubbedTopics[.subscriberDimensions] = [:]

        await self.provider.warm()

        expect(self.provider.cachedDimensions()) == .unavailable
    }

    func testWarmCachesUnavailableWhenTheDefaultItemIsUnusable() async throws {
        self.manager.stubbedTopics[.subscriberDimensions] = [
            "default": try Self.item(#"{"dimensions": {"country": "ES"}}"#)
        ]

        await self.provider.warm()

        expect(self.provider.cachedDimensions()) == .unavailable
    }

    func testConfigGenerationChangeInvalidatesTheCachedDimensions() async {
        self.manager.stubbedTopics[.subscriberDimensions] = Self.spainTopic
        await self.provider.warm()

        self.manager.configGeneration += 1

        expect(self.provider.cachedDimensions()).to(beNil())
    }

    func testDimensionsReturnsTheWarmedValueWithoutFetching() async throws {
        self.manager.stubbedTopics[.subscriberDimensions] = Self.spainTopic
        await self.provider.warm()

        let dimensions = try await self.provider.dimensions()

        expect(dimensions) == .resolved(Self.spain)
        expect(self.manager.invokedTopicCount) == 0
    }

    func testDimensionsReadsThroughTheConfigLayerWhenCold() async throws {
        self.manager.stubbedTopics[.subscriberDimensions] = Self.spainTopic

        let dimensions = try await self.provider.dimensions()

        expect(dimensions) == .resolved(Self.spain)
        expect(self.manager.invokedTopicCount) == 1
    }

    func testDimensionsReturnsNotConfiguredWhenTheTopicIsAbsent() async throws {
        let dimensions = try await self.provider.dimensions()

        expect(dimensions) == .notConfigured
    }

    func testDimensionsReturnsUnavailableWithoutCommittedConfig() async throws {
        self.manager.stubbedHasCommittedConfig = false

        let dimensions = try await self.provider.dimensions()

        expect(dimensions) == .unavailable
    }

    func testDimensionsPropagatesCancellation() async {
        self.manager.shouldStoreTopicCompletion = true
        let task = Task { try await self.provider.dimensions() }
        await expect(self.manager.invokedTopicCount).toEventually(equal(1))

        task.cancel()
        self.manager.completeStoredTopic()

        do {
            _ = try await task.value
            fail("Expected cancellation")
        } catch is CancellationError {
            // Expected.
        } catch {
            fail("Expected CancellationError, got \(error)")
        }
    }

    func testDimensionsPropagatesRepeatedlyStaleReads() async {
        var generationReadCount = 0
        self.manager.onConfigGenerationRead = {
            generationReadCount += 1
            self.manager.configGeneration = generationReadCount
        }

        do {
            _ = try await self.provider.dimensions()
            fail("Expected stale configuration")
        } catch let error as RemoteConfigConsistencyError {
            expect(error) == .stale
        } catch {
            fail("Expected RemoteConfigConsistencyError, got \(error)")
        }
        expect(self.manager.invokedTopicCount) == 2
    }

    func testObserverRegistrationWarmsTheCommittedTopic() async {
        self.manager.stubbedTopics[.subscriberDimensions] = Self.spainTopic

        self.provider.remoteConfigEventReceived(.observerRegistered(generation: self.manager.configGeneration))

        await expect(self.provider.cachedDimensions()).toEventually(equal(.resolved(Self.spain)))
    }

    private static var spainTopic: RemoteConfiguration.ConfigTopic {
        return [
            "default": .init(content: [
                "dimensions": ["country": "ES"],
                "as_of": 100
            ])
        ]
    }

    private static let spain = SubscriberDimensions(
        values: ["country": .string("ES")],
        asOf: 100
    )

    private static func item(_ json: String) throws -> RemoteConfiguration.ConfigItem {
        return try JSONDecoder.default.decode(RemoteConfiguration.ConfigItem.self, from: Data(json.utf8))
    }

}
