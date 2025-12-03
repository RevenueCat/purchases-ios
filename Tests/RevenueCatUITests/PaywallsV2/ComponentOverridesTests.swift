//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ComponentOverridesTests.swift
//
//  Created by Facundo Menzella on 11/2/25.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.

import Foundation
import Nimble
@testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class ComponentOverridesTests: TestCase {
    typealias ComparisonOperatorType = PaywallComponent.Condition.ComparisonOperatorType

    func test_defaultsToUnsupportedOnUnknownCondition() throws {
        let json = """
        [
          {
            "conditions": [
              { "type": "Some-unknown-condition", "operator": "<", "value": "12" }
            ],
            "properties": { }
          }
        ]
        """.data(using: .utf8)!

        let overrides = try JSONDecoder.default.decode(
            PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent>.self,
            from: json
        )

        let condition = try XCTUnwrap(overrides.first?.conditions.first)

        switch condition {
        case .unsupported:
            XCTAssert(true) // success
        default:
            fail("Expected app version condition")
        }
    }

    func testDecodesAppVersionCondition() throws {
        let testCases = [
            (ComparisonOperatorType.lessThan, "12.12.12", "<", 121212),
            (ComparisonOperatorType.equal, "12.01.120", "=", 1201120),
            (ComparisonOperatorType.greaterThan, "1", ">", 1),
            (ComparisonOperatorType.greaterThanOrEqual, "100.100.100", ">=", 100100100),
            (ComparisonOperatorType.lessThanOrEqual, "001.101.101", "<=", 1101101)
        ]

        try testCases.forEach { expectedOperand, value, operand, expectedValue in
            let json = """
            [
              {
                "conditions": [
                  { "type": "app_version", "operator": "\(operand)", "ios_version": "\(value)" }
                ],
                "properties": { }
              }
            ]
            """.data(using: .utf8)!

            let overrides = try JSONDecoder.default.decode(
                PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent>.self,
                from: json
            )

            let condition = try XCTUnwrap(overrides.first?.conditions.first)

            switch condition {
            case let .appVersion(operatorType, value):
                expect(operatorType) == expectedOperand
                expect(value) == expectedValue
            default:
                fail("Expected app version condition")
            }

        }
    }

    func testDecodesIntroOfferCondition() throws {
        let json = """
        [
          {
            "conditions": [
              { "type": "intro_offer", "operator": "=", "value": true }
            ],
            "properties": { }
          }
        ]
        """.data(using: .utf8)!

        let overrides = try JSONDecoder.default.decode(
            PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent>.self,
            from: json
        )

        let condition = try XCTUnwrap(overrides.first?.conditions.first)

        switch condition {
        case let .introOffer(operatorType, value):
            expect(operatorType) == .equals
            expect(value) == true
        default:
            fail("Expected introOffer condition")
        }
    }

    func testDecodesAnyIntroOfferCondition() throws {
        let json = """
        [
          {
            "conditions": [
              { "type": "introductory_offer_available", "operator": "!=", "value": false }
            ],
            "properties": { }
          }
        ]
        """.data(using: .utf8)!

        let overrides = try JSONDecoder.default.decode(
            PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent>.self,
            from: json
        )

        let condition = try XCTUnwrap(overrides.first?.conditions.first)

        switch condition {
        case let .anyPackageContainsIntroOffer(operatorType, value):
            expect(operatorType) == .notEquals
            expect(value) == false
        default:
            fail("Expected anyIntroOffer condition")
        }
    }

    func testIntroOfferDefaultsOperatorAndValueWhenMissing() throws {
        let json = """
        [
          {
            "conditions": [
              { "type": "intro_offer" }
            ],
            "properties": { }
          }
        ]
        """.data(using: .utf8)!

        let overrides = try JSONDecoder.default.decode(
            PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent>.self,
            from: json
        )

        let condition = try XCTUnwrap(overrides.first?.conditions.first)

        switch condition {
        case let .introOffer(operatorType, value):
            expect(operatorType) == .equals
            expect(value) == true
        default:
            fail("Expected introOffer condition")
        }
    }

}

#endif
