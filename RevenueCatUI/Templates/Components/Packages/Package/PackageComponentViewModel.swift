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
    let stackComponentViewModel: StackComponentViewModel

    init(localizedStrings: PaywallComponent.LocalizationDictionary,
         component: PaywallComponent.PackageComponent,
         offering: Offering) throws {
        self.localizedStrings = localizedStrings
        self.component = component
        self.offering = offering

        self.package = try Self.findPackage(identifier: component.packageID, offering: offering)

        self.stackComponentViewModel = try self.component.toStackComponentViewModel(
            components: self.component.components,
            localizedStrings: localizedStrings,
            offering: offering
        )
    }

    static func findPackage(identifier: String, offering: Offering) throws -> Package {
        guard let package = offering.package(identifier: identifier) else {
            Logger.error(Strings.paywall_could_not_find_package(identifier))
            throw PackageValidationError.missingPackage(
                "Missing package from offering: \"\(identifier)\""
            )
        }

        return package
    }

    enum PackageValidationError: Error {

        case missingPackage(String)

    }

}

#endif
