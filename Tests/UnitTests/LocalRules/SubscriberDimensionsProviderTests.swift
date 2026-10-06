//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriberDimensionsProviderTests.swift
//
//  Created by Rick van der Linden on 8/31/26.
//

// Swift Testing is only available with the Xcode 16+ toolchain
#if compiler(>=5.9)
#if canImport(Testing)

import Foundation
import Testing

@testable import RevenueCat

@Suite("Subscriber dimensions")
struct SubscriberDimensionsProviderTests {

    @Test
    func everySupportedValueShapeIsKept() async throws {
        let dimensions = try await Self.provider(#"""
            {
                "plan": "annual",
                "beta": true,
                "seats": 3,
                "score": 0.75,
                "profile": {"tier": "gold", "age": 42},
                "teams": [{"id": "a"}, {"id": "b"}]
            }
            """#).dimensions(at: Date())

        #expect(dimensions == [
            "plan": .string("annual"),
            "beta": .bool(true),
            "seats": .int(3),
            "score": .double(0.75),
            "profile": .object([
                "tier": .string("gold"),
                "age": .int(42)
            ]),
            "teams": .objectList([
                ["id": .string("a")],
                ["id": .string("b")]
            ])
        ])
    }

    @Test
    func explicitNullValuesAreKeptWithoutDroppingOthers() async throws {
        let dimensions = try await Self.provider(
            #"{"gone":null,"codes":[1,2],"plan":"annual"}"#
        ).dimensions(at: Date())

        #expect(dimensions == ["gone": .null, "plan": .string("annual")])
        #expect(dimensions["missing"] == nil)
    }

    @Test
    func explicitNullValuesAreKeptInsideObjects() async throws {
        let dimensions = try await Self.provider(
            #"{"profile":{"nickname":null,"tier":"gold"},"plan":"annual"}"#
        ).dimensions(at: Date())

        #expect(dimensions == [
            "profile": .object([
                "nickname": .null,
                "tier": .string("gold")
            ]),
            "plan": .string("annual")
        ])
    }

    @Test(arguments: ["not json", #"["an","array"]"#, #""a string""#, "42"])
    func nonObjectCacheContributesNothing(_ json: String) async throws {
        #expect(try await Self.provider(json).dimensions(at: Date()).isEmpty)
    }

    @Test
    func missingCacheContributesNothing() async throws {
        let provider = Self.providerWithoutCache()

        #expect(try await provider.dimensions(at: Date()).isEmpty)
    }

    @Test
    func cacheIsReadForEveryEvaluation() async throws {
        let deviceCache = MockDeviceCache()
        let currentUserProvider = MockCurrentUserProvider(mockAppUserID: "test")
        let provider = SubscriberDimensionsProvider(
            store: SubscriberDimensionsStore(deviceCache: deviceCache),
            currentUserProvider: currentUserProvider,
            configProvider: TestSubscriberDimensionsConfigProvider(.notConfigured)
        )
        deviceCache.cache(
            subscriberDimensions: Data(#"{"plan":"annual"}"#.utf8),
            asOf: Date(timeIntervalSince1970: 100),
            appUserID: "test"
        )

        #expect(try await provider.dimensions(at: Date())["plan"] == .string("annual"))

        deviceCache.cache(
            subscriberDimensions: Data(#"{"plan":"monthly"}"#.utf8),
            asOf: Date(timeIntervalSince1970: 200),
            appUserID: "test"
        )

        #expect(try await provider.dimensions(at: Date())["plan"] == .string("monthly"))
    }

    @Test
    func productionProviderReadsDimensionsForCurrentIdentityOnEveryEvaluation() async throws {
        let deviceCache = MockDeviceCache()
        let currentUserProvider = MockCurrentUserProvider(mockAppUserID: "user-a")
        deviceCache.cache(
            subscriberDimensions: Data(#"{"plan":"annual"}"#.utf8),
            asOf: Date(timeIntervalSince1970: 100),
            appUserID: "user-a"
        )
        deviceCache.cache(
            subscriberDimensions: Data(#"{"plan":"monthly"}"#.utf8),
            asOf: Date(timeIntervalSince1970: 100),
            appUserID: "user-b"
        )
        let provider = SubscriberDimensionsProvider(
            store: SubscriberDimensionsStore(deviceCache: deviceCache),
            currentUserProvider: currentUserProvider,
            configProvider: TestSubscriberDimensionsConfigProvider(.notConfigured)
        )

        #expect(try await provider.dimensions(at: Date())["plan"] == .string("annual"))

        currentUserProvider.mockAppUserID = "user-b"

        #expect(try await provider.dimensions(at: Date())["plan"] == .string("monthly"))
    }

    @Test
    func configuredDimensionsWinWhenTheyAreNewer() async throws {
        let deviceCache = MockDeviceCache()
        let cachedAsOf = Date(timeIntervalSince1970: 100)
        let configured = SubscriberDimensions(
            values: ["country": .string("NL")],
            asOf: Date(timeIntervalSince1970: 200)
        )
        let provider = Self.provider(
            #"{"country":"US"}"#,
            asOf: cachedAsOf,
            configResolution: .resolved(configured),
            deviceCache: deviceCache
        )

        #expect(try await provider.dimensions(at: Date()) == configured.values)
        #expect(deviceCache.cachedSubscriberDimensions(appUserID: "test") == nil)
    }

    @Test
    func purchaseDimensionsWinWhenTheyAreNewer() async throws {
        let provider = Self.provider(
            #"{"country":"NL"}"#,
            asOf: Date(timeIntervalSince1970: 200),
            configResolution: .resolved(.init(
                values: ["country": .string("US")],
                asOf: Date(timeIntervalSince1970: 100)
            ))
        )

        #expect(try await provider.dimensions(at: Date()) == ["country": .string("NL")])
    }

    @Test
    func persistedPurchaseDimensionsBeatOlderConfigAfterRelaunch() async throws {
        let userDefaults = MockUserDefaults()
        let systemInfo = MockSystemInfo(finishTransactions: false)
        let appUserID = "test"
        let initialDeviceCache = DeviceCache(systemInfo: systemInfo, userDefaults: userDefaults)
        initialDeviceCache.cache(
            subscriberDimensions: Data(#"{"country":"NL"}"#.utf8),
            asOf: Date(timeIntervalSince1970: 200),
            appUserID: appUserID
        )

        let relaunchedDeviceCache = DeviceCache(systemInfo: systemInfo, userDefaults: userDefaults)
        let provider = SubscriberDimensionsProvider(
            store: SubscriberDimensionsStore(deviceCache: relaunchedDeviceCache),
            currentUserProvider: MockCurrentUserProvider(mockAppUserID: appUserID),
            configProvider: TestSubscriberDimensionsConfigProvider(.resolved(.init(
                values: ["country": .string("US")],
                asOf: Date(timeIntervalSince1970: 100)
            )))
        )

        #expect(try await provider.dimensions(at: Date()) == ["country": .string("NL")])
    }

    @Test
    func purchaseDimensionsWinWhenTimestampsAreEqual() async throws {
        let asOf = Date(timeIntervalSince1970: 100)
        let provider = Self.provider(
            #"{"country":"US"}"#,
            asOf: asOf,
            configResolution: .resolved(.init(values: ["country": .string("NL")], asOf: asOf))
        )

        #expect(try await provider.dimensions(at: Date()) == ["country": .string("US")])
    }

    @Test
    func notConfiguredUsesPurchaseSubscriberDimensions() async throws {
        let provider = Self.provider(
            #"{"country":"NL"}"#,
            asOf: Date(timeIntervalSince1970: 100),
            configResolution: .notConfigured
        )

        #expect(try await provider.dimensions(at: Date()) == ["country": .string("NL")])
    }

    @Test
    func unavailableConfigurationFailsDimensionResolution() async {
        let provider = Self.provider(
            #"{"country":"NL"}"#,
            asOf: Date(timeIntervalSince1970: 100),
            configResolution: .unavailable
        )

        await #expect(throws: SubscriberDimensionsProviderError.configurationUnavailable) {
            try await provider.dimensions(at: Date())
        }
    }

    @Test
    func configurationErrorsArePropagated() async {
        let provider = SubscriberDimensionsProvider(
            store: SubscriberDimensionsStore(deviceCache: MockDeviceCache()),
            currentUserProvider: MockCurrentUserProvider(mockAppUserID: "test"),
            configProvider: ThrowingConfigProvider()
        )

        await #expect(throws: TestConfigError.failure) {
            try await provider.dimensions(at: Date())
        }
    }

    @Test
    func dimensionsAreReadableByPredicates() async throws {
        let snapshot = try await DimensionResolver(
            dimensionProviders: [
                Self.provider(#"{"plan":"annual","seats":3,"profile":{"tier":"gold"}}"#)
            ],
            currentAppUserIDProvider: { "user" }
        ).snapshot()

        #expect(try RulesEngine.evaluate(
            predicate: #"{"==":[{"var":"plan"},"annual"]}"#,
            variables: snapshot.values
        ).get())
        #expect(try RulesEngine.evaluate(
            predicate: #"{">":[{"var":"seats"},2]}"#,
            variables: snapshot.values
        ).get())
        #expect(try RulesEngine.evaluate(
            predicate: #"{"==":[{"var":"profile.tier"},"gold"]}"#,
            variables: snapshot.values
        ).get())
    }

    @Test
    func collisionWithSDKDimensionFailsSnapshot() async {
        let subscriber = Self.provider(#"{"platform":"spoofed"}"#)
        let device = TestProvider(values: ["platform": .string("ios")])

        do {
            _ = try await DimensionResolver(
                dimensionProviders: [device, subscriber],
                currentAppUserIDProvider: { "user" }
            ).snapshot()
            Issue.record("Expected duplicate ownership to fail")
        } catch let error as DimensionResolutionError {
            #expect(error == .conflictingValue(path: "platform"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    private static func provider(
        _ json: String,
        asOf: Date = Date(timeIntervalSince1970: 100),
        configResolution: SubscriberDimensionsResolution = .notConfigured,
        deviceCache: MockDeviceCache = MockDeviceCache()
    ) -> SubscriberDimensionsProvider {
        let currentUserProvider = MockCurrentUserProvider(mockAppUserID: "test")
        deviceCache.cache(
            subscriberDimensions: Data(json.utf8),
            asOf: asOf,
            appUserID: "test"
        )
        return SubscriberDimensionsProvider(
            store: SubscriberDimensionsStore(deviceCache: deviceCache),
            currentUserProvider: currentUserProvider,
            configProvider: TestSubscriberDimensionsConfigProvider(configResolution)
        )
    }

    private static func providerWithoutCache() -> SubscriberDimensionsProvider {
        return SubscriberDimensionsProvider(
            store: SubscriberDimensionsStore(deviceCache: MockDeviceCache()),
            currentUserProvider: MockCurrentUserProvider(mockAppUserID: "test"),
            configProvider: TestSubscriberDimensionsConfigProvider(.notConfigured)
        )
    }

}

private final class TestSubscriberDimensionsConfigProvider: SubscriberDimensionsConfigProviderType,
                                                              @unchecked Sendable {

    private let resolution: SubscriberDimensionsResolution

    init(_ resolution: SubscriberDimensionsResolution) {
        self.resolution = resolution
    }

    func dimensions() async throws -> SubscriberDimensionsResolution {
        return self.resolution
    }

    func cachedDimensions() -> SubscriberDimensionsResolution? {
        return self.resolution
    }

    func remoteConfigEventReceived(_ event: RemoteConfigLifecycleEvent) {}

}

private enum TestConfigError: Error {

    case failure

}

private final class ThrowingConfigProvider: SubscriberDimensionsConfigProviderType, @unchecked Sendable {

    func dimensions() async throws -> SubscriberDimensionsResolution { throw TestConfigError.failure }
    func cachedDimensions() -> SubscriberDimensionsResolution? { return nil }
    func remoteConfigEventReceived(_ event: RemoteConfigLifecycleEvent) {}

}

private struct TestProvider: DimensionProvider {

    let name = "test"
    let values: [String: DimensionValue]

    func dimensions(at _: Date) -> [String: DimensionValue] {
        return self.values
    }
}

#endif
#endif
