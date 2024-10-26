//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageValidator.swift
//
//  Created by Josh Holtz on 10/25/24.

import Foundation
import RevenueCat

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PackageValidator {

    private var packageViewModels: [PackageComponentViewModel] = []

    typealias PackageInfo = (package: Package, isDefaultSelected: Bool)

    var packageInfos: [PackageInfo] {
        self.packageViewModels.compactMap { packageViewModel in
            guard let package = packageViewModel.package else {
                return nil
            }
            return (package: package, isDefaultSelected: packageViewModel.isDefaultSelected)
        }
    }

    func add(_ packageViewModel: PackageComponentViewModel) {
        self.packageViewModels.append(packageViewModel)
    }

    var isValid: Bool {
        !packageInfos.isEmpty
    }

    var defaultSelectedPackage: Package? {
        let defaultSelectedPackage = packageInfos.first(where: { pkg in
            return pkg.isDefaultSelected
        })

        // Set selected package
        if let defaultSelectedPackage {
            return defaultSelectedPackage.package
        }

        Logger.warning(Strings.paywall_could_not_find_default_package)
        return packageInfos.first?.package
    }

}

#endif
