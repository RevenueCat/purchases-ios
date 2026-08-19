//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TextComponentLocalizationTests.swift
//
//  Created by Facundo Menzella on 2/16/26.

import Nimble
@_spi(Internal) import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TextComponentLocalizationTests: TestCase {

    // MARK: - Missing Localization Tests

    /// When a text_lid has no localization entry, the view model should not throw
    /// and should use an empty string as fallback.
    @MainActor
    func testMissingLocalization_ReturnsEmptyStringInsteadOfThrowing() throws {
        // Given: A text component with a text_lid that has no localization
        let textComponent = PaywallComponent.TextComponent(
            text: "orphan_text_lid", // Not in localizations
            color: Self.black
        )

        let localizations: PaywallComponent.LocalizationDictionary = [:] // Empty

        // When: Creating TextComponentViewModel should NOT throw
        let viewModel = try TextComponentViewModel(
            localizationProvider: LocalizationProvider(
                locale: .current,
                localizedStrings: localizations
            ),
            uiConfigProvider: try Self.createUIConfigProvider(),
            component: textComponent
        )

        // Then: The text should be an empty string
        var capturedText: String?
        _ = viewModel.styles(
            state: .default,
            condition: .compact,
            selectedPackageId: nil,
            packageContext: PackageContext(package: nil, variableContext: .init()),
            isEligibleForIntroOffer: false,
            promoOffer: nil
        ) { style -> EmptyView in
            capturedText = style.text
            return EmptyView()
        }
        expect(capturedText).to(equal(""))

        // Verify warning was logged
        self.logger.verifyMessageWasLogged(
            "Missing localization for text_lid 'orphan_text_lid', using empty string."
        )
    }

    /// When a text_lid has a valid localization entry, it should be used.
    @MainActor
    func testValidLocalization_DoesNotLogWarning() throws {
        // Given: A text component with a valid localization
        let textComponent = PaywallComponent.TextComponent(
            text: "valid_text_lid",
            color: Self.black
        )

        let localizations: PaywallComponent.LocalizationDictionary = [
            "valid_text_lid": .string("Hello World")
        ]

        // When: Creating TextComponentViewModel
        _ = try TextComponentViewModel(
            localizationProvider: LocalizationProvider(
                locale: .current,
                localizedStrings: localizations
            ),
            uiConfigProvider: try Self.createUIConfigProvider(),
            component: textComponent
        )

        // Then: No warning should be logged
        self.logger.verifyMessageWasNotLogged(
            "Missing localization for text_lid",
            allowNoMessages: true
        )
    }

    /// When base text_lid is missing but override has a valid one,
    /// the view model should be created without throwing.
    /// The empty base string won't be visible because the badge only renders
    /// when the override condition is active.
    @MainActor
    func testMissingBaseLocalization_WithValidOverride_DoesNotThrow() throws {
        // Given: A text component where base text_lid is missing but override has valid one
        let textComponent = PaywallComponent.TextComponent(
            text: "orphan_base_lid", // Missing
            color: Self.black,
            overrides: [
                .init(conditions: [.selected], properties: .init(
                    text: "valid_override_lid" // Valid
                ))
            ]
        )

        let localizations: PaywallComponent.LocalizationDictionary = [
            "valid_override_lid": .string("Selected Text")
            // "orphan_base_lid" intentionally missing
        ]

        // When/Then: Creating TextComponentViewModel should NOT throw
        expect {
            try TextComponentViewModel(
                localizationProvider: LocalizationProvider(
                    locale: .current,
                    localizedStrings: localizations
                ),
                uiConfigProvider: try Self.createUIConfigProvider(),
                component: textComponent
            )
        }.toNot(throwError())

        // Verify warning was logged for the missing base localization
        self.logger.verifyMessageWasLogged(
            "Missing localization for text_lid 'orphan_base_lid', using empty string."
        )
    }

    /// Multiple text components with missing localizations should each log a warning.
    @MainActor
    func testMultipleMissingLocalizations_LogsWarningForEach() throws {
        // Given: Multiple text components with missing localizations
        let localizations: PaywallComponent.LocalizationDictionary = [:]

        // When: Creating multiple TextComponentViewModels
        _ = try? TextComponentViewModel(
            localizationProvider: LocalizationProvider(
                locale: .current,
                localizedStrings: localizations
            ),
            uiConfigProvider: try Self.createUIConfigProvider(),
            component: PaywallComponent.TextComponent(
                text: "missing_lid_1",
                color: Self.black
            )
        )

        _ = try? TextComponentViewModel(
            localizationProvider: LocalizationProvider(
                locale: .current,
                localizedStrings: localizations
            ),
            uiConfigProvider: try Self.createUIConfigProvider(),
            component: PaywallComponent.TextComponent(
                text: "missing_lid_2",
                color: Self.black
            )
        )

        // Then: Both warnings should be logged
        self.logger.verifyMessageWasLogged(
            "Missing localization for text_lid 'missing_lid_1', using empty string."
        )
        self.logger.verifyMessageWasLogged(
            "Missing localization for text_lid 'missing_lid_2', using empty string."
        )
    }

    // MARK: - Selected Package Condition Wiring Tests

    @MainActor
    func testSelectedPackageConditionUsesGlobalSelectedPackageIdInsidePackageScope() throws {
        let viewModel = try self.makeConditionalVisibilityViewModel()
        let packageContext = PackageContext(
            package: TestData.annualPackage,
            variableContext: .init(packages: [TestData.monthlyPackage, TestData.annualPackage])
        )

        var capturedVisible: Bool?
        _ = viewModel.styles(
            state: .default,
            condition: .compact,
            selectedPackageId: TestData.monthlyPackage.identifier,
            packageContext: packageContext,
            isEligibleForIntroOffer: false,
            promoOffer: nil
        ) { style -> EmptyView in
            capturedVisible = style.visible
            return EmptyView()
        }

        expect(capturedVisible).to(beFalse())
    }

    @MainActor
    func testSelectedPackageConditionMatchesGlobalSelectionEvenIfParentPackageDiffers() throws {
        let viewModel = try self.makeConditionalVisibilityViewModel()
        let packageContext = PackageContext(
            package: TestData.monthlyPackage,
            variableContext: .init(packages: [TestData.monthlyPackage, TestData.annualPackage])
        )

        var capturedVisible: Bool?
        _ = viewModel.styles(
            state: .default,
            condition: .compact,
            selectedPackageId: TestData.annualPackage.identifier,
            packageContext: packageContext,
            isEligibleForIntroOffer: false,
            promoOffer: nil
        ) { style -> EmptyView in
            capturedVisible = style.visible
            return EmptyView()
        }

        expect(capturedVisible).to(beTrue())
    }

    @MainActor
    func testSelectedPackageConditionDoesNotMatchWhenGlobalSelectionIsNil() throws {
        let viewModel = try self.makeConditionalVisibilityViewModel()
        let packageContext = PackageContext(
            package: TestData.annualPackage,
            variableContext: .init(packages: [TestData.monthlyPackage, TestData.annualPackage])
        )

        var capturedVisible: Bool?
        _ = viewModel.styles(
            state: .default,
            condition: .compact,
            selectedPackageId: nil,
            packageContext: packageContext,
            isEligibleForIntroOffer: false,
            promoOffer: nil
        ) { style -> EmptyView in
            capturedVisible = style.visible
            return EmptyView()
        }

        expect(capturedVisible).to(beFalse())
    }

    @MainActor
    func testVariableProcessingUsesPackageContextPackageNotSelectedPackage() throws {
        let textComponent = PaywallComponent.TextComponent(
            text: "price_text",
            color: Self.black
        )
        let localizations: PaywallComponent.LocalizationDictionary = [
            "price_text": .string("{{ product.price }}")
        ]

        let viewModel = try TextComponentViewModel(
            localizationProvider: LocalizationProvider(locale: .current, localizedStrings: localizations),
            uiConfigProvider: try Self.createUIConfigProvider(),
            component: textComponent
        )
        let packageContext = PackageContext(
            package: TestData.annualPackage,
            variableContext: .init(packages: [TestData.monthlyPackage, TestData.annualPackage])
        )

        var capturedText: String?
        _ = viewModel.styles(
            state: .default,
            condition: .compact,
            selectedPackageId: TestData.monthlyPackage.identifier,
            packageContext: packageContext,
            isEligibleForIntroOffer: false,
            promoOffer: nil
        ) { style -> EmptyView in
            capturedText = style.text
            return EmptyView()
        }

        expect(capturedText).to(equal(TestData.annualPackage.localizedPriceString))
    }

    @MainActor
    func testSelectedPackageNotInConditionUsesGlobalSelectedPackageIdInsidePackageScope() throws {
        let textComponent = PaywallComponent.TextComponent(
            visible: false,
            text: "badge_text",
            color: Self.black,
            overrides: [
                .init(
                    extendedConditions: [.selectedPackage(
                        operator: .notIn,
                        packages: [TestData.annualPackage.identifier]
                    )],
                    properties: .init(visible: true)
                )
            ]
        )
        let localizations: PaywallComponent.LocalizationDictionary = [
            "badge_text": .string("Most popular!")
        ]
        let viewModel = try TextComponentViewModel(
            localizationProvider: LocalizationProvider(locale: .current, localizedStrings: localizations),
            uiConfigProvider: try Self.createUIConfigProvider(),
            component: textComponent
        )
        let packageContext = PackageContext(
            package: TestData.annualPackage,
            variableContext: .init(packages: [TestData.monthlyPackage, TestData.annualPackage])
        )

        var capturedVisible: Bool?
        _ = viewModel.styles(
            state: .default,
            condition: .compact,
            selectedPackageId: TestData.monthlyPackage.identifier,
            packageContext: packageContext,
            isEligibleForIntroOffer: false,
            promoOffer: nil
        ) { style -> EmptyView in
            capturedVisible = style.visible
            return EmptyView()
        }

        expect(capturedVisible).to(beTrue())
    }

    @MainActor
    func testStackSelectedPackageConditionUsesGlobalSelectedPackageId() throws {
        let stackComponent = PaywallComponent.StackComponent(
            visible: false,
            components: [],
            overrides: [
                .init(
                    extendedConditions: [.selectedPackage(
                        operator: .in,
                        packages: [TestData.annualPackage.identifier]
                    )],
                    properties: .init(visible: true)
                )
            ]
        )

        let viewModel = StackComponentViewModel(
            component: stackComponent,
            viewModels: [],
            badgeViewModels: [],
            uiConfigProvider: try Self.createUIConfigProvider()
        )

        let style = viewModel.styles(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            selectedPackageId: TestData.annualPackage.identifier,
            customVariables: [:],
            colorScheme: .light
        )

        expect(style.visible).to(beTrue())
    }

    // MARK: - Intro offer hidden by optimistic promo offer (StackComponentViewModel integration)
    //
    // Mirrors a real paywall layout where two stacks sit in a .zlayer container:
    //   - introPriceStack: visible only when `intro_offer` condition is met
    //   - promoPriceStack: visible only when `selected + promo_offer` conditions are both met
    //
    // Because the later sibling draws on top in a .zlayer, if promoPriceStack becomes visible
    // prematurely (before the offer is signed), it covers introPriceStack — hiding the intro
    // price display even though intro eligibility is already resolved.
    //
    // The fix: component views pass `isSignedEligible` (true only when signed) instead of
    // `isMostLikelyEligible` (true as soon as subscription history is known). These tests
    // drive `StackComponentViewModel.styles()` directly with the two possible boolean values
    // to verify that visibility is gated on actual signing, not optimistic eligibility.

    @MainActor
    func testIntroStackVisible_PromoStackHidden_WhenPromoNotYetSigned() throws {
        // After intro eligibility resolves but before promo signing completes,
        // `isSignedEligible` returns false. introPriceStack must be visible;
        // promoPriceStack must remain hidden so it cannot cover the intro display.
        let (introPriceStack, promoPriceStack) = try self.makeZLayeredPriceStacks()

        let introVisible = self.captureVisibility(
            from: introPriceStack,
            isEligibleForIntroOffer: true,
            isEligibleForPromoOffer: false  // isSignedEligible == false before signing
        )
        let promoVisible = self.captureVisibility(
            from: promoPriceStack,
            isEligibleForIntroOffer: true,
            isEligibleForPromoOffer: false
        )

        expect(introVisible).to(beTrue())
        expect(promoVisible).to(beFalse())
    }

    @MainActor
    func testPromoStackBecomesVisible_WhenOptimisticEligibility_BugRepro() throws {
        // BUG: `isMostLikelyEligible` returns true as soon as subscription history is known,
        // before signing completes. This makes promoPriceStack visible prematurely, covering
        // introPriceStack in the .zlayer and hiding the intro price display.
        let (introPriceStack, promoPriceStack) = try self.makeZLayeredPriceStacks()

        let introVisible = self.captureVisibility(
            from: introPriceStack,
            isEligibleForIntroOffer: true,
            isEligibleForPromoOffer: true  // isMostLikelyEligible == true (optimistic, not yet signed)
        )
        let promoVisible = self.captureVisibility(
            from: promoPriceStack,
            isEligibleForIntroOffer: true,
            isEligibleForPromoOffer: true
        )

        // Both become visible — promoPriceStack now draws on top of introPriceStack in
        // .zlayer, hiding the intro price. This is the broken state the fix prevents.
        expect(introVisible).to(beTrue())
        expect(promoVisible).to(beTrue())
    }

    @MainActor
    func testBothStacksVisible_WhenPromoActuallySigned() throws {
        // When `isSignedEligible` returns true (offer is signed), promoPriceStack correctly
        // becomes visible and draws on top of introPriceStack — intended behavior.
        let (introPriceStack, promoPriceStack) = try self.makeZLayeredPriceStacks()

        let introVisible = self.captureVisibility(
            from: introPriceStack,
            isEligibleForIntroOffer: true,
            isEligibleForPromoOffer: true  // isSignedEligible == true after signing
        )
        let promoVisible = self.captureVisibility(
            from: promoPriceStack,
            isEligibleForIntroOffer: true,
            isEligibleForPromoOffer: true
        )

        expect(introVisible).to(beTrue())
        expect(promoVisible).to(beTrue())
    }

    // MARK: - Helpers

    private static let black = PaywallComponent.ColorScheme(
        light: .hex("#000000")
    )

    private static func createUIConfigProvider() throws -> UIConfigProvider {
        let json = """
        {
          "app": {
            "colors": {},
            "fonts": {}
          },
          "localizations": {},
          "variable_config": {
            "variable_compatibility_map": {},
            "function_compatibility_map": {}
          }
        }
        """
        let jsonData = try XCTUnwrap(json.data(using: .utf8))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let uiConfig = try decoder.decode(UIConfig.self, from: jsonData)
        return UIConfigProvider(uiConfig: uiConfig)
    }

    private func makeConditionalVisibilityViewModel() throws -> TextComponentViewModel {
        let textComponent = PaywallComponent.TextComponent(
            visible: false,
            text: "badge_text",
            color: Self.black,
            overrides: [
                .init(
                    extendedConditions: [
                        .selectedPackage(operator: .in, packages: [TestData.annualPackage.identifier])
                    ],
                    properties: .init(visible: true)
                )
            ]
        )
        let localizations: PaywallComponent.LocalizationDictionary = [
            "badge_text": .string("Most popular!")
        ]

        return try TextComponentViewModel(
            localizationProvider: LocalizationProvider(locale: .current, localizedStrings: localizations),
            uiConfigProvider: try Self.createUIConfigProvider(),
            component: textComponent
        )
    }

    /// Returns an (introPriceStack, promoPriceStack) pair that mirrors the Logia paywall
    /// z-layer layout:
    ///   - introPriceStack: hidden by default, shown when `intro_offer` condition matches
    ///   - promoPriceStack: hidden by default, shown when `selected + promo_offer` both match
    private func makeZLayeredPriceStacks() throws -> (intro: StackComponentViewModel,
                                                      promo: StackComponentViewModel) {
        let intro = StackComponentViewModel(
            component: PaywallComponent.StackComponent(
                visible: false,
                components: [],
                dimension: .zlayer(.center),
                overrides: [
                    .init(extendedConditions: [.introOffer], properties: .init(visible: true))
                ]
            ),
            viewModels: [],
            badgeViewModels: [],
            uiConfigProvider: try Self.createUIConfigProvider()
        )
        let promo = StackComponentViewModel(
            component: PaywallComponent.StackComponent(
                visible: false,
                components: [],
                dimension: .zlayer(.center),
                overrides: [
                    .init(extendedConditions: [.selected, .promoOffer], properties: .init(visible: true))
                ]
            ),
            viewModels: [],
            badgeViewModels: [],
            uiConfigProvider: try Self.createUIConfigProvider()
        )
        return (intro, promo)
    }

    private func captureVisibility(
        from viewModel: StackComponentViewModel,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool
    ) -> Bool {
        let style = viewModel.styles(
            state: .selected,
            condition: .compact,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            selectedPackageId: nil,
            customVariables: [:],
            colorScheme: .light
        )

        return style.visible
    }

}

#endif
