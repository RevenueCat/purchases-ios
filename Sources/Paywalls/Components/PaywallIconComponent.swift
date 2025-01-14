//
//  PaywallIconComponent.swift
//
//
//  Created by Josh Holtz on 1/12/24.
//
// swiftlint:disable missing_docs

import Foundation

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    struct IconComponent: PaywallComponentBase {

        // swiftlint:disable:next nesting
        public struct Formats: PaywallComponentBase {

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

        }

        // swiftlint:disable:next nesting
        public struct IconBackground: PaywallComponentBase {

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

        }

        let type: ComponentType
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

    }

    struct PartialIconComponent: PartialComponent {

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

    }

}

#endif
