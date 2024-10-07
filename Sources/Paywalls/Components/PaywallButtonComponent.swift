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

        // swiftlint:disable:next nesting
        public enum Action: Codable, Sendable, Hashable, Equatable {
            case restorePurchases
            case navigateTo(destination: Destination)
            case navigateBack
        }

        // swiftlint:disable:next nesting
        public enum Destination: Codable, Sendable, Hashable, Equatable {
            case customerCenter
            case URL(urlLid: String, method: URLMethod)
            case privacyPolicy(urlLid: String, method: URLMethod)
            case terms(urlLid: String, method: URLMethod)
        }

        // swiftlint:disable:next nesting
        public enum URLMethod: Codable, Sendable, Hashable, Equatable {
            case inAppBrowser
            case externalBrowser
            case deepLink
        }

        let type: ComponentType
        public let action: Action
        public let stack: PaywallComponent.StackComponent

        public init(
            action: Action,
            stack: PaywallComponent.StackComponent
        ) {
            self.type = .button
            self.action = action
            self.stack = stack
        }

    }

}

#endif
