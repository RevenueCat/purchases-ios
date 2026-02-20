//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ToPresentedOverridesTests.swift
//
//  Created by RevenueCat on 2/18/26.
//

import Nimble
@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class ToPresentedOverridesTests: TestCase {

    // MARK: - Unsupported Condition Detection Tests

    // MARK: - Array hasUnsupportedCondition Tests

    func testHasUnsupportedCondition_WithUnsupportedCondition_ReturnsTrue() throws {
        let overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent> = [
            .init(extendedConditions: [.unsupported], properties: .init())
        ]

        expect(overrides.hasUnsupportedCondition()).to(beTrue())
    }

    func testHasUnsupportedCondition_WithUnsupportedConditionAmongOthers_ReturnsTrue() throws {
        let overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent> = [
            .init(extendedConditions: [.compact, .unsupported, .selected], properties: .init())
        ]

        expect(overrides.hasUnsupportedCondition()).to(beTrue())
    }

    func testHasUnsupportedCondition_WithMultipleOverrides_OneHasUnsupported_ReturnsTrue() throws {
        let overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent> = [
            .init(extendedConditions: [.compact], properties: .init()),
            .init(extendedConditions: [.unsupported], properties: .init()),
            .init(extendedConditions: [.medium], properties: .init())
        ]

        expect(overrides.hasUnsupportedCondition()).to(beTrue())
    }

    func testHasUnsupportedCondition_WithSupportedConditions_ReturnsFalse() throws {
        let overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent> = [
            .init(extendedConditions: [.compact], properties: .init()),
            .init(extendedConditions: [.medium, .selected], properties: .init()),
            .init(extendedConditions: [.introOffer(operator: .equals, value: true)], properties: .init())
        ]

        expect(overrides.hasUnsupportedCondition()).to(beFalse())
    }

    func testHasUnsupportedCondition_WithEmptyOverrides_ReturnsFalse() throws {
        let overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent> = []

        expect(overrides.hasUnsupportedCondition()).to(beFalse())
    }

    func testHasUnsupportedCondition_WithNewConditionTypes_ReturnsFalse() throws {
        let overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent> = [
            .init(extendedConditions: [
                .selectedPackage(operator: .in, packages: ["monthly"])
            ], properties: .init()),
            .init(extendedConditions: [
                .variable(operator: .equals, variable: "plan", value: .string("premium"))
            ], properties: .init()),
            .init(extendedConditions: [
                .introOffer(operator: .equals, value: true)
            ], properties: .init())
        ]

        expect(overrides.hasUnsupportedCondition()).to(beFalse())
    }

    // MARK: - Recursive containsUnsupportedConditions Tests

    func testStackWithUnsupportedCondition_ReturnsTrue() throws {
        let stack = PaywallComponent.StackComponent(
            components: [],
            overrides: [
                .init(extendedConditions: [.unsupported], properties: .init())
            ]
        )

        expect(stack.containsUnsupportedConditions()).to(beTrue())
    }

    func testStackWithNestedUnsupportedCondition_ReturnsTrue() throws {
        let innerText = PaywallComponent.TextComponent(
            text: "text_1",
            color: .init(light: .hex("#000000")),
            overrides: [
                .init(extendedConditions: [.unsupported], properties: .init())
            ]
        )
        let stack = PaywallComponent.StackComponent(
            components: [.text(innerText)]
        )

        expect(stack.containsUnsupportedConditions()).to(beTrue())
    }

    func testStackWithNoUnsupportedConditions_ReturnsFalse() throws {
        let stack = PaywallComponent.StackComponent(
            components: [],
            overrides: [
                .init(extendedConditions: [.compact], properties: .init())
            ]
        )

        expect(stack.containsUnsupportedConditions()).to(beFalse())
    }

    func testComponentWithNoOverrides_ReturnsFalse() throws {
        let component = PaywallComponent.text(
            .init(text: "text_1", color: .init(light: .hex("#000000")))
        )

        expect(component.containsUnsupportedConditions()).to(beFalse())
    }

}

#endif
