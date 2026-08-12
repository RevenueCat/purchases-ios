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
            identifier: "device-info",
            namespace: .device,
            snapshots: [
                ["launch_count": .int(1)],
                ["launch_count": .int(2)]
            ]
        )
        let evaluator = Self.evaluator(dimensionProviders: [provider], date: date)

        let rule = try await evaluator.match(in: [
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

        #expect(rule?.id == .matches)
        #expect(await provider.invocationCount == 1)
        #expect(await provider.receivedDates == [date])
    }

    @Test
    func subsequentEvaluationPullsProviderAgain() async throws {
        let provider = TestDimensionProvider(
            identifier: "session",
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
            identifier: "device",
            namespace: .device,
            snapshots: [["ready": .bool(true)]]
        )
        let session = TestDimensionProvider(
            identifier: "session",
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
            identifier: "identity",
            namespace: .device,
            snapshots: [[
                "app_version": .string("1.2.3"),
                "is_debug_build": .bool(true),
                "screen_scale": .double(3)
            ]]
        )
        let environment = TestDimensionProvider(
            identifier: "environment",
            namespace: .device,
            snapshots: [["tracking_enabled": .bool(false)]]
        )
        let client = TestDimensionProvider(
            identifier: "client",
            namespace: .client,
            snapshots: [["shoe_size": .int(42)]]
        )

        let snapshot = try await DimensionResolver(
            dimensionProviders: [identity, environment, client],
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
        let first = TestDimensionProvider(
            identifier: "first",
            namespace: .device,
            snapshots: [["app_version": .string("1.2.3")]]
        )
        let second = TestDimensionProvider(
            identifier: "second",
            namespace: .device,
            snapshots: [["app_version": .string("2.0.0")]]
        )

        do {
            _ = try await DimensionResolver(dimensionProviders: [first, second]).snapshot()
            Issue.record("Expected duplicate ownership to fail")
        } catch let error as DimensionResolutionError {
            #expect(error == .conflictingValue(path: "device.app_version"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func providerFailureIsThrown() async {
        let evaluator = Self.evaluator(dimensionProviders: [
            FailingDimensionProvider(identifier: "broken", namespace: .session)
        ])

        do {
            _ = try await evaluator.match(in: [
                TestLocalRule(id: "test", predicate: "true")
            ])
            Issue.record("Expected provider failure to be thrown")
        } catch let error as DimensionResolutionError {
            guard case .providerFailed(let identifier, _) = error else {
                Issue.record("Unexpected resolution error: \(error)")
                return
            }
            #expect(identifier == "broken")
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
                identifier: "device",
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
            identifier: "unused",
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
    func cancellationIsThrownByMatch() async {
        let evaluator = Self.evaluator(dimensionProviders: [
            CancellingDimensionProvider(identifier: "cancelled", namespace: .session)
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

private enum TestRuleID: Sendable {

    case doesNotMatch
    case matches
    case notEvaluated
}

private actor TestDimensionProvider: DimensionProvider {

    nonisolated let identifier: String
    nonisolated let namespace: DimensionNamespace

    private let snapshots: [[String: DimensionValue]]
    private(set) var invocationCount = 0
    private(set) var receivedDates: [Date] = []

    init(
        identifier: String,
        namespace: DimensionNamespace,
        snapshots: [[String: DimensionValue]]
    ) {
        self.identifier = identifier
        self.namespace = namespace
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

    let identifier: String
    let namespace: DimensionNamespace

    func dimensions(at date: Date) async throws -> [String: DimensionValue] {
        throw ProviderError()
    }
}

private struct CancellingDimensionProvider: DimensionProvider {

    let identifier: String
    let namespace: DimensionNamespace

    func dimensions(at date: Date) async throws -> [String: DimensionValue] {
        throw CancellationError()
    }
}

#endif
#endif
