//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ButtonComponentViewModel.swift
//
//  Created by Jay Shortway on 02/10/2024.
//
// swiftlint:disable missing_docs

import Foundation
import RevenueCat

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public class ButtonComponentViewModel {

    internal let component: PaywallComponent.ButtonComponent
    internal let localizedStrings: PaywallComponent.LocalizationDictionary
    let stackViewModel: StackComponentViewModel

    init(
        component: PaywallComponent.ButtonComponent,
        locale: Locale,
        localizedStrings: PaywallComponent.LocalizationDictionary,
        offering: Offering
    ) throws {
        self.component = component
        self.localizedStrings = localizedStrings
        self.stackViewModel = try StackComponentViewModel(
            locale: locale,
            component: component.stack,
            localizedStrings: localizedStrings,
            offering: offering
        )
    }

}

#endif
