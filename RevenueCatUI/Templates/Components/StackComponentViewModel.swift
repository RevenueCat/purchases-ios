//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StackComponentView.swift
//
//  Created by James Borthwick on 2024-08-20.

import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public class StackComponentViewModel: ObservableObject {

    let locale: Locale
    let component: PaywallComponent.StackComponent
    let viewModels: [PaywallComponentViewModel]

    init(locale: Locale,
         component: PaywallComponent.StackComponent,
         localization: [String: String],
         offering: Offering
    ) {
        self.locale = locale
        self.component = component
        self.viewModels = component.components.map {
            $0.toViewModel(offering: offering, locale: locale, localization: localization)
        }

    }

}

#endif
