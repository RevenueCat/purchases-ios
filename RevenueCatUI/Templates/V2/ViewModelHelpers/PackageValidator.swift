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

    typealias PackageInfo = (package: Package, isSelectedByDefault: Bool)

    private var packageInfos: [PackageInfo] = []

    func add(_ package: Package, isSelectedByDefault: Bool) {
        self.packageInfos.append((package, isSelectedByDefault))
    }

    var isValid: Bool {
        !packageInfos.isEmpty
    }

    var packages: [Package] {
        packageInfos.map(\.package)
    }

    var defaultSelectedPackage: Package? {
        let defaultSelectedPackage = packageInfos.first(where: { pkg in
            return pkg.isSelectedByDefault
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
