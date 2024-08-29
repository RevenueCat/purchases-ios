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

extension PaywallComponent.TextStyle {
    public var font: Font {
        switch self {
        case .largeTitle: return .largeTitle
        case .title: return .title
        case .title2: if #available(iOS 14.0, *) {
            return .title2
        } else {
            return .title
        }
        case .title3: if #available(iOS 14.0, *) {
            return .title3
        } else {
            return .title
        }
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .body: return .body
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption
        case .caption2: if #available(iOS 14.0, *) {
            return .caption2
        } else {
            return .caption
        }

        #if swift(>=5.9) && VISION_OS
        case .extraLargeTitle: return .extraLargeTitle
        case .extraLargeTitle2: return .extraLargeTitle2
        #else
        case .extraLargeTitle: return .largeTitle
        case .extraLargeTitle2: return .largeTitle
        #endif
        }
    }
}

extension PaywallComponent.FontWeight {
    public var fontWeight: Font.Weight {
        switch self {
        case .ultraLight:
            return .ultraLight
        case .thin:
            return .thin
        case .light:
            return .light
        case .regular:
            return .regular
        case .medium:
            return .medium
        case .semibold:
            return .semibold
        case .bold:
            return .bold
        case .heavy:
            return .heavy
        case .black:
            return .black
        }
    }
}

extension PaywallComponent.VerticalAlignment {
    public var stackAlignment: SwiftUI.VerticalAlignment {
        switch self {
        case .top:
            return .top
        case .center:
            return .center
        case .bottom:
            return .bottom
        }
    }
}

extension PaywallComponent.TwoDimensionAlignment {
    public var stackAlignment: SwiftUI.Alignment {
        switch self {
        case .center:
            return .center
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        case .top:
            return .top
        case .bottom:
            return .bottom
        case .topLeading:
            return .topLeading
        case .topTrailing:
            return .topTrailing
        case .bottomLeading:
            return .bottomLeading
        case .bottomTrailing:
            return .bottomTrailing
        }
    }
}

extension PaywallComponent.HorizontalAlignment {
    public var textAlignment: TextAlignment {
        switch self {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }

    public var stackAlignment: SwiftUI.HorizontalAlignment {
        switch self {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }
}

extension PaywallComponent.Padding {
    var edgeInsets: EdgeInsets {
            EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
        }
}


@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
// @PublicForExternalTesting
enum PaywallComponentViewModel {
    case text(TextComponentViewModel)
    case image(ImageComponentViewModel)
    case spacer(SpacerComponentViewModel)
    case stack(StackComponentViewModel)
    case linkButton(LinkButtonComponentViewModel)
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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
                LinkButtonComponentViewModel(locale: locale, component: component, localization: localization, offering: offering)
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
