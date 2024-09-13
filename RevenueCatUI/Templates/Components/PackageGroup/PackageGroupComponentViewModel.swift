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
//  Created by James Borthwick on 2024-09-06.
// swiftlint:disable missing_docs

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public class PackageGroupComponentViewModel: ObservableObject {

    private let component: PaywallComponent.PackageGroupComponent
    let viewModels: [PaywallComponentViewModel]

    var defaultSelectedPackageID: String {
        component.defaultSelectedPackageID
    }

    init(
         component: PaywallComponent.PackageGroupComponent,
         offering: Offering,
         locale: Locale,
         localizedStrings: PaywallComponent.LocalizationDictionary
    ) throws {
        self.component = component
        self.viewModels = try component.components.map {
            try $0.toViewModel(offering: offering, locale: locale, localizedStrings: localizedStrings)
        }
    }

}

#endif
