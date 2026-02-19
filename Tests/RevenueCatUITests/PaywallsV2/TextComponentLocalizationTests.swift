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
import RevenueCat
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

}

#endif
