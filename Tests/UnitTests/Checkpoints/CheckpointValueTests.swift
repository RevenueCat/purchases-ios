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
        let params = CheckpointParams(customProperties: [
            "string": "value",
            "integer": 42,
            "double": 4.5,
            "boolean": true
        ])

        XCTAssertEqual(params.customProperties["string"], .string("value"))
        XCTAssertEqual(params.customProperties["integer"], .integer(42))
        XCTAssertEqual(params.customProperties["double"], .double(4.5))
        XCTAssertEqual(params.customProperties["boolean"], .boolean(true))
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

}
