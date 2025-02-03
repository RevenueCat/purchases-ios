//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  UIConfigProvider.swift
//
//  Created by Josh Holtz on 1/5/25.

import Foundation
import RevenueCat

#if !os(macOS) && !os(tvOS) // For Paywalls V2

struct UIConfigProvider {

    private let uiConfig: UIConfig

    init(uiConfig: UIConfig) {
        self.uiConfig = uiConfig
    }

    var variableConfig: UIConfig.VariableConfig {
        return self.uiConfig.variableConfig
    }

    func getColor(for name: String) -> PaywallComponent.ColorScheme? {
        return self.uiConfig.app.colors[name]
    }

    func getFontFamily(for name: String?) -> String? {
        guard let name, let fontInfo = self.uiConfig.app.fonts[name]?.ios else {
            return nil
        }

        switch fontInfo {
        case .name(let fontFamily):
            return fontFamily
        case .googleFonts:
            // Not supported on this platform (yet)
            Logger.warning("Google Fonts are not supported on this platform")
            return nil
        @unknown default:
            return nil
        }
    }

    func getLocalizations(for locale: Locale) -> [String: String] {
        guard let localizations = self.uiConfig.localizations[locale.identifier] else {
            Logger.error("Could not find localizations for '\(locale.identifier)'")
            return [:]
        }

        return localizations
    }

}

#endif
