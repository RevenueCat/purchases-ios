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

#if PAYWALL_COMPONENTS

extension PaywallComponent.Background {

    func asDisplayable(uiConfigProvider: UIConfigProvider) -> BackgroundStyle {
        switch self {
        case .color(let color):
            return .color(color.asDisplayable(uiConfigProvider: uiConfigProvider))
        case .image(let image):
            return .image(image)
        }
    }

}

struct DisplayableColorScheme: Equatable, Hashable {

    init(light: DisplayableColorInfo, dark: DisplayableColorInfo? = nil) {
        self.light = light
        self.dark = dark
    }

    let light: DisplayableColorInfo
    let dark: DisplayableColorInfo?

}

enum DisplayableColorInfo: Codable, Sendable, Hashable {

    case hex(PaywallComponent.ColorHex)
    case linear(Int, [PaywallComponent.GradientPoint])
    case radial([PaywallComponent.GradientPoint])

}

extension DisplayableColorScheme {

    static func from(colorScheme: PaywallComponent.ColorScheme,
                     uiConfigProvider: UIConfigProvider) throws -> DisplayableColorScheme {
        let light = try colorScheme.light.asDisplayable(forLight: true, uiConfigProvider: uiConfigProvider)
        let dark = try colorScheme.dark?.asDisplayable(forLight: false, uiConfigProvider: uiConfigProvider)

        return DisplayableColorScheme(light: light, dark: dark)
    }

}

extension PaywallComponent.ColorScheme {

    func asDisplayable(uiConfigProvider: UIConfigProvider) -> DisplayableColorScheme {
        do {
            return try DisplayableColorScheme.from(colorScheme: self, uiConfigProvider: uiConfigProvider)
        } catch {
            // WIP: Fallback clear (FOR NOW)
            return DisplayableColorScheme(light: .hex("#ffffff00"))
        }
    }

}

extension PaywallComponent.ColorInfo {

    func asDisplayable(forLight: Bool, uiConfigProvider: UIConfigProvider) throws -> DisplayableColorInfo {
        switch self {
        case .hex(let hex):
            return .hex(hex)
        case .alias(let name):

            let aliasedColorScheme = uiConfigProvider.getColor(for: name)
            let aliasedColorInfo = forLight ? aliasedColorScheme?.light : aliasedColorScheme?.dark

            guard let aliasedColorInfo else {
                Logger.warning("Aliased color '\(name)' does not exist.")
                fatalError()
            }

            switch aliasedColorInfo {
            case .hex(let hex):
                return .hex(hex)
            case .alias(let name):
                Logger.warning("Aliased color '\(name)' has an aliased value which is not allowed.")
                fatalError()
            case .linear(let degree, let points):
                return .linear(degree, points)
            case .radial(let points):
                return .radial(points)
            }
        case .linear(let degree, let points):
            return .linear(degree, points)
        case .radial(let points):
            return .radial(points)
        }
    }

}

#endif
