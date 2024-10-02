//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Stackable+Extensions.swift
//
//  Created by Josh Holtz on 9/29/24.

import Foundation
import RevenueCat

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallComponent.StackableComponent {

    func toStackComponentViewModel(
        components: [PaywallComponent],
        localizedStrings: PaywallComponent.LocalizationDictionary,
        offering: Offering
    ) throws -> StackComponentViewModel {
        try StackComponentViewModel(
            component: .init(
                components: components,
                dimension: self.dimension,
                width: self.width,
                spacing: self.spacing,
                backgroundColor: self.backgroundColor,
                padding: self.padding,
                margin: self.margin,
                cornerRadiuses: self.cornerRadiuses,
                border: self.border
            ),
            localizedStrings: localizedStrings,
            offering: offering
        )
    }

}

#endif
