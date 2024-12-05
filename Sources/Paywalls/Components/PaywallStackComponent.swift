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
// swiftlint:disable missing_docs

import Foundation

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    struct StackComponent: PaywallComponentBase {

        let type: ComponentType
        public let components: [PaywallComponent]
        public let size: Size
        public let spacing: CGFloat?
        public let backgroundColor: ColorScheme?
        public let dimension: Dimension
        public let padding: Padding
        public let margin: Padding
        public let shape: Shape?
        public let border: Border?
        public let shadow: Shadow?

        public let overrides: ComponentOverrides<PartialStackComponent>?

        public init(
            components: [PaywallComponent],
            dimension: Dimension = .vertical(.center, .start),
            size: Size = .init(width: .fill, height: .fit),
            spacing: CGFloat? = nil,
            backgroundColor: ColorScheme? = nil,
            padding: Padding = .zero,
            margin: Padding = .zero,
            shape: Shape? = nil,
            border: Border? = nil,
            shadow: Shadow? = nil,
            overrides: ComponentOverrides<PartialStackComponent>? = nil
        ) {
            self.components = components
            self.size = size
            self.spacing = spacing
            self.backgroundColor = backgroundColor
            self.type = .stack
            self.dimension = dimension
            self.padding = padding
            self.margin = margin
            self.shape = shape
            self.border = border
            self.shadow = shadow
            self.overrides = overrides
        }

    }

    struct PartialStackComponent: PartialComponent {

        public let visible: Bool?
        public let size: Size?
        public let spacing: CGFloat?
        public let backgroundColor: ColorScheme?
        public let dimension: Dimension?
        public let padding: Padding?
        public let margin: Padding?
        public let shape: Shape?
        public let border: Border?
        public let shadow: Shadow?

        public init(
            visible: Bool? = true,
            dimension: Dimension? = nil,
            size: Size? = nil,
            spacing: CGFloat? = nil,
            backgroundColor: ColorScheme? = nil,
            padding: Padding? = nil,
            margin: Padding? = nil,
            shape: Shape? = nil,
            border: Border? = nil,
            shadow: Shadow? = nil
        ) {
            self.visible = visible
            self.size = size
            self.spacing = spacing
            self.backgroundColor = backgroundColor
            self.dimension = dimension
            self.padding = padding
            self.margin = margin
            self.shape = shape
            self.border = border
            self.shadow = shadow
        }

    }

}

#endif
