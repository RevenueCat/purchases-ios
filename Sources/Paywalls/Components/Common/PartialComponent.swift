//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PartialComponent.swift
//
//  Created by Josh Holtz on 10/26/24.
//
// swiftlint:disable missing_docs

import Foundation

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    protocol PartialComponent: PaywallComponentBase {}

    struct ComponentState<T: PartialComponent>: PaywallComponentBase {

        public init(selected: T?, introOffer: T?) {
            self.selected = selected
            self.introOffer = introOffer
        }

        public let selected: T?
        public let introOffer: T?

    }

    enum ComponentConditionsType {
        case mobileLandscape, tablet, tabletLandscape, desktop
    }

    struct ComponentConditions<T: PartialComponent>: PaywallComponentBase {

        public init(
            mobileLandscape: T? = nil,
            tablet: T? = nil,
            tabletLandscape: T? = nil,
            desktop: T? = nil
        ) {
            self.mobileLandscape = mobileLandscape
            self.tablet = tablet
            self.tabletLandscape = tabletLandscape
            self.desktop = desktop
        }

        public let mobileLandscape: T?
        public let tablet: T?
        public let tabletLandscape: T?
        public let desktop: T?

    }

}

#endif
