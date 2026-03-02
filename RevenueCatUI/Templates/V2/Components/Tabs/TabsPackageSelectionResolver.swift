//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TabsPackageSelectionResolver.swift
//
//  Created by RevenueCat on 3/10/25.
//

import RevenueCat

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum TabsPackageSelectionResolver {

    struct PackageContextUpdate {
        let package: Package?
        let variableContext: PackageContext.VariableContext
    }

    struct UpdatePlan {
        let parentUpdate: PackageContextUpdate?
        let tabUpdate: PackageContextUpdate?
    }

    static func resolveTabSwitch(
        parentOwnedPackage: Package?,
        parentOwnedVariableContext: PackageContext.VariableContext,
        parentCurrentVariableContext: PackageContext.VariableContext,
        tabPackages: [Package],
        tabDefaultPackage: Package?
    ) -> UpdatePlan {
        if tabPackages.isEmpty {
            return .init(
                parentUpdate: .init(
                    package: parentOwnedPackage,
                    variableContext: parentOwnedVariableContext
                ),
                tabUpdate: nil
            )
        }

        let tabPackageIdentifiers = Set(tabPackages.map(\.identifier))

        if let parentPackage = parentOwnedPackage,
           tabPackageIdentifiers.contains(parentPackage.identifier) {
            let tabVariableContext = PackageContext.VariableContext(
                packages: tabPackages,
                showZeroDecimalPlacePrices: parentOwnedVariableContext.showZeroDecimalPlacePrices
            )
            let update = PackageContextUpdate(
                package: parentPackage,
                variableContext: tabVariableContext
            )
            return .init(parentUpdate: update, tabUpdate: update)
        }

        guard let defaultPackage = tabDefaultPackage else {
            return .init(parentUpdate: nil, tabUpdate: nil)
        }

        let tabVariableContext = PackageContext.VariableContext(
            packages: tabPackages,
            showZeroDecimalPlacePrices: parentCurrentVariableContext.showZeroDecimalPlacePrices
        )
        let update = PackageContextUpdate(
            package: defaultPackage,
            variableContext: tabVariableContext
        )
        return .init(parentUpdate: update, tabUpdate: update)
    }

}

#endif
