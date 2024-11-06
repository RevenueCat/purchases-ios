//
//  File.swift
//  
//
//  Created by Josh Holtz on 6/12/24.
//
// swiftlint:disable missing_docs

import Foundation

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    struct PurchaseButtonComponent: PaywallComponentBase {

        let type: ComponentType
        public let stack: PaywallComponent.StackComponent

        public init(
            stack: PaywallComponent.StackComponent
        ) {
            self.type = .button
            self.stack = stack
        }

    }

}

#endif
