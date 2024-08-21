//
//  PaywallTextComponent.swift
//  
//
//  Created by Josh Holtz on 6/11/24.
//

import Foundation
// swiftlint:disable all

#if PAYWALL_COMPONENTS

public extension PaywallComponent {
    struct TextComponent: PaywallComponentBase {

        let type: String
        public let text: DisplayString
        public let fontFamily: String
        public let fontWeight: FontWeight
        public let color: ColorInfo
        public let textStyle: TextStyle
        public let horizontalAlignment: HorizontalAlignment
        public let backgroundColor: ColorInfo?
        public let padding: Padding
        public let displayPreferences: [DisplayPreference]?

        public init(
            text: DisplayString,
            fontFamily: String = "SF Pro",
            fontWeight: FontWeight = .regular,
            color: ColorInfo,
            backgroundColor: ColorInfo? = nil,
            padding: Padding = .default,
            textStyle: TextStyle = .body,
            horitzontalAlignment: HorizontalAlignment = .center,
            displayPreferences: [DisplayPreference]? = nil
        ) {
            self.type = "text"
            self.text = text
            self.fontFamily = fontFamily
            self.fontWeight = fontWeight
            self.color = color
            self.backgroundColor = backgroundColor
            self.padding = padding
            self.textStyle = textStyle
            self.horizontalAlignment = horitzontalAlignment
            self.displayPreferences = displayPreferences
        }

        var focusIdentifiers: [FocusIdentifier]? = nil

    }
}

#endif
