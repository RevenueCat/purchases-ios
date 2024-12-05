//
//  PaywallTextComponent.swift
//  
//
//  Created by Josh Holtz on 6/11/24.
//
// swiftlint:disable missing_docs

import Foundation

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    struct TextComponent: PaywallComponentBase {

        let type: ComponentType
        public let text: LocalizationKey
        public let fontName: String?
        public let fontWeight: FontWeight
        public let color: ColorScheme
        public let fontSize: FontSize
        public let horizontalAlignment: HorizontalAlignment
        public let backgroundColor: ColorScheme?
        public let size: Size
        public let padding: Padding
        public let margin: Padding

        public let overrides: ComponentOverrides<PartialTextComponent>?

        public init(
            text: String,
            fontName: String? = nil,
            fontWeight: FontWeight = .regular,
            color: ColorScheme,
            backgroundColor: ColorScheme? = nil,
            size: Size = .init(width: .fill, height: .fit),
            padding: Padding = .zero,
            margin: Padding = .zero,
            fontSize: FontSize = .bodyM,
            horizontalAlignment: HorizontalAlignment = .center,
            overrides: ComponentOverrides<PartialTextComponent>? = nil
        ) {
            self.type = .text
            self.text = text
            self.fontName = fontName
            self.fontWeight = fontWeight
            self.color = color
            self.backgroundColor = backgroundColor
            self.size = size
            self.padding = padding
            self.margin = margin
            self.fontSize = fontSize
            self.horizontalAlignment = horizontalAlignment
            self.overrides = overrides
        }
    }

    struct PartialTextComponent: PartialComponent {

        public let visible: Bool?
        public let text: LocalizationKey?
        public let fontName: String?
        public let fontWeight: FontWeight?
        public let color: ColorScheme?
        public let fontSize: FontSize?
        public let horizontalAlignment: HorizontalAlignment?
        public let backgroundColor: ColorScheme?
        public let size: Size?
        public let padding: Padding?
        public let margin: Padding?

        public init(
            visible: Bool? = true,
            text: LocalizationKey? = nil,
            fontName: String? = nil,
            fontWeight: FontWeight? = nil,
            color: ColorScheme? = nil,
            backgroundColor: ColorScheme? = nil,
            size: Size? = nil,
            padding: Padding? = nil,
            margin: Padding? = nil,
            fontSize: FontSize? = nil,
            horizontalAlignment: HorizontalAlignment? = nil
        ) {
            self.visible = visible
            self.text = text
            self.fontName = fontName
            self.fontWeight = fontWeight
            self.color = color
            self.backgroundColor = backgroundColor
            self.size = size
            self.padding = padding
            self.margin = margin
            self.fontSize = fontSize
            self.horizontalAlignment = horizontalAlignment
        }
    }

}

extension PaywallComponent.TextComponent {

    enum CodingKeys: String, CodingKey {
        case type
        case text = "textLid"
        case fontName
        case fontWeight
        case color
        case fontSize
        case horizontalAlignment
        case backgroundColor
        case size
        case padding
        case margin

        case overrides
    }

}

extension PaywallComponent.PartialTextComponent {

    enum CodingKeys: String, CodingKey {
        case visible
        case text = "textLid"
        case fontName
        case fontWeight
        case color
        case fontSize
        case horizontalAlignment
        case backgroundColor
        case size
        case padding
        case margin
    }

}

#endif
