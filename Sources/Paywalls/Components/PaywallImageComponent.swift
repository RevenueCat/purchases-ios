//
//  PaywallImageComponent.swift
//
//
//  Created by Josh Holtz on 6/12/24.
//
// swiftlint:disable missing_docs

import Foundation

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    struct ImageComponent: PaywallComponentBase {

        let type: ComponentType
        public let url: URL
        public let cornerRadius: Double
        public let gradientColors: [ColorHex]
        public let maxHeight: CGFloat?
        public let fitMode: FitMode

        public init(
            url: URL,
            fitMode: FitMode = .fit,
            maxHeight: CGFloat? = nil,
            cornerRadius: Double = 0.0,
            gradientColors: [ColorHex] = []
        ) {
            self.type = .image
            self.url = url
            self.fitMode = fitMode
            self.maxHeight = maxHeight
            self.cornerRadius = cornerRadius
            self.gradientColors = gradientColors
        }

    }

}

#endif
