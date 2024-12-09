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

import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

extension PaywallComponent.FontSize {

    var font: Font {
        return Font(self.uiFont)
    }

    private var textStyle: UIFont.TextStyle {
        switch self {
        case .headingXXL: return .largeTitle
        case .headingXL: return .title1
        case .headingL: return .title2
        case .headingM: return .title3
        case .headingS: return .headline
        case .headingXS: return .subheadline
        case .bodyXL, .bodyL: return .body
        case .bodyM: return .callout
        case .bodyS: return .footnote
        }
    }

    private var uiFont: UIFont {
        let fontSize: CGFloat
        switch self {
        case .headingXXL: fontSize = 40
        case .headingXL: fontSize = 34
        case .headingL: fontSize = 28
        case .headingM: fontSize = 24
        case .headingS: fontSize = 20
        case .headingXS: fontSize = 16
        case .bodyXL: fontSize = 18
        case .bodyL: fontSize = 17
        case .bodyM: fontSize = 15
        case .bodyS: fontSize = 13
        }

        // Create a UIFont and apply dynamic type scaling
        let baseFont = UIFont.systemFont(ofSize: fontSize, weight: .regular)
        return UIFontMetrics(forTextStyle: self.textStyle).scaledFont(for: baseFont)
    }

}

extension PaywallComponent.FontWeight {

    var fontWeight: Font.Weight {
        switch self {
        case .extraLight:
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
        case .extraBold:
            return .heavy
        case .black:
            return .black
        }
    }

}

extension PaywallComponent.VerticalAlignment {

    var stackAlignment: SwiftUI.VerticalAlignment {
        switch self {
        case .top:
            return .top
        case .center:
            return .center
        case .bottom:
            return .bottom
        }
    }

    var frameAlignment: SwiftUI.Alignment {
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

    var stackAlignment: SwiftUI.Alignment {
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

    var stackAlignment: SwiftUI.HorizontalAlignment {
        switch self {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }

    var textAlignment: TextAlignment {
        switch self {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }

    var frameAlignment: SwiftUI.Alignment {
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

extension PaywallComponent.FlexDistribution {

    var verticalFrameAlignment: SwiftUI.Alignment {
        switch self {
        case .start:
            return .top
        case .center:
            return .center
        case .end:
            return .bottom
        default:
            return .top
        }
    }

    var horizontalFrameAlignment: SwiftUI.Alignment {
        switch self {
        case .start:
            return .leading
        case .center:
            return .center
        case .end:
            return .trailing
        default:
            return .leading
        }
    }

}

extension PaywallComponent.Padding {
    var edgeInsets: EdgeInsets {
            EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
        }

}

extension PaywallComponent.FitMode {
    var contentMode: ContentMode {
        switch self {
        case .fit:
            ContentMode.fit
        case .fill:
            ContentMode.fill
        }
    }
}

extension PaywallComponent.ColorInfo {

    func toColor(fallback: Color) -> Color {
        switch self {
        case .hex(let hex):
            return hex.toColor(fallback: fallback)
        case .alias:
            // WIP: Need to implement this when we actually have alias implemented
            return fallback
        case .linear, .radial:
            return fallback
        }
    }

    func toGradient() -> Gradient {
        switch self {
        case .hex, .alias:
            return Gradient(colors: [.clear])
        case .linear(_, let points), .radial(let points):
            let stops = points.map { point in
                Gradient.Stop(
                    color: point.color.toColor(fallback: Color.clear),
                    location: CGFloat(point.percent)/100
                )
            }
            return Gradient(stops: stops)
        }
    }

}

extension PaywallComponent.ColorHex {

    func toColor(fallback: Color) -> Color {
        let red, green, blue, alpha: CGFloat

        guard self.hasPrefix("#") else {
            Logger.error(Strings.invalid_color_string(self))
            return fallback
        }

        let start = self.index(self.startIndex, offsetBy: 1)
        let hexColor = String(self[start...])

        guard hexColor.count == 6 || hexColor.count == 8 else {
            Logger.error(Strings.invalid_color_string(self))
            return fallback
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
            Logger.error(Strings.invalid_color_string(self))
            return fallback
        }
    }

}

extension PaywallComponent.ColorScheme {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func toDynamicColor() -> Color {

        guard let darkModeColor = self.dark else {
            return light.toColor(fallback: Color.clear)
        }

        let lightModeColor = light

        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .light, .unspecified:
                return UIColor(lightModeColor.toColor(fallback: Color.clear))
            case .dark:
                return UIColor(darkModeColor.toColor(fallback: Color.clear))
            @unknown default:
                return UIColor(lightModeColor.toColor(fallback: Color.clear))
            }
        })
    }

    func effectiveColor(for colorScheme: ColorScheme) -> PaywallComponent.ColorInfo {
        switch colorScheme {
        case .light:
            return light
        case .dark:
            return dark ?? light
        @unknown default:
            return light
        }
    }

}

#endif
