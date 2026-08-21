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
            namespace: .device,
            snapshots: [
                ["launchCount": .int(1)],
                ["launchCount": .int(2)]
            ]
        )
        let evaluator = Self.evaluator(dimensionProviders: [provider], date: date)

        let rule = try await evaluator.match(in: [
            TestLocalRule(
                id: TestRuleID.doesNotMatch,
                predicate: #"{"==":[{"var":"device.launchCount"},2]}"#
            ),
            TestLocalRule(
                id: TestRuleID.matches,
                predicate: #"{"==":[{"var":"device.launchCount"},1]}"#
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
            namespace: .session,
            snapshots: [
                ["count": .int(1)],
                ["count": .int(2)]
            ]
        )
        let evaluator = Self.evaluator(dimensionProviders: [provider])

        let first = try await evaluator.match(in: [
            TestLocalRule(id: "first", predicate: #"{"==":[{"var":"session.count"},1]}"#)
        ])
        let second = try await evaluator.match(in: [
            TestLocalRule(id: "second", predicate: #"{"==":[{"var":"session.count"},2]}"#)
        ])

        #expect(first?.id == "first")
        #expect(second?.id == "second")
        #expect(await provider.invocationCount == 2)
    }

    @Test
    func allProvidersReceiveSameDate() async throws {
        let date = Date(timeIntervalSince1970: 9_876)
        let device = TestDimensionProvider(
            namespace: .device,
            snapshots: [["ready": .bool(true)]]
        )
        let session = TestDimensionProvider(
            namespace: .session,
            snapshots: [["ready": .bool(true)]]
        )
        let evaluator = Self.evaluator(dimensionProviders: [device, session], date: date)

        _ = try await evaluator.match(in: [
            TestLocalRule(id: "test", predicate: "true")
        ])

        #expect(await device.receivedDates == [date])
        #expect(await session.receivedDates == [date])
    }

    @Test
    func mergesProviderValuesByNamespace() async throws {
        let date = Date(timeIntervalSince1970: 5_432)
        let identity = TestDimensionProvider(
            namespace: .device,
            snapshots: [[
                "appVersion": .string("1.2.3"),
                "isDebugBuild": .bool(true),
                "screenScale": .double(3)
            ]]
        )
        let environment = TestDimensionProvider(
            namespace: .device,
            snapshots: [["trackingEnabled": .bool(false)]]
        )
        let client = TestDimensionProvider(
            namespace: .client,
            snapshots: [["shoeSize": .int(42)]]
        )

        let snapshot = try await DimensionResolver(
            dimensionProviders: [identity, environment, client],
            dateProvider: MockDateProvider(stubbedNow: date)
        ).snapshot()

        #expect(snapshot.evaluationDate == date)
        #expect(snapshot.values == [
            "evaluatedAt": .int(5_432_000),
            "device": .object([
                "appVersion": .string("1.2.3"),
                "isDebugBuild": .bool(true),
                "screenScale": .float(3),
                "trackingEnabled": .bool(false)
            ]),
            "client": .object(["shoeSize": .int(42)])
        ])
    }

    @Test
    func recursivelyOmitsInvalidProviderDimensionNames() async throws {
        let provider = TestDimensionProvider(
            namespace: .device,
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
                        "notificationsEnabled": .bool(true)
                    ])
                ]),
                "invalidObject": .object([
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

        let snapshot = try await DimensionResolver(dimensionProviders: [provider]).snapshot()

        guard case .object(let deviceValues) = snapshot.values["device"] else {
            Issue.record("Expected device dimensions")
            return
        }
        #expect(deviceValues == [
            "platform": .string("ios"),
            "profile": .object([
                "name": .string("Rick"),
                "preferences": .object([
                    "notificationsEnabled": .bool(true)
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
            namespace: .device,
            snapshots: [["appVersion": .string("1.2.3")]]
        )
        let second = TestDimensionProvider(
            namespace: .device,
            snapshots: [["appVersion": .string("2.0.0")]]
        )

        do {
            _ = try await DimensionResolver(dimensionProviders: [first, second]).snapshot()
            Issue.record("Expected duplicate ownership to fail")
        } catch let error as DimensionResolutionError {
            #expect(error == .conflictingValue(path: "device.appVersion"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func providerFailureIsThrown() async {
        let evaluator = Self.evaluator(dimensionProviders: [
            FailingDimensionProvider(namespace: .session)
        ])

        do {
            _ = try await evaluator.match(in: [
                TestLocalRule(id: "test", predicate: "true")
            ])
            Issue.record("Expected provider failure to be thrown")
        } catch let error as DimensionResolutionError {
            guard case .providerFailed(let namespace, _) = error else {
                Issue.record("Unexpected resolution error: \(error)")
                return
            }
            #expect(namespace == .session)
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
    func omittedVariableRetainsRulesEngineNullSemantics() async throws {
        let evaluator = Self.evaluator(dimensionProviders: [
            TestDimensionProvider(
                namespace: .device,
                snapshots: [["known": .bool(true)]]
            )
        ])

        let rule = try await evaluator.match(in: [
            TestLocalRule(
                id: "missing-is-null",
                predicate: #"{"==":[{"var":"device.unknown"},null]}"#
            )
        ])

        #expect(rule?.id == "missing-is-null")
    }

    @Test
    func emptyBatchDoesNotCollectVariables() async throws {
        let provider = TestDimensionProvider(
            namespace: .device,
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
            namespace: .device,
            snapshots: [["launchCount": .int(1)], ["launchCount": .int(2)]]
        )
        let evaluator = Self.evaluator(dimensionProviders: [provider])

        let rule = try await evaluator.match(in: ["a", "b"]) { _ in
            #"{"==":[{"var":"device.launchCount"},1]}"#
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
    func snapshotExposesEvaluatedAtFromTheGatheringInstant() async throws {
        let first = Date(timeIntervalSince1970: 100)
        let later = Date(timeIntervalSince1970: 999)
        let dateProvider = MockDateProvider(stubbedNow: first, subsequentNows: later)
        let snapshot = try await DimensionResolver(
            dimensionProviders: [
                TestDimensionProvider(namespace: .device, snapshots: [["platform": .string("ios")]])
            ],
            dateProvider: dateProvider
        ).snapshot()

        #expect(dateProvider.invokedNowCount == 1)
        #expect(snapshot.evaluationDate == first)
        #expect(snapshot.values["evaluatedAt"] == .int(100_000))
    }

    @Test
    func everyRuleInAMatchSeesTheSameEvaluatedAt() async throws {
        let evaluator = LocalRulesEvaluator(
            dimensionProviders: [],
            dateProvider: MockDateProvider(
                stubbedNow: Date(timeIntervalSince1970: 100),
                subsequentNows: Date(timeIntervalSince1970: 200)
            )
        )

        let rule = try await evaluator.match(in: [
            TestLocalRule(
                id: "later-clock",
                predicate: #"{"==":[{"var":"evaluatedAt"},200000]}"#
            ),
            TestLocalRule(
                id: "gathering-clock",
                predicate: #"{"==":[{"var":"evaluatedAt"},100000]}"#
            )
        ])

        #expect(rule?.id == "gathering-clock")
    }

    @Test
    func evaluatedAtIsReadableFromInsideAListWalk() async throws {
        let evaluator = Self.evaluator(
            dimensionProviders: [
                TestDimensionProvider(
                    namespace: .device,
                    snapshots: [[
                        "purchases": .objectList([
                            ["expiresAt": .int(50)]
                        ])
                    ]]
                )
            ],
            date: Date(timeIntervalSince1970: 100)
        )

        let expired = #"""
        {"some":[{"var":"device.purchases"},
                 {"<":[{"var":"expiresAt"},{"rc.rootVar":"evaluatedAt"}]}]}
        """#
        let rule = try await evaluator.match(in: [TestLocalRule(id: "expired", predicate: expired)])

        #expect(rule?.id == "expired")
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
            CancellingDimensionProvider(namespace: .session)
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
        date: Date = Date(timeIntervalSince1970: 100)
    ) -> LocalRulesEvaluator {
        LocalRulesEvaluator(
            dimensionProviders: dimensionProviders,
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

    nonisolated let namespace: DimensionNamespace

    private let snapshots: [[String: DimensionValue]]
    private(set) var invocationCount = 0
    private(set) var receivedDates: [Date] = []

    init(
        namespace: DimensionNamespace,
        snapshots: [[String: DimensionValue]]
    ) {
        self.namespace = namespace
        self.snapshots = snapshots
    }

    func dimensions(in context: DimensionContext) -> [String: DimensionValue] {
        self.receivedDates.append(context.date)
        defer { self.invocationCount += 1 }
        guard !self.snapshots.isEmpty else { return [:] }
        return self.snapshots[min(self.invocationCount, self.snapshots.count - 1)]
    }
}

private struct FailingDimensionProvider: DimensionProvider {

    struct ProviderError: Error {}

    let namespace: DimensionNamespace

    func dimensions(in context: DimensionContext) async throws -> [String: DimensionValue] {
        throw ProviderError()
    }
}

private struct CancellingDimensionProvider: DimensionProvider {

    let namespace: DimensionNamespace

    func dimensions(in context: DimensionContext) async throws -> [String: DimensionValue] {
        throw CancellationError()
    }
}

#endif
#endif
