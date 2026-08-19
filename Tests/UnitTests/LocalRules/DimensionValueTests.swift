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
    func dateAndObjectListConvertToRulesEngineValues() async throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let snapshot = try await Self.snapshot([
            "date": .date(date),
            "records": .objectList([
                [
                    "id": .string("one"),
                    "createdAt": .date(date)
                ]
            ])
        ])

        #expect(snapshot.values == [
            "device": .object([
                "date": .int(1_700_000_000_000),
                "records": .array([
                    .object([
                        "id": .string("one"),
                        "createdAt": .int(1_700_000_000_000)
                    ])
                ])
            ])
        ])
    }

    @Test
    func dateDimensionIsOrderedByPredicate() async throws {
        let snapshot = try await Self.snapshot([
            "expiresAt": .date(Date(timeIntervalSince1970: 1_700_000_000))
        ])

        #expect(try RulesEngine.Evaluator.evaluate(
            predicate: try RulesEngine.Value.fromJSONString(
                #"{">":[{"var":"device.expiresAt"},1699999999999]}"#
            ),
            variables: snapshot.values
        ))
        #expect(try !RulesEngine.Evaluator.evaluate(
            predicate: try RulesEngine.Value.fromJSONString(
                #"{">":[{"var":"device.expiresAt"},1700000000001]}"#
            ),
            variables: snapshot.values
        ))
    }

    @Test
    func objectListIsEvaluatedOneRecordAtATime() async throws {
        let snapshot = try await Self.snapshot([
            "purchases": .objectList([
                [
                    "productId": .string("plus"),
                    "isActive": .bool(false)
                ],
                [
                    "productId": .string("pro"),
                    "isActive": .bool(true)
                ]
            ])
        ])

        let active = try RulesEngine.Value.fromJSONString(
            #"{"some":[{"var":"device.purchases"},{"and":[{"==":[{"var":"productId"},"pro"]},{"var":"isActive"}]}]}"#
        )
        #expect(try RulesEngine.Evaluator.evaluate(predicate: active, variables: snapshot.values))

        let inactive = try RulesEngine.Value.fromJSONString(
            #"{"some":[{"var":"device.purchases"},{"and":[{"==":[{"var":"productId"},"plus"]},{"var":"isActive"}]}]}"#
        )
        #expect(try !RulesEngine.Evaluator.evaluate(predicate: inactive, variables: snapshot.values))

        let byIndex = try RulesEngine.Value.fromJSONString(
            #"{"==":[{"var":"device.purchases.1.productId"},"pro"]}"#
        )
        #expect(try RulesEngine.Evaluator.evaluate(predicate: byIndex, variables: snapshot.values))
    }

    @Test
    func emptyObjectListRemainsPresentAsEmptyArray() async throws {
        let snapshot = try await Self.snapshot([
            "purchases": .objectList([])
        ])

        #expect(snapshot.values == [
            "device": .object(["purchases": .array([])])
        ])

        let none = try RulesEngine.Value.fromJSONString(
            #"{"none":[{"var":"device.purchases"},{"var":"isActive"}]}"#
        )
        #expect(try RulesEngine.Evaluator.evaluate(predicate: none, variables: snapshot.values))
    }

    private static func snapshot(
        _ values: [String: DimensionValue]
    ) async throws -> DimensionSnapshot {
        return try await DimensionResolver(
            dimensionProviders: [StaticDimensionProvider(values: values)]
        ).snapshot()
    }

}

private struct StaticDimensionProvider: DimensionProvider {

    let namespace: DimensionNamespace = .device
    let values: [String: DimensionValue]

    func dimensions(at _: Date) async throws -> [String: DimensionValue] {
        return self.values
    }

}

#endif
#endif
