//
//  AudiencesConfigProviderTests.swift
//  UnitTests
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation
import Nimble
@preconcurrency @testable import RevenueCat
import XCTest

final class AudiencesConfigProviderTests: TestCase {

    func testWarmCachesLocalDataBeforeConfigurationIsRequested() async throws {
        let manager = MockRemoteConfigManager()
        manager.stubbedTopics[.audiences] = ["default": .init(blobRef: "audiences-ref", prefetch: true)]
        manager.stubbedBlobData[.audiences] = [
            "default": #"{ "aud_123": { "id": "aud_123", "rules": {} } }"#.asData
        ]
        let provider = AudiencesConfigProvider(manager: manager)

        await provider.warm()
        let configuration = try await provider.configuration()

        expect(configuration?.audiences["aud_123"]?.id) == "aud_123"
        expect(manager.invokedCachedBlobDataParameters.map(\.itemKey)) == ["default"]
        expect(manager.invokedTopicCount) == 0
        expect(manager.invokedBlobDataParameters).to(beEmpty())
    }

    func testWarmSkipsAudienceConfigurationWithoutPrefetch() async throws {
        let manager = MockRemoteConfigManager()
        manager.stubbedTopics[.audiences] = ["default": .init(blobRef: "audiences-ref", prefetch: false)]
        manager.stubbedBlobData[.audiences] = [
            "default": #"{ "aud_123": { "id": "aud_123", "rules": {} } }"#.asData
        ]
        let provider = AudiencesConfigProvider(manager: manager)

        await provider.warm()

        expect(manager.invokedCachedBlobDataParameters).to(beEmpty())
        let configuration = try await provider.configuration()
        expect(configuration?.audiences["aud_123"]?.id) == "aud_123"
    }

    func testWarmDoesNotCacheDataFromASupersededGeneration() async throws {
        let manager = MockRemoteConfigManager()
        manager.stubbedTopics[.audiences] = ["default": .init(blobRef: "old", prefetch: true)]
        manager.stubbedBlobData[.audiences] = ["default": #"{ "old": { "id": "old", "rules": {} } }"#.asData]
        manager.shouldStoreCachedBlobDataCompletion = true
        let provider = AudiencesConfigProvider(manager: manager)

        let warm = Task { await provider.warm() }
        await expect(manager.invokedCachedBlobDataParameters.count).toEventually(equal(1))
        manager.configGeneration += 1
        manager.stubbedTopics[.audiences] = ["default": .init(blobRef: "new", prefetch: true)]
        manager.stubbedBlobData[.audiences] = ["default": #"{ "new": { "id": "new", "rules": {} } }"#.asData]
        manager.completeStoredCachedBlobReads()
        await warm.value

        let configuration = try await provider.configuration()
        expect(configuration?.audiences["new"]?.id) == "new"
        expect(configuration?.audiences["old"]).to(beNil())
    }

}
