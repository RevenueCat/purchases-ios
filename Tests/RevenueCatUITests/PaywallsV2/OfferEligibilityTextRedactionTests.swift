//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfferEligibilityTextRedactionTests.swift
//

import Nimble
@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class OfferEligibilityTextRedactionTests: TestCase {

    func testStaticTextDoesNotNeedEligibility() throws {
        expect(self.redacts(try Self.makeViewModel(text: "Hello, world"))).to(beFalse())
    }

    func testRegularPriceVariableDoesNotNeedEligibility() throws {
        expect(self.redacts(try Self.makeViewModel(text: "{{ product.price }}"))).to(beFalse())
        expect(self.redacts(try Self.makeViewModel(text: "{{ product.relative_discount }}"))).to(beFalse())
        expect(self.redacts(try Self.makeViewModel(text: "{{ product.secondary_offer_price }}"))).to(beFalse())
        expect(self.redacts(try Self.makeViewModel(text: "{{ custom.offer_price }}"))).to(beFalse())
    }

    func testOfferVariablesNeedEligibility() throws {
        expect(self.redacts(try Self.makeViewModel(text: "Then {{ product.offer_price }}"))).to(beTrue())
        expect(self.redacts(try Self.makeViewModel(
            text: "{{ product.offer_period_abbreviated | uppercase }}"
        ))).to(beTrue())
        expect(self.redacts(try Self.makeViewModel(
            text: "{{ legacy_offer_price }}",
            variableCompatibilityMap: ["legacy_offer_price": "product.offer_price"]
        ))).to(beTrue())
    }

    func testIntroOfferCopyOverrideNeedsEligibility() throws {
        let viewModel = try Self.makeViewModel(
            text: "Subscribe",
            extraStrings: ["intro_key": "Start your free trial"],
            overrides: [
                .init(
                    conditions: [.introOffer],
                    properties: .init(visible: nil, text: "intro_key")
                )
            ]
        )

        expect(self.redacts(viewModel)).to(beTrue())
    }

    func testPromoOfferCopyOverrideNeedsEligibility() throws {
        let viewModel = try Self.makeViewModel(
            text: "Subscribe",
            extraStrings: ["promo_key": "Claim this offer"],
            overrides: [
                .init(
                    extendedConditions: [.promoOfferCondition(operator: .equals, value: true)],
                    properties: .init(visible: nil, text: "promo_key")
                )
            ]
        )

        expect(self.redacts(viewModel)).to(beTrue())
    }

    func testIntroOfferCopyDoesNotWaitForPromoEligibilityAfterIntroEligibilityResolves() throws {
        let viewModel = try Self.makeViewModel(
            text: "Subscribe",
            extraStrings: ["intro_key": "Start your free trial"],
            overrides: [
                .init(
                    conditions: [.introOffer],
                    properties: .init(visible: nil, text: "intro_key")
                )
            ]
        )

        expect(self.redacts(
            viewModel,
            isEligibleForIntroOffer: true,
            isIntroOfferEligibilityLoading: false,
            isPromoOfferEligibilityLoading: true
        )).to(beFalse())
    }

    func testPromoOfferCopyDoesNotWaitForIntroEligibilityAfterPromoEligibilityResolves() throws {
        let viewModel = try Self.makeViewModel(
            text: "Subscribe",
            extraStrings: ["promo_key": "Claim this offer"],
            overrides: [
                .init(
                    extendedConditions: [.promoOfferCondition(operator: .equals, value: true)],
                    properties: .init(visible: nil, text: "promo_key")
                )
            ]
        )

        expect(self.redacts(
            viewModel,
            isEligibleForPromoOffer: true,
            isIntroOfferEligibilityLoading: true,
            isPromoOfferEligibilityLoading: false
        )).to(beFalse())
    }

    func testOfferVariablesWaitForEitherEligibilityResult() throws {
        let viewModel = try Self.makeViewModel(text: "{{ product.offer_price }}")

        expect(self.redacts(
            viewModel,
            isIntroOfferEligibilityLoading: true,
            isPromoOfferEligibilityLoading: false
        )).to(beTrue())
        expect(self.redacts(
            viewModel,
            isIntroOfferEligibilityLoading: false,
            isPromoOfferEligibilityLoading: true
        )).to(beTrue())
        expect(self.redacts(
            viewModel,
            isIntroOfferEligibilityLoading: false,
            isPromoOfferEligibilityLoading: false
        )).to(beFalse())
    }

    func testOfferOverrideThatDoesNotChangeCopyDoesNotNeedEligibility() throws {
        let colorOnly = try Self.makeViewModel(
            text: "Subscribe",
            overrides: [
                .init(
                    conditions: [.introOffer],
                    properties: .init(visible: nil, color: .init(light: .hex("#ff0000")))
                )
            ]
        )
        let visibilityOnly = try Self.makeViewModel(
            text: "Subscribe",
            overrides: [
                .init(conditions: [.introOffer], properties: .init(visible: false))
            ]
        )

        expect(self.redacts(colorOnly)).to(beFalse())
        expect(self.redacts(visibilityOnly)).to(beFalse())
    }

    func testNonOfferConditionDoesNotNeedEligibility() throws {
        let viewModel = try Self.makeViewModel(
            text: "Monthly",
            extraStrings: ["selected_key": "Selected monthly"],
            overrides: [
                .init(
                    conditions: [.selected],
                    properties: .init(visible: nil, text: "selected_key")
                )
            ]
        )

        expect(self.redacts(viewModel)).to(beFalse())
        expect(self.redacts(viewModel, state: .selected)).to(beFalse())
    }

    func testOfferCopyOverrideOnAnotherScreenConditionIsIgnored() throws {
        let viewModel = try Self.makeViewModel(
            text: "Hello",
            extraStrings: ["offer_key": "{{ product.offer_price }}"],
            overrides: [
                .init(
                    extendedConditions: [.expanded, .introOffer],
                    properties: .init(visible: nil, text: "offer_key")
                )
            ]
        )

        expect(self.redacts(viewModel, condition: .compact)).to(beFalse())
        expect(self.redacts(viewModel, condition: .expanded)).to(beTrue())
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension OfferEligibilityTextRedactionTests {

    func redacts(
        _ viewModel: TextComponentViewModel,
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
            offerEligibility: .init(
                isEligibleForIntroOffer: isEligibleForIntroOffer,
                isEligibleForPromoOffer: isEligibleForPromoOffer,
                isIntroOfferEligibilityLoading: isIntroOfferEligibilityLoading,
                isPromoOfferEligibilityLoading: isPromoOfferEligibilityLoading
            ),
            conditionContext: .init()
        )
    }

    static func makeViewModel(
        text: String,
        extraStrings: [String: String] = [:],
        overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialTextComponent>? = nil,
        variableCompatibilityMap: [String: String] = [:]
    ) throws -> TextComponentViewModel {
        var localizedStrings: PaywallComponent.LocalizationDictionary = [
            "text_key": .string(text)
        ]
        for (key, value) in extraStrings {
            localizedStrings[key] = .string(value)
        }

        return try TextComponentViewModel(
            localizationProvider: LocalizationProvider(
                locale: Locale(identifier: "en_US"),
                localizedStrings: localizedStrings
            ),
            uiConfigProvider: UIConfigProvider(uiConfig: .init(
                app: .init(colors: [:], fonts: [:]),
                localizations: [:],
                variableConfig: .init(
                    variableCompatibilityMap: variableCompatibilityMap,
                    functionCompatibilityMap: [:]
                )
            )),
            component: PaywallComponent.TextComponent(
                text: "text_key",
                color: .init(light: .hex("#000000")),
                overrides: overrides
            )
        )
    }

}

#endif
