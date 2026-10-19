//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ButtonPackageOfferEligibilityVisibilityTests.swift
//

import Nimble
@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class ButtonOfferEligibilityVisibilityTests: TestCase {

    func testSelectedConditionDoesNotRedactWhileEligibilityLoads() throws {
        let viewModel = try Self.makeViewModel(overrides: [
            .init(conditions: [.selected], properties: .init(visible: false))
        ])

        expect(self.redacts(viewModel)).to(beFalse())
        expect(self.redacts(viewModel, state: .selected)).to(beFalse())
    }

    func testIntroOfferConditionRedactsWhileEligibilityLoads() throws {
        let viewModel = try Self.makeViewModel(overrides: [
            .init(conditions: [.introOffer], properties: .init(visible: false))
        ])

        expect(self.redacts(viewModel)).to(beTrue())
        expect(self.redacts(
            viewModel,
            isIntroOfferEligibilityLoading: false,
            isPromoOfferEligibilityLoading: false
        )).to(beFalse())
    }

    func testIntroOfferConditionDoesNotWaitForPromoEligibility() throws {
        let viewModel = try Self.makeViewModel(overrides: [
            .init(conditions: [.introOffer], properties: .init(visible: false))
        ])

        expect(self.redacts(
            viewModel,
            isEligibleForIntroOffer: true,
            isIntroOfferEligibilityLoading: false,
            isPromoOfferEligibilityLoading: true
        )).to(beFalse())
    }

    func testPromoOfferConditionDoesNotWaitForIntroEligibility() throws {
        let viewModel = try Self.makeViewModel(overrides: [
            .init(conditions: [.promoOffer], properties: .init(visible: false))
        ])

        expect(self.redacts(
            viewModel,
            isEligibleForPromoOffer: true,
            isIntroOfferEligibilityLoading: true,
            isPromoOfferEligibilityLoading: false
        )).to(beFalse())
    }

    func testBothOfferConditionsWaitForTheCheckThatChangesVisibility() throws {
        let viewModel = try Self.makeViewModel(overrides: [
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
            isEligibleForIntroOffer: true,
            isIntroOfferEligibilityLoading: false,
            isPromoOfferEligibilityLoading: true
        )).to(beFalse())
    }

    func testIntroOfferConditionIgnoresAnotherScreenCondition() throws {
        let viewModel = try Self.makeViewModel(overrides: [
            .init(
                conditions: [.expanded, .introOffer],
                properties: .init(visible: false)
            )
        ])

        expect(self.redacts(viewModel, condition: .compact)).to(beFalse())
        expect(self.redacts(viewModel, condition: .expanded)).to(beTrue())
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PackageOfferEligibilityVisibilityTests: TestCase {

    func testSelectedConditionDoesNotRedactWhileEligibilityLoads() {
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

    func testBothOfferConditionsWaitForTheCheckThatChangesVisibility() {
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
            isEligibleForIntroOffer: true,
            isIntroOfferEligibilityLoading: false,
            isPromoOfferEligibilityLoading: true
        )).to(beFalse())
    }

    func testIntroOfferConditionIgnoresAnotherScreenCondition() {
        let viewModel = Self.makeViewModel(overrides: [
            .init(
                conditions: [.expanded, .introOffer],
                properties: .init(visible: false)
            )
        ])

        expect(self.redacts(viewModel, condition: .compact)).to(beFalse())
        expect(self.redacts(viewModel, condition: .expanded)).to(beTrue())
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension ButtonOfferEligibilityVisibilityTests {

    func redacts(
        _ viewModel: ButtonComponentViewModel,
        state: ComponentViewState = .default,
        condition: ScreenCondition = .compact,
        isEligibleForIntroOffer: Bool = false,
        isEligibleForPromoOffer: Bool = false,
        isIntroOfferEligibilityLoading: Bool = true,
        isPromoOfferEligibilityLoading: Bool = true
    ) -> Bool {
        let offerEligibility = OfferEligibilityState(
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            loading: .init(
                intro: isIntroOfferEligibilityLoading,
                promo: isPromoOfferEligibilityLoading
            )
        )
        return offerEligibility.visibilityCanChange(
            variesWithEligibility: viewModel.dependsOnOfferEligibility
        ) { intro, promo in
            viewModel.visible(
                state: state,
                condition: condition,
                isEligibleForIntroOffer: intro,
                isEligibleForPromoOffer: promo,
                selectedPackageId: nil,
                customVariables: [:]
            )
        }
    }

    static func makeViewModel(
        overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialButtonComponent>? = nil
    ) throws -> ButtonComponentViewModel {
        let uiConfigProvider = UIConfigProvider(uiConfig: PreviewUIConfig.make())
        let component = PaywallComponent.ButtonComponent(
            action: .navigateBack,
            stack: .init(components: []),
            overrides: overrides
        )
        return try ButtonComponentViewModel(
            component: component,
            localizationProvider: LocalizationProvider(locale: .current, localizedStrings: [:]),
            offering: .init(
                identifier: "test",
                serverDescription: "",
                metadata: [:],
                availablePackages: [],
                webCheckoutUrl: nil
            ),
            stackViewModel: StackComponentViewModel(
                component: component.stack,
                viewModels: [],
                badgeViewModels: [],
                uiConfigProvider: uiConfigProvider
            ),
            uiConfigProvider: uiConfigProvider
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PackageOfferEligibilityVisibilityTests {

    func redacts(
        _ viewModel: PackageComponentViewModel,
        state: ComponentViewState = .default,
        condition: ScreenCondition = .compact,
        isEligibleForIntroOffer: Bool = false,
        isEligibleForPromoOffer: Bool = false,
        isIntroOfferEligibilityLoading: Bool = true,
        isPromoOfferEligibilityLoading: Bool = true
    ) -> Bool {
        let offerEligibility = OfferEligibilityState(
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            loading: .init(
                intro: isIntroOfferEligibilityLoading,
                promo: isPromoOfferEligibilityLoading
            )
        )
        return offerEligibility.visibilityCanChange(
            variesWithEligibility: viewModel.dependsOnOfferEligibility
        ) { intro, promo in
            viewModel.visible(
                state: state,
                condition: condition,
                isEligibleForIntroOffer: intro,
                isEligibleForPromoOffer: promo,
                selectedPackageId: nil,
                customVariables: [:]
            )
        }
    }

    static func makeViewModel(
        overrides: PaywallComponent.ComponentOverrides<PaywallComponent.PartialPackageComponent>? = nil
    ) -> PackageComponentViewModel {
        let uiConfigProvider = UIConfigProvider(uiConfig: PreviewUIConfig.make())
        let package = TestData.monthlyPackage
        let component = PaywallComponent.PackageComponent(
            packageID: package.identifier,
            isSelectedByDefault: false,
            applePromoOfferProductCode: nil,
            stack: .init(components: []),
            overrides: overrides
        )
        return PackageComponentViewModel(
            component: component,
            offering: .init(
                identifier: "test",
                serverDescription: "",
                metadata: [:],
                availablePackages: [package],
                webCheckoutUrl: nil
            ),
            stackViewModel: StackComponentViewModel(
                component: component.stack,
                viewModels: [],
                badgeViewModels: [],
                uiConfigProvider: uiConfigProvider
            ),
            hasPurchaseButton: false,
            uiConfigProvider: uiConfigProvider
        )
    }

}

#endif
