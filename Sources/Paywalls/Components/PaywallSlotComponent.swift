//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallButtonComponent.swift
//
//  Created by Jay Shortway on 02/10/2024.
//
// swiftlint:disable missing_docs nesting

import Foundation

public extension PaywallComponent {

    final class SlotComponent: PaywallComponentBase {

        let type: ComponentType

        public let visible: Bool?
        public let identifier: String
        public let size: Size?
        public let padding: Padding?
        public let margin: Padding?

        public let overrides: ComponentOverrides<PartialSlotComponent>?

        public init(
            identifier: String,
            visible: Bool? = nil,
            size: PaywallComponent.Size? = nil,
            padding: PaywallComponent.Padding? = .zero,
            margin: PaywallComponent.Padding? = .zero,
            overrides: ComponentOverrides<PartialSlotComponent>? = nil
        ) {
            self.type = .slot
            self.visible = visible
            self.identifier = identifier
            self.size = size
            self.padding = padding
            self.margin = margin
            self.overrides = overrides
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(visible)
            hasher.combine(identifier)
            hasher.combine(size)
            hasher.combine(padding)
            hasher.combine(margin)
            hasher.combine(overrides)
        }

        public static func == (lhs: SlotComponent, rhs: SlotComponent) -> Bool {
            return lhs.type == rhs.type &&
                   lhs.visible == rhs.visible &&
                   lhs.identifier == rhs.identifier &&
                   lhs.size == rhs.size &&
                   lhs.padding == rhs.padding &&
                   lhs.margin == rhs.margin &&
                   lhs.overrides == rhs.overrides
        }

    }

    final class PartialSlotComponent: PaywallPartialComponent {

        public let visible: Bool?
        public let size: Size?
        public let padding: Padding?
        public let margin: Padding?

        public init(
            visible: Bool? = true,
            size: Size? = nil,
            padding: Padding? = nil,
            margin: Padding? = nil,
        ) {
            self.visible = visible
            self.size = size
            self.padding = padding
            self.margin = margin
        }

        private enum CodingKeys: String, CodingKey {
            case visible
            case size
            case padding
            case margin
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(visible)
            hasher.combine(size)
            hasher.combine(padding)
            hasher.combine(margin)
        }

        public static func == (lhs: PartialSlotComponent, rhs: PartialSlotComponent) -> Bool {
            return lhs.visible == rhs.visible &&
                   lhs.size == rhs.size &&
                   lhs.padding == rhs.padding &&
                   lhs.margin == rhs.margin
        }
    }

}
