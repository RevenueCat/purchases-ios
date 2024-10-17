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

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PackageGroupComponentViewModel {

    private let localizedStrings: PaywallComponent.LocalizationDictionary
    private let component: PaywallComponent.PackageGroupComponent
    private let offering: Offering

    let defaultPackage: Package
    let stackComponentViewModel: StackComponentViewModel

    init(localizedStrings: PaywallComponent.LocalizationDictionary,
         component: PaywallComponent.PackageGroupComponent,
         offering: Offering) throws {
        self.localizedStrings = localizedStrings
        self.component = component
        self.offering = offering

        let info = try Self.getPackages(component: component, offering: offering)
        self.defaultPackage = info.defaultPackage

        self.stackComponentViewModel = try self.component.toStackComponentViewModel(
            components: info.availablePackageComponents.map { .package($0) },
            localizedStrings: localizedStrings,
            offering: offering
        )
    }

    static func getPackages(
        component: PaywallComponent.PackageGroupComponent,
        offering: Offering
    ) throws -> (defaultPackage: Package, availablePackageComponents: [PaywallComponent.PackageComponent]) {

        // Get list of available package components and their packages
        let availablePackageInfos = component.packages.compactMap { packageComponent in
            let pkg = offering.availablePackages.first(where: { $0.packageIdentifier == packageComponent.packageID })
            if let pkg {
                return (component: packageComponent, package: pkg)
            } else {
                return nil
            }
        }

        // We need packages
        guard let firstPackage = availablePackageInfos.first else {
            Logger.error(Strings.paywall_could_not_find_any_packages)
            throw PackageGroupValidationError.noAvailablePackages("No available packages found")
        }

        // Attempt to get default package
        let defaultPackage = availablePackageInfos.first { packageInfo in
            return packageInfo.package.id == component.defaultSelectedPackageID
        }

        let availablePackageComponents = availablePackageInfos.map { $0.component }
        if let defaultPackage {
            return (defaultPackage.package, availablePackageComponents)
        } else {
            Logger.warning(Strings.paywall_could_not_find_default_package(component.defaultSelectedPackageID))
            return (firstPackage.package, availablePackageComponents)
        }
    }

    enum PackageGroupValidationError: Error {

        case noAvailablePackages(String)

    }

}

#endif
