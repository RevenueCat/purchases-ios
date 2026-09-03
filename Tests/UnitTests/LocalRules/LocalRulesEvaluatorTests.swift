//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LocalRulesEvaluatorTests.swift
//
//  Created by Rick van der Linden on 7/28/26.
//

// Swift Testing is only available with the Xcode 16+ toolchain
#if compiler(>=5.9)
#if canImport(Testing)

import Foundation
import Testing

@testable import RevenueCat

@Suite("Local rules evaluation")
struct LocalRulesEvaluatorTests {

    @Test
    func batchUsesOneFreshSnapshotForEveryRule() async throws {
        let date = Date(timeIntervalSince1970: 1_234)
        let provider = TestDimensionProvider(
            name: "device",
            snapshots: [
                ["launch_count": .int(1)],
                ["launch_count": .int(2)]
            ]
        )
        let evaluator = Self.evaluator(dimensionProviders: [provider], date: date)

        let rule = try await evaluator.match(in: [
            TestLocalRule(
                id: TestRuleID.doesNotMatch,
                predicate: #"{"==":[{"var":"launch_count"},2]}"#
            ),
            TestLocalRule(
                id: TestRuleID.matches,
                predicate: #"{"==":[{"var":"launch_count"},1]}"#
            ),
            TestLocalRule(
                id: TestRuleID.notEvaluated,
                predicate: "{not-json"
            )
        ])

        #expect(rule?.id == .matches)
        #expect(await provider.invocationCount == 1)
        #expect(await provider.receivedDates == [date])
    }

    @Test
    func subsequentEvaluationPullsProviderAgain() async throws {
        let provider = TestDimensionProvider(
            name: "store",
            snapshots: [
                ["count": .int(1)],
                ["count": .int(2)]
            ]
        )
        let evaluator = Self.evaluator(dimensionProviders: [provider])

        let first = try await evaluator.match(in: [
            TestLocalRule(id: "first", predicate: #"{"==":[{"var":"count"},1]}"#)
        ])
        let second = try await evaluator.match(in: [
            TestLocalRule(id: "second", predicate: #"{"==":[{"var":"count"},2]}"#)
        ])

        #expect(first?.id == "first")
        #expect(second?.id == "second")
        #expect(await provider.invocationCount == 2)
    }

    @Test
    func allProvidersReceiveSameDate() async throws {
        let date = Date(timeIntervalSince1970: 9_876)
        let device = TestDimensionProvider(
            name: "device",
            snapshots: [["device_ready": .bool(true)]]
        )
        let store = TestDimensionProvider(
            name: "store",
            snapshots: [["store_ready": .bool(true)]]
        )
        let evaluator = Self.evaluator(dimensionProviders: [device, store], date: date)

        _ = try await evaluator.match(in: [
            TestLocalRule(id: "test", predicate: "true")
        ])

        #expect(await device.receivedDates == [date])
        #expect(await store.receivedDates == [date])
    }

    @Test
    func mergesProviderValuesAtRoot() async throws {
        let date = Date(timeIntervalSince1970: 5_432)
        let identity = TestDimensionProvider(
            name: "identity",
            snapshots: [[
                "app_version": .string("1.2.3"),
                "is_debug_build": .bool(true),
                "screen_scale": .double(3)
            ]]
        )
        let environment = TestDimensionProvider(
            name: "environment",
            snapshots: [["tracking_enabled": .bool(false)]]
        )
        let store = TestDimensionProvider(
            name: "store",
            snapshots: [["shoe_size": .int(42)]]
        )

        let snapshot = try await DimensionResolver(
            dimensionProviders: [identity, environment, store],
            currentAppUserIDProvider: { "user" },
            dateProvider: MockDateProvider(stubbedNow: date)
        ).snapshot()

        #expect(snapshot.evaluationDate == date)
        #expect(snapshot.values == [
            "evaluated_at": .int(5_432_000),
            "app_version": .string("1.2.3"),
            "is_debug_build": .bool(true),
            "screen_scale": .float(3),
            "tracking_enabled": .bool(false),
            "shoe_size": .int(42)
        ])
    }

