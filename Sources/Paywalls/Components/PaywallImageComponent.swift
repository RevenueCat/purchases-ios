//
//  PaywallImageComponent.swift
//
//
//  Created by Josh Holtz on 6/12/24.
//
// swiftlint:disable missing_docs identifier_name

import Foundation

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    struct ImageComponent: PaywallComponentBase {

        let type: String
        public let url: URL

        public var cornerRadius: Double {
            _cornerRadius
        }

        public var gradientColors: [ColorHex] {
            _gradientColors
        }

        @DefaultDecodable.ZeroDouble
        var _cornerRadius: Double

        @DefaultDecodable.EmptyArray
        var _gradientColors: [ColorHex]

        public init(
            url: URL,
            cornerRadius: Double = 0.0,
            gradientColors: [ColorHex] = []
        ) {
            self.type = "image"
            self.url = url
            self._cornerRadius = cornerRadius
            self._gradientColors = gradientColors
        }

    }

}

#endif
