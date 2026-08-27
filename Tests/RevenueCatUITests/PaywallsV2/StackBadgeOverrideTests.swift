//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StackBadgeOverrideTests.swift
//

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(tvOS)

/// A stack can have no badge of its own and gain one from a rule, and the dashboard commonly
/// authors one badge per offer type. Each badge carries its own rules, so the badge that renders
/// has to be the one whose condition matched, contents included.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class StackBadgeOverrideTests: TestCase {

    private static let introBaseLid = "intro_badge_base"
    private static let promoBaseLid = "promo_badge_base"

    private static let localizedStrings: [String: PaywallComponent.LocalizationDictionary.Value] = [
        introBaseLid: .string("INTRO BASE"),
        promoBaseLid: .string("PROMO BASE"),
        "intro_badge_resolved": .string("INTRO RESOLVED"),
        "promo_badge_resolved": .string("PROMO RESOLVED")
    ]

    // MARK: - Capture

    /// ViewBuilder closures cannot contain assignments, so capture through a single expression.
    private final class Box<T> {
        var value: T
        init(_ value: T) { self.value = value }
    }

    private static func capture<T>(_ value: T, into box: Box<T>) -> EmptyView {
        box.value = value
        return EmptyView()
    }

    // MARK: - Fixtures

    /// A badge whose inner text swaps itself when `condition` matches, the way the dashboard
    /// authors it: placeholder copy in the base, real copy behind the rule.
    private static func badge(
        baseLid: String,
        resolvedLid: String,
        condition: PaywallComponent.Condition
    ) -> PaywallComponent.Badge {
        let text = PaywallComponent.TextComponent(
            text: baseLid,
            color: .init(light: .hex("#000000")),
            overrides: [
                .init(conditions: [condition], properties: .init(text: resolvedLid))
            ]
        )
        return PaywallComponent.Badge(
            style: .overlaid,
            alignment: .topTrailing,
            stack: PaywallComponent.StackComponent(components: [.text(text)])
        )
    }

    private static func makeStackViewModel(promoRuleFirst: Bool = false) throws -> StackComponentViewModel {
        let factory = ViewModelFactory()
        let package = TestData.annualPackage
        let offering = Offering(
            identifier: "test",
            serverDescription: "",
            availablePackages: [package],
            webCheckoutUrl: nil
        )

        let introRule = PaywallComponent.ComponentOverride(
            conditions: [.introOffer],
            properties: PaywallComponent.PartialStackComponent(badge: badge(
                baseLid: introBaseLid,
                resolvedLid: "intro_badge_resolved",
                condition: .introOffer
            ))
        )
        let promoRule = PaywallComponent.ComponentOverride(
            conditions: [.promoOffer],
            properties: PaywallComponent.PartialStackComponent(badge: badge(
                baseLid: promoBaseLid,
                resolvedLid: "promo_badge_resolved",
                condition: .promoOffer
            ))
        )

        // No badge of its own; one badge per offer type, added by rules.
        let stack = PaywallComponent.StackComponent(
            components: [],
            badge: nil,
            overrides: promoRuleFirst ? [promoRule, introRule] : [introRule, promoRule]
        )

        guard case .stack(let viewModel) = try factory.toViewModel(
            component: .stack(stack),
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

    /// A signed promo offer, built the way the simulated cache builds one.
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

    // MARK: - Resolution

    /// What the badge that the stack actually presents renders as text.
    @MainActor
    private static func presentedBadgeText(
        of stackViewModel: StackComponentViewModel,
        isEligibleForIntroOffer: Bool,
        promoOffer: PromotionalOffer?
    ) -> String? {
        let badgeViewModels = Box<[PaywallComponentViewModel]>([])
        _ = stackViewModel.styles(
            state: .default,
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
            state: .default,
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

    // MARK: - Tests

    /// A promo-only customer presents the promo badge, so its own promo rule has to resolve too.
    /// It used to render the first rule's badge contents instead, leaving placeholder copy on
    /// screen for an eligible customer.
    @MainActor
    func testPromoOnlyCustomerSeesThePromoBadgeCopy() async throws {
        let stackViewModel = try Self.makeStackViewModel()
        let promoOffer = await Self.promotionalOffer()
        expect(promoOffer).toNot(beNil())

        let rendered = Self.presentedBadgeText(
            of: stackViewModel,
            isEligibleForIntroOffer: false,
            promoOffer: promoOffer
        )

        expect(rendered).to(equal("PROMO RESOLVED"))
    }

    /// The mirror case: put the promo rule first and the intro customer breaks instead. The defect
    /// tracked rule order, not offer type.
    @MainActor
    func testReversingTheRuleOrderKeepsIntroCustomersCorrect() throws {
        let stackViewModel = try Self.makeStackViewModel(promoRuleFirst: true)

        let rendered = Self.presentedBadgeText(
            of: stackViewModel,
            isEligibleForIntroOffer: true,
            promoOffer: nil
        )

        expect(rendered).to(equal("INTRO RESOLVED"))
    }

    /// The first rule's own badge keeps working, which is the case that always did.
    @MainActor
    func testIntroCustomerSeesTheIntroBadgeCopy() throws {
        let stackViewModel = try Self.makeStackViewModel()

        let rendered = Self.presentedBadgeText(
            of: stackViewModel,
            isEligibleForIntroOffer: true,
            promoOffer: nil
        )

        expect(rendered).to(equal("INTRO RESOLVED"))
    }

}

#endif
