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

    struct TabControlButtonComponent: PaywallComponentBase {
        let type: ComponentType

        public let tabIndex: Int
        public let stack: StackComponent

        public init(tabIndex: Int, stack: StackComponent) {
            self.type = .tabControlButton
            self.tabIndex = tabIndex
            self.stack = stack
        }
    }

    struct TabControlToggleComponent: PaywallComponentBase {
        let type: ComponentType

        public let thumbColorOn: ColorScheme
        public let thumbColorOff: ColorScheme
        public let trackColorOn: ColorScheme
        public let trackColorOff: ColorScheme

        public init(thumbColorOn: ColorScheme,
                    thumbColorOff: ColorScheme,
                    trackColorOn: ColorScheme,
                    trackColorOff: ColorScheme) {
            self.type = .tabControlToggle
            self.thumbColorOn = thumbColorOn
            self.thumbColorOff = thumbColorOff
            self.trackColorOn = trackColorOn
            self.trackColorOff = trackColorOff
        }
    }

    struct TabControlComponent: PaywallComponentBase {
        let type: ComponentType

        public init() {
            self.type = .tabControl
        }
    }

    struct TabsComponent: PaywallComponentBase {

        // swiftlint:disable:next nesting
        public struct Tab: PaywallComponentBase {

            public let stack: StackComponent

            public init(stack: PaywallComponent.StackComponent) {
                self.stack = stack
            }

        }

        // swiftlint:disable:next nesting
        public struct TabControl: Codable, Sendable, Hashable, Equatable {

            // swiftlint:disable:next nesting
            public enum TabControlType: Codable, Sendable, Hashable, Equatable {
                case buttons
                case toggle
            }

            public let type: TabControlType
            public let stack: StackComponent

            public init(type: PaywallComponent.TabsComponent.TabControl.TabControlType,
                        stack: PaywallComponent.StackComponent) {
                self.type = type
                self.stack = stack
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

        public let control: TabControl
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

            control: TabControl,
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

            self.control = control
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
