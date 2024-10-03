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
        public let fontFamily: String?
        public let fontWeight: FontWeight
        public let color: ColorInfo
        public let textStyle: TextStyle
        public let horizontalAlignment: HorizontalAlignment
        public let backgroundColor: ColorInfo?
        public let padding: Padding
        public let margin: Padding

        public let selectedState: TextComponent?

        public init(
            text: String,
            fontFamily: String? = nil,
            fontWeight: FontWeight = .regular,
            color: ColorInfo,
            backgroundColor: ColorInfo? = nil,
            padding: Padding = .default,
            margin: Padding = .default,
            textStyle: TextStyle = .body,
            horizontalAlignment: HorizontalAlignment = .center,
            selectedState: TextComponent? = nil
        ) {
            self.type = .text
            self.text = text
            self.fontFamily = fontFamily
            self.fontWeight = fontWeight
            self.color = color
            self.backgroundColor = backgroundColor
            self.padding = padding
            self.margin = margin
            self.textStyle = textStyle
            self.horizontalAlignment = horizontalAlignment
            self.selectedState = selectedState
        }

        // Hashable conformance
        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(textLid)
            hasher.combine(fontFamily)
            hasher.combine(fontWeight)
            hasher.combine(color)
            hasher.combine(textStyle)
            hasher.combine(horizontalAlignment)
            hasher.combine(backgroundColor)
            hasher.combine(padding)
            hasher.combine(margin)
            hasher.combine(selectedState)
        }

        // Equatable conformance
        public static func == (lhs: TextComponent, rhs: TextComponent) -> Bool {
            return lhs.type == rhs.type &&
                lhs.textLid == rhs.textLid &&
                lhs.fontFamily == rhs.fontFamily &&
                lhs.fontWeight == rhs.fontWeight &&
                lhs.color == rhs.color &&
                lhs.textStyle == rhs.textStyle &&
                lhs.horizontalAlignment == rhs.horizontalAlignment &&
                lhs.backgroundColor == rhs.backgroundColor &&
                lhs.padding == rhs.padding &&
                lhs.margin == rhs.margin &&
                lhs.selectedState == rhs.selectedState
        }
    }

}

extension PaywallComponent.TextComponent {

    enum CodingKeys: String, CodingKey {
        case type
        case text = "text_lid"
        case fontFamily
        case fontWeight
        case color
        case textStyle
        case horizontalAlignment
        case backgroundColor
        case padding
        case margin
    }

}

#endif
