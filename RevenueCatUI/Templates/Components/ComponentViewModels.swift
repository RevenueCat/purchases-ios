//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ComponentViewModels.swift
//
//  Created by Josh Holtz on 8/27/24.

import SwiftUI
import RevenueCat

// @PublicForExternalTesting
struct TextComponentViewModel {
    let locale: Locale
    let localization: [String: String]
    let component: PaywallComponent.TextComponent

    var text: String {
        // TODO: Remove explicit unwrap
        // TODO: Replace variables like "{{ }}"
        return localization[component.textLid!] ?? ""
    }

    // Add properties or methods needed to support the view
}

// @PublicForExternalTesting
struct ImageComponentViewModel {
    let locale: Locale
    let component: PaywallComponent.ImageComponent

    // Add properties or methods needed to support the view
}

// @PublicForExternalTesting
struct SpacerComponentViewModel {
    let locale: Locale
    let component: PaywallComponent.SpacerComponent

    // Add properties or methods needed to support the view
}

// @PublicForExternalTesting
struct StackComponentViewModel {
    let locale: Locale
    let component: PaywallComponent.StackComponent
    let viewModels: [PaywallComponentViewModel]

    init(locale: Locale,
         component: PaywallComponent.StackComponent,
         localization: [String: String],
         offering: Offering
    ) {
        self.locale = locale
        self.component = component
        self.viewModels = component.components.map {
            $0.toViewModel(offering: offering, locale: locale, localization: localization)
        }

    }
    // Add properties or methods needed to support the view
}

// @PublicForExternalTesting
struct LinkButtonComponentViewModel {
    let locale: Locale
    let component: PaywallComponent.LinkButtonComponent

    // Add properties or methods needed to support the view
}

// @PublicForExternalTesting
enum PaywallComponentViewModel {
    case text(TextComponentViewModel)
    case image(ImageComponentViewModel)
    case spacer(SpacerComponentViewModel)
    case stack(StackComponentViewModel)
    case linkButton(LinkButtonComponentViewModel)
}

extension PaywallComponent {
    func toViewModel(offering: Offering, locale: Locale, localization: [String: String]) -> PaywallComponentViewModel {
        switch self {
        case .text(let component):
            return .text(
                TextComponentViewModel(locale: locale, localization: localization, component: component)
            )
        case .image(let component):
            return .image(
                ImageComponentViewModel(locale: locale, component: component)
            )
        case .spacer(let component):
            return .spacer(
                SpacerComponentViewModel(locale: locale, component: component)
            )
        case .stack(let component):
            return .stack(
                StackComponentViewModel(locale: locale, component: component, localization: localization, offering: offering)
            )
        case .linkButton(let component):
            return .linkButton(
                LinkButtonComponentViewModel(locale: locale, component: component)
            )
        }
    }
}

extension ColorHex {

    enum Error: Swift.Error {

        case invalidStringFormat(String)
        case invalidColor(String)

    }

    public func toColor() throws -> Color {
        let red, green, blue, alpha: CGFloat

        guard self.hasPrefix("#") else {
            throw Error.invalidStringFormat(self)
        }

        let start = self.index(self.startIndex, offsetBy: 1)
        let hexColor = String(self[start...])

        guard hexColor.count == 6 || hexColor.count == 8 else {
            throw Error.invalidStringFormat(self)
        }

        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt64 = 0

        if scanner.scanHexInt64(&hexNumber) {
            // If Alpha channel is missing, it's a fully opaque color.
            if hexNumber <= 0xffffff {
                hexNumber <<= 8
                hexNumber |= 0xff
            }

            red = CGFloat((hexNumber & 0xff000000) >> 24) / 255
            green = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
            blue = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
            alpha = CGFloat(hexNumber & 0x000000ff) / 255

            return .init(red: red, green: green, blue: blue, opacity: alpha)
        } else {
            throw Error.invalidColor(self)
        }
    }

}
