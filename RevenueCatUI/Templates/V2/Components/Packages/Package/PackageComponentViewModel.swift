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
@_spi(Internal) import RevenueCat

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PackageComponentViewModel {

    let isSelectedByDefault: Bool
    let promotionalOfferProductCode: String?
    let package: Package?
    let stackViewModel: StackComponentViewModel
    let hasPurchaseButton: Bool

    init(
        component: PaywallComponent.PackageComponent,
        offering: Offering,
        stackViewModel: StackComponentViewModel,
        hasPurchaseButton: Bool
    ) {
        self.isSelectedByDefault = component.isSelectedByDefault
        self.promotionalOfferProductCode = component.applePromoOfferProductCode

        self.package = offering.package(identifier: component.packageID)
        if package == nil {
            Logger.warning(Strings.paywall_could_not_find_package(component.packageID))
        }

        self.stackViewModel = stackViewModel
        self.hasPurchaseButton = hasPurchaseButton
    }

}

#endif
