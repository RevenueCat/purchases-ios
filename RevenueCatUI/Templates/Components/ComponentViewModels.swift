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
public class TextComponentViewModel: ObservableObject {
    let locale: Locale
    let localization: [String: String]
    @Published private(set) var component: PaywallComponent.TextComponent

    init(locale: Locale, localization: [String : String], component: PaywallComponent.TextComponent) {
        self.locale = locale
        self.localization = localization
        self.component = component
    }

    var text: String {
        // TODO: Replace variables like "{{ }}"
        // TODO: Add logs?
        if let textLid = component.textLid {
            if let localizedText = localization[textLid] {
                return localizedText
            }
            else {
                return component.text.value.first?.value as? String ?? "missing localized text for \(textLid)"
            }
        } else {
            return component.text.value.first?.value as? String ?? "missing localized text"
        }
    }

    public var fontFamily: String {
        component.fontFamily
    }

    public var fontWeight: Font.Weight {
        component.fontWeight.fontWeight
    }

    public var color: Color {
        // TODO: implement color transformation
        // component.color
        Color.cyan
    }

    public var textStyle: Font {
        component.textStyle.font
    }

    public var horizontalAlignment: TextAlignment {
        component.horizontalAlignment.textAlignment
    }

    public var backgroundColor: Color {
        // TODO: implement color transformation
        // component.color
        Color.mint
    }

    public var padding: EdgeInsets {
        component.padding.edgeInsets
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
// @PublicForExternalTesting
class ImageComponentViewModel: ObservableObject {
    let locale: Locale
    @Published private(set) var component: PaywallComponent.ImageComponent

    init(locale: Locale, component: PaywallComponent.ImageComponent) {
        self.locale = locale
        self.component = component
    }
    
    public var url: URL {
        component.url
    }
    public var cornerRadius: Double {
        component.cornerRadius
    }
    public var gradientColors: [Color] {
        component.gradientColors.compactMap { try? $0.toColor() }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
// @PublicForExternalTesting
class SpacerComponentViewModel: ObservableObject {
    let locale: Locale
    let component: PaywallComponent.SpacerComponent

    init(locale: Locale, component: PaywallComponent.SpacerComponent) {
        self.locale = locale
        self.component = component
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
// @PublicForExternalTesting
class StackComponentViewModel: ObservableObject {
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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
