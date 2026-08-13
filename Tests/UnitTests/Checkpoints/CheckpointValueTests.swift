//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointValueTests.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) @testable import RevenueCat
import XCTest

final class CheckpointValueTests: TestCase {

    func testLiteralValuesPreserveTheirTypes() {
        let params = CheckpointParams(customVariables: [
            "string": "value",
            "integer": 42,
            "double": 4.5,
            "boolean": true
        ])

        XCTAssertEqual(params.customVariables["string"], .string("value"))
        XCTAssertEqual(params.customVariables["integer"], .integer(42))
        XCTAssertEqual(params.customVariables["double"], .double(4.5))
        XCTAssertEqual(params.customVariables["boolean"], .boolean(true))
    }

    func testCodableUsesPrimitiveJSONValues() throws {
        let values: [String: CheckpointValue] = [
            "string": .string("value"),
            "integer": .integer(42),
            "double": .double(4.5),
            "boolean": .boolean(true)
        ]

        let data = try JSONEncoder().encode(values)
        let decoded = try JSONDecoder().decode([String: CheckpointValue].self, from: data)

        XCTAssertEqual(decoded, values)
    }

    func testFoundationValuesDistinguishBooleansAndNumbers() {
        XCTAssertEqual(CheckpointValue(foundationValue: NSNumber(value: true)), .boolean(true))
        XCTAssertEqual(CheckpointValue(foundationValue: NSNumber(value: 1)), .integer(1))
        XCTAssertEqual(CheckpointValue(foundationValue: NSNumber(value: 1.5)), .double(1.5))
        XCTAssertEqual(CheckpointValue(foundationValue: "value"), .string("value"))
        XCTAssertNil(CheckpointValue(foundationValue: Date()))
    }

    func testFoundationNumberStorageTypesMatchJSONParsingBehavior() {
        let integers: [NSNumber] = [
            NSNumber(value: Int8(1)), NSNumber(value: Int16(2)), NSNumber(value: Int32(3)),
            NSNumber(value: Int64(4)), NSNumber(value: UInt8(5)), NSNumber(value: UInt16(6)),
            NSNumber(value: UInt32(7)), NSNumber(value: UInt64(8))
        ]

        for number in integers {
            guard case .integer = CheckpointValue(foundationValue: number) else {
                return XCTFail("Expected NSNumber with objCType \(String(cString: number.objCType)) to be an integer")
            }
        }

        XCTAssertEqual(CheckpointValue(foundationValue: NSNumber(value: Float(1.5))), .double(1.5))
        XCTAssertEqual(CheckpointValue(foundationValue: NSNumber(value: Double(2.5))), .double(2.5))
    }

    func testParamsPreserveValueEqualityAndHashing() {
        let firstParams = CheckpointParams(customVariables: ["name": "Rick"])
        let secondParams = CheckpointParams(customVariables: ["name": "Rick"])

        XCTAssertEqual(firstParams, secondParams)
        XCTAssertEqual(Set([firstParams, secondParams]).count, 1)
    }

    func testValuesConvertToDimensionsWithoutLosingTheirTypes() {
        XCTAssertEqual(CheckpointValue.string("value").dimensionValue, .string("value"))
        XCTAssertEqual(CheckpointValue.integer(42).dimensionValue, .int(42))
        XCTAssertEqual(CheckpointValue.double(4.5).dimensionValue, .double(4.5))
        XCTAssertEqual(CheckpointValue.boolean(true).dimensionValue, .bool(true))
    }

}
