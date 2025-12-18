//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DisplayColor.swift
//
//  Created by Josh Holtz on 1/11/25.

import Foundation
import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallComponent.Background {

    func asDisplayable(
        uiConfigProvider: UIConfigProvider,
        localizationProvider: LocalizationProvider? = nil
    ) -> BackgroundStyle {
        switch self {
        case .color(let color):
            return .color(color.asDisplayable(uiConfigProvider: uiConfigProvider))
        case .image(let image, let fitMode, let colorScheme):
            return .image(image, fitMode, colorScheme?.asDisplayable(uiConfigProvider: uiConfigProvider))
        case let .video(video, image, loop, mute, fitMode, colorScheme):
            let viewModel = VideoComponentViewModel(
                localizationProvider: localizationProvider ?? .init(locale: .current, localizedStrings: .init()),
                uiConfigProvider: uiConfigProvider,
                component: .init(
                    source: video,
                    fallbackSource: image,
                    loop: loop,
                    muteAudio: mute,
                    fitMode: fitMode
                )
            )
            return .video(viewModel, colorScheme?.asDisplayable(uiConfigProvider: uiConfigProvider))
        }
    }

}

struct DisplayableColorScheme: Equatable, Hashable {

    static let error = DisplayableColorScheme(hasError: true)

    let light: DisplayableColorInfo
    let dark: DisplayableColorInfo?

    let hasError: Bool

    init(light: DisplayableColorInfo, dark: DisplayableColorInfo? = nil) {
        self.light = light
        self.dark = dark
        self.hasError = false
    }

    private init(hasError: Bool) {
        self.light = .hex("#ffffff00")
        self.dark = nil
        self.hasError = true
    }

}

enum DisplayableColorInfo: Codable, Sendable, Hashable {

    case hex(PaywallComponent.ColorHex)
    case linear(Int, [PaywallComponent.GradientPoint])
    case radial([PaywallComponent.GradientPoint])

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension DisplayableColorScheme {

    static func from(colorScheme: PaywallComponent.ColorScheme,
                     uiConfigProvider: UIConfigProvider) throws -> DisplayableColorScheme {
        let light = try colorScheme.light.asDisplayable(forLight: true, uiConfigProvider: uiConfigProvider)
        let dark = try colorScheme.dark?.asDisplayable(forLight: false, uiConfigProvider: uiConfigProvider)

        return DisplayableColorScheme(light: light, dark: dark)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallComponent.ColorScheme {

    func asDisplayable(uiConfigProvider: UIConfigProvider) -> DisplayableColorScheme {
        do {
            return try DisplayableColorScheme.from(colorScheme: self, uiConfigProvider: uiConfigProvider)
        } catch {
            // WIP: Falling back to clear color until move validation into view model initialization
            return DisplayableColorScheme.error
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallComponent.ColorInfo {

    func asDisplayable(forLight: Bool, uiConfigProvider: UIConfigProvider) throws -> DisplayableColorInfo {
        switch self {
        // Directly convert to displayable type
        case .hex(let hex):
            return .hex(hex)
        case .linear(let degree, let points):
            return .linear(degree, points)
        case .radial(let points):
            return .radial(points)

        // Attempt to look up alias and creat a new color
        case .alias(let name):

            let aliasedColorScheme = uiConfigProvider.getColor(for: name)
            let aliasedColorInfo = forLight ? aliasedColorScheme?.light : aliasedColorScheme?.dark

            guard let aliasedColorInfo else {
                Logger.error("Aliased color '\(name)' does not exist.")
                throw PaywallColorError.aliasDoesNotExist(name)
            }

            switch aliasedColorInfo {
            // Direclty convert the alias to displayable type
            case .hex(let hex):
                return .hex(hex)
            case .linear(let degree, let points):
                return .linear(degree, points)
            case .radial(let points):
                return .radial(points)

            // Throwing error if alias has an alias
            // This should NEVER happen though
            case .alias(let name):
                Logger.error("Aliased color '\(name)' has an aliased value which is not allowed.")
                throw PaywallColorError.aliasedColorIsAliased(name)
            }
        }
    }

}

enum PaywallColorError: LocalizedError {
    case aliasDoesNotExist(String)
    case aliasedColorIsAliased(String)

    var errorDescription: String? {
        switch self {
        case .aliasDoesNotExist(let alias):
            return "Aliased color '\(alias)' does not exist."
        case .aliasedColorIsAliased(let alias):
            return "Aliased color '\(alias)' has an aliased value which is not allowed."
        }
    }
}

#endif
