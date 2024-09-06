//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallComponentPropertyTypes.swift
//
//  Created by James Borthwick on 2024-08-29.
// swiftlint:disable missing_docs

import Foundation

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    struct ColorInfo: Codable, Sendable, Hashable, Equatable {

        public init(light: ColorHex, dark: ColorHex? = nil) {
            self.light = light
            self.dark = dark
        }

        public let light: ColorHex
        public let dark: ColorHex?

    }

    struct Padding: Codable, Sendable, Hashable, Equatable {

        public init(top: Double, bottom: Double, leading: Double, trailing: Double) {
            self.top = top
            self.bottom = bottom
            self.leading = leading
            self.trailing = trailing
        }

        public let top: Double
        public let bottom: Double
        public let leading: Double
        public let trailing: Double

        public static let `default` = Padding(top: 10, bottom: 10, leading: 20, trailing: 20)
        public static let zero = Padding(top: 0, bottom: 0, leading: 0, trailing: 0)

    }

    enum HorizontalAlignment: String, Codable, Sendable, Hashable, Equatable {

        case leading
        case center
        case trailing

    }

    enum VerticalAlignment: String, Codable, Sendable, Hashable, Equatable {

        case top
        case center
        case bottom

    }

    enum TwoDimensionAlignment: String, Decodable, Sendable, Hashable, Equatable {

        case center
        case leading
        case trailing
        case top
        case bottom
        case topLeading
        case topTrailing
        case bottomLeading
        case bottomTrailing

    }

    enum FontWeight: String, Codable, Sendable, Hashable, Equatable {

        case ultraLight
        case thin
        case light
        case regular
        case medium
        case semibold
        case bold
        case heavy
        case black

    }

    enum TextStyle: String, Codable, Sendable, Hashable, Equatable {

        case largeTitle
        case title
        case title2
        case title3
        case headline
        case subheadline
        case body
        case callout
        case footnote
        case caption
        case caption2

        // Swift 5.9 stuff
        case extraLargeTitle
        case extraLargeTitle2

    }

    enum FitMode: String, Codable, Sendable, Hashable, Equatable {

        case fit
        case fill

    }

}

#endif
