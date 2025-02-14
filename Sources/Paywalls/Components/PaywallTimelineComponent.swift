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

// swiftlint:disable missing_docs nesting
public extension PaywallComponent {

    final class TimelineComponent: PaywallComponentBase {

        let type: ComponentType
        public let visible: Bool?
        public let iconAlignment: IconAlignment?
        public let itemSpacing: CGFloat?
        public let textSpacing: CGFloat?
        public let columnGutter: CGFloat?
        public let size: Size
        public let padding: Padding
        public let margin: Padding
        public let items: [Item]

        public let overrides: ComponentOverrides<PartialTimelineComponent>?

        public init(
            visible: Bool? = nil,
            iconAlignment: IconAlignment?,
            itemSpacing: CGFloat?,
            textSpacing: CGFloat?,
            columnGutter: CGFloat?,
            size: Size,
            padding: Padding,
            margin: Padding,
            items: [Item],
            overrides: ComponentOverrides<PartialTimelineComponent>?
        ) {
            self.type = .timeline
            self.visible = visible
            self.iconAlignment = iconAlignment
            self.itemSpacing = itemSpacing
            self.textSpacing = textSpacing
            self.columnGutter = columnGutter
            self.size = size
            self.padding = padding
            self.margin = margin
            self.items = items
            self.overrides = overrides
        }

        public static func == (
            lhs: PaywallComponent.TimelineComponent,
            rhs: PaywallComponent.TimelineComponent
        ) -> Bool {
            return lhs.iconAlignment == rhs.iconAlignment &&
                   lhs.visible == rhs.visible &&
                   lhs.itemSpacing == rhs.itemSpacing &&
                   lhs.textSpacing == rhs.textSpacing &&
                   lhs.columnGutter == rhs.columnGutter &&
                   lhs.size == rhs.size &&
                   lhs.padding == rhs.padding &&
                   lhs.margin == rhs.margin &&
                   lhs.items == rhs.items
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(visible)
            hasher.combine(iconAlignment)
            hasher.combine(itemSpacing)
            hasher.combine(textSpacing)
            hasher.combine(columnGutter)
            hasher.combine(size)
            hasher.combine(padding)
            hasher.combine(margin)
            hasher.combine(items)
        }

        public final class Item: Codable, Sendable, Hashable, Equatable {

            public let title: TextComponent
            public let description: TextComponent?
            public let icon: IconComponent
            public let connector: Connector?

            public init(title: TextComponent,
                        description: TextComponent?,
                        icon: IconComponent,
                        connector: Connector) {
                self.title = title
                self.description = description
                self.icon = icon
                self.connector = connector
            }

            public static func == (lhs: PaywallComponent.TimelineComponent.Item,
                                   rhs: PaywallComponent.TimelineComponent.Item) -> Bool {
                return lhs.title == rhs.title &&
                lhs.description == rhs.description &&
                lhs.icon == rhs.icon &&
                lhs.connector == rhs.connector
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(title)
                hasher.combine(description)
                hasher.combine(icon)
                hasher.combine(connector)
            }

        }

        public final class Connector: Codable, Sendable, Hashable, Equatable {

            public let width: CGFloat
            public let color: ColorScheme
            public let margin: Padding

            public init(width: CGFloat, color: ColorScheme, margin: Padding) {
                self.width = width
                self.color = color
                self.margin = margin
            }

            public static func == (lhs: PaywallComponent.TimelineComponent.Connector,
                                   rhs: PaywallComponent.TimelineComponent.Connector) -> Bool {
                return lhs.color == rhs.color &&
                    lhs.width == rhs.width &&
                    lhs.margin == rhs.margin
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(color)
                hasher.combine(width)
                hasher.combine(margin)
            }
        }

        public enum IconAlignment: String, Sendable, Codable, Equatable, Hashable {
            case title = "title"
            case titleAndDescription = "title_and_description"
        }
    }

    final class PartialTimelineComponent: PaywallPartialComponent {

        public let visible: Bool?
        public let iconAlignment: PaywallComponent.TimelineComponent.IconAlignment?
        public let itemSpacing: CGFloat?
        public let textSpacing: CGFloat?
        public let columnGutter: CGFloat?
        public let size: Size?
        public let padding: Padding?
        public let margin: Padding?

        public init(
            visible: Bool? = nil,
            iconAlignment: PaywallComponent.TimelineComponent.IconAlignment?,
            itemSpacing: CGFloat?,
            textSpacing: CGFloat?,
            columnGutter: CGFloat?,
            size: Size?,
            padding: Padding?,
            margin: Padding?
        ) {
            self.visible = visible
            self.iconAlignment = iconAlignment
            self.itemSpacing = itemSpacing
            self.textSpacing = textSpacing
            self.columnGutter = columnGutter
            self.size = size
            self.padding = padding
            self.margin = margin
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(visible)
            hasher.combine(iconAlignment)
            hasher.combine(itemSpacing)
            hasher.combine(textSpacing)
            hasher.combine(columnGutter)
            hasher.combine(size)
            hasher.combine(padding)
            hasher.combine(margin)
        }

        public static func == (
            lhs: PartialTimelineComponent,
            rhs: PartialTimelineComponent
        ) -> Bool {
            return lhs.iconAlignment == rhs.iconAlignment &&
                   lhs.visible == rhs.visible &&
                   lhs.itemSpacing == rhs.itemSpacing &&
                   lhs.textSpacing == rhs.textSpacing &&
                   lhs.columnGutter == rhs.columnGutter &&
                   lhs.size == rhs.size &&
                   lhs.padding == rhs.padding &&
                   lhs.margin == rhs.margin
        }

    }

}
