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

#if !os(macOS) && !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class UIConfigProvider {
    typealias FailedToLoadFont = (_ fontConfig: UIConfig.FontsConfig) -> Void

    private let uiConfig: UIConfig
    private let failedToLoadFont: FailedToLoadFont?
    private var loggedMessages: Set<LogMessage> = []

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
            self.logMessageIfNeeded(.localizationNotFound(identifier: locale.identifier))
            return [:]
        }

        return localizations
    }

    @MainActor
    func resolveFont(size fontSize: CGFloat, name: String) -> Font? {

        guard let fontsConfig = self.uiConfig.app.fonts[name] else {
            self.logMessageIfNeeded(.fontMappingNotFound(name: name))
            return nil
        }

        let fontName: String
        switch fontsConfig.ios.type {
        case .name:
            fontName = fontsConfig.ios.value
        case .googleFonts:
            // Not supported on this platform (yet)
            self.logMessageIfNeeded(.googleFontsNotSupported)
            return nil
        @unknown default:
            return nil
        }

        // Check if the font name is a generic font (serif, sans-serif, monospace)
        if let genericFont = GenericFont(rawValue: fontName) {
            return genericFont.makeFont(fontSize: fontSize)
        }

        guard let customFont = UIFont(name: fontName, size: fontSize) else {
            self.logMessageIfNeeded(.customFontFailedToLoad(fontName: fontName))
            self.failedToLoadFont?(fontsConfig)
            return nil
        }

        // Apply dynamic type scaling
        let uiFont = UIFontMetrics.default.scaledFont(for: customFont)
        return Font(uiFont)
    }
}

// MARK: - Log management
// This section exists to prevent duplicate log messages from being repeatedly emitted,
// ensuring that identical warnings (like missing font mappings) are only logged once per instance.

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension UIConfigProvider {

    enum LogMessage: Hashable {
        case localizationNotFound(identifier: String)
        case fontMappingNotFound(name: String)
        case customFontFailedToLoad(fontName: String)
        case googleFontsNotSupported
    }

    func logMessageIfNeeded(_ message: LogMessage) {
        guard !self.loggedMessages.contains(message) else { return }
        self.loggedMessages.insert(message)
        message.log()
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension UIConfigProvider.LogMessage {

    func log() {
        switch self {
        case .localizationNotFound(let identifier):
            Logger.error("Could not find localizations for '\(identifier)'")
        case .fontMappingNotFound(let name):
            Logger.warning("Mapping for '\(name)' could not be found. Falling back to system font.")
        case .customFontFailedToLoad(let fontName):
            Logger.warning("Custom font '\(fontName)' could not be loaded. Falling back to system font.")
        case .googleFontsNotSupported:
            Logger.warning("Google Fonts are not supported on this platform")
        }
    }

}

#endif
