//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ButtonComponentAccessibilityLabelTests.swift
//
//  Created by Facundo Menzella on 8/4/26.

import Nimble
@_spi(Internal) @testable import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

/// Covers which label is derived, not whether VoiceOver announces it: SwiftUI builds no
/// accessibility tree under XCTest, so that part needs VoiceOver or Maestro.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class ButtonComponentAccessibilityLabelTests: TestCase {

    private static let locale = Locale(identifier: "en_US")

    // MARK: - Labels derived from the action

    func testIconOnlyNavigateBackDerivesCloseLabel() throws {
        let viewModel = try Self.makeIconOnlyButton(action: #"{ "type": "navigate_back" }"#)

        XCTAssertEqual(viewModel.derivedAccessibilityLabel, "Close")
    }

    func testIconOnlyCloseWorkflowDerivesCloseLabel() throws {
        let viewModel = try Self.makeIconOnlyButton(action: #"{ "type": "close_workflow" }"#)

        XCTAssertEqual(viewModel.derivedAccessibilityLabel, "Close")
    }

    func testIconOnlyRestorePurchasesDerivesRestoreLabel() throws {
        let viewModel = try Self.makeIconOnlyButton(action: #"{ "type": "restore_purchases" }"#)

        XCTAssertEqual(viewModel.derivedAccessibilityLabel, "Restore purchases")
    }

    func testIconOnlyPrivacyPolicyDerivesPrivacyPolicyLabel() throws {
        let viewModel = try Self.makeIconOnlyButton(action: Self.navigateTo(destination: "privacy_policy"))

        XCTAssertEqual(viewModel.derivedAccessibilityLabel, "Privacy policy")
    }

    func testIconOnlyTermsDerivesTermsLabel() throws {
        let viewModel = try Self.makeIconOnlyButton(action: Self.navigateTo(destination: "terms"))

        XCTAssertEqual(viewModel.derivedAccessibilityLabel, "Terms and conditions")
    }

    func testIconOnlyCustomerCenterDerivesManageSubscriptionLabel() throws {
        let viewModel = try Self.makeIconOnlyButton(
            action: #"{ "type": "navigate_to", "destination": "customer_center" }"#
        )

        XCTAssertEqual(viewModel.derivedAccessibilityLabel, "Manage subscription")
    }

    func testIconOnlyOfferCodeDerivesRedeemCodeLabel() throws {
        let viewModel = try Self.makeIconOnlyButton(action: #"{ "type": "navigate_to", "destination": "offer_code" }"#)

        XCTAssertEqual(viewModel.derivedAccessibilityLabel, "Redeem code")
    }

    // MARK: - Actions with no honest label

    func testIconOnlyArbitraryURLDerivesNoLabel() throws {
        let viewModel = try Self.makeIconOnlyButton(action: Self.navigateTo(destination: "url"))

        XCTAssertNil(viewModel.derivedAccessibilityLabel)
    }

    func testIconOnlyWorkflowTriggerDerivesNoLabel() throws {
        let viewModel = try Self.makeIconOnlyButton(action: #"{ "type": "workflow" }"#)

        XCTAssertNil(viewModel.derivedAccessibilityLabel)
    }

    // MARK: - The fallback never overrides a label that already works

    func testButtonWithTextDerivesNoLabel() throws {
        let viewModel = try Self.makeButton(
            action: #"{ "type": "navigate_back" }"#,
            children: [.text(try Self.makeTextViewModel())]
        )

        XCTAssertNil(viewModel.derivedAccessibilityLabel)
    }

    func testButtonWithTextNestedInStackDerivesNoLabel() throws {
        let nested = Self.makeStackViewModel(children: [.text(try Self.makeTextViewModel())])

        let viewModel = try Self.makeButton(
            action: #"{ "type": "navigate_back" }"#,
            children: [.stack(nested)]
        )

        XCTAssertNil(viewModel.derivedAccessibilityLabel)
    }

    /// Badges live in a separate array from the stack's children and render text of their own.
    func testButtonWithTextOnlyInABadgeDerivesNoLabel() throws {
        let viewModel = try Self.makeButton(
            action: #"{ "type": "navigate_back" }"#,
            children: [.icon(Self.makeIconViewModel())],
            badges: [.text(try Self.makeTextViewModel())]
        )

        XCTAssertNil(viewModel.derivedAccessibilityLabel)
    }

    /// A text component whose localization is missing renders nothing, so it must not count as
    /// content a screen reader can announce.
    func testButtonWithEmptyTextDerivesCloseLabel() throws {
        let viewModel = try Self.makeButton(
            action: #"{ "type": "navigate_back" }"#,
            children: [.text(try Self.makeTextViewModel(lid: "missing_lid"))]
        )

        XCTAssertEqual(viewModel.derivedAccessibilityLabel, "Close")
    }

    // MARK: - Catalog

    /// Guards against a derived label silently falling back to its raw key because the string
    /// was never added to `Localizable.strings`.
    func testEveryDerivedLabelKeyExistsInTheLocalizationCatalog() throws {
        let bundle = Localization.localizedBundle(Self.locale)

        for key in ["Close", "Restore purchases", "Privacy policy",
                    "Terms and conditions", "Manage subscription", "Redeem code"] {
            XCTAssertNotEqual(
                bundle.localizedString(forKey: key, value: "__missing__", table: nil),
                "__missing__",
                "Missing \"\(key)\" in Localizable.strings"
            )
        }
    }

    /// The new keys only ship English for now. An untranslated locale must still announce
    /// something, so it falls back to the key itself rather than to an empty label.
    func testUntranslatedLocaleFallsBackToTheEnglishLabel() throws {
        let viewModel = try Self.makeIconOnlyButton(
            action: #"{ "type": "navigate_back" }"#,
            locale: Locale(identifier: "ja_JP")
        )

        XCTAssertEqual(viewModel.derivedAccessibilityLabel, "Close")
    }

    // MARK: - Helpers

    private static func navigateTo(destination: String) -> String {
        return """
        {
            "type": "navigate_to",
            "destination": "\(destination)",
            "url": { "url_lid": "url_lid", "method": "in_app_browser" }
        }
        """
    }

    private static func makeIconOnlyButton(
        action: String,
        locale: Locale = ButtonComponentAccessibilityLabelTests.locale
    ) throws -> ButtonComponentViewModel {
        return try self.makeButton(
            action: action,
            children: [.icon(self.makeIconViewModel())],
            locale: locale
        )
    }

    private static func makeButton(
        action: String,
        children: [PaywallComponentViewModel],
        badges: [PaywallComponentViewModel] = [],
        locale: Locale = ButtonComponentAccessibilityLabelTests.locale
    ) throws -> ButtonComponentViewModel {
        let json = """
        {
            "type": "button",
            "action": \(action),
            "stack": {
                "type": "stack",
                "dimension": {"type": "vertical", "alignment": "center", "distribution": "start"},
                "size": {"width": {"type": "fit"}, "height": {"type": "fit"}},
                "padding": {"top": 0, "bottom": 0, "leading": 0, "trailing": 0},
                "margin": {"top": 0, "bottom": 0, "leading": 0, "trailing": 0},
                "components": []
            }
        }
        """
        let component = try JSONDecoder.default.decode(
            PaywallComponent.ButtonComponent.self,
            from: json.data(using: .utf8)!
        )

        return try ButtonComponentViewModel(
            component: component,
            localizationProvider: self.makeLocalizationProvider(locale: locale),
            offering: .init(
                identifier: "test",
                serverDescription: "",
                metadata: [:],
                availablePackages: [],
                webCheckoutUrl: nil
            ),
            stackViewModel: self.makeStackViewModel(children: children, badges: badges),
            uiConfigProvider: self.uiConfigProvider
        )
    }

    private static func makeStackViewModel(
        children: [PaywallComponentViewModel],
        badges: [PaywallComponentViewModel] = []
    ) -> StackComponentViewModel {
        return StackComponentViewModel(
            component: .init(components: []),
            viewModels: children,
            badgeViewModels: badges,
            uiConfigProvider: self.uiConfigProvider
        )
    }

    private static func makeTextViewModel(lid: String = "text_lid") throws -> TextComponentViewModel {
        return try TextComponentViewModel(
            localizationProvider: self.localizationProvider,
            uiConfigProvider: self.uiConfigProvider,
            component: .init(text: lid, color: .init(light: .hex("#000000")))
        )
    }

    private static func makeIconViewModel() -> IconComponentViewModel {
        return IconComponentViewModel(
            localizationProvider: self.localizationProvider,
            uiConfigProvider: self.uiConfigProvider,
            component: .init(
                baseUrl: "https://icons.pawwalls.com/icons",
                iconName: "x",
                formats: .init(svg: "x.svg", png: "x.png", heic: "x.heic", webp: "x.webp"),
                size: .init(width: .fixed(24), height: .fixed(24)),
                padding: .zero,
                margin: .zero,
                color: .init(light: .hex("#000000")),
                iconBackground: nil
            )
        )
    }

    private static let uiConfigProvider = UIConfigProvider(uiConfig: PreviewUIConfig.make())

    private static var localizationProvider: LocalizationProvider {
        return self.makeLocalizationProvider(locale: ButtonComponentAccessibilityLabelTests.locale)
    }

    private static func makeLocalizationProvider(locale: Locale) -> LocalizationProvider {
        return LocalizationProvider(
            locale: locale,
            localizedStrings: [
                "text_lid": .string("Continue"),
                "url_lid": .string("https://revenuecat.com")
            ]
        )
    }

}

#endif
