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

    var viewModels: [PaywallComponentViewModel]

    private let component: PaywallComponent.PackageComponent
    private let offering: Offering
    let package: Package

    init(
        component: PaywallComponent.PackageComponent,
        offering: Offering,
        locale: Locale,
        localizedStrings: PaywallComponent.LocalizationDictionary
    ) throws {
        self.component = component
        self.offering = offering
        self.package = try Self.retrievePackage(from: offering, id: component.packageID)
        self.viewModels = try component.components.map {
            try $0.toViewModel(offering: offering, locale: locale, localizedStrings: localizedStrings)
        }

    }

    var packageID: String {
        component.packageID
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PackageComponentViewModel {

    enum PackageValidationError: Error {

        case missingPackage(String)

    }

    static func retrievePackage(from offering: Offering, id packageID: String) throws -> Package {
        guard let thisPackage = offering.availablePackages.first(where: { package in
            package.identifier == packageID
        }) else {
            throw PackageValidationError.missingPackage("Package for id \(packageID) not found.")
        }

        return thisPackage
    }

}

#endif