    @Test
    func recursivelyOmitsInvalidProviderDimensionNames() async throws {
        let provider = TestDimensionProvider(
            name: "device",
            snapshots: [[
                "": .string("empty"),
                " \n": .string("blank"),
                "user.tier": .string("gold"),
                "platform": .string("ios"),
                "profile": .object([
                    "": .string("empty"),
                    "\t": .string("blank"),
                    "account.tier": .string("gold"),
                    "name": .string("Rick"),
                    "preferences": .object([
                        "invalid.key": .bool(false),
                        "notifications_enabled": .bool(true)
                    ])
                ]),
                "invalid_object": .object([
                    "invalid.key": .string("value")
                ]),
                "events": .objectList([
                    [
                        "": .string("empty"),
                        " ": .string("blank"),
                        "event.name": .string("purchase"),
                        "name": .string("purchase")
                    ],
                    [
                        "invalid.key": .string("value")
                    ]
                ])
            ]]
        )

        let snapshot = try await DimensionResolver(
            dimensionProviders: [provider],
            currentAppUserIDProvider: { "user" }
        ).snapshot()

        #expect(snapshot.values.filter { $0.key != "evaluated_at" } == [
            "platform": .string("ios"),
            "profile": .object([
                "name": .string("Rick"),
                "preferences": .object([
                    "notifications_enabled": .bool(true)
                ])
            ]),
            "events": .array([
                .object(["name": .string("purchase")])
            ])
        ])
    }

    @Test
    func customVariablesAreAvailableInCustomNamespace() async throws {
        let evaluator = Self.evaluator(dimensionProviders: [])

        let rule = try await evaluator.match(
            in: [
                TestLocalRule(
                    id: "matching-rule",
                    predicate: """
                        {
                          "and": [
                            { "==": [{ "var": "custom.name" }, "Rick"] },
                            { "==": [{ "var": "custom.attempts" }, 3] },
                            { "==": [{ "var": "custom.score" }, 4.5] },
                            { "==": [{ "var": "custom.subscriber" }, true] }
                          ]
                        }
                        """
                )
            ],
            customVariables: [
                "name": .string("Rick"),
                "attempts": .int(3),
                "score": .double(4.5),
                "subscriber": .bool(true)
            ]
        )

        #expect(rule?.id == "matching-rule")
    }

    @Test
    func customVariablesAreScopedToOneEvaluation() async throws {
        let evaluator = Self.evaluator(dimensionProviders: [])
        let rules = [
            TestLocalRule(
                id: "matching-rule",
                predicate: #"{"==":[{"var":"custom.source"},"onboarding"]}"#
            )
        ]

        let first = try await evaluator.match(
            in: rules,
            customVariables: ["source": .string("onboarding")]
        )
        let second = try await evaluator.match(
            in: rules,
            customVariables: ["source": .string("paywall")]
        )

        #expect(first?.id == "matching-rule")
        #expect(second?.id == nil)
    }

    @Test
    func duplicateLeafIsAConfigurationError() async {
        let first = TestDimensionProvider(
            name: "first",
            snapshots: [["app_version": .string("1.2.3")]]
        )
        let second = TestDimensionProvider(
            name: "second",
            snapshots: [["app_version": .string("2.0.0")]]
        )

        do {
            _ = try await DimensionResolver(
                dimensionProviders: [first, second],
                currentAppUserIDProvider: { "user" }
            ).snapshot()
            Issue.record("Expected duplicate ownership to fail")
        } catch let error as DimensionResolutionError {
            #expect(error == .conflictingValue(path: "app_version"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test(arguments: ["evaluated_at", "custom"])
    func providerCannotClaimReservedRoot(_ reservedRoot: String) async {
        let provider = TestDimensionProvider(
            name: "invalid",
            snapshots: [[reservedRoot: .string("claimed")]]
        )

        do {
            _ = try await DimensionResolver(
                dimensionProviders: [provider],
                currentAppUserIDProvider: { "user" }
            ).snapshot()
            Issue.record("Expected reserved root ownership to fail")
        } catch let error as DimensionResolutionError {
            #expect(error == .conflictingValue(path: reservedRoot))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func providerFailureIsThrown() async {
        let evaluator = Self.evaluator(dimensionProviders: [
            FailingDimensionProvider(name: "store")
        ])

        do {
            _ = try await evaluator.match(in: [
                TestLocalRule(id: "test", predicate: "true")
            ])
            Issue.record("Expected provider failure to be thrown")
        } catch let error as DimensionResolutionError {
            guard case .providerFailed(let providerName, _) = error else {
                Issue.record("Unexpected resolution error: \(error)")
                return
            }
            #expect(providerName == "store")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func appUserChangeWhileDimensionsAreCollectedThrows() async {
        let currentAppUserID = Atomic("user-a")
        let provider = ClosureDimensionProvider(name: "identity_flipper") { _ in
            currentAppUserID.value = "user-b"
            return [:]
        }
        let resolver = DimensionResolver(
            dimensionProviders: [provider],
            currentAppUserIDProvider: { currentAppUserID.value }
        )

        do {
            _ = try await resolver.snapshot()
            Issue.record("Expected an app user change to fail the snapshot")
        } catch let error as DimensionResolutionError {
            #expect(error == .appUserChanged)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func appUserChangingBackBeforeCollectionFinishesDoesNotFailTheSnapshot() async throws {
        let currentAppUserID = Atomic("user-a")
        let changeAppUser = ClosureDimensionProvider(name: "identity_flipper") { _ in
            currentAppUserID.value = "user-b"
            return [:]
        }
        let restoreAppUser = ClosureDimensionProvider(name: "identity_flipper_back") { _ in
            currentAppUserID.value = "user-a"
            return [:]
        }
        let resolver = DimensionResolver(
            dimensionProviders: [changeAppUser, restoreAppUser],
            currentAppUserIDProvider: { currentAppUserID.value }
        )

        _ = try await resolver.snapshot()
    }

    @Test
    func appUserChangeDuringSnapshotFailsRuleEvaluation() async {
        let currentAppUserID = Atomic("user-a")
        let provider = ClosureDimensionProvider(name: "identity_flipper") { _ in
            currentAppUserID.value = "user-b"
            return [:]
        }
        let evaluator = Self.evaluator(
            dimensionProviders: [provider],
            currentAppUserIDProvider: { currentAppUserID.value }
        )

        do {
            _ = try await evaluator.match(in: [
                TestLocalRule(id: "test", predicate: "true")
            ])
            Issue.record("Expected an app user change to fail rule evaluation")
        } catch let error as DimensionResolutionError {
            #expect(error == .appUserChanged)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func invalidRuleDoesNotPreventLaterRuleFromMatching() async throws {
        let evaluator = Self.evaluator(dimensionProviders: [])

        let rule = try await evaluator.match(in: [
            TestLocalRule(id: "invalid", predicate: "{not-json"),
            TestLocalRule(id: "valid", predicate: "true")
        ])

        #expect(rule?.id == "valid")
    }

    @Test
    func unsupportedOperatorIsThrown() async {
        let evaluator = Self.evaluator(dimensionProviders: [])

        do {
            _ = try await evaluator.match(in: [
                TestLocalRule(id: "unsupported", predicate: #"{"future_operator":[]}"#)
            ])
            Issue.record("Expected predicate failure to be thrown")
        } catch let error as LocalRulesEvaluationError {
            #expect(error == .predicateEvaluation(
                ruleIndex: 0,
                error: .unsupportedOperator(name: "future_operator")
            ))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func omittedVariableIsTreatedAsNoMatch() async throws {
        // A missing local value means this audience does not match. It should
        // not make the complete rules configuration unavailable.
        let logger = TestLogHandler(testIdentifier: #function)
        let evaluator = Self.evaluator(dimensionProviders: [
            TestDimensionProvider(
                name: "device",
                snapshots: [["known": .bool(true)]]
            )
        ])

        let rule = try await evaluator.match(in: [
            TestLocalRule(
                id: "reads-unknown-dimension",
                predicate: #"{"==":[{"var":"unknown"},null]}"#
            )
        ])

        #expect(rule == nil)
        let expectedMessage = Strings.localRules.ruleUnresolvedVariable(ruleIndex: 0, path: "unknown")
        #expect(logger.messages.contains {
            $0.level == .debug && $0.message.contains(expectedMessage.description)
        })
    }

    @Test
    func ruleReadingAnOmittedVariableDoesNotBlockALaterMatch() async throws {
        // The first rule cannot be answered, but that says nothing about the
        // second, so evaluation carries on and a later match still wins.
        let evaluator = Self.evaluator(dimensionProviders: [
            TestDimensionProvider(
                name: "device",
                snapshots: [["known": .bool(true)]]
            )
        ])

        let rule = try await evaluator.match(in: [
            TestLocalRule(
                id: "reads-unknown-dimension",
                predicate: #"{"==":[{"var":"unknown"},null]}"#
            ),
            TestLocalRule(
                id: "reads-known-dimension",
                predicate: #"{"==":[{"var":"known"},true]}"#
            )
        ])

        #expect(rule?.id == "reads-known-dimension")
    }

    @Test
    func emptyBatchDoesNotCollectVariables() async throws {
        let provider = TestDimensionProvider(
            name: "device",
            snapshots: [["value": .int(1)]]
        )
        let evaluator = Self.evaluator(dimensionProviders: [provider])

        let rule = try await evaluator.match(in: [TestLocalRule<String>]())
        #expect(rule?.id == nil)
        #expect(await provider.invocationCount == 0)
    }

    @Test
    func successfulFalseRulesReturnNil() async throws {
        let evaluator = Self.evaluator(dimensionProviders: [])

        let rule = try await evaluator.match(in: [
            TestLocalRule(id: "false", predicate: "false")
        ])

        #expect(rule?.id == nil)
    }

    @Test
    func resolvedPredicatesAreLookedUpOnlyUntilARuleMatches() async throws {
        let evaluator = Self.evaluator(dimensionProviders: [])
        let resolved = Atomic<[String]>([])

        let rule = try await evaluator.match(in: ["first", "second", "third"]) { rule in
            resolved.modify { $0.append(rule) }
            return rule == "first" ? "false" : "true"
        }

        #expect(rule == "second")
        #expect(resolved.value == ["first", "second"])
    }

    @Test
    func predicateLookupFailureEndsTheCallInsteadOfFallingThrough() async {
        let evaluator = Self.evaluator(dimensionProviders: [])
        let resolved = Atomic<[String]>([])

        do {
            _ = try await evaluator.match(in: ["unreadable", "would-match"]) { rule in
                resolved.modify { $0.append(rule) }
                guard rule != "unreadable" else { throw TestPredicateLookupError.failed }
                return "true"
            }
            Issue.record("Expected the lookup failure to be thrown")
        } catch is TestPredicateLookupError {
            // A rule whose predicate can't be obtained leaves its outcome unknown, so the rules after it
            // must not be treated as the winner.
            #expect(resolved.value == ["unreadable"])
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func resolvedPredicatesShareTheSingleSnapshot() async throws {
        let provider = TestDimensionProvider(
            name: "device",
            snapshots: [["launch_count": .int(1)], ["launch_count": .int(2)]]
        )
        let evaluator = Self.evaluator(dimensionProviders: [provider])

        let rule = try await evaluator.match(in: ["a", "b"]) { _ in
            #"{"==":[{"var":"launch_count"},1]}"#
        }

        #expect(rule == "a")
        #expect(await provider.invocationCount == 1)
    }

    @Test
    func emptyRulesNeverLookUpAPredicate() async throws {
        let evaluator = Self.evaluator(dimensionProviders: [])
        let resolved = Atomic<Int>(0)

        let rule = try await evaluator.match(in: [String]()) { _ in
            resolved.modify { $0 += 1 }
            return "true"
        }

        #expect(rule == nil)
        #expect(resolved.value == 0)
    }

    @Test
    func cancellationStopsTheRuleWalk() async {
        let evaluator = Self.evaluator(dimensionProviders: [])
        let resolved = Atomic<[String]>([])
        let lookupStarted = Atomic<Bool>(false)
        let cancelled = Atomic<Bool>(false)

        let task = Task {
            try await evaluator.match(in: ["first", "second"]) { rule in
                resolved.modify { $0.append(rule) }
                lookupStarted.value = true
                // Stands in for an audience read that suspends while the task is cancelled. Nothing on this
                // path throws on its own, so the walk only stops if the evaluator checks cancellation itself.
                while !cancelled.value {
                    await Task.yield()
                }
                return "false"
            }
        }

        while !lookupStarted.value {
            await Task.yield()
        }
        task.cancel()
        cancelled.value = true

        do {
            _ = try await task.value
            Issue.record("Expected cancellation to be thrown")
        } catch is CancellationError {
            #expect(resolved.value == ["first"])
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func cancellationIsThrownByMatch() async {
        let evaluator = Self.evaluator(dimensionProviders: [
            CancellingDimensionProvider(name: "store")
        ])

        do {
            _ = try await evaluator.match(in: [
                TestLocalRule(id: "test", predicate: "true")
            ])
            Issue.record("Expected cancellation to be thrown")
        } catch is CancellationError {
            // Expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

private extension LocalRulesEvaluatorTests {

    static func evaluator(
        dimensionProviders: [any DimensionProvider],
        date: Date = Date(timeIntervalSince1970: 100),
        currentAppUserIDProvider: @escaping @Sendable () -> String = { "user" }
    ) -> LocalRulesEvaluator {
        LocalRulesEvaluator(
            dimensionProviders: dimensionProviders,
            currentAppUserIDProvider: currentAppUserIDProvider,
            dateProvider: MockDateProvider(stubbedNow: date)
        )
    }
}

private struct TestLocalRule<ID: Sendable>: LocalRule {

    let id: ID
    let predicate: String
}

private enum TestPredicateLookupError: Error {
    case failed
}

private enum TestRuleID: Sendable {

    case doesNotMatch
    case matches
    case notEvaluated
}

private actor TestDimensionProvider: DimensionProvider {

    nonisolated let name: String

    private let snapshots: [[String: DimensionValue]]
    private(set) var invocationCount = 0
    private(set) var receivedDates: [Date] = []

    init(
        name: String,
        snapshots: [[String: DimensionValue]]
    ) {
        self.name = name
        self.snapshots = snapshots
    }

    func dimensions(at date: Date) -> [String: DimensionValue] {
        self.receivedDates.append(date)
        defer { self.invocationCount += 1 }
        guard !self.snapshots.isEmpty else { return [:] }
        return self.snapshots[min(self.invocationCount, self.snapshots.count - 1)]
    }
}

private struct FailingDimensionProvider: DimensionProvider {

    struct ProviderError: Error {}

    let name: String

    func dimensions(at date: Date) async throws -> [String: DimensionValue] {
        throw ProviderError()
    }
}

private struct CancellingDimensionProvider: DimensionProvider {

    let name: String

    func dimensions(at date: Date) async throws -> [String: DimensionValue] {
        throw CancellationError()
    }
}

private struct ClosureDimensionProvider: DimensionProvider {

    let name: String
    let dimensionsProvider: @Sendable (Date) async throws -> [String: DimensionValue]

    func dimensions(at date: Date) async throws -> [String: DimensionValue] {
        return try await self.dimensionsProvider(date)
    }
}

#endif
#endif
