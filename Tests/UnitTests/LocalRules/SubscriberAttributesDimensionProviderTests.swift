//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SubscriberAttributesDimensionProviderTests.swift
//
//  Created by Rick van der Linden on 8/19/26.
//

// Swift Testing is only available with the Xcode 16+ toolchain
#if compiler(>=5.9)
#if canImport(Testing)

import Foundation
import Testing

@testable import RevenueCat

@Suite("Subscriber attributes dimension provider")
struct SubscriberAttributesProviderTests {

    @Test
    func exposesEveryStoredAttributeUnderItsOriginalName() async throws {
        let provider = Self.provider(
            Self.attribute("$email", value: "jane@example.com"),
            Self.attribute("goal", value: "lose_weight")
        )

        let dimensions = try await provider.dimensions(at: Self.evaluationDate)
        let attributes = Self.attributes(in: dimensions)

        #expect(provider.name == "subscriber_attributes")
        #expect(Set(attributes.keys) == ["$email", "goal"])
    }

    @Test
    func exposesValueAndUpdatedAtUnderCanonicalRoot() async throws {
        let provider = Self.provider(Self.attribute("goal", value: "lose_weight"))

        let dimensions = try await provider.dimensions(at: Self.evaluationDate)

        #expect(dimensions == [
            "subscriber_attributes": .object([
                "goal": .object([
                    "value": .string("lose_weight"),
                    "updated_at": .date(Self.setDate)
                ])
            ])
        ])
    }

    @Test
    func preservesAttributeValuesAsStrings() async throws {
        let dimensions = try await Self.provider(
            Self.attribute("seats", value: "3"),
            Self.attribute("betaOptIn", value: "true"),
            Self.attribute("sku", value: "0123")
        ).dimensions(at: Self.evaluationDate)

        #expect(Self.value(of: "seats", in: dimensions) == .string("3"))
        #expect(Self.value(of: "betaOptIn", in: dimensions) == .string("true"))
        #expect(Self.value(of: "sku", in: dimensions) == .string("0123"))
    }

    @Test
    func omitsDeletedAttributesRegardlessOfSyncState() async throws {
        let dimensions = try await Self.provider(
            Self.attribute("pending", value: nil, isSynced: false),
            Self.attribute("posted", value: nil, isSynced: true),
            Self.attribute("goal", value: "lose_weight")
        ).dimensions(at: Self.evaluationDate)

        #expect(Set(Self.attributes(in: dimensions).keys) == ["goal"])
    }

    @Test
    func omitsEmptyAndUnreachableAttributeNames() async throws {
        let snapshot = try await DimensionResolver(
            dimensionProviders: [
                Self.provider(
                    Self.attribute("user.tier", value: "gold"),
                    Self.attribute("", value: "anything"),
                    Self.attribute("tier", value: "gold")
                )
            ]
        ).snapshot()

        guard case .object(let attributes) = snapshot.values["subscriber_attributes"] else {
            Issue.record("Expected subscriber attribute dimensions")
            return
        }
        #expect(Set(attributes.keys) == ["tier"])
    }

    @Test
    func omitsNamespaceWhenThereAreNoAttributes() async throws {
        let snapshot = try await DimensionResolver(
            dimensionProviders: [Self.provider()]
        ).snapshot()

        #expect(snapshot.values["subscriber_attributes"] == nil)
    }

    @Test
    func readFailureLeavesOtherDimensionsAvailable() async throws {
        let provider = SubscriberAttributesDimensionProvider {
            throw TestError.unavailable
        }
        let snapshot = try await DimensionResolver(
            dimensionProviders: [
                SubscriberAttributesTestDeviceProvider(),
                provider
            ],
            dateProvider: MockDateProvider(stubbedNow: Self.evaluationDate)
        ).snapshot()

        #expect(snapshot.values == [
            "evaluated_at": .int(1_718_452_800_000),
            "platform": .string("ios")
        ])
    }

    @Test
    func readsAttributesForEveryEvaluation() async throws {
        let attributes: Atomic<SubscriberAttribute.Dictionary> = .init([
            "goal": Self.attribute("goal", value: "lose_weight")
        ])
        let provider = SubscriberAttributesDimensionProvider {
            attributes.value
        }

        let first = try await provider.dimensions(at: Self.evaluationDate)
        attributes.value = ["goal": Self.attribute("goal", value: "gain_muscle")]
        let second = try await provider.dimensions(at: Self.evaluationDate)

        #expect(Self.value(of: "goal", in: first) == .string("lose_weight"))
        #expect(Self.value(of: "goal", in: second) == .string("gain_muscle"))
    }

    @Test
    func readsAttributesForCurrentAppUserOnEveryEvaluation() async throws {
        let deviceCache = DeviceCache(
            systemInfo: MockSystemInfo(finishTransactions: false),
            userDefaults: MockUserDefaults()
        )
        let currentUserProvider = MockCurrentUserProvider(mockAppUserID: "first-user")
        deviceCache.store(
            subscriberAttribute: Self.attribute("goal", value: "lose_weight"),
            appUserID: "first-user"
        )
        deviceCache.store(
            subscriberAttribute: Self.attribute("goal", value: "gain_muscle"),
            appUserID: "second-user"
        )
        let provider = SubscriberAttributesDimensionProvider(
            deviceCache: deviceCache,
            currentUserProvider: currentUserProvider
        )

        let first = try await provider.dimensions(at: Self.evaluationDate)
        currentUserProvider.mockAppUserID = "second-user"
        let second = try await provider.dimensions(at: Self.evaluationDate)

        #expect(Self.value(of: "goal", in: first) == .string("lose_weight"))
        #expect(Self.value(of: "goal", in: second) == .string("gain_muscle"))
    }

    @Test
    func attributesCanBeEvaluatedUsingSDKDimensionPaths() async throws {
        let recentSetDate = Self.evaluationDate.addingTimeInterval(-86_400)
        let evaluator = LocalRulesEvaluator(
            dimensionProviders: [
                Self.provider(
                    Self.attribute("$email", value: "jane@example.com"),
                    Self.attribute("seats", value: "3"),
                    Self.attribute("goal", value: "lose_weight"),
                    Self.attribute("tier", value: "gold", setTime: recentSetDate)
                )
            ],
            dateProvider: MockDateProvider(stubbedNow: Self.evaluationDate)
        )

        let matchingPredicates = [
            #"{"==":[{"var":"subscriber_attributes.$email.value"},"jane@example.com"]}"#,
            #"{"==":[{"var":"subscriber_attributes.seats.value"},3]}"#,
            #"{">":[{"var":"subscriber_attributes.seats.value"},2]}"#,
            #"""
            {"<":[
                {"-":[{"var":"evaluated_at"},
                      {"var":"subscriber_attributes.tier.updated_at"}]},
                604800000
            ]}
            """#
        ]
        let nonMatchingPredicates = [
            #"{"==":[{"var":"subscriber_attributes.goal.value"},"gain_muscle"]}"#,
            // An attribute the app never set on this device, and one the SDK does not expose. Both
            // need a default, since reading a name that resolves to nothing is now an error.
            #"{"!!":{"var":["subscriber_attributes.favoriteColor.value",false]}}"#,
            #"{"!!":{"var":["subscriber_attributes.goal.is_synced",false]}}"#,
            #"""
            {"<":[
                {"-":[{"var":"evaluated_at"},
                      {"var":"subscriber_attributes.goal.updated_at"}]},
                604800000
            ]}
            """#
        ]

        for predicate in matchingPredicates {
            #expect(try await evaluator.match(in: [TestSubscriberAttributeRule(predicate: predicate)]) != nil)
        }
        for predicate in nonMatchingPredicates {
            #expect(try await evaluator.match(in: [TestSubscriberAttributeRule(predicate: predicate)]) == nil)
        }
    }

    private static let evaluationDate = Date(timeIntervalSince1970: 1_718_452_800)
    private static let setDate = Date(timeIntervalSince1970: 1_714_780_800)

    private static func attribute(
        _ key: String,
        value: String?,
        isSynced: Bool = true,
        setTime: Date = Self.setDate
    ) -> SubscriberAttribute {
        return SubscriberAttribute(
            withKey: key,
            value: value,
            isSynced: isSynced,
            setTime: setTime
        )
    }

    private static func provider(
        _ attributes: SubscriberAttribute...
    ) -> SubscriberAttributesDimensionProvider {
        return SubscriberAttributesDimensionProvider {
            Dictionary(uniqueKeysWithValues: attributes.map { ($0.key, $0) })
        }
    }

    private static func value(
        of name: String,
        in dimensions: [String: DimensionValue]
    ) -> DimensionValue? {
        guard case .object(let attribute) = Self.attributes(in: dimensions)[name] else { return nil }
        return attribute["value"]
    }

    private static func attributes(
        in dimensions: [String: DimensionValue]
    ) -> [String: DimensionValue] {
        guard case .object(let attributes) = dimensions["subscriber_attributes"] else { return [:] }
        return attributes
    }

}

private struct TestSubscriberAttributeRule: LocalRule {

    let predicate: String

}

private struct SubscriberAttributesTestDeviceProvider: DimensionProvider {

    let name = "device"

    func dimensions(at _: Date) async throws -> [String: DimensionValue] {
        return ["platform": .string("ios")]
    }

}

private enum TestError: Error {

    case unavailable

}

#endif
#endif
