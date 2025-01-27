//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallTimelineComponent.swift
//
//  Created by mark on 15/1/25.

import Foundation

#if PAYWALL_COMPONENTS

// swiftlint:disable missing_docs nesting
public extension PaywallComponent {

    struct TimelineComponent: PaywallComponentBase, Equatable, Hashable {
        let type: ComponentType
        public let iconAlignment: IconAlignment?
        public let itemSpacing: CGFloat?
        public let textSpacing: CGFloat?
        public let columnGutter: CGFloat?
        public let size: Size
        public let padding: Padding
        public let margin: Padding
        public let items: [Item]

        public init(iconAlignment: IconAlignment?,
                    itemSpacing: CGFloat?,
                    textSpacing: CGFloat?,
                    columnGutter: CGFloat?,
                    size: Size,
                    padding: Padding,
                    margin: Padding,
                    items: [Item]) {
            self.type = .timeline
            self.iconAlignment = iconAlignment
            self.itemSpacing = itemSpacing
            self.textSpacing = textSpacing
            self.columnGutter = columnGutter
            self.size = size
            self.padding = padding
            self.margin = margin
            self.items = items
        }

        public struct Item: Codable, Sendable, Equatable, Hashable {
            public let text: TextComponent
            public let description: TextComponent?
            public let icon: IconComponent
            public let connector: Connector?

            public init(text: TextComponent, description: TextComponent?, icon: IconComponent, connector: Connector) {
                self.text = text
                self.description = description
                self.icon = icon
                self.connector = connector
            }
        }

        public struct Connector: Codable, Sendable, Equatable, Hashable {
            public let width: CGFloat
            public let color: ColorScheme
            public let margin: Padding

            public init(width: CGFloat, color: ColorScheme, margin: Padding) {
                self.width = width
                self.color = color
                self.margin = margin
            }
        }

        public enum IconAlignment: String, Sendable, Codable, Equatable, Hashable {
            case title = "title"
            case titleAndDescription = "title_and_description"
        }
    }

}

#endif
