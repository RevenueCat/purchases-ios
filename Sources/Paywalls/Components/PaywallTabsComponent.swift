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

    final class TabControlButtonComponent: Codable, Sendable, Hashable, Equatable {

        let type: ComponentType
        public let tabIndex: Int
        public let stack: StackComponent

        public init(tabIndex: Int, stack: StackComponent) {
            self.type = .tabControlButton
            self.tabIndex = tabIndex
            self.stack = stack
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(tabIndex)
            hasher.combine(stack)
        }

        public static func == (lhs: TabControlButtonComponent, rhs: TabControlButtonComponent) -> Bool {
            return lhs.type == rhs.type && lhs.tabIndex == rhs.tabIndex && lhs.stack == rhs.stack
        }
    }

    final class TabControlToggleComponent: Codable, Sendable, Hashable, Equatable {

        let type: ComponentType
        public let defaultValue: Bool
        public let thumbColorOn: ColorScheme
        public let thumbColorOff: ColorScheme
        public let trackColorOn: ColorScheme
        public let trackColorOff: ColorScheme

        public init(defaultValue: Bool,
                    thumbColorOn: ColorScheme,
                    thumbColorOff: ColorScheme,
                    trackColorOn: ColorScheme,
                    trackColorOff: ColorScheme) {
            self.type = .tabControlToggle
            self.defaultValue = defaultValue
            self.thumbColorOn = thumbColorOn
            self.thumbColorOff = thumbColorOff
            self.trackColorOn = trackColorOn
            self.trackColorOff = trackColorOff
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(defaultValue)
            hasher.combine(thumbColorOn)
            hasher.combine(thumbColorOff)
            hasher.combine(trackColorOn)
            hasher.combine(trackColorOff)
        }

        public static func == (lhs: TabControlToggleComponent, rhs: TabControlToggleComponent) -> Bool {
            return lhs.type == rhs.type &&
                   lhs.defaultValue == rhs.defaultValue &&
                   lhs.thumbColorOn == rhs.thumbColorOn &&
                   lhs.thumbColorOff == rhs.thumbColorOff &&
                   lhs.trackColorOn == rhs.trackColorOn &&
                   lhs.trackColorOff == rhs.trackColorOff
        }
    }

    final class TabControlComponent: Codable, Sendable, Hashable, Equatable {

        let type: ComponentType

        public init() {
            self.type = .tabControl
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
        }

        public static func == (lhs: TabControlComponent, rhs: TabControlComponent) -> Bool {
            return lhs.type == rhs.type
        }
    }

    final class TabsComponent: PaywallComponentBase {

        final public class Tab: Codable, Sendable, Hashable, Equatable {

            public let stack: StackComponent

            public init(stack: PaywallComponent.StackComponent) {
                self.stack = stack
            }

            public func hash(into hasher: inout Hasher) {
                hasher.combine(stack)
            }

            public static func == (lhs: Tab, rhs: Tab) -> Bool {
                return lhs.stack == rhs.stack
            }
        }

        final public class TabControl: Codable, Sendable, Hashable, Equatable {

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

            public func hash(into hasher: inout Hasher) {
                hasher.combine(type)
                hasher.combine(stack)
            }

            public static func == (lhs: TabControl, rhs: TabControl) -> Bool {
                return lhs.type == rhs.type && lhs.stack == rhs.stack
            }
        }

        let type: ComponentType
        public let visible: Bool?
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
            visible: Bool? = nil,
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
            self.visible = visible
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

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(visible)
            hasher.combine(size)
            hasher.combine(padding)
            hasher.combine(margin)
            hasher.combine(backgroundColor)
            hasher.combine(shape)
            hasher.combine(border)
            hasher.combine(shadow)
            hasher.combine(control)
            hasher.combine(tabs)
            hasher.combine(overrides)
        }

        public static func == (lhs: TabsComponent, rhs: TabsComponent) -> Bool {
            return lhs.type == rhs.type &&
                   lhs.visible == rhs.visible &&
                   lhs.size == rhs.size &&
                   lhs.padding == rhs.padding &&
                   lhs.margin == rhs.margin &&
                   lhs.backgroundColor == rhs.backgroundColor &&
                   lhs.shape == rhs.shape &&
                   lhs.border == rhs.border &&
                   lhs.shadow == rhs.shadow &&
                   lhs.control == rhs.control &&
                   lhs.tabs == rhs.tabs &&
                   lhs.overrides == rhs.overrides
        }
    }

    final class PartialTabsComponent: PaywallPartialComponent {

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

        public func hash(into hasher: inout Hasher) {
            hasher.combine(visible)
            hasher.combine(size)
            hasher.combine(padding)
            hasher.combine(margin)
            hasher.combine(backgroundColor)
            hasher.combine(shape)
            hasher.combine(border)
            hasher.combine(shadow)
        }

        public static func == (lhs: PartialTabsComponent, rhs: PartialTabsComponent) -> Bool {
            return lhs.visible == rhs.visible &&
                   lhs.size == rhs.size &&
                   lhs.padding == rhs.padding &&
                   lhs.margin == rhs.margin &&
                   lhs.backgroundColor == rhs.backgroundColor &&
                   lhs.shape == rhs.shape &&
                   lhs.border == rhs.border &&
                   lhs.shadow == rhs.shadow
        }
    }

}
