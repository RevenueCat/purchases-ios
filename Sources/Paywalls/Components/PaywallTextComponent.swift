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

        public init(
            text: String,
            fontFamily: String? = nil,
            fontWeight: FontWeight = .regular,
            color: ColorInfo,
            backgroundColor: ColorInfo? = nil,
            padding: Padding = .default,
            margin: Padding = .default,
            textStyle: TextStyle = .body,
            horizontalAlignment: HorizontalAlignment = .center
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
