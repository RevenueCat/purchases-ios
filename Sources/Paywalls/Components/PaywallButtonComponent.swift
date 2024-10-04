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
// swiftlint:disable missing_docs

import Foundation

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    struct ButtonComponent: PaywallComponentBase {

        let type: ComponentType
        public let text: PaywallComponent.TextComponent

        public init(
            text: PaywallComponent.TextComponent
        ) {
            self.type = .button
            self.text = text
        }

    }

}

#endif
