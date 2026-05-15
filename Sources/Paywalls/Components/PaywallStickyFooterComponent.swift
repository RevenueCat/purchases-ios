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

        public let id: String?
        public let name: String?
        public let stack: PaywallComponent.StackComponent

        public init(
            id: String? = nil,
            name: String? = nil,
            stack: PaywallComponent.StackComponent
        ) {
            self.id = id
            self.name = name
            self.stack = stack
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(name)
            hasher.combine(stack)
        }

        public static func == (lhs: StickyFooterComponent, rhs: StickyFooterComponent) -> Bool {
            return lhs.id == rhs.id &&
                   lhs.name == rhs.name &&
                   lhs.stack == rhs.stack
        }

    }

}
