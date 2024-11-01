//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ComponentOverrides.swift
//
//  Created by Josh Holtz on 10/26/24.
//
// swiftlint:disable missing_docs

import Foundation

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    protocol PartialComponent: PaywallComponentBase {}

    struct ComponentOverrides<T: PartialComponent>: PaywallComponentBase {

        public init(
            introOffer: T? = nil,
            states: PaywallComponent.ComponentStates<T>? = nil,
            conditions: PaywallComponent.ComponentConditions<T>? = nil
        ) {
            self.introOffer = introOffer
            self.states = states
            self.conditions = conditions
        }

        public let introOffer: T?
        public let states: ComponentStates<T>?
        public let conditions: ComponentConditions<T>?

    }

    struct ComponentStates<T: PartialComponent>: PaywallComponentBase {

        public init(selected: T? = nil) {
            self.selected = selected
        }

        public let selected: T?

    }

    enum ComponentConditionsType {
        case compact, medium, expanded
    }

    struct ComponentConditions<T: PartialComponent>: PaywallComponentBase {
        public init(compact: T? = nil, medium: T? = nil, expanded: T? = nil) {
            self.compact = compact
            self.medium = medium
            self.expanded = expanded
        }

        public let compact: T?
        public let medium: T?
        public let expanded: T?

    }

}

#endif
