//
//  PaywallTextComponent.swift
//  
//
//  Created by Josh Holtz on 6/11/24.
//
// swiftlint:disable missing_docs nesting

import Foundation

public extension PaywallComponent {

    final class TextComponent: PaywallComponentBase {

        let type: ComponentType
        public let visible: Bool?
        public let text: LocalizationKey
        public let fontName: String?
        public let fontWeight: FontWeight
        public let color: ColorScheme
        public let fontSize: CGFloat
        public let horizontalAlignment: HorizontalAlignment
        public let backgroundColor: ColorScheme?
        public let size: Size
        public let padding: Padding
        public let margin: Padding

        public let overrides: ComponentOverrides<PartialTextComponent>?

        public init(
            visible: Bool? = nil,
            text: String,
            fontName: String? = nil,
            fontWeight: FontWeight = .regular,
            color: ColorScheme,
            backgroundColor: ColorScheme? = nil,
            size: Size = .init(width: .fill, height: .fit),
            padding: Padding = .zero,
            margin: Padding = .zero,
            fontSize: CGFloat = 16,
            horizontalAlignment: HorizontalAlignment = .center,
            overrides: ComponentOverrides<PartialTextComponent>? = nil
        ) {
            self.type = .text
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
            self.overrides = overrides
        }

        private enum CodingKeys: String, CodingKey {
            case type
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
            case overrides
        }

        required public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.type = try container.decode(ComponentType.self, forKey: .type)
            self.visible = try container.decodeIfPresent(Bool.self, forKey: .visible)
            self.text = try container.decode(LocalizationKey.self, forKey: .text)
            self.fontName = try container.decodeIfPresent(String.self, forKey: .fontName)
            self.fontWeight = try container.decode(FontWeight.self, forKey: .fontWeight)
            self.color = try container.decode(ColorScheme.self, forKey: .color)
            self.horizontalAlignment = try container.decode(HorizontalAlignment.self, forKey: .horizontalAlignment)
            self.backgroundColor = try container.decodeIfPresent(ColorScheme.self, forKey: .backgroundColor)
            self.size = try container.decode(Size.self, forKey: .size)
            self.padding = try container.decode(Padding.self, forKey: .padding)
            self.margin = try container.decode(Padding.self, forKey: .margin)
            self.overrides = try container.decodeIfPresent(
                ComponentOverrides<PartialTextComponent>.self,
                forKey: .overrides
            )

            if let rawFontSize = try? container.decode(CGFloat.self, forKey: .fontSize) {
                self.fontSize = rawFontSize
            } else if let fontSizeEnum = try? container.decode(FontSize.self, forKey: .fontSize) {
                self.fontSize = fontSizeEnum.size
            } else {
                throw DecodingError.dataCorruptedError(forKey: .fontSize,
                                                       in: container,
                                                       debugDescription: "Invalid fontSize format")
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encode(type, forKey: .type)
            try container.encodeIfPresent(visible, forKey: .visible)
            try container.encode(text, forKey: .text)
            try container.encodeIfPresent(fontName, forKey: .fontName)
            try container.encode(fontWeight, forKey: .fontWeight)
            try container.encode(color, forKey: .color)
            try container.encode(horizontalAlignment, forKey: .horizontalAlignment)
            try container.encodeIfPresent(backgroundColor, forKey: .backgroundColor)
            try container.encode(size, forKey: .size)
            try container.encode(padding, forKey: .padding)
            try container.encode(margin, forKey: .margin)
            try container.encodeIfPresent(overrides, forKey: .overrides)

            try container.encode(fontSize, forKey: .fontSize)
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(visible)
            hasher.combine(text)
            hasher.combine(fontName)
            hasher.combine(fontWeight)
            hasher.combine(color)
            hasher.combine(fontSize)
            hasher.combine(horizontalAlignment)
            hasher.combine(backgroundColor)
            hasher.combine(size)
            hasher.combine(padding)
            hasher.combine(margin)
            hasher.combine(overrides)
        }

        public static func == (lhs: TextComponent, rhs: TextComponent) -> Bool {
            return lhs.type == rhs.type &&
                   lhs.visible == rhs.visible &&
                   lhs.text == rhs.text &&
                   lhs.fontName == rhs.fontName &&
                   lhs.fontWeight == rhs.fontWeight &&
                   lhs.color == rhs.color &&
                   lhs.fontSize == rhs.fontSize &&
                   lhs.horizontalAlignment == rhs.horizontalAlignment &&
                   lhs.backgroundColor == rhs.backgroundColor &&
                   lhs.size == rhs.size &&
                   lhs.padding == rhs.padding &&
                   lhs.margin == rhs.margin &&
                   lhs.overrides == rhs.overrides
        }
    }

    final class PartialTextComponent: PaywallPartialComponent {

        public let visible: Bool?
        public let text: LocalizationKey?
        public let fontName: String?
        public let fontWeight: FontWeight?
        public let color: ColorScheme?
        public let fontSize: CGFloat?
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
            fontSize: CGFloat? = nil,
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

        private enum CodingKeys: String, CodingKey {
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

        public func hash(into hasher: inout Hasher) {
            hasher.combine(visible)
            hasher.combine(text)
            hasher.combine(fontName)
            hasher.combine(fontWeight)
            hasher.combine(color)
            hasher.combine(fontSize)
            hasher.combine(horizontalAlignment)
            hasher.combine(backgroundColor)
            hasher.combine(size)
            hasher.combine(padding)
            hasher.combine(margin)
        }

        public static func == (lhs: PartialTextComponent, rhs: PartialTextComponent) -> Bool {
            return lhs.visible == rhs.visible &&
                   lhs.text == rhs.text &&
                   lhs.fontName == rhs.fontName &&
                   lhs.fontWeight == rhs.fontWeight &&
                   lhs.color == rhs.color &&
                   lhs.fontSize == rhs.fontSize &&
                   lhs.horizontalAlignment == rhs.horizontalAlignment &&
                   lhs.backgroundColor == rhs.backgroundColor &&
                   lhs.size == rhs.size &&
                   lhs.padding == rhs.padding &&
                   lhs.margin == rhs.margin
        }
    }

}

private extension PaywallComponent.FontSize {

    var size: CGFloat {
        switch self {
        case .headingXXL: return 40
        case .headingXL: return 34
        case .headingL: return 28
        case .headingM: return 24
        case .headingS: return 20
        case .headingXS: return 16
        case .bodyXL: return 18
        case .bodyL: return 17
        case .bodyM: return 15
        case .bodyS: return 13
        }
    }

}
