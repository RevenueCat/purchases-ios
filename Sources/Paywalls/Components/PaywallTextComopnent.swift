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
        public let text: String
        public let textLid: LocalizationKey
        public let fontFamily: String
        public let fontWeight: FontWeight
        public let color: ColorInfo
        public let textStyle: TextStyle
        public let horizontalAlignment: HorizontalAlignment
        public let backgroundColor: ColorInfo?
        public let padding: Padding

        public init(
            text: String,
            textLid: String,
            fontFamily: String = "SF Pro",
            fontWeight: FontWeight = .regular,
            color: ColorInfo,
            backgroundColor: ColorInfo? = nil,
            padding: Padding = .default,
            textStyle: TextStyle = .body,
            horitzontalAlignment: HorizontalAlignment = .center
        ) {
            self.type = .text
            self.text = text
            self.textLid = textLid
            self.fontFamily = fontFamily
            self.fontWeight = fontWeight
            self.color = color
            self.backgroundColor = backgroundColor
            self.padding = padding
            self.textStyle = textStyle
            self.horizontalAlignment = horitzontalAlignment
        }

    }
}

#endif
