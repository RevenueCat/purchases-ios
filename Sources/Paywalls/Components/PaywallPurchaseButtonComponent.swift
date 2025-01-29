//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/12/24.
//
// swiftlint:disable missing_docs

import Foundation

public extension PaywallComponent {

    final class PurchaseButtonComponent: PaywallComponentBase {

        let type: ComponentType
        public let stack: PaywallComponent.StackComponent

        public init(
            stack: PaywallComponent.StackComponent
        ) {
            self.type = .button
            self.stack = stack
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(stack)
        }

        public static func == (lhs: PurchaseButtonComponent, rhs: PurchaseButtonComponent) -> Bool {
            return lhs.type == rhs.type && lhs.stack == rhs.stack
        }
    }

}
