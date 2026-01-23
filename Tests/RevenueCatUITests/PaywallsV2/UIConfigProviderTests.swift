//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  UIConfigProviderTests.swift
//
//  Created by Antonio Pallares on 12/9/25.

import Nimble
import RevenueCat
@testable import RevenueCatUI
import XCTest

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class UIConfigProviderTests: TestCase {

    // MARK: - Localizations

    func testGetLocalizationsForNotFoundLocaleReturnsEmpty() throws {
        let uiConfigProvider = try createUIConfigProvider()

        let localizations = uiConfigProvider.getLocalizations(for: Locale(identifier: "de_DE"))
        XCTAssertTrue(localizations.isEmpty)

        self.logger.verifyMessageWasLogged("Could not find localizations for 'de_DE'")
    }

    func testRepeatedGetLocalizationsForNotFoundLocaleLogsMessageOnlyOnce() throws {
        let uiConfigProvider = try createUIConfigProvider()

        let localizations = uiConfigProvider.getLocalizations(for: Locale(identifier: "de_DE"))
        XCTAssertTrue(localizations.isEmpty)

        _ = uiConfigProvider.getLocalizations(for: Locale(identifier: "de_DE"))
        _ = uiConfigProvider.getLocalizations(for: Locale(identifier: "de_DE"))

        self.logger.verifyMessageWasLogged("Could not find localizations for 'de_DE'",
                                           expectedCount: 1)
    }

    func testGetLocalizationsForFoundLocaleDoesNotLogMessage() throws {
        let uiConfigProvider = try createUIConfigProvider()

        let localizations = uiConfigProvider.getLocalizations(for: Locale(identifier: "en_US"))
        XCTAssertFalse(localizations.isEmpty)

        self.logger.verifyMessageWasNotLogged("Could not find localizations for 'en_US'", allowNoMessages: true)
    }

    func testRepeatedGetLocalizationsForNotFoundLanguageLogsMessageOnlyOncePerNotFoundLocale() throws {
        let uiConfigProvider = try createUIConfigProvider()

        let localizationsDE = uiConfigProvider.getLocalizations(for: Locale(identifier: "de_DE"))
        let localizationsFR = uiConfigProvider.getLocalizations(for: Locale(identifier: "fr_FR"))
        XCTAssertTrue(localizationsDE.isEmpty)
        XCTAssertTrue(localizationsFR.isEmpty)

        _ = uiConfigProvider.getLocalizations(for: Locale(identifier: "de_DE"))
        _ = uiConfigProvider.getLocalizations(for: Locale(identifier: "de_DE"))
        _ = uiConfigProvider.getLocalizations(for: Locale(identifier: "fr_FR"))
        _ = uiConfigProvider.getLocalizations(for: Locale(identifier: "fr_FR"))
        _ = uiConfigProvider.getLocalizations(for: Locale(identifier: "fr_FR"))

        self.logger.verifyMessageWasLogged("Could not find localizations for 'de_DE'",
                                           expectedCount: 1)
        self.logger.verifyMessageWasLogged("Could not find localizations for 'fr_FR'",
                                           expectedCount: 1)
    }

    func testGetLocalizationForNotFoundLocaleLogsOncePerUIConfigProvider() throws {
        let uiConfigProvider = try createUIConfigProvider()

        let localizations = uiConfigProvider.getLocalizations(for: Locale(identifier: "de_DE"))
        XCTAssertTrue(localizations.isEmpty)

        _ = uiConfigProvider.getLocalizations(for: Locale(identifier: "de_DE"))
        _ = uiConfigProvider.getLocalizations(for: Locale(identifier: "de_DE"))

        let uiConfigProvider2 = try createUIConfigProvider()

        let localizations2 = uiConfigProvider.getLocalizations(for: Locale(identifier: "de_DE"))
        XCTAssertTrue(localizations2.isEmpty)

        _ = uiConfigProvider2.getLocalizations(for: Locale(identifier: "de_DE"))
        _ = uiConfigProvider2.getLocalizations(for: Locale(identifier: "de_DE"))

        self.logger.verifyMessageWasLogged("Could not find localizations for 'de_DE'",
                                           expectedCount: 2)
    }

    // MARK: - Fonts

    func testResolveFontReturnsNilIfFontMappingNotFound() throws {
        let uiConfigProvider = try createUIConfigProvider()

        XCTAssertNil(uiConfigProvider.resolveFont(size: 10, name: "unknown_font"))
        self.logger.verifyMessageWasLogged(
            "Mapping for 'unknown_font' could not be found. Falling back to system font.",
            expectedCount: 1
        )
    }

    func testResolveFontReturnsFontIfFontMappingFound() throws {
        let uiConfigProvider = try createUIConfigProvider()

        XCTAssertNotNil(uiConfigProvider.resolveFont(size: 10, name: "primary"))
    }

    func testResolveNotFoundFontMultipleTimesLogsOnlyOnce() throws {
        let uiConfigProvider = try createUIConfigProvider()

        XCTAssertNil(uiConfigProvider.resolveFont(size: 10, name: "unknown_font"))
        XCTAssertNil(uiConfigProvider.resolveFont(size: 10, name: "unknown_font"))
        XCTAssertNil(uiConfigProvider.resolveFont(size: 10, name: "unknown_font"))
        XCTAssertNil(uiConfigProvider.resolveFont(size: 10, name: "unknown_font"))
        XCTAssertNil(uiConfigProvider.resolveFont(size: 10, name: "unknown_font"))

        self.logger.verifyMessageWasLogged(
            "Mapping for 'unknown_font' could not be found. Falling back to system font.",
            expectedCount: 1
        )
    }

    func testResolveFontLogsOnlyOncePerNotFoundFont() throws {
        let uiConfigProvider = try createUIConfigProvider()

        XCTAssertNil(uiConfigProvider.resolveFont(size: 10, name: "unknown_font"))
        XCTAssertNil(uiConfigProvider.resolveFont(size: 10, name: "unknown_font"))
        XCTAssertNil(uiConfigProvider.resolveFont(size: 10, name: "another_unknown_font"))
        XCTAssertNil(uiConfigProvider.resolveFont(size: 10, name: "another_unknown_font"))
        XCTAssertNil(uiConfigProvider.resolveFont(size: 10, name: "another_unknown_font"))
        XCTAssertNil(uiConfigProvider.resolveFont(size: 10, name: "unknown_font"))

        self.logger.verifyMessageWasLogged(
            "Mapping for 'unknown_font' could not be found. Falling back to system font.",
            expectedCount: 1
        )
        self.logger.verifyMessageWasLogged(
            "Mapping for 'another_unknown_font' could not be found. Falling back to system font.",
            expectedCount: 1
        )
    }

    func testResolveFontNotFoundFontLogsOncePerUIConfigProvider() throws {
        let uiConfigProvider = try createUIConfigProvider()
        let uiConfigProvider2 = try createUIConfigProvider()

        XCTAssertNil(uiConfigProvider.resolveFont(size: 10, name: "unknown_font"))
        XCTAssertNil(uiConfigProvider2.resolveFont(size: 10, name: "unknown_font"))
        XCTAssertNil(uiConfigProvider.resolveFont(size: 10, name: "another_unknown_font"))
        XCTAssertNil(uiConfigProvider2.resolveFont(size: 10, name: "another_unknown_font"))

        XCTAssertNil(uiConfigProvider2.resolveFont(size: 10, name: "another_unknown_font"))
        XCTAssertNil(uiConfigProvider.resolveFont(size: 10, name: "unknown_font"))

        self.logger.verifyMessageWasLogged(
            "Mapping for 'unknown_font' could not be found. Falling back to system font.",
            expectedCount: 2
        )
        self.logger.verifyMessageWasLogged(
            "Mapping for 'another_unknown_font' could not be found. Falling back to system font.",
            expectedCount: 2
        )
    }

    func testResolveFontReturnsNilIfCustomFontFailsToLoad() throws {
        let uiConfigProvider = try createUIConfigProvider()

        XCTAssertNil(uiConfigProvider.resolveFont(size: 10, name: "alt"))
        self.logger.verifyMessageWasNotLogged(
            "Mapping for 'another_unknown_font' could not be found. Falling back to system font."
        )
        self.logger.verifyMessageWasLogged(
            "Custom font 'not_installed_font' could not be loaded. Falling back to system font.",
            expectedCount: 1
        )
    }

    func testResolveGoogleFontReturnsNil() throws {
        let uiConfigProvider = try createUIConfigProvider()

        XCTAssertNil(uiConfigProvider.resolveFont(size: 10, name: "a_google_font"))
        self.logger.verifyMessageWasLogged(
            "Google Fonts are not supported on this platform",
            expectedCount: 1
        )
    }

    func testResolveGoogleFontLogsOnlyOnce() throws {
        let uiConfigProvider = try createUIConfigProvider()

        XCTAssertNil(uiConfigProvider.resolveFont(size: 10, name: "a_google_font"))
        XCTAssertNil(uiConfigProvider.resolveFont(size: 10, name: "a_google_font"))
        XCTAssertNil(uiConfigProvider.resolveFont(size: 10, name: "a_google_font"))
        XCTAssertNil(uiConfigProvider.resolveFont(size: 10, name: "a_google_font"))

        self.logger.verifyMessageWasLogged(
            "Google Fonts are not supported on this platform",
            expectedCount: 1
        )
    }

    func testResolveFontLogsOnlyOncePerFailedFont() throws {
        let uiConfigProvider = try createUIConfigProvider()

        XCTAssertNil(uiConfigProvider.resolveFont(size: 100, name: "unknown_font"))
        XCTAssertNil(uiConfigProvider.resolveFont(size: 10, name: "alt"))
        XCTAssertNil(uiConfigProvider.resolveFont(size: 100, name: "unknown_font"))
        XCTAssertNil(uiConfigProvider.resolveFont(size: 10, name: "alt"))
        XCTAssertNil(uiConfigProvider.resolveFont(size: 100, name: "unknown_font"))
        XCTAssertNil(uiConfigProvider.resolveFont(size: 10, name: "alt"))

        self.logger.verifyMessageWasLogged(
            "Mapping for 'unknown_font' could not be found. Falling back to system font.",
            expectedCount: 1
        )
        self.logger.verifyMessageWasLogged(
            "Custom font 'not_installed_font' could not be loaded. Falling back to system font.",
            expectedCount: 1
        )
    }

    // MARK: - Utils

    private func createUIConfigProvider() throws -> UIConfigProvider {
        return try UIConfigProvider(uiConfig: Self.mockUIConfig)
    }

    private let googleFontName = "google_fonts"

    private static var mockUIConfig: UIConfig {
        get throws {
            let json = """
        {
          "app": {
            "colors": {
                  "primary": {
                    "light": {
                      "type": "hex",
                      "value": "#ffcc00"
                    }
                  },
                },
            "fonts": {
              "primary": {
                "ios": {
                  "type": "name",
                  "value": "Helvetica"
                }
              },
              "alt": {
                "ios": {
                  "type": "name",
                  "value": "not_installed_font"
                }
              },
              "a_google_font": {
                "ios": {
                  "type": "google_fonts",
                  "value": "Google_font_name"
                }
              }
            }
          },
          "localizations": {
            "en_US": {
              "monthly": "monthly"
            },
            "es_ES": {
              "monthly": "mensual"
            }
          },
          "variable_config": {
            "variable_compatibility_map": {
              "new var": "guaranteed var"
            },
            "function_compatibility_map": {
              "new fun": "guaranteed fun"
            }
          }
        }
        """
            let jsonData = try XCTUnwrap(json.data(using: .utf8))
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(UIConfig.self, from: jsonData)
        }
    }
}

#endif
