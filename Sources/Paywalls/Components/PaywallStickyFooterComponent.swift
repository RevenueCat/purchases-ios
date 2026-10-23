//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallStickyFooterComponent.swift
//
//  Created by Jay Shortway on 24/10/2024.
//
// swiftlint:disable missing_docs

import Foundation

@_spi(Internal) public extension PaywallComponent {

    final class StickyFooterComponent: PaywallComponentBase {

        // swiftlint:disable:next nesting
        @_spi(Internal) public enum Layout: String, PaywallComponentBase {
            case normal
            case hidden
            case splitLeading = "split_leading"
            case splitTrailing = "split_trailing"

            public init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                self = Self(rawValue: (try? container.decode(String.self)) ?? "") ?? .normal
            }
        }

        public let layout: Layout?
        public let overrides: ComponentOverrides<PartialStickyFooterComponent>?
        public let stack: PaywallComponent.StackComponent

        public init(
            stack: PaywallComponent.StackComponent,
            layout: Layout? = nil,
            overrides: ComponentOverrides<PartialStickyFooterComponent>? = nil
        ) {
            self.stack = stack
            self.layout = layout
            self.overrides = overrides
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(stack)
            hasher.combine(layout)
            hasher.combine(overrides)
        }

        public static func == (lhs: StickyFooterComponent, rhs: StickyFooterComponent) -> Bool {
            return lhs.stack == rhs.stack && lhs.layout == rhs.layout && lhs.overrides == rhs.overrides
        }

    }

    final class PartialStickyFooterComponent: PaywallPartialComponent {
        public let layout: StickyFooterComponent.Layout?

        public init(layout: StickyFooterComponent.Layout? = nil) {
            self.layout = layout
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(layout)
        }

        public static func == (lhs: PartialStickyFooterComponent, rhs: PartialStickyFooterComponent) -> Bool {
            return lhs.layout == rhs.layout
        }
    }

}
