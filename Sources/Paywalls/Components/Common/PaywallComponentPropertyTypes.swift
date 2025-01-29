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
// swiftlint:disable missing_docs file_length

import Foundation

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

        public init(width: Int, height: Int, original: URL, heic: URL, heicLowRes: URL) {
            self.width = width
            self.height = height
            self.original = original
            self.heic = heic
            self.heicLowRes = heicLowRes
        }

        public let width: Int
        public let height: Int
        public let original: URL
        public let heic: URL
        public let heicLowRes: URL
    }

    struct GradientPoint: Codable, Sendable, Hashable, Equatable {

        public let color: ColorHex
        public let percent: Int

        public init(color: ColorHex, percent: Int) {
            self.color = color
            self.percent = percent
        }

    }

    struct ColorScheme: Codable, Sendable, Hashable, Equatable {

        public init(light: ColorInfo, dark: ColorInfo? = nil) {
            self.light = light
            self.dark = dark
        }

        public let light: ColorInfo
        public let dark: ColorInfo?

    }

    enum ColorInfo: Codable, Sendable, Hashable {

        case hex(ColorHex)
        case alias(String)
        case linear(Int, [GradientPoint])
        case radial([GradientPoint])

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .hex(let hex):
                try container.encode(ColorInfoTypes.hex.rawValue, forKey: .type)
                try container.encode(hex, forKey: .value)
            case .alias(let alias):
                try container.encode(ColorInfoTypes.alias.rawValue, forKey: .type)
                try container.encode(alias, forKey: .value)
            case .linear(let degrees, let points):
                try container.encode(ColorInfoTypes.linear.rawValue, forKey: .type)
                try container.encode(degrees, forKey: .degrees)
                try container.encode(points, forKey: .points)
            case .radial(let points):
                try container.encode(ColorInfoTypes.radial.rawValue, forKey: .type)
                try container.encode(points, forKey: .points)
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(ColorInfoTypes.self, forKey: .type)

            switch type {
            case .hex:
                let value = try container.decode(ColorHex.self, forKey: .value)
                self = .hex(value)
            case .alias:
                let value = try container.decode(String.self, forKey: .value)
                self = .alias(value)
            case .linear:
                let points = try container.decode([GradientPoint].self, forKey: .points)
                let degrees = try container.decode(Int.self, forKey: .degrees)
                self = .linear(degrees, points)
            case .radial:
                let points = try container.decode([GradientPoint].self, forKey: .points)
                self = .radial(points)
            }
        }

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {

            case type
            case value
            case degrees
            case points

        }

        // swiftlint:disable:next nesting
        private enum ColorInfoTypes: String, Decodable {

            case hex
            case alias
            case linear
            case radial

        }

    }

    enum Shape: Codable, Sendable, Hashable, Equatable {

        case rectangle(CornerRadiuses?)
        case pill

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .rectangle(let corners):
                try container.encode(ShapeType.rectangle.rawValue, forKey: .type)
                try container.encodeIfPresent(corners, forKey: .corners)
            case .pill:
                try container.encode(ShapeType.pill.rawValue, forKey: .type)
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(ShapeType.self, forKey: .type)

            switch type {
            case .rectangle:
                let value: CornerRadiuses? = try container.decodeIfPresent(CornerRadiuses.self, forKey: .corners)
                self = .rectangle(value)
            case .pill:
                self = .pill
            }
        }

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {

            case type
            case corners

        }

        // swiftlint:disable:next nesting
        private enum ShapeType: String, Decodable {

            case rectangle
            case pill

        }

    }

    enum IconBackgroundShape: Codable, Sendable, Hashable, Equatable {

        case rectangle(CornerRadiuses?)
        case circle

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .rectangle(let corners):
                try container.encode(ShapeType.rectangle.rawValue, forKey: .type)
                try container.encodeIfPresent(corners, forKey: .corners)
            case .circle:
                try container.encode(ShapeType.circle.rawValue, forKey: .type)
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(ShapeType.self, forKey: .type)

            switch type {
            case .rectangle:
                let value: CornerRadiuses? = try container.decodeIfPresent(CornerRadiuses.self, forKey: .corners)
                self = .rectangle(value)
            case .circle:
                self = .circle
            }
        }

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {

            case type
            case corners

        }

        // swiftlint:disable:next nesting
        private enum ShapeType: String, Decodable {

            case rectangle
            case circle

        }

    }

    enum MaskShape: Codable, Sendable, Hashable, Equatable {

        case rectangle(CornerRadiuses?)
        case circle
        case concave
        case convex

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .rectangle(let corners):
                try container.encodeIfPresent(MaskShapeType.rectangle.rawValue, forKey: .type)
                try container.encode(corners, forKey: .corners)
            case .circle:
                try container.encode(MaskShapeType.circle.rawValue, forKey: .type)
            case .concave:
                try container.encode(MaskShapeType.concave.rawValue, forKey: .type)
            case .convex:
                try container.encode(MaskShapeType.convex.rawValue, forKey: .type)
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(MaskShapeType.self, forKey: .type)

            switch type {
            case .rectangle:
                let value: CornerRadiuses? = try container.decodeIfPresent(CornerRadiuses.self, forKey: .corners)
                self = .rectangle(value)
            case .circle:
                self = .circle
            case .concave:
                self = .concave
            case .convex:
                self = .convex
            }
        }

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {

            case type
            case corners

        }

        // swiftlint:disable:next nesting
        private enum MaskShapeType: String, Decodable {

            case rectangle
            case circle
            case concave
            case convex

        }

    }

    struct Padding: Codable, Sendable, Hashable, Equatable {

        public init(top: Double?,
                    bottom: Double?,
                    leading: Double?,
                    trailing: Double?) {
            self.top = top
            self.bottom = bottom
            self.leading = leading
            self.trailing = trailing
        }

        public let top: Double?
        public let bottom: Double?
        public let leading: Double?
        public let trailing: Double?

        public static let `default` = Padding(top: 10, bottom: 10, leading: 20, trailing: 20)
        public static let zero = Padding(top: 0, bottom: 0, leading: 0, trailing: 0)

    }

    struct CornerRadiuses: Codable, Sendable, Hashable, Equatable {

        public init(topLeading: Double?,
                    topTrailing: Double?,
                    bottomLeading: Double?,
                    bottomTrailing: Double?) {
            self.topLeading = topLeading
            self.topTrailing = topTrailing
            self.bottomLeading = bottomLeading
            self.bottomTrailing = bottomTrailing
        }

        public let topLeading: Double?
        public let topTrailing: Double?
        public let bottomLeading: Double?
        public let bottomTrailing: Double?

        public static let `default` = CornerRadiuses(topLeading: 0,
                                                     topTrailing: 0,
                                                     bottomLeading: 0,
                                                     bottomTrailing: 0)
        public static let zero = CornerRadiuses(topLeading: 0,
                                                topTrailing: 0,
                                                bottomLeading: 0,
                                                bottomTrailing: 0)

    }

    struct Size: Codable, Sendable, Hashable, Equatable {

        public let width: SizeConstraint
        public let height: SizeConstraint

        public init(width: PaywallComponent.SizeConstraint, height: PaywallComponent.SizeConstraint) {
            self.width = width
            self.height = height
        }

    }

    enum SizeConstraint: Codable, Sendable, Hashable {

        case fit
        case fill
        case fixed(UInt)

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .fit:
                try container.encode(SizeConstraintType.fit.rawValue, forKey: .type)
            case .fill:
                try container.encode(SizeConstraintType.fill.rawValue, forKey: .type)
            case .fixed(let value):
                try container.encode(SizeConstraintType.fixed.rawValue, forKey: .type)
                try container.encode(value, forKey: .value)
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(SizeConstraintType.self, forKey: .type)

            switch type {
            case .fit:
                self = .fit
            case .fill:
                self = .fill
            case .fixed:
                let value = try container.decode(UInt.self, forKey: .value)
                self = .fixed(value)
            }
        }

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {

            case type
            case value

        }

        // swiftlint:disable:next nesting
        private enum SizeConstraintType: String, Decodable {

            case fit
            case fill
            case fixed

        }

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

    enum TwoDimensionAlignment: String, Codable, Sendable, Hashable, Equatable {

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

    enum FontSize: String, Codable, Sendable, Hashable, Equatable {

        case headingXXL = "heading_xxl"
        case headingXL = "heading_xl"
        case headingL = "heading_l"
        case headingM = "heading_m"
        case headingS = "heading_s"
        case headingXS = "heading_xs"
        case bodyXL = "body_xl"
        case bodyL = "body_l"
        case bodyM = "body_m"
        case bodyS = "body_s"

    }

    enum FitMode: String, Codable, Sendable, Hashable, Equatable {

        case fit
        case fill

    }

    struct Shadow: Codable, Sendable, Hashable, Equatable {

        public let color: ColorScheme
        public let radius: CGFloat
        // swiftlint:disable:next identifier_name
        public let x: CGFloat
        // swiftlint:disable:next identifier_name
        public let y: CGFloat

        // swiftlint:disable:next identifier_name
        public init(color: ColorScheme, radius: CGFloat, x: CGFloat, y: CGFloat) {
            self.color = color
            self.radius = radius
            self.x = x
            self.y = y
        }

    }

    enum BadgeStyle: String, Codable, Sendable, Hashable, Equatable {

        case edgeToEdge = "edge_to_edge"
        case overlaid = "overlay"
        case nested = "nested"

    }

    final class Badge: Codable, Sendable, Hashable, Equatable {

        public let style: BadgeStyle
        public let alignment: TwoDimensionAlignment
        public let stack: StackComponent

        public init(style: BadgeStyle, alignment: TwoDimensionAlignment, stack: StackComponent) {
            self.style = style
            self.alignment = alignment
            self.stack = stack
        }

        public static func == (lhs: Badge, rhs: Badge) -> Bool {
            return lhs.style == rhs.style &&
                   lhs.alignment == rhs.alignment &&
                   lhs.stack == rhs.stack
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(style)
            hasher.combine(alignment)
            hasher.combine(stack)
        }

    }

}
