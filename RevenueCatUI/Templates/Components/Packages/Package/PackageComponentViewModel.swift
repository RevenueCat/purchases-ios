//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageComponentViewModel.swift
//
//  Created by Josh Holtz on 9/27/24.

import Foundation
import RevenueCat

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PackageComponentViewModel {

    private let localizedStrings: PaywallComponent.LocalizationDictionary
    private let component: PaywallComponent.PackageComponent
    private let offering: Offering

    let package: Package
    let stackViewModel: StackComponentViewModel

    init(localizedStrings: PaywallComponent.LocalizationDictionary,
         component: PaywallComponent.PackageComponent,
         offering: Offering,
         package: Package) throws {
        self.localizedStrings = localizedStrings
        self.component = component
        self.offering = offering
        self.package = package

        self.stackViewModel = try StackComponentViewModel(
            component: component.stack,
            localizedStrings: localizedStrings,
            offering: offering
        )
    }

}

#endif
