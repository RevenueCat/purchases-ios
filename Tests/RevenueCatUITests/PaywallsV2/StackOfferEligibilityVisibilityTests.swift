//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StackOfferEligibilityVisibilityTests.swift
//

import Nimble
@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class StackOfferEligibilityVisibilityTests: TestCase {

    func testStackWithoutOfferConditionsDoesNotRedactWhileEligibilityLoads() {
        let viewModel = Self.makeViewModel(overrides: [
            .init(conditions: [.selected], properties: .init(visible: false))
        ])

        expect(self.redacts(viewModel)).to(beFalse())
        expect(self.redacts(viewModel, state: .selected)).to(beFalse())
    }

    func testIntroOfferConditionRedactsWhileEligibilityLoads() {
        let viewModel = Self.makeViewModel(overrides: [
            .init(conditions: [.introOffer], properties: .init(visible: false))
        ])

        expect(self.redacts(viewModel)).to(beTrue())
        expect(self.redacts(
            viewModel,
            isIntroOfferEligibilityLoading: false,
            isPromoOfferEligibilityLoading: false
        )).to(beFalse())
    }

    func testIntroOfferConditionDoesNotWaitForPromoEligibility() {
        let viewModel = Self.makeViewModel(overrides: [
            .init(conditions: [.introOffer], properties: .init(visible: false))
        ])

        expect(self.redacts(
            viewModel,
            isEligibleForIntroOffer: false,
            isIntroOfferEligibilityLoading: false,
            isPromoOfferEligibilityLoading: true
        )).to(beFalse())
        expect(self.redacts(
            viewModel,
            isEligibleForIntroOffer: true,
            isIntroOfferEligibilityLoading: false,
            isPromoOfferEligibilityLoading: true
        )).to(beFalse())
    }

    func testPromoOfferConditionDoesNotWaitForIntroEligibility() {
        let viewModel = Self.makeViewModel(overrides: [
            .init(conditions: [.promoOffer], properties: .init(visible: false))
        ])

        expect(self.redacts(
            viewModel,
            isEligibleForPromoOffer: true,
            isIntroOfferEligibilityLoading: true,
            isPromoOfferEligibilityLoading: false
        )).to(beFalse())
    }

    func testStackWithBothOfferConditionsWaitsForTheCheckThatChangesVisibility() {
        let viewModel = Self.makeViewModel(overrides: [
            .init(conditions: [.introOffer], properties: .init(visible: false)),
            .init(conditions: [.promoOffer], properties: .init(visible: false))
        ])

        expect(self.redacts(
            viewModel,
            isEligibleForIntroOffer: false,
            isIntroOfferEligibilityLoading: false,
            isPromoOfferEligibilityLoading: true
        )).to(beTrue())
        expect(self.redacts(
            viewModel,
            isEligibleForPromoOffer: false,
            isIntroOfferEligibilityLoading: true,
            isPromoOfferEligibilityLoading: false
        )).to(beTrue())
        expect(self.redacts(
            viewModel,
            isEligibleForIntroOffer: true,
            isIntroOfferEligibilityLoading: false,
            isPromoOfferEligibilityLoading: true
        )).to(beFalse())
    }

    func testIntroOfferConditionRedactsWhetherTheStackEndsUpHiddenOrShown() {
        let shownForIntro = Self.makeViewModel(
            visible: false,
            overrides: [
                .init(conditions: [.introOffer], properties: .init(visible: true))
            ]
        )
        let hiddenForIntro = Self.makeViewModel(overrides: [
            .init(conditions: [.introOffer], properties: .init(visible: false))
        ])

        expect(self.redacts(shownForIntro)).to(beTrue())
        expect(self.redacts(hiddenForIntro)).to(beTrue())
        expect(self.redacts(
            shownForIntro,
            isIntroOfferEligibilityLoading: false,
            isPromoOfferEligibilityLoading: false
        )).to(beFalse())
    }

    func testIntroOfferSpacingOverrideDoesNotRedact() {
        let viewModel = Self.makeViewModel(
            visible: false,
            overrides: [
                .init(conditions: [.introOffer], properties: .init(visible: nil, spacing: 12))
            ]
        )

        expect(self.redacts(viewModel)).to(beFalse())
    }

    func testIntroOfferConditionIgnoresOverridesForAnotherScreenCondition() {
        let viewModel = Self.makeViewModel(overrides: [
            .init(
                conditions: [.expanded, .introOffer],
                properties: .init(visible: false)
            )
        ])

        expect(self.redacts(viewModel, condition: .compact)).to(beFalse())
        expect(self.redacts(viewModel, condition: .expanded)).to(beTrue())
        expect(self.redacts(
            viewModel,
            condition: .compact,
            isIntroOfferEligibilityLoading: false,
            isPromoOfferEligibilityLoading: false
        )).to(beFalse())
    }

    func testPromoIneligibleConditionRedactsWhileEligibilityLoads() {
        let viewModel = Self.makeViewModel(overrides: [
            .init(
                extendedConditions: [.promoOfferCondition(operator: .equals, value: false)],
                properties: .init(visible: false)
            )
        ])

        expect(self.redacts(viewModel)).to(beTrue())
        expect(self.redacts(
            viewModel,
            isEligibleForPromoOffer: false,
            isIntroOfferEligibilityLoading: true,
            isPromoOfferEligibilityLoading: false
        )).to(beFalse())
        expect(self.redacts(
            viewModel,
            isIntroOfferEligibilityLoading: false,
            isPromoOfferEligibilityLoading: false
        )).to(beFalse())
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension StackOfferEligibilityVisibilityTests {

    func redacts(
        _ viewModel: StackComponentViewModel,
        state: ComponentViewState = .default,
        condition: ScreenCondition = .compact,
        isEligibleForIntroOffer: Bool = false,
        isEligibleForPromoOffer: Bool = false,
        isIntroOfferEligibilityLoading: Bool = true,
        isPromoOfferEligibilityLoading: Bool = true
    ) -> Bool {
        return viewModel.redactsWhileOfferEligibilityLoads(
            state: state,
            condition: condition,
            offerEligibility: OfferEligibilityState(
                isEligibleForIntroOffer: isEligibleForIntroOffer,
                isEligibleForPromoOffer: isEligibleForPromoOffer,
                isIntroOfferEligibilityLoading: isIntroOfferEligibilityLoading,
                isPromoOfferEligibilityLoading: isPromoOfferEligibilityLoading
            ),
            conditionContext: .init()
        )
    }

    static func makeViewModel(
        visible: Bool? = nil,
        overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialStackComponent>? = nil
    ) -> StackComponentViewModel {
        return StackComponentViewModel(
            component: .init(visible: visible, components: [], overrides: overrides),
            viewModels: [],
            badgeViewModels: [],
            uiConfigProvider: UIConfigProvider(uiConfig: PreviewUIConfig.make())
        )
    }

}

#endif
