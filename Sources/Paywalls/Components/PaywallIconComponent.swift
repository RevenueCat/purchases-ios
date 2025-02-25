//
//  PaywallIconComponent.swift
//
//
//  Created by Josh Holtz on 1/12/24.
//
// swiftlint:disable missing_docs nesting

import Foundation

public extension PaywallComponent {

    final class IconComponent: PaywallComponentBase {

        final public class Formats: Codable, Sendable, Hashable, Equatable {

            public let svg: String
            public let png: String
            public let heic: String
            public let webp: String

            public init(svg: String,
                        png: String,
                        heic: String,
                        webp: String) {
                self.svg = svg
                self.png = png
                self.heic = heic
                self.webp = webp
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(svg)
                hasher.combine(png)
                hasher.combine(heic)
                hasher.combine(webp)
            }

            public static func == (lhs: Formats, rhs: Formats) -> Bool {
                return lhs.svg == rhs.svg &&
                       lhs.png == rhs.png &&
                       lhs.heic == rhs.heic &&
                       lhs.webp == rhs.webp
            }
        }

        final public class IconBackground: Codable, Sendable, Hashable, Equatable {

            public let color: ColorScheme
            public let shape: IconBackgroundShape
            public let border: Border?
            public let shadow: Shadow?

            public init(color: PaywallComponent.ColorScheme,
                        shape: IconBackgroundShape,
                        border: PaywallComponent.Border? = nil,
                        shadow: PaywallComponent.Shadow? = nil) {
                self.color = color
                self.shape = shape
                self.border = border
                self.shadow = shadow
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(color)
                hasher.combine(shape)
                hasher.combine(border)
                hasher.combine(shadow)
            }

            public static func == (lhs: IconBackground, rhs: IconBackground) -> Bool {
                return lhs.color == rhs.color &&
                       lhs.shape == rhs.shape &&
                       lhs.border == rhs.border &&
                       lhs.shadow == rhs.shadow
            }
        }

        let type: ComponentType
        public let visible: Bool?
        public let baseUrl: String
        public let iconName: String
        public let formats: Formats
        public let size: Size
        public let padding: Padding?
        public let margin: Padding?
        public let color: ColorScheme
        public let iconBackground: IconBackground?

        public let overrides: ComponentOverrides<PartialIconComponent>?

        public init(
            visible: Bool? = nil,
            baseUrl: String,
            iconName: String,
            formats: Formats,
            size: Size,
            padding: Padding?,
            margin: Padding?,
            color: ColorScheme,
            iconBackground: IconBackground?,
            overrides: ComponentOverrides<PartialIconComponent>? = nil
        ) {
            self.type = .image
            self.visible = visible
            self.baseUrl = baseUrl
            self.iconName = iconName
            self.formats = formats
            self.size = size
            self.padding = padding
            self.margin = margin
            self.color = color
            self.iconBackground = iconBackground
            self.overrides = overrides
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(visible)
            hasher.combine(baseUrl)
            hasher.combine(iconName)
            hasher.combine(formats)
            hasher.combine(size)
            hasher.combine(padding)
            hasher.combine(margin)
            hasher.combine(color)
            hasher.combine(iconBackground)
            hasher.combine(overrides)
        }

        public static func == (lhs: IconComponent, rhs: IconComponent) -> Bool {
            return lhs.type == rhs.type &&
                   lhs.visible == rhs.visible &&
                   lhs.baseUrl == rhs.baseUrl &&
                   lhs.iconName == rhs.iconName &&
                   lhs.formats == rhs.formats &&
                   lhs.size == rhs.size &&
                   lhs.padding == rhs.padding &&
                   lhs.margin == rhs.margin &&
                   lhs.color == rhs.color &&
                   lhs.iconBackground == rhs.iconBackground &&
                   lhs.overrides == rhs.overrides
        }
    }

    final class PartialIconComponent: PaywallPartialComponent {

        public let visible: Bool?
        public let baseUrl: String?
        public let iconName: String?
        public let formats: IconComponent.Formats?
        public let size: Size?
        public let padding: Padding?
        public let margin: Padding?
        public let color: ColorScheme?
        public let iconBackground: IconComponent.IconBackground?

        public init(
            visible: Bool? = true,
            baseUrl: String? = nil,
            iconName: String? = nil,
            formats: IconComponent.Formats? = nil,
            size: Size? = nil,
            padding: Padding? = nil,
            margin: Padding? = nil,
            color: ColorScheme? = nil,
            iconBackground: IconComponent.IconBackground? = nil
        ) {
            self.visible = visible
            self.baseUrl = baseUrl
            self.iconName = iconName
            self.formats = formats
            self.size = size
            self.padding = padding
            self.margin = margin
            self.color = color
            self.iconBackground = iconBackground
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(visible)
            hasher.combine(baseUrl)
            hasher.combine(iconName)
            hasher.combine(formats)
            hasher.combine(size)
            hasher.combine(padding)
            hasher.combine(margin)
            hasher.combine(color)
            hasher.combine(iconBackground)
        }

        public static func == (lhs: PartialIconComponent, rhs: PartialIconComponent) -> Bool {
            return lhs.visible == rhs.visible &&
                   lhs.baseUrl == rhs.baseUrl &&
                   lhs.iconName == rhs.iconName &&
                   lhs.formats == rhs.formats &&
                   lhs.size == rhs.size &&
                   lhs.padding == rhs.padding &&
                   lhs.margin == rhs.margin &&
                   lhs.color == rhs.color &&
                   lhs.iconBackground == rhs.iconBackground
        }
    }

}
