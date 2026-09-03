//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DimensionValueTests.swift
//
//  Created by Rick van der Linden on 8/19/26.
//

// Swift Testing is only available with the Xcode 16+ toolchain
#if compiler(>=5.9)
#if canImport(Testing)

import Foundation
import Testing

@testable import RevenueCat

@Suite("Dimension values")
struct DimensionValueTests {

    @Test
    func anyDecodableConvertsSupportedDimensionValues() throws {
        let json = #"""
        {
            "null": null,
            "nested": {"kept": true, "unsupported": [1, 2]},
            "records": [{"id": "one", "unsupported": [1, 2]}],
            "mixed": [{"id": "one"}, "invalid"]
        }
        """#
        let values = try JSONDecoder.default.decode(
            [String: AnyDecodable].self,
            from: json.asData
        )

        #expect(values["null"]?.dimensionValue == .null)
        #expect(values["nested"]?.dimensionValue == .object(["kept": .bool(true)]))
        #expect(values["records"]?.dimensionValue == .objectList([["id": .string("one")]]))
        #expect(values["mixed"]?.dimensionValue == nil)
    }

    @Test
    func dateAndObjectListConvertToRulesEngineValues() async throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let snapshot = try await Self.snapshot([
            "date": .date(date),
            "missing": .null,
            "record": .object([
                "id": .string("one"),
                "missing": .null,
                "created_at": .date(date)
            ]),
            "records": .objectList([
                [
                    "id": .string("one"),
                    "missing": .null,
                    "created_at": .date(date)
                ]
            ])
        ])

        #expect(snapshot.values == [
            "evaluated_at": .int(123_000),
            "date": .int(1_700_000_000_000),
            "missing": .null,
            "record": .object([
                "id": .string("one"),
                "missing": .null,
                "created_at": .int(1_700_000_000_000)
            ]),
            "records": .array([
                .object([
                    "id": .string("one"),
                    "missing": .null,
                    "created_at": .int(1_700_000_000_000)
                ])
            ])
        ])
    }

    @Test
    func objectDimensionIsReadThroughByName() async throws {
        let snapshot = try await Self.snapshot([
            "goal": .object([
                "value": .string("lose_weight"),
                "updated_at": .date(Date(timeIntervalSince1970: 1_700_000_000))
            ])
        ])

        let predicate = #"""
            {"and":[
                {"==":[{"var":"goal.value"},"lose_weight"]},
                {">":[{"var":"goal.updated_at"},1699999999999]}
            ]}
            """#

        #expect(try RulesEngine.evaluate(predicate: predicate, variables: snapshot.values).get())
    }

    @Test
    func explicitNullIsResolvedAndFalsyWhileMissingUsesItsDefault() async throws {
        let snapshot = try await Self.snapshot(["present": .null])

        #expect(try RulesEngine.evaluate(
            predicate: #"{"==":[{"var":"present"},null]}"#,
            variables: snapshot.values
        ).get())
        #expect(try !RulesEngine.evaluate(
            predicate: #"{"!!":{"var":"present"}}"#,
            variables: snapshot.values
        ).get())
        #expect(try RulesEngine.evaluate(
            predicate: #"{"var":["missing",true]}"#,
            variables: snapshot.values
        ).get())
    }

    @Test
    func dateDimensionIsOrderedByPredicate() async throws {
        let snapshot = try await Self.snapshot([
            "expires_at": .date(Date(timeIntervalSince1970: 1_700_000_000))
        ])

        #expect(try RulesEngine.evaluate(
            predicate: #"{">":[{"var":"expires_at"},1699999999999]}"#,
            variables: snapshot.values
        ).get())
        #expect(try !RulesEngine.evaluate(
            predicate: #"{">":[{"var":"expires_at"},1700000000001]}"#,
            variables: snapshot.values
        ).get())
    }

    @Test
    func objectListIsEvaluatedOneRecordAtATime() async throws {
        let snapshot = try await Self.snapshot([
            "purchases": .objectList([
                [
                    "product_id": .string("plus"),
                    "is_active": .bool(false)
                ],
                [
                    "product_id": .string("pro"),
                    "is_active": .bool(true)
                ]
            ])
        ])

        let active =
            #"{"some":[{"var":"purchases"},{"and":[{"==":[{"var":"product_id"},"pro"]},{"var":"is_active"}]}]}"#
        #expect(try RulesEngine.evaluate(predicate: active, variables: snapshot.values).get())

        let inactive =
            #"{"some":[{"var":"purchases"},{"and":[{"==":[{"var":"product_id"},"plus"]},{"var":"is_active"}]}]}"#
        #expect(try !RulesEngine.evaluate(predicate: inactive, variables: snapshot.values).get())

        let byIndex = #"{"==":[{"var":"purchases.1.product_id"},"pro"]}"#
        #expect(try RulesEngine.evaluate(predicate: byIndex, variables: snapshot.values).get())
    }

    @Test
    func emptyObjectListRemainsPresentAsEmptyArray() async throws {
        let snapshot = try await Self.snapshot([
            "purchases": .objectList([])
        ])

        #expect(snapshot.values == [
            "evaluated_at": .int(123_000),
            "purchases": .array([])
        ])

        let none = #"{"none":[{"var":"purchases"},{"var":"is_active"}]}"#
        #expect(try RulesEngine.evaluate(predicate: none, variables: snapshot.values).get())
    }

    private static func snapshot(
        _ values: [String: DimensionValue]
    ) async throws -> DimensionSnapshot {
        return try await DimensionResolver(
            dimensionProviders: [StaticDimensionProvider(values: values)],
            dateProvider: MockDateProvider(stubbedNow: Date(timeIntervalSince1970: 123))
        ).snapshot()
    }

}

private struct StaticDimensionProvider: DimensionProvider {

    let name = "test"
    let values: [String: DimensionValue]

    func dimensions(at _: Date) async throws -> [String: DimensionValue] {
        return self.values
    }

}

#endif
#endif
