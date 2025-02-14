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

public extension PaywallComponent {

    final class StickyFooterComponent: PaywallComponentBase {

        public let stack: PaywallComponent.StackComponent

        public init(
            stack: PaywallComponent.StackComponent
        ) {
            self.stack = stack
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(stack)
        }

        public static func == (lhs: StickyFooterComponent, rhs: StickyFooterComponent) -> Bool {
            return lhs.stack == rhs.stack
        }

    }

}
