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

        let selected: T?
        let introOffer: T?

    }

    struct ComponentConditions<T: PartialComponent>: PaywallComponentBase {

        let mobileLandscape: T?
        let tablet: T?
        let tabletLandscape: T?
        let desktop: T?

    }

}

#endif
