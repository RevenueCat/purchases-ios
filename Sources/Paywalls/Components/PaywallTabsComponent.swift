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

    struct TabControlComponent: PaywallComponentBase {
        let type: ComponentType

        public init() {
            self.type = .tabControl
        }
    }

    struct TabsComponent: PaywallComponentBase {

        // swiftlint:disable:next nesting
        public struct Tab: PaywallComponentBase {

            public let tabStack: StackComponent
            public let contentStack: StackComponent
            
            public init(tabStack: PaywallComponent.StackComponent, contentStack: PaywallComponent.StackComponent) {
                self.tabStack = tabStack
                self.contentStack = contentStack
            }
            
        }

        let type: ComponentType
        public let size: Size
        public let padding: Padding
        public let margin: Padding
        public let backgroundColor: ColorScheme?
        public let shape: Shape?
        public let border: Border?
        public let shadow: Shadow?

        public let controlStack: StackComponent
        public let tabs: [Tab]

        public let overrides: ComponentOverrides<PartialTabsComponent>?

        public init(
            size: Size = .init(width: .fill, height: .fit),
            padding: Padding = .zero,
            margin: Padding = .zero,
            backgroundColor: ColorScheme? = nil,
            shape: Shape? = nil,
            border: Border? = nil,
            shadow: Shadow? = nil,

            controlStack: StackComponent,
            tabs: [Tab],

            overrides: ComponentOverrides<PartialTabsComponent>? = nil
        ) {
            self.type = .stack
            self.size = size
            self.padding = padding
            self.margin = margin
            self.backgroundColor = backgroundColor
            self.shape = shape
            self.border = border
            self.shadow = shadow

            self.controlStack = controlStack
            self.tabs = tabs

            self.overrides = overrides
        }

    }

    struct PartialTabsComponent: PartialComponent {

        public let visible: Bool?
        public let size: Size?
        public let padding: Padding?
        public let margin: Padding?
        public let backgroundColor: ColorScheme?
        public let shape: Shape?
        public let border: Border?
        public let shadow: Shadow?

        public init(
            visible: Bool? = true,
            size: Size? = nil,
            padding: Padding? = nil,
            margin: Padding? = nil,
            backgroundColor: ColorScheme? = nil,
            shape: Shape? = nil,
            border: Border? = nil,
            shadow: Shadow? = nil
        ) {
            self.visible = visible
            self.size = size
            self.padding = padding
            self.margin = margin
            self.backgroundColor = backgroundColor
            self.shape = shape
            self.border = border
            self.shadow = shadow
        }

    }

}

#endif
