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
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct UIConfigProvider {
    typealias FailedToLoadFont = (_ fontConfig: UIConfig.FontsConfig) -> Void

    private let uiConfig: UIConfig
    private let failedToLoadFont: FailedToLoadFont?

    init(uiConfig: UIConfig, failedToLoadFont: FailedToLoadFont? = nil) {
        self.uiConfig = uiConfig
        self.failedToLoadFont = failedToLoadFont
    }

    var variableConfig: UIConfig.VariableConfig {
        return self.uiConfig.variableConfig
    }

    func getColor(for name: String) -> PaywallComponent.ColorScheme? {
        return self.uiConfig.app.colors[name]
    }

    func getLocalizations(for locale: Locale) -> [String: String] {
        guard let localizations = self.uiConfig.localizations.findLocale(locale) else {
            Logger.error("Could not find localizations for '\(locale.identifier)'")
            return [:]
        }

        return localizations
    }

    @MainActor
    func resolveFont(size fontSize: CGFloat, name: String) -> Font? {

        guard let fontsConfig = self.uiConfig.app.fonts[name] else {
            Logger.warning("Mapping for '\(name)' could not be found. Falling back to system font.")
            return nil
        }

        let fontName: String
        switch fontsConfig.ios.type {
        case .name:
            fontName = fontsConfig.ios.value
        case .googleFonts:
            // Not supported on this platform (yet)
            Logger.warning("Google Fonts are not supported on this platform")
            return nil
        @unknown default:
            return nil
        }

        // Check if the font name is a generic font (serif, sans-serif, monospace)
        if let genericFont = GenericFont(rawValue: fontName) {
            return genericFont.makeFont(fontSize: fontSize)
        }

        guard let customFont = PlatformFont(name: fontName, size: fontSize) else {
            Logger.warning("Custom font '\(fontName)' could not be loaded. Falling back to system font.")
            self.failedToLoadFont?(fontsConfig)
            return nil
        }

        // Apply dynamic type scaling
        #if canImport(UIKit)
        let uiFont = UIFontMetrics.default.scaledFont(for: customFont)
        return Font(uiFont)
        #else
        // macOS does not support dynamic type (see https://developer.apple.com/design/human-interface-guidelines/typography)
        return Font(customFont)
        #endif
    }
}

#endif
