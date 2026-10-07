//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class StackOverflowOverrideTests: TestCase {

    func testWidthRuleDisablesBaseScrollAndRestoresItAfterResize() {
        let viewModel = Self.viewModel(base: .scroll, ruleOverflow: .default)

        expect(Self.scrollable(viewModel, width: 300)) == true
        expect(Self.scrollable(viewModel, width: 700)) == false
        expect(Self.scrollable(viewModel, width: 300)) == true
    }

    func testWidthRuleEnablesBaseNoScrollAndRestoresItAfterResize() {
        let viewModel = Self.viewModel(base: .default, ruleOverflow: .scroll)

        expect(Self.scrollable(viewModel, width: 300)) == false
        expect(Self.scrollable(viewModel, width: 700)) == true
        expect(Self.scrollable(viewModel, width: 300)) == false
    }

    func testNonmatchingWidthRulePreservesAbsentBaseOverflow() {
        let viewModel = Self.viewModel(base: nil, ruleOverflow: .default)

        expect(Self.scrollable(viewModel, width: 300)).to(beNil())
        expect(Self.scrollable(viewModel, width: 700)) == false
        expect(Self.scrollable(viewModel, width: 300)).to(beNil())
    }

    func testLaterMatchingRuleWithAbsentOverflowInheritsEarlierRule() {
        let viewModel = Self.viewModel(base: .scroll, ruleOverflow: .default, laterOverride: .init(spacing: 12))

        expect(Self.scrollable(viewModel, width: 700)) == false
    }

    func testLaterMatchingRuleWithExplicitOverflowWins() {
        let viewModel = Self.viewModel(base: .scroll, ruleOverflow: .default, laterOverride: .init(overflow: .scroll))

        expect(Self.scrollable(viewModel, width: 700)) == true
    }

    private static func viewModel(
        base: PaywallComponent.StackComponent.Overflow?,
        ruleOverflow: PaywallComponent.StackComponent.Overflow,
        laterOverride: PaywallComponent.PartialStackComponent? = nil
    ) -> StackComponentViewModel {
        let condition = PaywallComponent.ExtendedCondition.windowWidth(operator: .greaterThanOrEqual, value: 600)
        var overrides = [PaywallComponent.ComponentOverride(
            extendedConditions: [condition],
            properties: PaywallComponent.PartialStackComponent(overflow: ruleOverflow)
        )]
        if let laterOverride {
            overrides.append(.init(extendedConditions: [condition], properties: laterOverride))
        }
        return StackComponentViewModel(
            component: .init(components: [], dimension: .zlayer(.top), overflow: base, overrides: overrides),
            viewModels: [],
            badgeViewModels: [],
            uiConfigProvider: UIConfigProvider(uiConfig: PreviewUIConfig.make())
        )
    }

    private static func scrollable(_ viewModel: StackComponentViewModel, width: CGFloat) -> Bool? {
        viewModel.styles(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            selectedPackageId: nil,
            customVariables: [:],
            windowSize: CGSize(width: width, height: 600),
            colorScheme: .light
        ).scrollable
    }

}

#endif
