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
            .init(extendedConditions: [.introOfferCondition(operator: .equals, value: true)], properties: .init())
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
                .introOfferCondition(operator: .equals, value: true)
            ], properties: .init())
        ]

        expect(overrides.hasUnsupportedCondition()).to(beFalse())
    }

    // MARK: - Multiple Intro Offers Compatibility (iOS)

    func testHasUnsupportedCondition_WithMultipleIntroOffers_ReturnsFalse() throws {
        let overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent> = [
            .init(extendedConditions: [.multipleIntroOffers], properties: .init())
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

    // MARK: - containsUnsupportedConditions per Component Type (Bug Bash Section 5)

    func testCarouselWithUnsupportedCondition_ReturnsTrue() throws {
        let carousel = PaywallComponent.CarouselComponent(
            pages: [.init(components: [])],
            overrides: [
                .init(extendedConditions: [.unsupported], properties: .init())
            ]
        )

        expect(carousel.containsUnsupportedConditions()).to(beTrue())
    }

    func testCarouselWithUnsupportedConditionInPage_ReturnsTrue() throws {
        let carousel = PaywallComponent.CarouselComponent(
            pages: [.init(
                components: [],
                overrides: [
                    .init(extendedConditions: [.unsupported], properties: .init())
                ]
            )]
        )

        expect(carousel.containsUnsupportedConditions()).to(beTrue())
    }

    func testCarouselWithNoUnsupportedConditions_ReturnsFalse() throws {
        let carousel = PaywallComponent.CarouselComponent(
            pages: [.init(components: [])],
            overrides: [
                .init(extendedConditions: [.compact], properties: .init())
            ]
        )

        expect(carousel.containsUnsupportedConditions()).to(beFalse())
    }

    func testTabsWithUnsupportedCondition_ReturnsTrue() throws {
        let tabs = PaywallComponent.TabsComponent(
            control: .init(type: .buttons, stack: .init(components: [])),
            tabs: [.init(id: "tab_1", stack: .init(components: []))],
            overrides: [
                .init(extendedConditions: [.unsupported], properties: .init())
            ]
        )

        expect(tabs.containsUnsupportedConditions()).to(beTrue())
    }

    func testTabsWithUnsupportedConditionInTab_ReturnsTrue() throws {
        let tabs = PaywallComponent.TabsComponent(
            control: .init(type: .buttons, stack: .init(components: [])),
            tabs: [.init(
                id: "tab_1",
                stack: .init(
                    components: [],
                    overrides: [
                        .init(extendedConditions: [.unsupported], properties: .init())
                    ]
                )
            )]
        )

        expect(tabs.containsUnsupportedConditions()).to(beTrue())
    }

    func testTabsWithUnsupportedConditionInControl_ReturnsTrue() throws {
        let tabs = PaywallComponent.TabsComponent(
            control: .init(
                type: .buttons,
                stack: .init(
                    components: [],
                    overrides: [
                        .init(extendedConditions: [.unsupported], properties: .init())
                    ]
                )
            ),
            tabs: [.init(id: "tab_1", stack: .init(components: []))]
        )

        expect(tabs.containsUnsupportedConditions()).to(beTrue())
    }

    func testTabsWithNoUnsupportedConditions_ReturnsFalse() throws {
        let tabs = PaywallComponent.TabsComponent(
            control: .init(type: .buttons, stack: .init(components: [])),
            tabs: [.init(id: "tab_1", stack: .init(components: []))],
            overrides: [
                .init(extendedConditions: [.selectedPackage(operator: .in, packages: ["annual"])],
                      properties: .init())
            ]
        )

        expect(tabs.containsUnsupportedConditions()).to(beFalse())
    }

    func testButtonWithUnsupportedConditionInStack_ReturnsTrue() throws {
        let button = PaywallComponent.ButtonComponent(
            action: .restorePurchases,
            stack: .init(
                components: [],
                overrides: [
                    .init(extendedConditions: [.unsupported], properties: .init())
                ]
            )
        )

        expect(PaywallComponent.button(button).containsUnsupportedConditions()).to(beTrue())
    }

    func testPackageWithUnsupportedConditionInStack_ReturnsTrue() throws {
        let package = PaywallComponent.PackageComponent(
            packageID: "monthly",
            isSelectedByDefault: false,
            applePromoOfferProductCode: nil,
            stack: .init(
                components: [],
                overrides: [
                    .init(extendedConditions: [.unsupported], properties: .init())
                ]
            )
        )

        expect(PaywallComponent.package(package).containsUnsupportedConditions()).to(beTrue())
    }

    func testDeeplyNestedUnsupportedCondition_ReturnsTrue() throws {
        // Stack > Stack > Text with unsupported condition
        let text = PaywallComponent.TextComponent(
            text: "text_1",
            color: .init(light: .hex("#000000")),
            overrides: [
                .init(extendedConditions: [.unsupported], properties: .init())
            ]
        )
        let innerStack = PaywallComponent.StackComponent(
            components: [.text(text)]
        )
        let outerStack = PaywallComponent.StackComponent(
            components: [.stack(innerStack)]
        )

        expect(outerStack.containsUnsupportedConditions()).to(beTrue())
    }

    func testDeeplyNestedNoUnsupportedConditions_ReturnsFalse() throws {
        // Stack > Stack > Text with supported condition
        let text = PaywallComponent.TextComponent(
            text: "text_1",
            color: .init(light: .hex("#000000")),
            overrides: [
                .init(extendedConditions: [.variable(operator: .equals, variable: "x", value: .string("y"))],
                      properties: .init())
            ]
        )
        let innerStack = PaywallComponent.StackComponent(
            components: [.text(text)]
        )
        let outerStack = PaywallComponent.StackComponent(
            components: [.stack(innerStack)]
        )

        expect(outerStack.containsUnsupportedConditions()).to(beFalse())
    }

    // MARK: - toPresentedOverrides Default Paywall Behavior (Filters Rules When Unsupported Present)

    func testToPresentedOverrides_WithOnlyUnsupportedCondition_ReturnsEmpty() throws {
        let overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent> = [
            .init(extendedConditions: [.unsupported], properties: .init())
        ]

        let result = try overrides.toPresentedOverrides { $0 }
        expect(result).to(beEmpty())
    }

    func testToPresentedOverrides_WithUnsupportedConditionAmongOthers_FiltersOutRuleOverride() throws {
        // Override has [.compact, .unsupported, .selected] — contains a rule (.unsupported),
        // so the entire override is discarded
        let overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent> = [
            .init(extendedConditions: [.compact, .unsupported, .selected], properties: .init())
        ]

        let result = try overrides.toPresentedOverrides { $0 }
        expect(result).to(beEmpty())
    }

    func testToPresentedOverrides_WithUnsupportedPresent_KeepsOnlyLegacyOverrides() throws {
        let overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent> = [
            .init(extendedConditions: [.compact], properties: .init()),
            .init(extendedConditions: [.unsupported], properties: .init()),
            .init(extendedConditions: [.medium], properties: .init())
        ]

        let result = try overrides.toPresentedOverrides { $0 }
        expect(result.count).to(equal(2))
        expect(result[0].conditions).to(equal([PaywallComponent.ExtendedCondition.compact]))
        expect(result[1].conditions).to(equal([PaywallComponent.ExtendedCondition.medium]))
    }

    func testToPresentedOverrides_WithUnsupportedPresent_DiscardsAllRuleOverrides() throws {
        // When unsupported is present, ALL rule-based overrides are discarded — even known ones
        let overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent> = [
            .init(extendedConditions: [.compact], properties: .init()),
            .init(extendedConditions: [.introOffer], properties: .init()),
            .init(extendedConditions: [
                .selectedPackage(operator: .in, packages: ["monthly"])
            ], properties: .init()),
            .init(extendedConditions: [
                .variable(operator: .equals, variable: "plan", value: .string("pro"))
            ], properties: .init()),
            .init(extendedConditions: [.unsupported], properties: .init())
        ]

        let result = try overrides.toPresentedOverrides { $0 }
        // Only compact and introOffer survive (legacy/base conditions)
        expect(result.count).to(equal(2))
        expect(result[0].conditions).to(equal([PaywallComponent.ExtendedCondition.compact]))
        expect(result[1].conditions).to(equal([PaywallComponent.ExtendedCondition.introOffer]))
    }

    func testToPresentedOverrides_WithSupportedConditions_SucceedsAndReturnsOverrides() throws {
        let overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent> = [
            .init(extendedConditions: [.compact], properties: .init()),
            .init(extendedConditions: [.medium, .selected], properties: .init())
        ]

        let result = try overrides.toPresentedOverrides { $0 }

        expect(result.count).to(equal(2))
        expect(result[0].conditions).to(equal([PaywallComponent.ExtendedCondition.compact]))
        expect(result[1].conditions).to(equal([
            PaywallComponent.ExtendedCondition.medium,
            PaywallComponent.ExtendedCondition.selected
        ]))
    }

    func testToPresentedOverrides_WithEmptyOverrides_SucceedsAndReturnsEmptyArray() throws {
        let overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent> = []

        let result = try overrides.toPresentedOverrides { $0 }

        expect(result).to(beEmpty())
    }

}

#endif
