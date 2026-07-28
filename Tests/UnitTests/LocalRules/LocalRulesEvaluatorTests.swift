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
    func batchUsesOneFreshSnapshotForEveryRule() async {
        let date = Date(timeIntervalSince1970: 1_234)
        let provider = TestRulesVariableProvider(
            identifier: "device-info",
            namespace: .device,
            snapshots: [
                ["launch_count": .int(1)],
                ["launch_count": .int(2)]
            ]
        )
        let evaluator = Self.evaluator(providers: [provider], date: date)

        let identifier = await evaluator.firstMatch(in: [
            TestLocalRule(
                id: TestRuleID.doesNotMatch,
                predicate: #"{"==":[{"var":"device.launch_count"},2]}"#
            ),
            TestLocalRule(
                id: TestRuleID.matches,
                predicate: #"{"==":[{"var":"device.launch_count"},1]}"#
            ),
            TestLocalRule(
                id: TestRuleID.notEvaluated,
                predicate: "{not-json"
            )
        ])

        #expect(identifier == .matches)
        #expect(await provider.invocationCount == 1)
        #expect(await provider.receivedDates == [date])
    }

    @Test
    func subsequentEvaluationPullsProviderAgain() async {
        let provider = TestRulesVariableProvider(
            identifier: "session",
            namespace: .session,
            snapshots: [
                ["count": .int(1)],
                ["count": .int(2)]
            ]
        )
        let evaluator = Self.evaluator(providers: [provider])

        let first = await evaluator.firstMatch(in: [
            TestLocalRule(id: "first", predicate: #"{"==":[{"var":"session.count"},1]}"#)
        ])
        let second = await evaluator.firstMatch(in: [
            TestLocalRule(id: "second", predicate: #"{"==":[{"var":"session.count"},2]}"#)
        ])

        #expect(first == "first")
        #expect(second == "second")
        #expect(await provider.invocationCount == 2)
    }

    @Test
    func allProvidersReceiveSameDate() async {
        let date = Date(timeIntervalSince1970: 9_876)
        let device = TestRulesVariableProvider(
            identifier: "device",
            namespace: .device,
            snapshots: [["ready": .bool(true)]]
        )
        let session = TestRulesVariableProvider(
            identifier: "session",
            namespace: .session,
            snapshots: [["ready": .bool(true)]]
        )
        let evaluator = Self.evaluator(providers: [device, session], date: date)

        _ = await evaluator.firstMatch(in: [
            TestLocalRule(id: "test", predicate: "true")
        ])

        #expect(await device.receivedDates == [date])
        #expect(await session.receivedDates == [date])
    }

    @Test
    func mergesProviderValuesByNamespace() async throws {
        let date = Date(timeIntervalSince1970: 5_432)
        let identity = TestRulesVariableProvider(
            identifier: "identity",
            namespace: .device,
            snapshots: [[
                "app_version": .string("1.2.3"),
                "is_debug_build": .bool(true),
                "screen_scale": .double(3)
            ]]
        )
        let environment = TestRulesVariableProvider(
            identifier: "environment",
            namespace: .device,
            snapshots: [["tracking_enabled": .bool(false)]]
        )
        let client = TestRulesVariableProvider(
            identifier: "client",
            namespace: .client,
            snapshots: [["shoe_size": .int(42)]]
        )

        let snapshot = try await RulesVariableResolver(
            providers: [identity, environment, client],
            dateProvider: MockDateProvider(stubbedNow: date)
        ).snapshot()

        #expect(snapshot.evaluationDate == date)
        #expect(snapshot.values == [
            "device": .object([
                "app_version": .string("1.2.3"),
                "is_debug_build": .bool(true),
                "screen_scale": .float(3),
                "tracking_enabled": .bool(false)
            ]),
            "client": .object(["shoe_size": .int(42)])
        ])
    }

    @Test
    func duplicateLeafIsAConfigurationError() async {
        let first = TestRulesVariableProvider(
            identifier: "first",
            namespace: .device,
            snapshots: [["app_version": .string("1.2.3")]]
        )
        let second = TestRulesVariableProvider(
            identifier: "second",
            namespace: .device,
            snapshots: [["app_version": .string("2.0.0")]]
        )

        do {
            _ = try await RulesVariableResolver(providers: [first, second]).snapshot()
            Issue.record("Expected duplicate ownership to fail")
        } catch let error as RulesVariableResolutionError {
            #expect(error == .conflictingValue(path: "device.app_version"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func providerFailureReturnsNoIdentifier() async {
        let evaluator = Self.evaluator(providers: [
            FailingRulesVariableProvider(identifier: "broken", namespace: .session)
        ])

        let identifier = await evaluator.firstMatch(in: [
            TestLocalRule(id: "test", predicate: "true")
        ])
        #expect(identifier == nil)
    }

    @Test
    func invalidRuleDoesNotPreventLaterRuleFromMatching() async {
        let evaluator = Self.evaluator(providers: [])

        let identifier = await evaluator.firstMatch(in: [
            TestLocalRule(id: "invalid", predicate: "{not-json"),
            TestLocalRule(id: "valid", predicate: "true")
        ])

        #expect(identifier == "valid")
    }

    @Test
    func matchesAnyReturnsWhetherARuleMatches() async {
        let evaluator = Self.evaluator(providers: [])

        let matches = await evaluator.matchesAny(in: [
            TestLocalRule(id: "false", predicate: "false"),
            TestLocalRule(id: "true", predicate: "true")
        ])

        #expect(matches)
    }

    @Test
    func unsupportedOperatorReturnsNoIdentifier() async {
        let evaluator = Self.evaluator(providers: [])

        let identifier = await evaluator.firstMatch(in: [
            TestLocalRule(id: "unsupported", predicate: #"{"future_operator":[]}"#)
        ])
        #expect(identifier == nil)
    }

    @Test
    func omittedVariableRetainsRulesEngineNullSemantics() async {
        let evaluator = Self.evaluator(providers: [
            TestRulesVariableProvider(
                identifier: "device",
                namespace: .device,
                snapshots: [["known": .bool(true)]]
            )
        ])

        let identifier = await evaluator.firstMatch(in: [
            TestLocalRule(
                id: "missing-is-null",
                predicate: #"{"==":[{"var":"device.unknown"},null]}"#
            )
        ])

        #expect(identifier == "missing-is-null")
    }

    @Test
    func emptyBatchDoesNotCollectVariables() async {
        let provider = TestRulesVariableProvider(
            identifier: "unused",
            namespace: .device,
            snapshots: [["value": .int(1)]]
        )
        let evaluator = Self.evaluator(providers: [provider])

        let identifier: String? = await evaluator.firstMatch(in: [TestLocalRule<String>]())
        #expect(identifier == nil)
        #expect(await provider.invocationCount == 0)
    }
}

private extension LocalRulesEvaluatorTests {

    static func evaluator(
        providers: [any RulesVariableProvider],
        date: Date = Date(timeIntervalSince1970: 100)
    ) -> LocalRulesEvaluator {
        LocalRulesEvaluator(
            providers: providers,
            dateProvider: MockDateProvider(stubbedNow: date)
        )
    }
}

private struct TestLocalRule<ID: Sendable>: LocalRule {

    let id: ID
    let predicate: String
}

private enum TestRuleID: Sendable {

    case doesNotMatch
    case matches
    case notEvaluated
}

private actor TestRulesVariableProvider: RulesVariableProvider {

    nonisolated let identifier: String
    nonisolated let namespace: RulesVariableNamespace

    private let snapshots: [[String: RulesVariableValue]]
    private(set) var invocationCount = 0
    private(set) var receivedDates: [Date] = []

    init(
        identifier: String,
        namespace: RulesVariableNamespace,
        snapshots: [[String: RulesVariableValue]]
    ) {
        self.identifier = identifier
        self.namespace = namespace
        self.snapshots = snapshots
    }

    func variables(at date: Date) -> [String: RulesVariableValue] {
        self.receivedDates.append(date)
        defer { self.invocationCount += 1 }
        guard !self.snapshots.isEmpty else { return [:] }
        return self.snapshots[min(self.invocationCount, self.snapshots.count - 1)]
    }
}

private struct FailingRulesVariableProvider: RulesVariableProvider {

    struct ProviderError: Error {}

    let identifier: String
    let namespace: RulesVariableNamespace

    func variables(at date: Date) async throws -> [String: RulesVariableValue] {
        throw ProviderError()
    }
}

#endif
#endif
