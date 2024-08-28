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

        public enum FitMode: Codable, Sendable, Hashable {

            case fit
            case crop

        }

        let type: String
        public let url: URL
        public let fitMode: FitMode
        public var gradientColors: [ColorHex]
        public var cornerRadius: Double
        public var maxHeight: CGFloat?

        public init(
            url: URL,
            cornerRadius: Double = 0.0,
            gradientColors: [ColorHex] = [],
            fitMode: FitMode = .fit,
            maxHeight: CGFloat? = nil
        ) {
            self.type = "image"
            self.url = url
            self.cornerRadius = cornerRadius
            self.gradientColors = gradientColors
            self.fitMode = fitMode
            self.maxHeight = maxHeight
        }

    }

}

#endif
