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
// swiftlint:disable file_length

import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallComponent.FontSize {

    func makeFont(familyName: String?) -> Font {
        return Font(self.makePlatformFont(familyName: familyName))
    }

    private var textStyle: PlatformFont.TextStyle {
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

    // swiftlint:disable cyclomatic_complexity
    private func makePlatformFont(familyName: String?) -> PlatformFont {
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

        // Create the base font, with fallback to the system font
        let baseFont: PlatformFont
        if let familyName = familyName {
            if let customFont = PlatformFont(name: familyName, size: fontSize) {
                baseFont = customFont
            } else {
                Logger.warning("Custom font '\(familyName)' could not be loaded. Falling back to system font.")
                baseFont = PlatformFont.systemFont(ofSize: fontSize, weight: .regular)
            }
        } else {
            baseFont = PlatformFont.systemFont(ofSize: fontSize, weight: .regular)
        }

        // Apply dynamic type scaling
        #if canImport(UIKit)
        return UIFontMetrics(forTextStyle: self.textStyle).scaledFont(for: baseFont)
        #else
        // macOS does not support dynamic type (see
        // https://developer.apple.com/design/human-interface-guidelines/typography)
        return baseFont
        #endif
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
            EdgeInsets(top: top ?? 0,
                       leading: leading ?? 0,
                       bottom: bottom ?? 0,
                       trailing: trailing ?? 0)
        }

}

extension EdgeInsets {
    func extend(by amount: CGFloat) -> EdgeInsets {
        if amount == 0 {
            return self
        }
        return .init(
            top: self.top + amount,
            leading: self.leading + amount,
            bottom: self.bottom + amount,
            trailing: self.trailing + amount
        )
    }
}

extension PaywallComponent.FitMode {
    var contentMode: ContentMode {
        switch self {
        case .fit:
            return ContentMode.fit
        case .fill:
            return ContentMode.fill
        }
    }
}

extension DisplayableColorInfo {

    func toColor(fallback: Color) -> Color {
        switch self {
        case .hex(let hex):
            return hex.toColor(fallback: fallback)
        case .linear, .radial:
            return fallback
        }
    }

    func toGradient() -> Gradient {
        switch self {
        case .hex:
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
            if hexColor.count == 6 {
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

extension DisplayableColorScheme {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    func toDynamicColor(with colorScheme: SwiftUI.ColorScheme) -> Color {
        guard let darkModeColor = self.dark else {
            return light.toColor(fallback: Color.clear)
        }

        if colorScheme == .dark {
            return darkModeColor.toColor(fallback: .clear)
        } else {
            return light.toColor(fallback: .clear)
        }
    }

    func effectiveColor(for colorScheme: ColorScheme) -> DisplayableColorInfo {
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallComponent.Shape {

    var shape: ShapeModifier.Shape {
        switch self {
        case .rectangle(let cornerRadiuses):
            let corners = cornerRadiuses.flatMap { cornerRadiuses in
                ShapeModifier.RadiusInfo(
                    topLeft: cornerRadiuses.topLeading ?? 0,
                    topRight: cornerRadiuses.topTrailing ?? 0,
                    bottomLeft: cornerRadiuses.bottomLeading ?? 0,
                    bottomRight: cornerRadiuses.bottomTrailing ?? 0
                )
            }
            return .rectangle(corners)
        case .pill:
            return .pill
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallComponent.Border {

    func border(uiConfigProvider: UIConfigProvider) -> ShapeModifier.BorderInfo? {
        return ShapeModifier.BorderInfo(
            color: self.color.asDisplayable(uiConfigProvider: uiConfigProvider),
            width: self.width
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallComponent.Shadow {

    func shadow(uiConfigProvider: UIConfigProvider, colorScheme: ColorScheme) -> ShadowModifier.ShadowInfo? {
        return ShadowModifier.ShadowInfo(
            color: self.color.asDisplayable(uiConfigProvider: uiConfigProvider).toDynamicColor(with: colorScheme),
            radius: self.radius,
            x: self.x,
            y: self.y
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallComponent.Badge {

    func badge(stackShape: ShapeModifier.Shape?,
               stackBorder: ShapeModifier.BorderInfo?,
               badgeViewModels: [PaywallComponentViewModel],
               uiConfigProvider: UIConfigProvider) -> BadgeModifier.BadgeInfo? {
        BadgeModifier.BadgeInfo(
            style: self.style,
            alignment: self.alignment,
            stack: self.stack,
            badgeViewModels: badgeViewModels,
            stackShape: stackShape,
            stackBorder: stackBorder,
            uiConfigProvider: uiConfigProvider
        )
    }

}

#endif
