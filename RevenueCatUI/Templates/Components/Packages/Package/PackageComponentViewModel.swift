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

    let isSelectedByDefault: Bool
    let package: Package?
    let stackViewModel: StackComponentViewModel

    init(
        localizedStrings: PaywallComponent.LocalizationDictionary,
        component: PaywallComponent.PackageComponent,
        offering: Offering,
        stackViewModel: StackComponentViewModel
    ) {
        self.isSelectedByDefault = component.isSelectedByDefault
        self.package = offering.package(identifier: component.packageID)
        if package == nil {
            Logger.warning(Strings.paywall_could_not_find_package(component.packageID))
        }

        self.stackViewModel = stackViewModel
    }

}

#endif
