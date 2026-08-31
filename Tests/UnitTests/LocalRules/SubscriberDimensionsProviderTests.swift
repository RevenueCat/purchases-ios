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
    func everySupportedValueShapeIsKept() {
        let dimensions = Self.provider(#"""
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
    func unreadableValuesAreDroppedWithoutDroppingOthers() {
        let dimensions = Self.provider(
            #"{"gone":null,"codes":[1,2],"plan":"annual"}"#
        ).dimensions(at: Date())

        #expect(dimensions == ["plan": .string("annual")])
    }

    @Test(arguments: ["not json", #"["an","array"]"#, #""a string""#, "42"])
    func nonObjectCacheContributesNothing(_ json: String) {
        #expect(Self.provider(json).dimensions(at: Date()).isEmpty)
    }

    @Test
    func missingCacheContributesNothing() {
        let provider = SubscriberDimensionsProvider(cachedDimensionsProvider: { nil })

        #expect(provider.dimensions(at: Date()).isEmpty)
    }

    @Test
    func cacheReadFailureContributesNothing() {
        let provider = SubscriberDimensionsProvider(cachedDimensionsProvider: {
            throw TestError.unavailable
        })

        #expect(provider.dimensions(at: Date()).isEmpty)
    }

    @Test
    func cacheIsReadForEveryEvaluation() {
        let data = Atomic(Data(#"{"plan":"annual"}"#.utf8))
        let provider = SubscriberDimensionsProvider(cachedDimensionsProvider: { data.value })

        #expect(provider.dimensions(at: Date())["plan"] == .string("annual"))

        data.value = Data(#"{"plan":"monthly"}"#.utf8)

        #expect(provider.dimensions(at: Date())["plan"] == .string("monthly"))
    }

    @Test
    func productionProviderReadsDimensionsForCurrentIdentityOnEveryEvaluation() {
        let deviceCache = MockDeviceCache()
        let currentUserProvider = MockCurrentUserProvider(mockAppUserID: "user-a")
        deviceCache.cache(
            subscriberDimensions: Data(#"{"plan":"annual"}"#.utf8),
            appUserID: "user-a"
        )
        deviceCache.cache(
            subscriberDimensions: Data(#"{"plan":"monthly"}"#.utf8),
            appUserID: "user-b"
        )
        let provider = SubscriberDimensionsProvider(
            deviceCache: deviceCache,
            currentUserProvider: currentUserProvider
        )

        #expect(provider.dimensions(at: Date())["plan"] == .string("annual"))

        currentUserProvider.mockAppUserID = "user-b"

        #expect(provider.dimensions(at: Date())["plan"] == .string("monthly"))
    }

    @Test
    func dimensionsAreReadableByPredicates() async throws {
        let snapshot = try await DimensionResolver(dimensionProviders: [
            Self.provider(#"{"plan":"annual","seats":3,"profile":{"tier":"gold"}}"#)
        ]).snapshot()

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
            _ = try await DimensionResolver(dimensionProviders: [device, subscriber]).snapshot()
            Issue.record("Expected duplicate ownership to fail")
        } catch let error as DimensionResolutionError {
            #expect(error == .conflictingValue(path: "platform"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    private static func provider(_ json: String) -> SubscriberDimensionsProvider {
        return SubscriberDimensionsProvider(cachedDimensionsProvider: { Data(json.utf8) })
    }

}

private enum TestError: Error {
    case unavailable
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
