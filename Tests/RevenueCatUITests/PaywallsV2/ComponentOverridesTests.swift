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
        case let .anyIntroOffer(operatorType, value):
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
