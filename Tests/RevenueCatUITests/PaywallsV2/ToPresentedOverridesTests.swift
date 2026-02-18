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

    func testContainsUnsupportedConditions_WithUnsupportedCondition_ReturnsTrue() throws {
        let overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent> = [
            .init(extendedConditions: [.unsupported], properties: .init())
        ]

        expect(overrides.containsUnsupportedConditions()).to(beTrue())
    }

    func testContainsUnsupportedConditions_WithUnsupportedConditionAmongOthers_ReturnsTrue() throws {
        let overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent> = [
            .init(extendedConditions: [.compact, .unsupported, .selected], properties: .init())
        ]

        expect(overrides.containsUnsupportedConditions()).to(beTrue())
    }

    func testContainsUnsupportedConditions_WithMultipleOverrides_OneHasUnsupported_ReturnsTrue() throws {
        let overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent> = [
            .init(extendedConditions: [.compact], properties: .init()),
            .init(extendedConditions: [.unsupported], properties: .init()),
            .init(extendedConditions: [.medium], properties: .init())
        ]

        expect(overrides.containsUnsupportedConditions()).to(beTrue())
    }

    func testContainsUnsupportedConditions_WithSupportedConditions_ReturnsFalse() throws {
        let overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent> = [
            .init(extendedConditions: [.compact], properties: .init()),
            .init(extendedConditions: [.medium, .selected], properties: .init()),
            .init(extendedConditions: [.introOffer], properties: .init())
        ]

        expect(overrides.containsUnsupportedConditions()).to(beFalse())
    }

    func testContainsUnsupportedConditions_WithEmptyOverrides_ReturnsFalse() throws {
        let overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent> = []

        expect(overrides.containsUnsupportedConditions()).to(beFalse())
    }

    func testContainsUnsupportedConditions_WithNewConditionTypes_ReturnsFalse() throws {
        let overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent> = [
            .init(extendedConditions: [
                .selectedPackageCondition(operator: .in, packages: ["monthly"])
            ], properties: .init()),
            .init(extendedConditions: [
                .variableCondition(operator: .equals, variable: "plan", value: .string("premium"))
            ], properties: .init()),
            .init(extendedConditions: [
                .introOfferCondition(operator: .equals, value: true)
            ], properties: .init())
        ]

        expect(overrides.containsUnsupportedConditions()).to(beFalse())
    }

}

#endif
