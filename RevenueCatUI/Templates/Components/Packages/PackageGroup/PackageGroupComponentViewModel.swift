//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageGroupComponentViewModel.swift
//
//  Created by Josh Holtz on 9/27/24.

import Foundation
import RevenueCat

// swiftlint:disable missing_docs

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public class PackageGroupComponentViewModel {

    private let localizedStrings: PaywallComponent.LocalizationDictionary
    private let component: PaywallComponent.PackageGroupComponent
    private let offering: Offering

    let stackComponentViewModel: StackComponentViewModel

    init(localizedStrings: PaywallComponent.LocalizationDictionary,
         component: PaywallComponent.PackageGroupComponent,
         offering: Offering) throws {
        self.localizedStrings = localizedStrings
        self.component = component
        self.offering = offering

        self.stackComponentViewModel = try self.component.toStackComponentViewModel(
            localizedStrings: localizedStrings,
            offering: offering
        )
    }

}

#endif
