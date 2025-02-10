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

    final class NavigationBarComponent: PaywallComponentBase {

        public let leadingStack: PaywallComponent.StackComponent?
        public let trailingStack: PaywallComponent.StackComponent?

        public init(
            leadingStack: PaywallComponent.StackComponent? = nil,
            trailingStack: PaywallComponent.StackComponent? = nil
        ) {
            self.leadingStack = leadingStack
            self.trailingStack = trailingStack
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(leadingStack)
            hasher.combine(trailingStack)
        }

        public static func == (lhs: NavigationBarComponent, rhs: NavigationBarComponent) -> Bool {
            return lhs.leadingStack == rhs.leadingStack &&
                   lhs.trailingStack == rhs.trailingStack
        }
        }

}
