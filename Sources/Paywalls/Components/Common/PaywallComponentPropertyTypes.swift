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

    struct ThemeImageUrls: Codable, Sendable, Hashable, Equatable {

        public init(light: ImageUrls, dark: ImageUrls? = nil) {
            self.light = light
            self.dark = dark
        }

        public let light: ImageUrls
        public let dark: ImageUrls?

    }

    struct ImageUrls: Codable, Sendable, Hashable, Equatable {

        public init(original: URL, heic: URL, heicLowRes: URL) {
            self.original = original
            self.heic = heic
            self.heicLowRes = heicLowRes
        }

        public let original: URL
        public let heic: URL
        public let heicLowRes: URL
    }

    struct ColorInfo: Codable, Sendable, Hashable, Equatable {

        public init(light: ColorHex, dark: ColorHex? = nil) {
            self.light = light
            self.dark = dark
        }

        public let light: ColorHex
        public let dark: ColorHex?

    }

    enum Shape: Codable, Sendable, Hashable, Equatable {

        case rectangle
        case pill

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

    struct CornerRadiuses: Codable, Sendable, Hashable, Equatable {

        public init(topLeading: Double,
                    topTrailing: Double,
                    bottomLeading: Double,
                    bottomTrailing: Double) {
            self.topLeading = topLeading
            self.topTrailing = topTrailing
            self.bottomLeading = bottomLeading
            self.bottomTrailing = bottomTrailing
        }

        public let topLeading: Double
        public let topTrailing: Double
        public let bottomLeading: Double
        public let bottomTrailing: Double

        public static let `default` = CornerRadiuses(topLeading: 0,
                                                     topTrailing: 0,
                                                     bottomLeading: 0,
                                                     bottomTrailing: 0)
        public static let zero = CornerRadiuses(topLeading: 0,
                                                topTrailing: 0,
                                                bottomLeading: 0,
                                                bottomTrailing: 0)

    }

    enum WidthSizeType: String, Codable, Sendable, Hashable, Equatable {
        case fit, fill, fixed
    }

    struct WidthSize: Codable, Sendable, Hashable, Equatable {

        public init(type: WidthSizeType, value: Int? ) {
            self.type = type
            self.value = value
        }

        public let type: WidthSizeType
        public let value: Int?

    }

    enum FlexDistribution: String, Codable, Sendable, Hashable, Equatable {

        case start
        case center
        case end
        case spaceBetween = "space_between"
        case spaceAround = "space_around"
        case spaceEvenly = "space_evenly"

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
        case topLeading = "top_leading"
        case topTrailing = "top_trailing"
        case bottomLeading = "bottom_leading"
        case bottomTrailing = "bottom_trailing"

    }

    enum FontWeight: String, Codable, Sendable, Hashable, Equatable {

        case extraLight = "extra_light"
        case thin
        case light
        case regular
        case medium
        case semibold
        case bold
        case extraBold = "extra_bold"
        case black

    }

    enum TextStyle: String, Codable, Sendable, Hashable, Equatable {

        case largeTitle = "large_title"
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
        case extraLargeTitle = "extra_large_title"
        case extraLargeTitle2 = "extra_large_title2"

    }

    enum FitMode: String, Codable, Sendable, Hashable, Equatable {

        case fit
        case fill

    }

    struct Shadow: Codable, Sendable, Hashable, Equatable {

        public let color: ColorInfo
        public let radius: CGFloat
        // swiftlint:disable:next identifier_name
        public let x: CGFloat
        // swiftlint:disable:next identifier_name
        public let y: CGFloat

        // swiftlint:disable:next identifier_name
        public init(color: ColorInfo, radius: CGFloat, x: CGFloat, y: CGFloat) {
            self.color = color
            self.radius = radius
            self.x = x
            self.y = y
        }

    }

}

#endif
