//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WindowSizeConditionTests.swift
//
//  Created by Josh Holtz on 9/2/26.
//

import Nimble
@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class WindowSizeConditionTests: TestCase {

    // MARK: - Deserialization

    func testDecodeWindowWidthCondition() throws {
        let json = """
        {"type": "window_width_condition", "operator": ">=", "value": 700}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.windowWidth(operator: .greaterThanOrEqual, value: 700)))
    }

    func testDecodeWindowHeightCondition() throws {
        let json = """
        {"type": "window_height_condition", "operator": ">=", "value": 480}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.windowHeight(operator: .greaterThanOrEqual, value: 480)))
    }

    func testDecodeWindowAspectRatioCondition() throws {
        let json = """
        {"type": "window_aspect_ratio_condition", "operator": ">=", "value": 1.2}
        """
        let condition = try decode(json)
        expect(condition).to(equal(.windowAspectRatio(operator: .greaterThanOrEqual, value: 1.2)))
    }

    func testWindowConditionsRoundTripThroughEncoding() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .windowWidth(operator: .greaterThanOrEqual, value: 700),
            .windowHeight(operator: .lessThan, value: 480),
            .windowAspectRatio(operator: .greaterThan, value: 1)
        ]

        let encoded = try JSONEncoder().encode(conditions)
        let decoded = try JSONDecoder().decode(
            [PaywallComponent.ExtendedCondition].self,
            from: encoded
        )

        expect(decoded).to(equal(conditions))
    }

    func testMalformedWindowConditionsDecodeAsUnsupported() throws {
        let unknownOperator = try decode("""
        {"type": "window_width_condition", "operator": "~=", "value": 700}
        """)
        expect(unknownOperator).to(equal(.unsupported))

        let missingValue = try decode("""
        {"type": "window_height_condition", "operator": ">="}
        """)
        expect(missingValue).to(equal(.unsupported))

        let nonNumericValue = try decode("""
        {"type": "window_width_condition", "operator": ">=", "value": "wide"}
        """)
        expect(nonNumericValue).to(equal(.unsupported))

        let malformedRatio = try decode("""
        {"type": "window_aspect_ratio_condition", "operator": "~=", "value": 1.2}
        """)
        expect(malformedRatio).to(equal(.unsupported))
    }

    func testWindowConditionsConvertToUnsupportedPublicCondition() {
        expect(PaywallComponent.ExtendedCondition
            .windowWidth(operator: .greaterThanOrEqual, value: 700)
            .toCondition()) == .unsupported
        expect(PaywallComponent.ExtendedCondition
            .windowHeight(operator: .greaterThanOrEqual, value: 480)
            .toCondition()) == .unsupported
        expect(PaywallComponent.ExtendedCondition
            .windowAspectRatio(operator: .greaterThanOrEqual, value: 1.2)
            .toCondition()) == .unsupported
    }

    func testWindowConditionsAreRules() {
        expect(PaywallComponent.ExtendedCondition
            .windowWidth(operator: .greaterThanOrEqual, value: 700).isRule) == true
        expect(PaywallComponent.ExtendedCondition
            .windowHeight(operator: .greaterThanOrEqual, value: 480).isRule) == true
        expect(PaywallComponent.ExtendedCondition
            .windowAspectRatio(operator: .greaterThanOrEqual, value: 1.2).isRule) == true
    }

    // MARK: - Evaluation

    private func buildPartial(
        conditions: [PaywallComponent.ExtendedCondition],
        windowSize: CGSize?
    ) -> TestPartial? {
        TestPartial.buildPartial(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            conditionContext: ConditionContext(windowSize: windowSize),
            with: [PresentedOverride(conditions: conditions, properties: TestPartial())]
        )
    }

    func testWindowWidthConditionMatchesWideWindow() {
        let result = self.buildPartial(
            conditions: [.windowWidth(operator: .greaterThanOrEqual, value: 700)],
            windowSize: CGSize(width: 904, height: 640)
        )
        expect(result).toNot(beNil())
    }

    func testWindowWidthConditionDoesNotMatchNarrowWindow() {
        let result = self.buildPartial(
            conditions: [.windowWidth(operator: .greaterThanOrEqual, value: 700)],
            windowSize: CGSize(width: 402, height: 874)
        )
        expect(result).to(beNil())
    }

    func testWindowConditionsDoNotMatchWithoutWindowSize() {
        expect(self.buildPartial(
            conditions: [.windowWidth(operator: .greaterThanOrEqual, value: 700)],
            windowSize: nil
        )).to(beNil())
        expect(self.buildPartial(
            conditions: [.windowHeight(operator: .greaterThanOrEqual, value: 480)],
            windowSize: nil
        )).to(beNil())
    }

    func testAspectRatioConditionFollowsOrientation() {
        let landscapeIsWide: [PaywallComponent.ExtendedCondition] = [
            .windowAspectRatio(operator: .greaterThanOrEqual, value: 1.2)
        ]

        // iPad landscape: 1024/768 = 1.33.
        expect(self.buildPartial(
            conditions: landscapeIsWide,
            windowSize: CGSize(width: 1024, height: 768)
        )).toNot(beNil())

        // Same iPad rotated to portrait: 768/1024 = 0.75.
        expect(self.buildPartial(
            conditions: landscapeIsWide,
            windowSize: CGSize(width: 768, height: 1024)
        )).to(beNil())

        // Zero height never matches (no division).
        expect(self.buildPartial(
            conditions: landscapeIsWide,
            windowSize: CGSize(width: 1024, height: 0)
        )).to(beNil())

        // Unknown size never matches.
        expect(self.buildPartial(conditions: landscapeIsWide, windowSize: nil)).to(beNil())
    }

    func testEqualOperatorUsesEpsilonTolerance() {
        expect(self.buildPartial(
            conditions: [.windowWidth(operator: .equal, value: 700)],
            windowSize: CGSize(width: 700 + 1e-12, height: 480)
        )).toNot(beNil())
        expect(self.buildPartial(
            conditions: [.windowWidth(operator: .equal, value: 700)],
            windowSize: CGSize(width: 700.5, height: 480)
        )).to(beNil())
    }

    func testWidthAndHeightConditionsRequireBoth() {
        let splitConditions: [PaywallComponent.ExtendedCondition] = [
            .windowWidth(operator: .greaterThanOrEqual, value: 700),
            .windowHeight(operator: .greaterThanOrEqual, value: 480)
        ]

        // Landscape phone: wide enough but too short.
        expect(self.buildPartial(
            conditions: splitConditions,
            windowSize: CGSize(width: 874, height: 402)
        )).to(beNil())

        // Unfolded foldable: both dimensions qualify.
        expect(self.buildPartial(
            conditions: splitConditions,
            windowSize: CGSize(width: 904, height: 640)
        )).toNot(beNil())
    }

    func testComparisonOperators() {
        let size = CGSize(width: 700, height: 480)

        expect(self.buildPartial(
            conditions: [.windowWidth(operator: .greaterThanOrEqual, value: 700)],
            windowSize: size
        )).toNot(beNil())
        expect(self.buildPartial(
            conditions: [.windowWidth(operator: .greaterThan, value: 700)],
            windowSize: size
        )).to(beNil())
        expect(self.buildPartial(
            conditions: [.windowWidth(operator: .lessThanOrEqual, value: 700)],
            windowSize: size
        )).toNot(beNil())
        expect(self.buildPartial(
            conditions: [.windowWidth(operator: .lessThan, value: 700)],
            windowSize: size
        )).to(beNil())
        expect(self.buildPartial(
            conditions: [.windowHeight(operator: .equal, value: 480)],
            windowSize: size
        )).toNot(beNil())
    }

    // MARK: - Helpers

    private func decode(_ json: String) throws -> PaywallComponent.ExtendedCondition {
        let decoder = JSONDecoder()
        return try decoder.decode(PaywallComponent.ExtendedCondition.self, from: json.data(using: .utf8)!)
    }

}

private struct TestPartial: PresentedPartial {

    static func combine(_ base: TestPartial?, with other: TestPartial?) -> TestPartial {
        return other ?? base ?? TestPartial()
    }

}

#endif
