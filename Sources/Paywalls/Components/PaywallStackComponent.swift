//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StackComponent.swift
//
//  Created by James Borthwick on 2024-08-20.
// swiftlint:disable missing_docs nesting

import Foundation

public extension PaywallComponent {

    final class StackComponent: PaywallComponentBase {

        public enum Overflow: PaywallComponentBase {
            case `default`
            case scroll
        }

        let type: ComponentType
        public let visible: Bool?
        public let components: [PaywallComponent]
        public let size: Size
        public let spacing: CGFloat?
        public let backgroundColor: ColorScheme?
        public let background: Background?
        public let dimension: Dimension
        public let padding: Padding
        public let margin: Padding
        public let shape: Shape?
        public let border: Border?
        public let shadow: Shadow?
        public let badge: Badge?
        public let overflow: Overflow?

        public let overrides: ComponentOverrides<PartialStackComponent>?

        public init(
            visible: Bool? = nil,
            components: [PaywallComponent],
            dimension: Dimension = .vertical(.center, .start),
            size: Size = .init(width: .fill, height: .fit),
            spacing: CGFloat? = nil,
            backgroundColor: ColorScheme? = nil,
            background: Background? = nil,
            padding: Padding = .zero,
            margin: Padding = .zero,
            shape: Shape? = nil,
            border: Border? = nil,
            shadow: Shadow? = nil,
            badge: Badge? = nil,
            overflow: Overflow? = nil,
            overrides: ComponentOverrides<PartialStackComponent>? = nil
        ) {
            self.visible = visible
            self.components = components
            self.size = size
            self.spacing = spacing
            self.backgroundColor = backgroundColor
            self.background = background
            self.type = .stack
            self.dimension = dimension
            self.padding = padding
            self.margin = margin
            self.shape = shape
            self.border = border
            self.shadow = shadow
            self.badge = badge
            self.overflow = overflow
            self.overrides = overrides
        }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(visible)
            hasher.combine(components)
            hasher.combine(size)
            hasher.combine(spacing)
            hasher.combine(backgroundColor)
            hasher.combine(background)
            hasher.combine(dimension)
            hasher.combine(padding)
            hasher.combine(margin)
            hasher.combine(shape)
            hasher.combine(border)
            hasher.combine(shadow)
            hasher.combine(badge)
            hasher.combine(overflow)
            hasher.combine(overrides)
        }

        public static func == (lhs: StackComponent, rhs: StackComponent) -> Bool {
            return lhs.type == rhs.type &&
                   lhs.visible == rhs.visible &&
                   lhs.components == rhs.components &&
                   lhs.size == rhs.size &&
                   lhs.spacing == rhs.spacing &&
                   lhs.backgroundColor == rhs.backgroundColor &&
                   lhs.background == rhs.background &&
                   lhs.dimension == rhs.dimension &&
                   lhs.padding == rhs.padding &&
                   lhs.margin == rhs.margin &&
                   lhs.shape == rhs.shape &&
                   lhs.border == rhs.border &&
                   lhs.shadow == rhs.shadow &&
                   lhs.badge == rhs.badge &&
                   lhs.overflow == rhs.overflow &&
                   lhs.overrides == rhs.overrides
        }
    }

    final class PartialStackComponent: PaywallPartialComponent {

        public let visible: Bool?
        public let size: Size?
        public let spacing: CGFloat?
        public let backgroundColor: ColorScheme?
        public let background: Background?
        public let dimension: Dimension?
        public let padding: Padding?
        public let margin: Padding?
        public let shape: Shape?
        public let border: Border?
        public let shadow: Shadow?
        public let overflow: PaywallComponent.StackComponent.Overflow?
        public let badge: Badge?

        public init(
            visible: Bool? = true,
            dimension: Dimension? = nil,
            size: Size? = nil,
            spacing: CGFloat? = nil,
            backgroundColor: ColorScheme? = nil,
            background: Background? = nil,
            padding: Padding? = nil,
            margin: Padding? = nil,
            shape: Shape? = nil,
            border: Border? = nil,
            shadow: Shadow? = nil,
            overflow: PaywallComponent.StackComponent.Overflow? = nil,
            badge: Badge? = nil
        ) {
            self.visible = visible
            self.size = size
            self.spacing = spacing
            self.backgroundColor = backgroundColor
            self.background = background
            self.dimension = dimension
            self.padding = padding
            self.margin = margin
            self.shape = shape
            self.border = border
            self.shadow = shadow
            self.overflow = overflow
            self.badge = badge
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(visible)
            hasher.combine(size)
            hasher.combine(spacing)
            hasher.combine(backgroundColor)
            hasher.combine(background)
            hasher.combine(dimension)
            hasher.combine(padding)
            hasher.combine(margin)
            hasher.combine(shape)
            hasher.combine(border)
            hasher.combine(shadow)
            hasher.combine(overflow)
            hasher.combine(badge)
        }

        public static func == (lhs: PartialStackComponent, rhs: PartialStackComponent) -> Bool {
            return lhs.visible == rhs.visible &&
                   lhs.size == rhs.size &&
                   lhs.spacing == rhs.spacing &&
                   lhs.backgroundColor == rhs.backgroundColor &&
                   lhs.background == rhs.background &&
                   lhs.dimension == rhs.dimension &&
                   lhs.padding == rhs.padding &&
                   lhs.margin == rhs.margin &&
                   lhs.shape == rhs.shape &&
                   lhs.border == rhs.border &&
                   lhs.shadow == rhs.shadow &&
                   lhs.overflow == rhs.overflow &&
                   lhs.badge == rhs.badge
        }
    }

}
