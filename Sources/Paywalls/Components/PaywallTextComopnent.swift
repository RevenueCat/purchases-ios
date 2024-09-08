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
    final class TextComponent: PaywallComponentBase {
        public static func == (lhs: PaywallComponent.TextComponent, rhs: PaywallComponent.TextComponent) -> Bool {
            lhs.text == rhs.text &&
            lhs.textLid == rhs.textLid &&
            lhs.fontFamily == rhs.fontFamily &&
            lhs.fontWeight == rhs.fontWeight &&
            lhs.color == rhs.color &&
            lhs.textStyle == rhs.textStyle &&
            lhs.horizontalAlignment == rhs.horizontalAlignment &&
            lhs.backgroundColor == rhs.backgroundColor &&
            lhs.padding == rhs.padding
}

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(text)
            hasher.combine(textLid)
            hasher.combine(fontFamily)
            hasher.combine(fontWeight)
            hasher.combine(color)
            hasher.combine(textStyle)
            hasher.combine(horizontalAlignment)
            hasher.combine(backgroundColor)
            hasher.combine(padding)
        }


        public let selectedComponent: TextComponent?
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
            horitzontalAlignment: HorizontalAlignment = .center,
            selectedComponent: TextComponent? = nil
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
            self.selectedComponent = selectedComponent
        }

    }
}

#endif
