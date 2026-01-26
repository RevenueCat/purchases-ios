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

    // MARK: - Custom Variables

    func testDefaultCustomVariablesReturnsEmptyWhenNoCustomVariables() throws {
        let uiConfigProvider = try createUIConfigProvider()

        XCTAssertTrue(uiConfigProvider.defaultCustomVariables.isEmpty)
    }

    func testDefaultCustomVariablesParseStringType() throws {
        let uiConfigProvider = try createUIConfigProviderWithCustomVariables([
            "player_name": UIConfig.CustomVariableDefinition(type: "string", defaultValue: "Player")
        ])

        let customVars = uiConfigProvider.defaultCustomVariables
        XCTAssertEqual(customVars["player_name"], .string("Player"))
    }

    func testDefaultCustomVariablesParseNumberType() throws {
        let uiConfigProvider = try createUIConfigProviderWithCustomVariables([
            "max_health": UIConfig.CustomVariableDefinition(type: "number", defaultValue: "100")
        ])

        let customVars = uiConfigProvider.defaultCustomVariables
        XCTAssertEqual(customVars["max_health"], .number(100.0))
    }

    func testDefaultCustomVariablesParseNumberTypeWithDecimals() throws {
        let uiConfigProvider = try createUIConfigProviderWithCustomVariables([
            "multiplier": UIConfig.CustomVariableDefinition(type: "number", defaultValue: "1.5")
        ])

        let customVars = uiConfigProvider.defaultCustomVariables
        XCTAssertEqual(customVars["multiplier"], .number(1.5))
    }

    func testDefaultCustomVariablesParseIntegerTypeAsNumber() throws {
        // Backend sends "number" but we also support "integer" for compatibility
        let uiConfigProvider = try createUIConfigProviderWithCustomVariables([
            "level": UIConfig.CustomVariableDefinition(type: "integer", defaultValue: "42")
        ])

        let customVars = uiConfigProvider.defaultCustomVariables
        XCTAssertEqual(customVars["level"], .number(42.0))
    }

    func testDefaultCustomVariablesParseBooleanTypeTrue() throws {
        let uiConfigProvider = try createUIConfigProviderWithCustomVariables([
            "is_premium": UIConfig.CustomVariableDefinition(type: "boolean", defaultValue: "true")
        ])

        let customVars = uiConfigProvider.defaultCustomVariables
        XCTAssertEqual(customVars["is_premium"], .bool(true))
    }

    func testDefaultCustomVariablesParseBooleanTypeFalse() throws {
        let uiConfigProvider = try createUIConfigProviderWithCustomVariables([
            "is_premium": UIConfig.CustomVariableDefinition(type: "boolean", defaultValue: "false")
        ])

        let customVars = uiConfigProvider.defaultCustomVariables
        XCTAssertEqual(customVars["is_premium"], .bool(false))
    }

    func testDefaultCustomVariablesParseMultipleTypes() throws {
        let uiConfigProvider = try createUIConfigProviderWithCustomVariables([
            "player_name": UIConfig.CustomVariableDefinition(type: "string", defaultValue: "Player"),
            "max_health": UIConfig.CustomVariableDefinition(type: "number", defaultValue: "100"),
            "is_premium": UIConfig.CustomVariableDefinition(type: "boolean", defaultValue: "true")
        ])

        let customVars = uiConfigProvider.defaultCustomVariables
        XCTAssertEqual(customVars["player_name"], .string("Player"))
        XCTAssertEqual(customVars["max_health"], .number(100.0))
        XCTAssertEqual(customVars["is_premium"], .bool(true))
    }

    func testDefaultCustomVariablesInvalidNumberFallsBackToString() throws {
        let uiConfigProvider = try createUIConfigProviderWithCustomVariables([
            "bad_number": UIConfig.CustomVariableDefinition(type: "number", defaultValue: "not_a_number")
        ])

        let customVars = uiConfigProvider.defaultCustomVariables
        XCTAssertEqual(customVars["bad_number"], .string("not_a_number"))

        self.logger.verifyMessageWasLogged(
            "Custom variable default value 'not_a_number' could not be parsed as a number"
        )
    }

    func testDefaultCustomVariablesUnknownTypeFallsBackToString() throws {
        let uiConfigProvider = try createUIConfigProviderWithCustomVariables([
            "unknown": UIConfig.CustomVariableDefinition(type: "unknown_type", defaultValue: "some_value")
        ])

        let customVars = uiConfigProvider.defaultCustomVariables
        XCTAssertEqual(customVars["unknown"], .string("some_value"))

        self.logger.verifyMessageWasLogged(
            "Unknown custom variable type 'unknown_type'"
        )
    }

    func testDefaultCustomVariablesEmptyStringValue() throws {
        let uiConfigProvider = try createUIConfigProviderWithCustomVariables([
            "empty_string": UIConfig.CustomVariableDefinition(type: "string", defaultValue: "")
        ])

        let customVars = uiConfigProvider.defaultCustomVariables
        XCTAssertEqual(customVars["empty_string"], .string(""))
    }

    func testDefaultCustomVariablesEmptyNumberFallsBackToString() throws {
        let uiConfigProvider = try createUIConfigProviderWithCustomVariables([
            "empty_number": UIConfig.CustomVariableDefinition(type: "number", defaultValue: "")
        ])

        let customVars = uiConfigProvider.defaultCustomVariables
        // Empty string can't be parsed as number, falls back to string
        XCTAssertEqual(customVars["empty_number"], .string(""))

        self.logger.verifyMessageWasLogged(
            "Custom variable default value '' could not be parsed as a number"
        )
    }

    func testDefaultCustomVariablesBooleanWithNonStandardValue() throws {
        // Backend enforces "true"/"false" but our parser is lenient
        let uiConfigProvider = try createUIConfigProviderWithCustomVariables([
            "bool_yes": UIConfig.CustomVariableDefinition(type: "boolean", defaultValue: "yes"),
            "bool_1": UIConfig.CustomVariableDefinition(type: "boolean", defaultValue: "1"),
            "bool_random": UIConfig.CustomVariableDefinition(type: "boolean", defaultValue: "random")
        ])

        let customVars = uiConfigProvider.defaultCustomVariables
        XCTAssertEqual(customVars["bool_yes"], .bool(true))
        XCTAssertEqual(customVars["bool_1"], .bool(true))
        XCTAssertEqual(customVars["bool_random"], .bool(false)) // Non-truthy string = false
    }

    func testDefaultCustomVariablesTypeIsCaseInsensitive() throws {
        let uiConfigProvider = try createUIConfigProviderWithCustomVariables([
            "upper_string": UIConfig.CustomVariableDefinition(type: "STRING", defaultValue: "test"),
            "upper_number": UIConfig.CustomVariableDefinition(type: "NUMBER", defaultValue: "42"),
            "upper_bool": UIConfig.CustomVariableDefinition(type: "BOOLEAN", defaultValue: "true")
        ])

        let customVars = uiConfigProvider.defaultCustomVariables
        XCTAssertEqual(customVars["upper_string"], .string("test"))
        XCTAssertEqual(customVars["upper_number"], .number(42.0))
        XCTAssertEqual(customVars["upper_bool"], .bool(true))
    }

    func testDefaultCustomVariablesArrayTypeIsUnsupported() throws {
        let uiConfigProvider = try createUIConfigProviderWithCustomVariables([
            "array_var": UIConfig.CustomVariableDefinition(type: "array", defaultValue: "[1,2,3]")
        ])

        let customVars = uiConfigProvider.defaultCustomVariables
        // Unsupported type falls back to string
        XCTAssertEqual(customVars["array_var"], .string("[1,2,3]"))

        self.logger.verifyMessageWasLogged(
            "Unknown custom variable type 'array'"
        )
    }

    func testDefaultCustomVariablesObjectTypeIsUnsupported() throws {
        let uiConfigProvider = try createUIConfigProviderWithCustomVariables([
            "object_var": UIConfig.CustomVariableDefinition(type: "object", defaultValue: "{\"key\":\"value\"}")
        ])

        let customVars = uiConfigProvider.defaultCustomVariables
        // Unsupported type falls back to string
        XCTAssertEqual(customVars["object_var"], .string("{\"key\":\"value\"}"))

        self.logger.verifyMessageWasLogged(
            "Unknown custom variable type 'object'"
        )
    }

    func testDefaultCustomVariablesNullTypeIsUnsupported() throws {
        let uiConfigProvider = try createUIConfigProviderWithCustomVariables([
            "null_var": UIConfig.CustomVariableDefinition(type: "null", defaultValue: "null")
        ])

        let customVars = uiConfigProvider.defaultCustomVariables
        // Unsupported type falls back to string
        XCTAssertEqual(customVars["null_var"], .string("null"))

        self.logger.verifyMessageWasLogged(
            "Unknown custom variable type 'null'"
        )
    }

    // MARK: - Utils

    private func createUIConfigProvider() throws -> UIConfigProvider {
        return try UIConfigProvider(uiConfig: Self.mockUIConfig)
    }

    private func createUIConfigProviderWithCustomVariables(
        _ customVariables: [String: UIConfig.CustomVariableDefinition]
    ) throws -> UIConfigProvider {
        var uiConfig = try Self.mockUIConfig
        uiConfig.customVariables = customVariables
        return UIConfigProvider(uiConfig: uiConfig)
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
