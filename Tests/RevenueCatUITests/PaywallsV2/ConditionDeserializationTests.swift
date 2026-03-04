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
//  Created by RevenueCat on 2/18/26.
//

import Nimble
@_spi(Internal) import RevenueCat
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
        // Legacy intro_offer decodes to .introOffer (no params)
        let json = """
        {"type": "intro_offer"}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.introOffer))
    }

    func testDecodeLegacyPromoOfferCondition() throws {
        // Legacy promo_offer decodes to .promoOffer (no params)
        let json = """
        {"type": "promo_offer"}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.promoOffer))
    }

    // MARK: - Extended Intro Offer Condition Tests

    func testDecodeExtendedIntroOfferConditionEqualsTrue() throws {
        let json = """
        {"type": "intro_offer_condition", "operator": "=", "value": true}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.introOfferCondition(operator: .equals, value: true)))
    }

    func testDecodeExtendedIntroOfferConditionEqualsFalse() throws {
        let json = """
        {"type": "intro_offer_condition", "operator": "=", "value": false}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.introOfferCondition(operator: .equals, value: false)))
    }

    func testDecodeExtendedIntroOfferConditionNotEquals() throws {
        let json = """
        {"type": "intro_offer_condition", "operator": "!=", "value": true}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.introOfferCondition(operator: .notEquals, value: true)))
    }

    func testDecodeExtendedIntroOfferConditionWithWrongValueType_FallsBackToUnsupported() throws {
        // value should be a boolean, not a string
        let json = """
        {"type": "intro_offer_condition", "operator": "=", "value": "not_a_boolean"}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.unsupported))
    }

    // MARK: - Extended Promo Offer Condition Tests

    func testDecodeExtendedPromoOfferConditionEqualsTrue() throws {
        let json = """
        {"type": "promo_offer_condition", "operator": "=", "value": true}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.promoOfferCondition(operator: .equals, value: true)))
    }

    func testDecodeExtendedPromoOfferConditionEqualsFalse() throws {
        let json = """
        {"type": "promo_offer_condition", "operator": "=", "value": false}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.promoOfferCondition(operator: .equals, value: false)))
    }

    func testDecodeExtendedPromoOfferConditionWithWrongValueType_FallsBackToUnsupported() throws {
        // value should be a boolean, not a string
        let json = """
        {"type": "promo_offer_condition", "operator": "=", "value": "not_a_boolean"}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.unsupported))
    }

    // MARK: - Variable Condition Tests

    func testDecodeVariableConditionWithStringValue() throws {
        let json = """
        {"type": "variable_condition", "operator": "=", "variable": "user_tier", "value": "premium"}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.variable(
            operator: .equals,
            variable: "user_tier",
            value: .string("premium")
        )))
    }

    func testDecodeVariableConditionWithBooleanValue() throws {
        let json = """
        {"type": "variable_condition", "operator": "!=", "variable": "is_vip", "value": true}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.variable(
            operator: .notEquals,
            variable: "is_vip",
            value: .bool(true)
        )))
    }

    func testDecodeVariableConditionWithIntValue() throws {
        let json = """
        {"type": "variable_condition", "operator": "=", "variable": "level", "value": 5}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.variable(
            operator: .equals,
            variable: "level",
            value: .int(5)
        )))
    }

    func testDecodeVariableConditionWithDoubleValue() throws {
        let json = """
        {"type": "variable_condition", "operator": "=", "variable": "score", "value": 3.14}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.variable(
            operator: .equals,
            variable: "score",
            value: .double(3.14)
        )))
    }

    // MARK: - Selected Package Condition Tests

    func testDecodeSelectedPackageConditionIn() throws {
        let json = """
        {"type": "selected_package_condition", "operator": "in", "packages": ["monthly", "annual"]}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.selectedPackage(
            operator: .in,
            packages: ["monthly", "annual"]
        )))
    }

    func testDecodeSelectedPackageConditionNotIn() throws {
        let json = """
        {"type": "selected_package_condition", "operator": "not in", "packages": ["trial"]}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.selectedPackage(
            operator: .notIn,
            packages: ["trial"]
        )))
    }

    // MARK: - Multiple Intro Offers Compatibility (iOS)

    func testDecodeMultipleIntroOffersCondition_DecodesToMultipleIntroOffers() throws {
        let json = """
        {"type": "multiple_intro_offers", "operator": "=", "value": true}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.multipleIntroOffers))
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
        {"type": "variable_condition", "operator": "=", "variable": "plan", "value": "premium",
        "description": "Check plan"}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.variable(
            operator: .equals,
            variable: "plan",
            value: .string("premium")
        )))
    }

    func testDecodeMalformedVariableCondition_FallsBackToUnsupported() throws {
        // Missing required "variable" field
        let json = """
        {"type": "variable_condition", "operator": "=", "value": "test"}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.unsupported))
    }

    func testDecodeMalformedSelectedPackageCondition_FallsBackToUnsupported() throws {
        // Missing required "packages" field
        let json = """
        {"type": "selected_package_condition", "operator": "in"}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.unsupported))
    }

    func testDecodeSelectedPackageWithUnknownOperator_FallsBackToUnsupported() throws {
        let json = """
        {"type": "selected_package_condition", "operator": "contains", "packages": ["monthly"]}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.unsupported))
    }

    func testDecodeVariableWithUnknownOperator_FallsBackToUnsupported() throws {
        let json = """
        {"type": "variable_condition", "operator": ">", "variable": "level", "value": 5}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.unsupported))
    }

    func testDecodeSelectedPackageWithWrongFieldType_FallsBackToUnsupported() throws {
        // packages should be an array, not a string
        let json = """
        {"type": "selected_package_condition", "operator": "in", "packages": "not_an_array"}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.unsupported))
    }

    func testDecodeVariableWithArrayValue_FallsBackToUnsupported() throws {
        // value should be a primitive, not an array
        let json = """
        {"type": "variable_condition", "operator": "=", "variable": "items", "value": [1, 2, 3]}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.unsupported))
    }

    func testDecodeVariableWithObjectValue_FallsBackToUnsupported() throws {
        // value should be a primitive, not an object
        let json = """
        {"type": "variable_condition", "operator": "=", "variable": "config", "value": {"nested": true}}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.unsupported))
    }

    func testDecodeEmptyJsonObject_FallsBackToUnsupported() throws {
        let json = """
        {}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.unsupported))
    }

    func testDecodeJsonWithoutTypeField_FallsBackToUnsupported() throws {
        let json = """
        {"no_type_field": true, "operator": "="}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.unsupported))
    }

    // MARK: - Encoding Tests

    func testEncodeVariableCondition() throws {
        let condition = PaywallComponent.ExtendedCondition.variable(
            operator: .equals,
            variable: "plan",
            value: .string("premium")
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(condition)
        let decoded = try decode(String(data: data, encoding: .utf8)!)

        expect(decoded).to(equal(condition))
    }

    func testEncodeSelectedPackageCondition() throws {
        let condition = PaywallComponent.ExtendedCondition.selectedPackage(
            operator: .in,
            packages: ["monthly", "annual"]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(condition)
        let decoded = try decode(String(data: data, encoding: .utf8)!)

        expect(decoded).to(equal(condition))
    }

    // MARK: - Public Condition Conversion Tests

    func testExtendedConditionToPublicCondition_Legacy() throws {
        expect(PaywallComponent.ExtendedCondition.compact.toCondition()).to(equal(.compact))
        expect(PaywallComponent.ExtendedCondition.medium.toCondition()).to(equal(.medium))
        expect(PaywallComponent.ExtendedCondition.expanded.toCondition()).to(equal(.expanded))
        expect(PaywallComponent.ExtendedCondition.selected.toCondition()).to(equal(.selected))
    }

    func testExtendedConditionToPublicCondition_LegacyOffers() throws {
        // Legacy intro/promo offer conditions map to their public equivalents
        expect(PaywallComponent.ExtendedCondition.introOffer.toCondition()).to(equal(.introOffer))
        expect(PaywallComponent.ExtendedCondition.promoOffer.toCondition()).to(equal(.promoOffer))
    }

    func testExtendedConditionToPublicCondition_Extended() throws {
        // Extended intro/promo offer conditions also map to their legacy public equivalents
        let introCondition = PaywallComponent.ExtendedCondition.introOfferCondition(
            operator: .equals,
            value: true
        )
        expect(introCondition.toCondition()).to(equal(.introOffer))

        let promoCondition = PaywallComponent.ExtendedCondition.promoOfferCondition(
            operator: .notEquals,
            value: false
        )
        expect(promoCondition.toCondition()).to(equal(.promoOffer))
    }

    func testExtendedConditionToPublicCondition_NewTypes() throws {
        // New condition types map to .unsupported in public API
        let variableCondition = PaywallComponent.ExtendedCondition.variable(
            operator: .equals,
            variable: "plan",
            value: .string("premium")
        )
        expect(variableCondition.toCondition()).to(equal(.unsupported))

        let packageCondition = PaywallComponent.ExtendedCondition.selectedPackage(
            operator: .in,
            packages: ["monthly"]
        )
        expect(packageCondition.toCondition()).to(equal(.unsupported))
    }

    // MARK: - Helpers

    private func decode(_ json: String) throws -> PaywallComponent.ExtendedCondition {
        let decoder = JSONDecoder()
        return try decoder.decode(PaywallComponent.ExtendedCondition.self, from: json.data(using: .utf8)!)
    }

}

#endif
