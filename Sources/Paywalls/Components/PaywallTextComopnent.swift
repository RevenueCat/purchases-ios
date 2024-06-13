//
//  PaywallTextComponent.swift
//  
//
//  Created by Josh Holtz on 6/11/24.
//

import Foundation

public extension PaywallComponent {
    struct TextComponent: Decodable, Sendable, Hashable, Equatable {

        let type: String
        public let text: DisplayString
        public let color: ColorInfo
        public let textStyle: TextStyle
        public let horizontalAlignment: HorizontalAlignment
        public let backgroundColor: ColorInfo?
        public let padding: Padding

        public init(
            text: DisplayString,
            color: ColorInfo,
            backgroundColor: ColorInfo? = nil,
            padding: Padding = .default,
            textStyle: TextStyle = .body,
            horitzontalAlignment: HorizontalAlignment = .center
        ) {
            self.type = "text"
            self.text = text
            self.color = color
            self.backgroundColor = backgroundColor
            self.padding = padding
            self.textStyle = textStyle
            self.horizontalAlignment = horitzontalAlignment
        }

    }
}
