//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallRootComponent.swift
//
//  Created by Jay Shortway on 24/10/2024.
//
// swiftlint:disable missing_docs

import Foundation

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    struct RootComponent: PaywallComponentBase {

        public let stack: PaywallComponent.StackComponent
        public let stickyFooter: PaywallComponent.StickyFooterComponent?

        public init(
            stack: PaywallComponent.StackComponent,
            stickyFooter: PaywallComponent.StickyFooterComponent?
        ) {
            self.stack = stack
            self.stickyFooter = stickyFooter
        }

    }

}

#endif
