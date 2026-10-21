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

    func testIntroOfferColorOverrideDoesNotNeedEligibility() throws {
        let viewModel = try Self.makeViewModel(
            text: "Subscribe",
            overrides: [
                .init(
                    conditions: [.introOffer],
                    properties: .init(visible: nil, color: .init(light: .hex("#ff0000")))
                )
            ]
        )

        expect(self.redacts(viewModel)).to(beFalse())
    }

    func testIntroOfferVisibilityOverrideNeedsEligibility() throws {
        let viewModel = try Self.makeViewModel(
            text: "Subscribe",
            overrides: [
                .init(conditions: [.introOffer], properties: .init(visible: false))
            ]
        )

        expect(self.redacts(viewModel)).to(beTrue())
        expect(self.redacts(
            viewModel,
            isIntroOfferEligibilityLoading: false,
            isPromoOfferEligibilityLoading: false
        )).to(beFalse())
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

    func testIntroCopyOnlyRedactsProductsWithAnIntroOffer() throws {
        let monthly = TestData.monthlyPackage
        let annual = Package(
            identifier: "$rc_annual",
            packageType: .annual,
            storeProduct: TestData.productWithNoIntroOffer.toStoreProduct(),
            offeringIdentifier: "default",
            webCheckoutUrl: nil
        )
        let lifetime = TestData.lifetimePackage
        let availability = OfferEligibilityAvailability(packageInfos: [
            (monthly, nil), (annual, nil), (lifetime, nil)
        ])
        let viewModel = try Self.makeViewModel(
            text: "{{ product.price_per_period_abbreviated }}",
            extraStrings: ["intro_key": "1 week free, then {{ product.price_per_period_abbreviated }}"],
            overrides: [.init(conditions: [.introOffer], properties: .init(visible: nil, text: "intro_key"))]
        )

        for package in [monthly, annual, lifetime] {
            expect(self.redacts(
                viewModel,
                isPromoOfferEligibilityLoading: false,
                package: package,
                availability: availability
            )) == (package == monthly)
        }
    }

    func testIntroAvailabilityDoesNotLeakBetweenBillingPlans() throws {
        let productWithOffer = TestData.monthlyProduct
        var productWithoutOffer = productWithOffer
        productWithoutOffer.introductoryDiscount = nil
        let viewModel = try Self.makeViewModel(text: "{{ product.offer_price }}")

        for offerOnBillingPlan in [false, true] {
            let withOffer = Self.makePackage(product: productWithOffer, hasBillingPlan: offerOnBillingPlan)
            let withoutOffer = Self.makePackage(product: productWithoutOffer, hasBillingPlan: !offerOnBillingPlan)
            let availability = OfferEligibilityAvailability(packageInfos: [(withOffer, nil), (withoutOffer, nil)])

            expect(self.redacts(viewModel, package: withOffer, availability: availability)).to(beTrue())
            expect(self.redacts(viewModel, package: withoutOffer, availability: availability)).to(beFalse())
            expect(availability.loadingForVisibility(.intro, for: withoutOffer)).to(beEmpty())
        }
    }

    func testPromoAvailabilityDoesNotLeakBetweenBillingPlans() throws {
        let productWithOffer = TestData.productWithPromoOfferPayUpFront
        var productWithoutOffer = productWithOffer
        productWithoutOffer.discounts = []
        let code = try XCTUnwrap(productWithOffer.discounts.first?.offerIdentifier)
        let viewModel = try Self.makeViewModel(text: "{{ product.offer_price }}")

        for offerOnBillingPlan in [false, true] {
            let withOffer = Self.makePackage(product: productWithOffer, hasBillingPlan: offerOnBillingPlan)
            let withoutOffer = Self.makePackage(product: productWithoutOffer, hasBillingPlan: !offerOnBillingPlan)
            let availability = OfferEligibilityAvailability(packageInfos: [(withOffer, code), (withoutOffer, code)])

            expect(self.redacts(viewModel, package: withOffer, availability: availability)).to(beTrue())
            expect(self.redacts(viewModel, package: withoutOffer, availability: availability)).to(beFalse())
        }
    }

    @MainActor
    func testPromoCacheDoesNotChangeBillingPlanWithoutOffer() async throws {
        let productWithOffer = TestData.productWithPromoOfferPayUpFront
        var productWithoutOffer = productWithOffer
        productWithoutOffer.discounts = []
        let code = try XCTUnwrap(productWithOffer.discounts.first?.offerIdentifier)
        let viewModel = try Self.makeViewModel(text: "{{ product.offer_price }}")

        for offerOnBillingPlan in [false, true] {
            let withOffer = Self.makePackage(product: productWithOffer, hasBillingPlan: offerOnBillingPlan)
            let withoutOffer = Self.makePackage(product: productWithoutOffer, hasBillingPlan: !offerOnBillingPlan)
            XCTAssertEqual(withOffer.storeProduct.productIdentifier, withoutOffer.storeProduct.productIdentifier)
            XCTAssertNotEqual(withOffer.storeProduct.id, withoutOffer.storeProduct.id)

            for packages in [[withOffer, withoutOffer], [withoutOffer, withOffer]] {
                let context = "offerOnBillingPlan=\(offerOnBillingPlan), first=\(packages[0].identifier)"
                let packageInfos = packages.map { (package: $0, promotionalOfferProductCode: code as String?) }
                let availability = OfferEligibilityAvailability(packageInfos: packageInfos)
                // Use the real cache, with simulated signing so no StoreKit or backend request is needed.
                let cache = PaywallPromoOfferCache(simulateEligible: true)

                XCTAssertNil(cache.get(for: withoutOffer), context)
                XCTAssertFalse(self.redacts(
                    viewModel,
                    isIntroOfferEligibilityLoading: false,
                    package: withoutOffer,
                    availability: availability
                ), context)

                await cache.computeEligibility(for: packageInfos)

                XCTAssertEqual(cache.get(for: withOffer)?.discount.offerIdentifier, code, context)
                XCTAssertTrue(cache.isMostLikelyEligible(for: withOffer), context)
                // Text was already readable: completing another variant's check must not give it a promo.
                XCTAssertNil(cache.get(for: withoutOffer), context)
                XCTAssertFalse(cache.isMostLikelyEligible(for: withoutOffer), context)
            }
        }
    }

    func testPromoCopyRequiresAConfiguredMatchingOffer() throws {
        let package = TestData.packageWithPromoOfferPayUpFront
        let viewModel = try Self.makeViewModel(
            text: "Subscribe",
            extraStrings: ["promo_key": "Claim this offer"],
            overrides: [.init(conditions: [.promoOffer], properties: .init(visible: nil, text: "promo_key"))]
        )

        // The product has an offer, but only a matching paywall association makes signing necessary.
        for code in [nil, "missing", "intro"] as [String?] {
            let availability = OfferEligibilityAvailability(packageInfos: [(package, code)])
            expect(self.redacts(
                viewModel,
                isIntroOfferEligibilityLoading: false,
                package: package,
                availability: availability
            )) == (code == "intro")
        }
    }

    func testOfferVariablesOnlyWaitForApplicableChecks() throws {
        let intro = TestData.monthlyPackage
        let promo = TestData.packageWithPromoOfferPayUpFront
        let lifetime = TestData.lifetimePackage
        let availability = OfferEligibilityAvailability(packageInfos: [
            (intro, nil), (promo, "intro"), (lifetime, nil)
        ])
        let viewModel = try Self.makeViewModel(text: "{{ product.offer_price }}")

        for package in [intro, promo, lifetime] {
            for loading in [[], [.intro], [.promo], [.intro, .promo]] as [OfferEligibilityLoading] {
                let shouldRedact = (package == intro && loading.contains(.intro)) ||
                    (package == promo && loading.contains(.promo))
                expect(self.redacts(
                    viewModel,
                    isIntroOfferEligibilityLoading: loading.contains(.intro),
                    isPromoOfferEligibilityLoading: loading.contains(.promo),
                    package: package,
                    availability: availability
                )) == shouldRedact
            }
        }
    }

    func testVisibilityNarrowsIntroLoadingButPreservesSubscriptionHistoryUncertainty() {
        let intro = TestData.monthlyPackage
        let promo = TestData.packageWithPromoOfferPayUpFront
        let lifetime = TestData.lifetimePackage
        let availability = OfferEligibilityAvailability(packageInfos: [
            (intro, nil), (promo, "intro"), (lifetime, nil)
        ])

        for package in [intro, promo, lifetime] {
            let state = OfferEligibilityState(
                isEligibleForIntroOffer: false,
                isEligibleForPromoOffer: false,
                loading: availability.loadingForVisibility([.intro, .promo], for: package)
            )
            expect(state.visibilityCanChange(variesWithEligibility: true) { intro, _ in !intro }) ==
                (package == intro)
            expect(state.visibilityCanChange(variesWithEligibility: true) { _, promo in !promo }).to(beTrue())
        }
    }

    @MainActor
    func testSelectedPackageTextReevaluatesWhileEligibilityIsPending() throws {
        let monthly = TestData.monthlyPackage
        let lifetime = TestData.lifetimePackage
        let packages = [monthly, lifetime]
        let availability = OfferEligibilityAvailability(packageInfos: packages.map { ($0, nil) })
        let context = PackageContext(package: monthly, variableContext: .init(packages: packages))
        let viewModel = try Self.makeViewModel(text: "{{ product.offer_price }}")

        for package in [monthly, lifetime, monthly] {
            context.update(package: package, variableContext: context.variableContext)
            expect(self.redacts(
                viewModel,
                package: context.package,
                availability: availability
            )) == (package == monthly)
        }
    }

    func testInheritedAndDuplicatePromoAssociationsUseTheSigningConfiguration() {
        let package = TestData.packageWithPromoOfferPayUpFront
        let infos = PaywallsV2View.promoEligibilityPackageInfos(
            paywallPackageInfos: [(package, nil), (package, nil)],
            workflowPackages: [package],
            workflowPromoOfferProductCodes: [package.identifier: "intro"]
        )
        let availability = OfferEligibilityAvailability(packageInfos: infos)

        expect(availability.loading([.intro, .promo], for: package)) == [.promo]
        expect(availability.loading([.intro, .promo], for: nil)).to(beEmpty())
    }

    func testDependsOnOfferEligibilityMatchesTheOfferVariables() {
        let dependent = Set(VariablesV2.allCases.filter(\.dependsOnOfferEligibility))

        expect(dependent).to(equal([
            .productOfferPrice,
            .productOfferPricePerDay,
            .productOfferPricePerWeek,
            .productOfferPricePerMonth,
            .productOfferPricePerYear,
            .productOfferPriceWithZero,
            .productOfferPriceWithZeroPerDay,
            .productOfferPriceWithZeroPerWeek,
            .productOfferPriceWithZeroPerMonth,
            .productOfferPriceWithZeroPerYear,
            .productOfferPeriod,
            .productOfferPeriodAbbreviated,
            .productOfferPeriodInDays,
            .productOfferPeriodInWeeks,
            .productOfferPeriodInMonths,
            .productOfferPeriodInYears,
            .productOfferPeriodWithUnit,
            .productOfferEndDate,
            .productOfferRelativeDiscount,
            .productOfferAbsoluteDiscount,
            .productRelativeDiscountWithOffer,
            .productAbsoluteDiscountWithOffer,
            .productRelativeDiscountWithOfferFullPeriod,
            .productAbsoluteDiscountWithOfferFullPeriod
        ]))
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
        isPromoOfferEligibilityLoading: Bool = true,
        package: Package? = nil,
        availability: OfferEligibilityAvailability = .unknown
    ) -> Bool {
        return viewModel.redactsWhileOfferEligibilityLoads(
            state: state,
            condition: condition,
            offerEligibility: .init(
                isEligibleForIntroOffer: isEligibleForIntroOffer,
                isEligibleForPromoOffer: isEligibleForPromoOffer,
                loading: availability.loading(
                    .init(intro: isIntroOfferEligibilityLoading, promo: isPromoOfferEligibilityLoading),
                    for: package
                )
            ),
            conditionContext: .init()
        )
    }

    static func makePackage(product: TestStoreProduct, hasBillingPlan: Bool) -> Package {
        var product = product
        if hasBillingPlan {
            product.installmentsInfo = .init(
                commitmentInstallmentsCount: 12,
                commitmentInstallmentPeriod: .init(value: 1, unit: .month),
                installmentBillingPrice: 1,
                installmentBillingDisplayPrice: "$1",
                commitmentTotalPeriod: .init(value: 1, unit: .year),
                commitmentTotalPrice: 12,
                commitmentTotalDisplayPrice: "$12",
                billingPlanType: .monthly
            )
        }
        return Package(
            identifier: hasBillingPlan ? "installments" : "upfront",
            packageType: .custom,
            storeProduct: product.toStoreProduct(),
            offeringIdentifier: "default",
            webCheckoutUrl: nil
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
