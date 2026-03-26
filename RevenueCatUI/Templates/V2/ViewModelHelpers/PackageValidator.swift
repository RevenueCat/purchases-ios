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

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class PackageValidator {

    // swiftlint:disable:next line_length
    typealias PackageInfo = (package: Package, isSelectedByDefault: Bool, promotionalOfferProductCode: String?, isStaticallyHidden: Bool)

    private(set) var packageInfos: [PackageInfo] = []
    // Parallel to packageInfos; kept in sync by add(_:viewModel:) and merge(from:).
    private(set) var packageViewModels: [PackageComponentViewModel] = []

    func add(_ packageInfo: PackageInfo, viewModel: PackageComponentViewModel) {
        self.packageInfos.append(packageInfo)
        self.packageViewModels.append(viewModel)
    }

    /// Merges all entries from `other` into this validator (used when tab-level validators
    /// are folded into the global paywall validator).
    func merge(from other: PackageValidator) {
        self.packageInfos.append(contentsOf: other.packageInfos)
        self.packageViewModels.append(contentsOf: other.packageViewModels)
    }

    var isValid: Bool {
        !packageInfos.isEmpty
    }

    var packages: [Package] {
        packageInfos.map(\.package)
    }

    /// Fast static selection used for the initial render before eligibility is known.
    /// Skips packages that are unconditionally hidden (visible=false, no overrides).
    var defaultSelectedPackage: Package? {
        let visiblePackages = packageInfos.filter { !$0.isStaticallyHidden }

        let defaultSelectedPackage = visiblePackages.first(where: { pkg in
            return pkg.isSelectedByDefault
        })

        if let defaultSelectedPackage {
            return defaultSelectedPackage.package
        }

        Logger.warning(Strings.paywall_could_not_find_default_package)
        return visiblePackages.first?.package
    }

    /// Runtime selection used after intro/promo eligibility is known.
    /// Evaluates full visibility (including overrides) for each package.
    @MainActor
    func resolveDefaultSelectedPackage(
        condition: ScreenCondition,
        introEligibilityContext: IntroOfferEligibilityContext,
        promoOfferCache: PaywallPromoOfferCache,
        customVariables: [String: CustomVariableValue]
    ) -> Package? {
        // swiftlint:disable:next identifier_name
        let visibleViewModels = packageViewModels.filter { vm in
            guard let package = vm.package else { return false }
            return vm.visible(
                state: .default,
                condition: condition,
                isEligibleForIntroOffer: introEligibilityContext.isEligible(package: package),
                isEligibleForPromoOffer: promoOfferCache.isMostLikelyEligible(for: package),
                selectedPackageId: nil,
                customVariables: customVariables
            )
        }

        if let defaultSelected = visibleViewModels.first(where: { $0.isSelectedByDefault }) {
            return defaultSelected.package
        }

        Logger.warning(Strings.paywall_could_not_find_default_package)
        return visibleViewModels.first?.package
    }

}

#endif
