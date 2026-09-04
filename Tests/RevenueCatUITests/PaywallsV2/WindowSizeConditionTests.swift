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

    func testWindowConditionsRoundTripThroughEncoding() throws {
        let conditions: [PaywallComponent.ExtendedCondition] = [
            .windowWidth(operator: .greaterThanOrEqual, value: 700),
            .windowHeight(operator: .lessThan, value: 480)
        ]

        let encoded = try JSONEncoder().encode(conditions)
        let decoded = try JSONDecoder().decode(
            [PaywallComponent.ExtendedCondition].self,
            from: encoded
        )

        expect(decoded).to(equal(conditions))
    }

    func testWindowConditionsAreRules() {
        expect(PaywallComponent.ExtendedCondition
            .windowWidth(operator: .greaterThanOrEqual, value: 700).isRule) == true
        expect(PaywallComponent.ExtendedCondition
            .windowHeight(operator: .greaterThanOrEqual, value: 480).isRule) == true
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
        let result = self.buildPartial(
            conditions: [.windowWidth(operator: .greaterThanOrEqual, value: 700)],
            windowSize: nil
        )
        expect(result).to(beNil())
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

    var value: String?

    static func combine(_ base: TestPartial?, with other: TestPartial?) -> TestPartial {
        return TestPartial(value: other?.value ?? base?.value)
    }

}

#endif
