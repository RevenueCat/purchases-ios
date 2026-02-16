//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ConditionDeserializationTests.swift
//
//  Created by RevenueCat on 2/16/26.
//

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class ConditionDeserializationTests: TestCase {

    // MARK: - Legacy Condition Tests

    func testDecodeLegacyCompactCondition() throws {
        let json = """
        {"type": "compact"}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.compact))
    }

    func testDecodeLegacyMediumCondition() throws {
        let json = """
        {"type": "medium"}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.medium))
    }

    func testDecodeLegacyExpandedCondition() throws {
        let json = """
        {"type": "expanded"}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.expanded))
    }

    func testDecodeLegacySelectedCondition() throws {
        let json = """
        {"type": "selected"}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.selected))
    }

    func testDecodeLegacyIntroOfferCondition() throws {
        let json = """
        {"type": "intro_offer"}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.introOffer))
    }

    func testDecodeLegacyPromoOfferCondition() throws {
        let json = """
        {"type": "promo_offer"}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.promoOffer))
    }

    // MARK: - Extended Intro Offer Condition Tests

    func testDecodeExtendedIntroOfferConditionEqualsTrue() throws {
        let json = """
        {"type": "intro_offer", "operator": "=", "value": true}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.introOfferCondition(operator: .equals, value: true)))
    }

    func testDecodeExtendedIntroOfferConditionEqualsFalse() throws {
        let json = """
        {"type": "intro_offer", "operator": "=", "value": false}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.introOfferCondition(operator: .equals, value: false)))
    }

    func testDecodeExtendedIntroOfferConditionNotEquals() throws {
        let json = """
        {"type": "intro_offer", "operator": "!=", "value": true}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.introOfferCondition(operator: .notEquals, value: true)))
    }

    // MARK: - Extended Promo Offer Condition Tests

    func testDecodeExtendedPromoOfferConditionEqualsTrue() throws {
        let json = """
        {"type": "promo_offer", "operator": "=", "value": true}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.promoOfferCondition(operator: .equals, value: true)))
    }

    func testDecodeExtendedPromoOfferConditionEqualsFalse() throws {
        let json = """
        {"type": "promo_offer", "operator": "=", "value": false}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.promoOfferCondition(operator: .equals, value: false)))
    }

    // MARK: - Variable Condition Tests

    func testDecodeVariableConditionWithStringValue() throws {
        let json = """
        {"type": "variable", "operator": "=", "variable": "user_tier", "value": "premium"}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.variableCondition(
            operator: .equals,
            variable: "user_tier",
            value: .string("premium")
        )))
    }

    func testDecodeVariableConditionWithBooleanValue() throws {
        let json = """
        {"type": "variable", "operator": "!=", "variable": "is_vip", "value": true}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.variableCondition(
            operator: .notEquals,
            variable: "is_vip",
            value: .bool(true)
        )))
    }

    func testDecodeVariableConditionWithNumericValue() throws {
        let json = """
        {"type": "variable", "operator": "=", "variable": "level", "value": 5}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.variableCondition(
            operator: .equals,
            variable: "level",
            value: .number(5)
        )))
    }

    // MARK: - Package Condition Tests

    func testDecodePackageConditionEquals() throws {
        let json = """
        {"type": "package", "operator": "=", "package_id": "monthly"}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.packageCondition(operator: .equals, packageId: "monthly")))
    }

    func testDecodePackageConditionNotEquals() throws {
        let json = """
        {"type": "package", "operator": "!=", "package_id": "annual"}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.packageCondition(operator: .notEquals, packageId: "annual")))
    }

    // MARK: - Selected Package Condition Tests

    func testDecodeSelectedPackageConditionIn() throws {
        let json = """
        {"type": "selected_package", "operator": "in", "packages": ["monthly", "annual"]}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.selectedPackageCondition(
            operator: .in,
            packages: ["monthly", "annual"]
        )))
    }

    func testDecodeSelectedPackageConditionNotIn() throws {
        let json = """
        {"type": "selected_package", "operator": "not in", "packages": ["trial"]}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.selectedPackageCondition(
            operator: .notIn,
            packages: ["trial"]
        )))
    }

    // MARK: - Unknown Condition Type Tests

    func testDecodeUnknownConditionType_FallsBackToUnsupported() throws {
        let json = """
        {"type": "unknown_future_condition"}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.unsupported))
    }

    func testDecodeUnknownConditionTypeWithExtraFields_FallsBackToUnsupported() throws {
        let json = """
        {"type": "window_width", "operator": ">", "value": 500}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.unsupported))
    }

    // MARK: - Resilience Tests

    func testDecodeConditionIgnoresUnknownFields() throws {
        let json = """
        {"type": "compact", "unknown_field": "should_be_ignored", "another_field": 123}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.compact))
    }

    func testDecodeVariableConditionWithExtraFields() throws {
        let json = """
        {"type": "variable", "operator": "=", "variable": "plan", "value": "premium", "description": "Check plan"}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.variableCondition(
            operator: .equals,
            variable: "plan",
            value: .string("premium")
        )))
    }

    // MARK: - Encoding Tests

    func testEncodeVariableCondition() throws {
        let condition = PaywallComponent.Condition.variableCondition(
            operator: .equals,
            variable: "plan",
            value: .string("premium")
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(condition)
        let decoded = try decode(String(data: data, encoding: .utf8)!)

        expect(decoded).to(equal(condition))
    }

    func testEncodePackageCondition() throws {
        let condition = PaywallComponent.Condition.packageCondition(
            operator: .notEquals,
            packageId: "trial"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(condition)
        let decoded = try decode(String(data: data, encoding: .utf8)!)

        expect(decoded).to(equal(condition))
    }

    func testEncodeSelectedPackageCondition() throws {
        let condition = PaywallComponent.Condition.selectedPackageCondition(
            operator: .in,
            packages: ["monthly", "annual"]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(condition)
        let decoded = try decode(String(data: data, encoding: .utf8)!)

        expect(decoded).to(equal(condition))
    }

    // MARK: - Helpers

    private func decode(_ json: String) throws -> PaywallComponent.Condition {
        let decoder = JSONDecoder()
        return try decoder.decode(PaywallComponent.Condition.self, from: json.data(using: .utf8)!)
    }

}

#endif
