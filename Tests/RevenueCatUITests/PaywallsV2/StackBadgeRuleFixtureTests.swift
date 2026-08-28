//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StackBadgeRuleFixtureTests.swift
//

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(tvOS)

/// Badge rules built from real dashboard JSON, so decoding is covered too. Every case has two
/// badge rules, which is the shape that broke.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class StackBadgeRuleFixtureTests: TestCase {

    // MARK: - Fixtures

    /// A badge whose inner text swaps on `innerCondition`, the way the dashboard authors it:
    /// placeholder copy in the base, real copy behind a rule.
    private static func badgeJSON(
        baseLid: String,
        resolvedLid: String,
        innerCondition: String
    ) -> String {
        return """
        {
          "style": "overlay",
          "alignment": "top_trailing",
          "stack": {
            "type": "stack",
            "size": { "width": { "type": "fit" }, "height": { "type": "fit" } },
            "dimension": { "type": "vertical", "alignment": "center", "distribution": "start" },
            "padding": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
            "margin": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
            "components": [
              {
                "type": "text",
                "text_lid": "\(baseLid)",
                "color": { "light": { "type": "hex", "value": "#000000" } },
                "font_weight": "regular",
                "font_size": 16,
                "horizontal_alignment": "center",
                "size": { "width": { "type": "fill" }, "height": { "type": "fit" } },
                "padding": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
                "margin": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
                "overrides": [
                  {
                    "conditions": [{ "type": "\(innerCondition)" }],
                    "properties": { "text_lid": "\(resolvedLid)" }
                  }
                ]
              }
            ]
          }
        }
        """
    }

    /// A stack with no badge of its own, gaining one from each listed rule.
    private static func stackJSON(rules: [(condition: String, badge: String)]) -> String {
        let overrides = rules.map { rule in
            """
            { "conditions": [{ "type": "\(rule.condition)" }],
              "properties": { "badge": \(rule.badge) } }
            """
        }.joined(separator: ",")

        return """
        {
          "type": "stack",
          "size": { "width": { "type": "fit" }, "height": { "type": "fit" } },
            "dimension": { "type": "vertical", "alignment": "center", "distribution": "start" },
            "padding": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
            "margin": { "top": 0, "bottom": 0, "leading": 0, "trailing": 0 },
          "components": [],
          "overrides": [\(overrides)]
        }
        """
    }

    private static let localizedStrings: [String: PaywallComponent.LocalizationDictionary.Value] = [
        "intro_base": .string("INTRO BASE"),
        "intro_resolved": .string("INTRO RESOLVED"),
        "promo_base": .string("PROMO BASE"),
        "promo_resolved": .string("PROMO RESOLVED"),
        "shared_base": .string("SHARED BASE"),
        "shared_resolved": .string("SHARED RESOLVED")
    ]

    // MARK: - Harness

    private final class Box<T> {
        var value: T
        init(_ value: T) { self.value = value }
    }

    private static func capture<T>(_ value: T, into box: Box<T>) -> EmptyView {
        box.value = value
        return EmptyView()
    }

    private static func stackViewModel(from json: String) throws -> StackComponentViewModel {
        // The production decoder, so the wire keys under test are the real ones.
        let component = try JSONDecoder.default.decode(
            PaywallComponent.StackComponent.self,
            from: Data(json.utf8)
        )
        let factory = ViewModelFactory()
        let offering = Offering(
            identifier: "test",
            serverDescription: "",
            availablePackages: [TestData.annualPackage],
            webCheckoutUrl: nil
        )

        guard case .stack(let viewModel) = try factory.toViewModel(
            component: .stack(component),
            packageValidator: factory.packageValidator,
            offering: offering,
            localizationProvider: LocalizationProvider(
                locale: Locale(identifier: "en_US"),
                localizedStrings: localizedStrings
            ),
            uiConfigProvider: UIConfigProvider(uiConfig: PreviewUIConfig.make()),
            colorScheme: .light
        ) else {
            throw XCTSkip("Expected a .stack view model")
        }
        return viewModel
    }

    @MainActor
    private static func promotionalOffer() async -> PromotionalOffer? {
        let discount = TestStoreProductDiscount(
            identifier: "promo_code",
            price: 1,
            localizedPriceString: "$1.00",
            paymentMode: .payUpFront,
            subscriptionPeriod: .init(value: 1, unit: .year),
            numberOfPeriods: 1,
            type: .promotional
        )
        let product = TestStoreProduct(
            localizedTitle: "Annual",
            price: 10,
            localizedPriceString: "$10.00",
            productIdentifier: "annual",
            productType: .autoRenewableSubscription,
            localizedDescription: "",
            subscriptionGroupIdentifier: "group",
            subscriptionPeriod: .init(value: 1, unit: .year),
            discounts: [discount]
        )
        let package = Package(
            identifier: "$rc_annual",
            packageType: .annual,
            storeProduct: product.toStoreProduct(),
            offeringIdentifier: "test",
            webCheckoutUrl: nil
        )
        let cache = PaywallPromoOfferCache(simulateEligible: true)
        await cache.computeEligibility(for: [(package, "promo_code")])
        return cache.get(for: package)
    }

    /// The text inside the badge the stack actually presents.
    @MainActor
    private static func presentedBadgeText(
        json: String,
        isEligibleForIntroOffer: Bool,
        promoOffer: PromotionalOffer?,
        state: ComponentViewState = .default
    ) throws -> String? {
        let stackViewModel = try Self.stackViewModel(from: json)

        let badgeViewModels = Box<[PaywallComponentViewModel]>([])
        _ = stackViewModel.styles(
            state: state,
            condition: .compact,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: promoOffer != nil,
            selectedPackageId: nil,
            customVariables: [:],
            colorScheme: .light
        ) { style in
            Self.capture(style.badge?.badgeViewModels ?? [], into: badgeViewModels)
        }

        guard case .text(let text) = badgeViewModels.value.first else { return nil }

        let rendered = Box<String?>(nil)
        _ = text.styles(
            state: state,
            condition: .compact,
            selectedPackageId: nil,
            packageContext: PackageContext(package: nil, variableContext: .init()),
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            promoOffer: promoOffer
        ) { style in
            Self.capture(style.text, into: rendered)
        }
        return rendered.value
    }

    // MARK: - One rule per offer type

    private static var introThenPromo: String {
        return stackJSON(rules: [
            (condition: "intro_offer",
             badge: badgeJSON(baseLid: "intro_base", resolvedLid: "intro_resolved",
                              innerCondition: "intro_offer")),
            (condition: "promo_offer",
             badge: badgeJSON(baseLid: "promo_base", resolvedLid: "promo_resolved",
                              innerCondition: "promo_offer"))
        ])
    }

    @MainActor
    func testTrialCustomerGetsTheTrialBadge() throws {
        expect(try Self.presentedBadgeText(
            json: Self.introThenPromo,
            isEligibleForIntroOffer: true,
            promoOffer: nil
        )).to(equal("INTRO RESOLVED"))
    }

    @MainActor
    func testPromoCustomerGetsThePromoBadge() async throws {
        let promoOffer = await Self.promotionalOffer()
        expect(try Self.presentedBadgeText(
            json: Self.introThenPromo,
            isEligibleForIntroOffer: false,
            promoOffer: promoOffer
        )).to(equal("PROMO RESOLVED"))
    }

    /// Rules are last-match-wins, so a customer matching both gets the later rule's badge.
    @MainActor
    func testCustomerMatchingBothRulesGetsTheLastOne() async throws {
        let promoOffer = await Self.promotionalOffer()
        expect(try Self.presentedBadgeText(
            json: Self.introThenPromo,
            isEligibleForIntroOffer: true,
            promoOffer: promoOffer
        )).to(equal("PROMO RESOLVED"))
    }

    // MARK: - Inner rule on a different condition than the rule that supplied the badge

    /// The badge arrives from the promo rule, but its text swaps on selection instead. The two are
    /// independent, so the inner rule has to be evaluated on its own terms.
    private static var promoBadgeWithSelectionInnerRule: String {
        return stackJSON(rules: [
            (condition: "intro_offer",
             badge: badgeJSON(baseLid: "intro_base", resolvedLid: "intro_resolved",
                              innerCondition: "intro_offer")),
            (condition: "promo_offer",
             badge: badgeJSON(baseLid: "shared_base", resolvedLid: "shared_resolved",
                              innerCondition: "selected"))
        ])
    }

    @MainActor
    func testInnerRuleOnAnotherConditionStaysUnresolvedWhenItDoesNotMatch() async throws {
        let promoOffer = await Self.promotionalOffer()
        expect(try Self.presentedBadgeText(
            json: Self.promoBadgeWithSelectionInnerRule,
            isEligibleForIntroOffer: false,
            promoOffer: promoOffer,
            state: .default
        )).to(equal("SHARED BASE"))
    }

    @MainActor
    func testInnerRuleOnAnotherConditionResolvesWhenItMatches() async throws {
        let promoOffer = await Self.promotionalOffer()
        expect(try Self.presentedBadgeText(
            json: Self.promoBadgeWithSelectionInnerRule,
            isEligibleForIntroOffer: false,
            promoOffer: promoOffer,
            state: .selected
        )).to(equal("SHARED RESOLVED"))
    }

    // MARK: - Two rules authoring the same badge

    @MainActor
    func testTwoRulesAuthoringAnIdenticalBadgeStillResolve() async throws {
        let shared = Self.badgeJSON(baseLid: "shared_base", resolvedLid: "shared_resolved",
                                    innerCondition: "promo_offer")
        let json = Self.stackJSON(rules: [
            (condition: "intro_offer", badge: shared),
            (condition: "promo_offer", badge: shared)
        ])
        let promoOffer = await Self.promotionalOffer()

        expect(try Self.presentedBadgeText(
            json: json,
            isEligibleForIntroOffer: false,
            promoOffer: promoOffer
        )).to(equal("SHARED RESOLVED"))
    }

    // MARK: - No rule matches

    @MainActor
    func testNoMatchingRuleShowsNoBadge() throws {
        expect(try Self.presentedBadgeText(
            json: Self.introThenPromo,
            isEligibleForIntroOffer: false,
            promoOffer: nil
        )).to(beNil())
    }

}

#endif
