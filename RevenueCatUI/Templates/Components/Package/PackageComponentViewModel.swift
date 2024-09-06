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
//  Created by James Borthwick on 2024-09-06.
// swiftlint:disable missing_docs

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public class PackageComponentViewModel: ObservableObject {

    private let component: PaywallComponent.PackageComponent
    let selectedViewModels: [PaywallComponentViewModel]
    let notSelectedViewModels: [PaywallComponentViewModel]
    let offering: Offering
    init(
        component: PaywallComponent.PackageComponent,
        offering: Offering,
        locale: Locale,
        localizedStrings: PaywallComponent.LocalizationDictionary
    ) throws {
        self.component = component
        self.offering = offering
        self.selectedViewModels = try component.selectedComponents.map {
            try $0.toViewModel(offering: offering, locale: locale, localizedStrings: localizedStrings)
        }
        self.notSelectedViewModels = try component.notSelectedComponents.map {
            try $0.toViewModel(offering: offering, locale: locale, localizedStrings: localizedStrings)
        }
    }

    var packageID: String {
        component.packageID
    }

    var title: String {
        guard let title = offering.availablePackages.first(where: { package in
            package.identifier == packageID
        }) else {
            return "Package for id \(packageID) not found"
        }
        return title.productName
    }

}

#endif
